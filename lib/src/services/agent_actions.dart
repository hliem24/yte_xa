import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state.dart';
import '../storage.dart';

/// ---------- Action types ----------
sealed class AgentAction { const AgentAction(); }

class StockInRequestAction extends AgentAction {
  final String medicineId; final int qty; final String? note;
  const StockInRequestAction({required this.medicineId, required this.qty, this.note});
}

class ApproveRequestAction extends AgentAction {
  final String requestId; final bool approve; final String? note;
  const ApproveRequestAction({required this.requestId, required this.approve, this.note});
}

class StockOut extends AgentAction {
  final String medicineId; final int qty; final String? reason;
  const StockOut({required this.medicineId, required this.qty, this.reason});
}

class CreateMedicine extends AgentAction {
  final String id; final String name; final String unit;
  const CreateMedicine({required this.id, required this.name, required this.unit});
}

class QuickReport extends AgentAction { const QuickReport(); }

/// ---------- Validate helpers ----------
String? _requireNonEmpty(String v, String label) =>
    v.trim().isEmpty ? 'Thiếu $label.' : null;
String? _requirePositive(int n, String label) =>
    n <= 0 ? '$label phải > 0.' : null;

/// ---------- Resolver mã thuốc ----------
String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
String? _resolveMedicineId(WidgetRef ref, String raw) {
  final inv  = ref.read(inventoryProvider);
  final meds = inv.medicines;
  if (meds.isEmpty) return null;

  final want = _norm(raw);
  // 1) Khớp ID exact
  final exact = meds.where((m) => m.id.toLowerCase() == raw.toLowerCase());
  if (exact.isNotEmpty) return exact.first.id;

  // 2) Khớp ID bắt đầu (PARA -> PARA500)
  final prefix = meds.where((m) => m.id.toLowerCase().startsWith(raw.toLowerCase()));
  if (prefix.isNotEmpty) return prefix.first.id;

  // 3) Khớp theo tên chứa (paracetamol -> PARA500)
  final byName = meds.where((m) => _norm(m.name).contains(want));
  if (byName.isNotEmpty) return byName.first.id;

  return null;
}

/// Cho phép UI kiểm tra trước khi thực thi (và để lọc rác từ model)
bool validateActionAgainstState(WidgetRef ref, AgentAction a) {
  final inv = ref.read(inventoryProvider);
  bool okId(String id) => inv.medicines.any((m) => m.id.toLowerCase() == id.toLowerCase());

  if (a is StockInRequestAction) {
    return a.qty > 0 && _resolveMedicineId(ref, a.medicineId) != null;
  }
  if (a is StockOut) {
    final real = _resolveMedicineId(ref, a.medicineId);
    return a.qty > 0 && real != null;
  }
  if (a is ApproveRequestAction) {
    return a.requestId.trim().isNotEmpty; // còn kiểm tra sâu khi reviewRequest
  }
  if (a is CreateMedicine) {
    return a.id.isNotEmpty && a.name.isNotEmpty && a.unit.isNotEmpty;
  }
  if (a is QuickReport) return true;
  return false;
}

/// ---------- Execute ----------
Future<String> executeAction(WidgetRef ref, AgentAction action) async {
  const wh = 'KHO_1';
  final auth = ref.read(authProvider);
  final user = auth is Authenticated ? auth.user : null;
  final role = user?.role ?? 'staff';

  if (action is StockInRequestAction) {
    final idErr  = _requireNonEmpty(action.medicineId, 'mã thuốc (medicineId)');
    final qtyErr = _requirePositive(action.qty, 'Số lượng (qty)');
    if (idErr != null || qtyErr != null) {
      return '⚠️ ${[idErr, qtyErr].whereType<String>().join(" ")}\n'
             'Ví dụ: `wms { "type":"stockInRequest", "params":{"medicineId":"PARA500","qty":10,"note":"..."} }`.';
    }

    final resolved = _resolveMedicineId(ref, action.medicineId);
    if (resolved == null) {
      return '⚠️ Không tìm thấy mã **${action.medicineId}** trong kho. Bạn có thể gõ đúng mã (ví dụ: PARA500) hoặc tên gần đúng (Paracetamol).';
    }

    final id = await ref.read(inventoryProvider.notifier).createStockInRequest(
      medicineId: resolved,
      qty: action.qty,
      note: action.note ?? '',
      requester: user?.username ?? 'unknown',
    );
    final suffix = resolved.toUpperCase() == action.medicineId.toUpperCase()
        ? ''
        : ' (đã map từ "${action.medicineId}" → "$resolved")';
    return '📝 Đã tạo **phiếu yêu cầu nhập** (#$id) cho $resolved số lượng ${action.qty}.$suffix Chờ admin duyệt.';
  }

  if (action is ApproveRequestAction) {
    if (role != 'admin') return '⛔ Chỉ admin mới được duyệt yêu cầu.';
    final idErr = _requireNonEmpty(action.requestId, 'mã phiếu (requestId)');
    if (idErr != null) {
      return '⚠️ $idErr Ví dụ: `wms { "type":"approveRequest", "params":{"requestId":"RQ-...","approve":true} }`.';
    }
    final ok = await ref.read(inventoryProvider.notifier).reviewRequest(
      requestId: action.requestId,
      approve: action.approve,
      reviewer: user?.username ?? 'admin',
      note: action.note ?? '',
    );
    if (!ok) return '⚠️ Không tìm thấy hoặc phiếu #${action.requestId} đã được xử lý.';
    return action.approve
      ? '✅ Đã duyệt và nhập kho cho phiếu #${action.requestId}.'
      : '❌ Đã từ chối phiếu #${action.requestId}.';
  }

  if (action is StockOut) {
    final idErr  = _requireNonEmpty(action.medicineId, 'mã thuốc (medicineId)');
    final qtyErr = _requirePositive(action.qty, 'Số lượng (qty)');
    if (idErr != null || qtyErr != null) {
      return '⚠️ ${[idErr, qtyErr].whereType<String>().join(" ")}\n'
             'Ví dụ: `wms { "type":"stockOut", "params":{"medicineId":"PARA500","qty":5,"reason":"cấp phát"} }`.';
    }

    final resolved = _resolveMedicineId(ref, action.medicineId);
    if (resolved == null) {
      return '⚠️ Không tìm thấy mã **${action.medicineId}** trong kho. Vui lòng cung cấp mã đúng.';
    }

    await ref.read(inventoryProvider.notifier)
        .addMovement(resolved, wh, 'out', action.qty, reason: action.reason);
    final reasonStr = (action.reason != null && action.reason!.isNotEmpty)
        ? ' • Lý do: ${action.reason}' : '';
    final suffix = resolved.toUpperCase() == action.medicineId.toUpperCase()
        ? ''
        : ' (đã map từ "${action.medicineId}" → "$resolved")';
    return '✅ Đã **xuất** ${action.qty} từ $resolved$reasonStr.$suffix';
  }

  if (action is CreateMedicine) {
    final idErr   = _requireNonEmpty(action.id, 'ID');
    final nameErr = _requireNonEmpty(action.name, 'tên');
    final unitErr = _requireNonEmpty(action.unit, 'đơn vị');
    if (idErr != null || nameErr != null || unitErr != null) {
      return '⚠️ ${[idErr, nameErr, unitErr].whereType<String>().join(" ")}\n'
             'Ví dụ: `wms { "type":"createMedicine", "params":{"id":"ZINC50","name":"Kẽm 50mg","unit":"vỉ"} }`.';
    }
    final inv = ref.read(inventoryProvider);
    final exists = inv.medicines.any((m) => m.id.toUpperCase() == action.id.toUpperCase());
    if (exists) return 'ℹ️ Thuốc/vật tư **${action.id}** đã tồn tại.';
    final meds = [...inv.medicines, Medicine(id: action.id, name: action.name, unit: action.unit, lots: const [])];
    final repo = ref.read(storageProvider);
    await repo.saveMedicines(meds);
    ref.read(inventoryProvider.notifier).state = inv.copyWith(medicines: meds);
    return '✅ Đã tạo: **${action.name}** (${action.id}) • đơn vị **${action.unit}**.';
  }

  if (action is QuickReport) return _quickReportText(ref);
  return '❓ Không nhận diện được hành động.';
}

/// ---------- Report ----------
String _quickReportText(WidgetRef ref) {
  final inv = ref.read(inventoryProvider);
  final meds = inv.medicines;
  final total = meds.fold<int>(0, (s, m) => s + m.totalQuantity);
  final now = DateTime.now();

  bool near(Medicine m) {
    final ne = m.nearestExpiry;
    return ne != null && ne.difference(now).inDays <= 30;
  }

  final nearList = meds.where(near).toList();
  final low  = meds.where((m) => m.totalQuantity < 20).toList();

  final b = StringBuffer();
  b.writeln('📦 **Tổng tồn kho:** $total đơn vị');
  b.writeln(nearList.isNotEmpty
      ? '⏳ **Sắp hết hạn (≤30 ngày):** ${nearList.map((m) => m.id).take(6).join(", ")}${nearList.length>6?"…":""}'
      : '⏳ Không có mặt hàng sắp hết hạn.');
  b.writeln(low.isNotEmpty
      ? '📉 **Tồn thấp (<20):** ${low.map((m) => "${m.id}(${m.totalQuantity})").take(6).join(", ")}${low.length>6?"…":""}'
      : '📉 Không có mặt hàng tồn thấp.');
  return b.toString();
}

/// ---------- NL parser ----------
AgentAction? parseVietnameseFreeText(String s) {
  final text = s.toLowerCase().trim();

  if (RegExp(r'(tổng|bao nhiêu|báo cáo|bao cao)').hasMatch(text)) {
    return const QuickReport();
  }

  // nhập: 2 thứ tự
  final inA = RegExp(r'(nhap|nhập)\s+([a-z0-9_]+)\s+(\d+)(?:\s+ghichu\s+(.+))?').firstMatch(text);
  if (inA != null) {
    final id  = inA.group(2)!.toUpperCase();
    final qty = int.parse(inA.group(3)!);
    final note = inA.group(4);
    return StockInRequestAction(medicineId: id, qty: qty, note: note);
  }
  final inB = RegExp(r'(nhap|nhập)\s+(\d+)\s+([a-z0-9_]+)(?:\s+ghichu\s+(.+))?').firstMatch(text);
  if (inB != null) {
    final qty = int.parse(inB.group(2)!);
    final id  = inB.group(3)!.toUpperCase();
    final note = inB.group(4);
    return StockInRequestAction(medicineId: id, qty: qty, note: note);
  }

  // xuất
  final out = RegExp(r'(xuat|xuất)\s+([a-z0-9_]+)\s+(\d+)(?:\s+lydo\s+(.+))?').firstMatch(text);
  if (out != null) {
    final id  = out.group(2)!.toUpperCase();
    final qty = int.parse(out.group(3)!);
    final reason = out.group(4);
    return StockOut(medicineId: id, qty: qty, reason: reason);
  }

  // tạo thuốc
  final mk = RegExp(
    r'(tao|tạo)\s+(thuoc|vattu|vật tư)\s+([a-z0-9_]+)\s+(.+?)\s+(vien|vi|goi|gói|hộp|hop|chai|ống|ong)',
    caseSensitive: false, unicode: true).firstMatch(text);
  if (mk != null) {
    final id   = mk.group(3)!.toUpperCase();
    final name = mk.group(4)!.trim();
    final unit = mk.group(5)!.toLowerCase().replaceAll('hop', 'hộp').replaceAll('ong', 'ống');
    return CreateMedicine(id: id, name: name, unit: unit);
  }

  return null;
}

/// ---------- Extractors ----------
AgentAction? extractActionFromAssistantStrict(String answer) {
  // Chỉ chấp nhận khi có `wms` rồi mới tìm JSON
  final tag = RegExp(r'wms\b', caseSensitive: false).firstMatch(answer);
  if (tag == null) return null;

  final after = answer.substring(tag.end);
  final fenced = RegExp(r'```(?:json|js|)\s*({[\s\S]*?})\s*```', dotAll: true).firstMatch(after);
  if (fenced != null) return _fromJsonSafe(fenced.group(1)!);

  final brace = RegExp(r'({[\s\S]*?})', dotAll: true).firstMatch(after);
  if (brace != null) return _fromJsonSafe(brace.group(1)!);

  return null;
}

AgentAction? _fromJsonSafe(String jsonStr) {
  try {
    final j = json.decode(jsonStr);
    if (j is! Map) return null;
    final type = (j['type'] ?? '').toString();
    final params = Map<String, dynamic>.from(j['params'] ?? {});

    switch (type) {
      case 'stockInRequest':
        return StockInRequestAction(
          medicineId: (params['medicineId'] ?? '').toString().toUpperCase(),
          qty: int.tryParse('${params['qty']}') ?? 0,
          note: (params['note'] ?? '').toString(),
        );
      case 'approveRequest':
        return ApproveRequestAction(
          requestId: (params['requestId'] ?? '').toString(),
          approve: (params['approve'] == true) || (params['approve'].toString() == 'true'),
          note: (params['note'] ?? '').toString(),
        );
      case 'stockOut':
        return StockOut(
          medicineId: (params['medicineId'] ?? '').toString().toUpperCase(),
          qty: int.tryParse('${params['qty']}') ?? 0,
          reason: (params['reason'] ?? '').toString(),
        );
      case 'createMedicine':
        return CreateMedicine(
          id: (params['id'] ?? '').toString().toUpperCase(),
          name: (params['name'] ?? '').toString(),
          unit: (params['unit'] ?? '').toString(),
        );
      case 'quickReport':
        return const QuickReport();

      // tương thích ngược (model cũ)
      case 'stockIn':
        return StockInRequestAction(
          medicineId: (params['medicineId'] ?? '').toString().toUpperCase(),
          qty: int.tryParse('${params['qty']}') ?? 0,
          note: (params['note'] ?? '').toString(),
        );
    }
  } catch (_) {}
  return null;
}
