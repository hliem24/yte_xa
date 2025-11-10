import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'storage.dart';

// ---------- providers ----------
final storageProvider = Provider<LocalStorageRepo>((_) => LocalStorageRepo());

// ---------- auth ----------
sealed class AuthState { const AuthState(); }
class Unauth extends AuthState { const Unauth(); }
class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
}

final authProvider =
  StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));

class AuthController extends StateNotifier<AuthState> {
  final Ref ref;
  AuthController(this.ref) : super(const Unauth()) { _init(); }

  Future<void> _init() async {
    final u = await ref.read(storageProvider).getUser();
    if (u != null) state = Authenticated(u);
  }

  Future<bool> login(String username, String password) async {
    final ok = (username=='admin' && password=='123456') ||
               (username=='ytx'   && password=='123456');
    if (!ok) return false;
    final u = User(username: username, role: username=='admin' ? 'admin' : 'staff');
    await ref.read(storageProvider).saveUser(u);
    state = Authenticated(u);
    return true;
  }

  Future<void> logout() async {
    await ref.read(storageProvider).saveUser(null);
    state = const Unauth();
  }
}

// ---------- inventory ----------
class InventoryState {
  final List<Medicine> medicines;
  final List<Movement> movements;
  final List<StockInRequest> requests;

  const InventoryState({
    required this.medicines,
    required this.movements,
    required this.requests,
  });

  InventoryState copyWith({
    List<Medicine>? medicines,
    List<Movement>? movements,
    List<StockInRequest>? requests,
  }) => InventoryState(
        medicines: medicines ?? this.medicines,
        movements: movements ?? this.movements,
        requests:  requests  ?? this.requests,
      );
}

final inventoryProvider =
  StateNotifierProvider<InventoryController, InventoryState>(
    (ref) => InventoryController(ref),
  );

class InventoryController extends StateNotifier<InventoryState> {
  final Ref ref;
  static const String defaultWarehouse = 'KHO_1';

  InventoryController(this.ref)
      : super(const InventoryState(medicines: [], movements: [], requests: [])) {
    _init();
  }

  Future<void> _init() async {
    final repo = ref.read(storageProvider);
    final meds = await repo.loadMedicines();
    final mvs  = await repo.loadMovements();
    final reqs = await repo.loadStockInRequests();

    // ✅ Lần đầu trống → seed dữ liệu mẫu
    if (meds.isEmpty) {
      await _seedDemo();
      return;
    }

    state = InventoryState(medicines: meds, movements: mvs, requests: reqs);
  }

  /// Seed dữ liệu mặc định để dùng ngay (hiện ở Trang chủ & Dropdown)
  Future<void> _seedDemo() async {
    final now = DateTime.now();

    final meds = <Medicine>[
      Medicine(
        id: 'PARA500', name: 'Paracetamol 500mg', unit: 'vỉ',
        lots: [
          MedicineLot(lotId: 'P1', expiry: now.add(const Duration(days: 60)),  quantity: 40, warehouseId: defaultWarehouse),
          MedicineLot(lotId: 'P2', expiry: now.add(const Duration(days: 180)), quantity: 110, warehouseId: defaultWarehouse),
        ],
      ),
      Medicine(
        id: 'AMOX500', name: 'Amoxicillin 500mg', unit: 'vỉ',
        lots: [
          MedicineLot(lotId: 'A1', expiry: now.add(const Duration(days: 210)), quantity: 28, warehouseId: defaultWarehouse),
        ],
      ),
      Medicine(
        id: 'IBU200', name: 'Ibuprofen 200mg', unit: 'vỉ',
        lots: [
          MedicineLot(lotId: 'I1', expiry: now.add(const Duration(days: 120)), quantity: 20, warehouseId: defaultWarehouse),
        ],
      ),
      Medicine(
        id: 'PVDI', name: 'Povidone-Iodine (Betadine)', unit: 'chai',
        lots: [
          MedicineLot(lotId: 'PO1', expiry: now.add(const Duration(days: 365)), quantity: 80, warehouseId: defaultWarehouse),
        ],
      ),
      Medicine(
        id: 'NACL09', name: 'Natri Clorid 0.9%', unit: 'chai',
        lots: [
          MedicineLot(lotId: 'N1', expiry: now.add(const Duration(days: 300)), quantity: 80, warehouseId: defaultWarehouse),
        ],
      ),
      Medicine(
        id: 'COTTON', name: 'Bông gạc y tế', unit: 'bịch',
        lots: [
          MedicineLot(lotId: 'B1', expiry: now.add(const Duration(days: 400)), quantity: 30, warehouseId: defaultWarehouse),
        ],
      ),
    ];

    state = state.copyWith(medicines: meds, movements: [], requests: []);
    final repo = ref.read(storageProvider);
    await repo.saveMedicines(meds);
    await repo.saveMovements([]);
    await repo.saveStockInRequests([]);
  }

  int stockOf(String medId, [String warehouseId = defaultWarehouse]) {
    final med = state.medicines.firstWhere(
      (m)=>m.id.toLowerCase()==medId.toLowerCase(),
      orElse: ()=>const Medicine(id:'',name:'',unit:'',lots:[]));
    if (med.id.isEmpty) return 0;
    return med.lots
      .where((l)=>l.warehouseId==warehouseId)
      .fold(0,(s,l)=>s+l.quantity);
  }

  String _guessUnit(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'(găng|khẩu|mask)').hasMatch(t)) return 'hộp';
    if (RegExp(r'(bông|gạc|gauze)').hasMatch(t)) return 'bịch';
    if (RegExp(r'(dây|truyền)').hasMatch(t)) return 'bộ';
    if (RegExp(r'(nhiệt kế|máy)').hasMatch(t)) return 'cái';
    if (RegExp(r'(cồn|nacl|dung dịch)').hasMatch(t)) return 'chai';
    if (RegExp(r'(oresol|gói)').hasMatch(t)) return 'gói';
    if (RegExp(r'(\d+ ?mg|\d+ ?mcg|\d+ ?g\b)').hasMatch(t)) return 'vỉ';
    return 'gói';
  }

  Medicine _ensureMedicine(String medId, {String? displayName}) {
    final meds = [...state.medicines];
    final idx = meds.indexWhere((m) => m.id.toLowerCase() == medId.toLowerCase());
    if (idx >= 0) return meds[idx];

    final unit = _guessUnit(displayName ?? medId);
    final newMed = Medicine(id: medId.toUpperCase(), name: displayName ?? medId.toUpperCase(), unit: unit, lots: const []);
    meds.add(newMed);
    state = state.copyWith(medicines: meds);
    ref.read(storageProvider).saveMedicines(meds);
    return newMed;
  }

  Future<void> addMovement(
    String medicineId,
    String warehouseId,
    String type,
    int qty, {
    String? displayName,
    String? reason, // ✔ lý do xuất
  }) async {
    if (qty <= 0) return;

    final repo = ref.read(storageProvider);
    final id = 'MV-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';

    List<Medicine> meds = [...state.medicines];
    int idx = meds.indexWhere((m) => m.id.toLowerCase() == medicineId.toLowerCase());

    if (idx < 0 && type == 'in') {
      final created = _ensureMedicine(medicineId, displayName: displayName);
      meds = [...state.medicines];
      idx = meds.indexWhere((m) => m.id == created.id);
    }
    if (idx < 0) return;

    final med = meds[idx];
    var lots = [...med.lots];

    if (type == 'in') {
      lots.add(MedicineLot(
        lotId: 'L${Random().nextInt(9999)}',
        expiry: DateTime.now().add(const Duration(days: 365)),
        quantity: qty,
        warehouseId: warehouseId,
      ));
    } else {
      // FEFO
      final indices = <int>[];
      for (var i = 0; i < lots.length; i++) {
        if (lots[i].warehouseId == warehouseId) indices.add(i);
      }
      indices.sort((a,b)=>lots[a].expiry.compareTo(lots[b].expiry));
      var remain = qty;
      for (final i in indices) {
        if (remain<=0) break;
        final l = lots[i];
        final take = remain <= l.quantity ? remain : l.quantity;
        lots[i] = MedicineLot(
          lotId: l.lotId, expiry: l.expiry, quantity: l.quantity - take, warehouseId: l.warehouseId);
        remain -= take;
      }
      if (remain > 0) return;
      lots = lots.where((l)=>l.quantity>0).toList();
    }

    meds[idx] = Medicine(id: med.id, name: med.name, unit: med.unit, lots: lots);
    final mv = Movement(
      id: id,
      medicineId: meds[idx].id,
      warehouseId: warehouseId,
      type: type,
      quantity: qty,
      time: DateTime.now(),
      reason: reason,
    );

    final moves = [...state.movements, mv];
    state = state.copyWith(medicines: meds, movements: moves);
    await repo.saveMedicines(meds);
    await repo.saveMovements(moves);
  }

  // ---------- StockIn requests ----------
  Future<String> createStockInRequest({
    required String medicineId,
    required int qty,
    required String requester,
    String note = '',
  }) async {
    final repo = ref.read(storageProvider);
    final id = 'RQ-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}';

    final req = StockInRequest(
      id: id,
      medicineId: medicineId.toUpperCase(),
      qty: qty,
      requester: requester,
      status: 'pending',
      note: note,
      createdAt: DateTime.now(),
    );
    final reqs = [...state.requests, req];
    state = state.copyWith(requests: reqs);
    await repo.saveStockInRequests(reqs);
    return id;
  }

  Future<bool> reviewRequest({
    required String requestId,
    required bool approve,
    required String reviewer,
    required String note,
  }) async {
    final repo = ref.read(storageProvider);
    final reqs = [...state.requests];
    final idx = reqs.indexWhere((r) => r.id == requestId);
    if (idx < 0) return false;

    final r = reqs[idx];
    if (r.status != 'pending') return false;

    if (approve) {
      await addMovement(r.medicineId, defaultWarehouse, 'in', r.qty);
      reqs[idx] = r.copyWith(status: 'approved', reviewer: reviewer, note: note);
    } else {
      reqs[idx] = r.copyWith(status: 'rejected', reviewer: reviewer, note: note);
    }

    state = state.copyWith(requests: reqs);
    await repo.saveStockInRequests(reqs);
    return true;
  }

  Future<bool> approveRequest({required String requestId, required String reviewer, String note = ''})
    => reviewRequest(requestId: requestId, approve: true, reviewer: reviewer, note: note);

  Future<bool> rejectRequest({required String requestId, required String reviewer, String note = ''})
    => reviewRequest(requestId: requestId, approve: false, reviewer: reviewer, note: note);
}
