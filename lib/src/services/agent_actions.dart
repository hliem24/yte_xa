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
             'Gửi lại: `wms { "type":"stockInRequest", "params":{"medicineId":"PARA500","qty":10,"note":"..."} }` '
             'hoặc nhắn: `nhập PARA500 10 ghichu viện trợ` / `nhập 10 PARA500 ghichu viện trợ`.';
    }
    final id = await ref.read(inventoryProvider.notifier).createStockInRequest(
      medicineId: action.medicineId,
      qty: action.qty,
      note: action.note ?? '',
      requester: user?.username ?? 'unknown',
    );
    return '📝 Đã tạo **phiếu yêu cầu nhập** (#$id) cho ${action.medicineId} số lượng ${action.qty}. Chờ admin duyệt.';
  }

  if (action is ApproveRequestAction) {
    if (role != 'admin') return '⛔ Chỉ admin mới được duyệt yêu cầu.';
    final idErr = _requireNonEmpty(action.requestId, 'mã phiếu (requestId)');
    if (idErr != null) {
      return '⚠️ $idErr Gửi lại: `wms { "type":"approveRequest", "params":{"requestId":"RQ-...","approve":true,"note":"..."} }`.';
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
             'Gửi lại: `wms { "type":"stockOut", "params":{"medicineId":"PARA500","qty":5,"reason":"cấp phát"} }` '
             'hoặc nhắn: `xuất PARA500 5 lydo cấp phát`.';
    }
    await ref.read(inventoryProvider.notifier)
        .addMovement(action.medicineId, wh, 'out', action.qty, reason: action.reason);
    final reasonStr = (action.reason != null && action.reason!.isNotEmpty)
        ? ' • Lý do: ${action.reason}' : '';
    return '✅ Đã **xuất** ${action.qty} từ ${action.medicineId}$reasonStr.';
  }

  if (action is CreateMedicine) {
    final idErr   = _requireNonEmpty(action.id, 'ID');
    final nameErr = _requireNonEmpty(action.name, 'tên');
    final unitErr = _requireNonEmpty(action.unit, 'đơn vị');
    if (idErr != null || nameErr != null || unitErr != null) {
      return '⚠️ ${[idErr, nameErr, unitErr].whereType<String>().join(" ")}\n'
             'Gửi lại: `wms { "type":"createMedicine", "params":{"id":"ZINC50","name":"Kẽm 50mg","unit":"vỉ"} }`.';
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

/// ---------- Natural-language parser ----------
AgentAction? parseVietnameseFreeText(String s) {
  final text = s.toLowerCase().trim();

  if (RegExp(r'(tổng|bao nhiêu|báo cáo|bao cao)').hasMatch(text)) {
    return const QuickReport();
  }

  // nhập: hỗ trợ 2 thứ tự
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

/// ---------- Robust extractor ----------
AgentAction? extractActionFromAssistant(String answer) {
  // 1) Tìm sau chữ "wms" (không phân biệt hoa/thường)
  final tag = RegExp(r'wms\b', caseSensitive: false);
  final tagMatch = tag.firstMatch(answer);
  if (tagMatch != null) {
    final after = answer.substring(tagMatch.end);
    // bắt khối ``` ... ``` hoặc { ... }
    final fenced = RegExp(r'```(?:json|js|)\s*({[\s\S]*?})\s*```', dotAll: true)
        .firstMatch(after);
    if (fenced != null) {
      final obj = fenced.group(1)!;
      final a = _fromJsonSafe(obj);
      if (a != null) return a;
    }
    final brace = RegExp(r'({[\s\S]*?})', dotAll: true).firstMatch(after);
    if (brace != null) {
      final obj = brace.group(1)!;
      final a = _fromJsonSafe(obj);
      if (a != null) return a;
    }
  }

  // 2) Không có 'wms': quét tất cả JSON trong câu
  for (final m in RegExp(r'({[\s\S]*?})', dotAll: true).allMatches(answer)) {
    final a = _fromJsonSafe(m.group(1)!);
    if (a != null) return a;
  }
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

      // tương thích ngược
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
