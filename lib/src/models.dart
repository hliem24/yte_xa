import 'dart:convert';

class User {
  final String username;
  final String role; // 'admin' | 'staff'
  const User({required this.username, required this.role});

  Map<String, dynamic> toJson() => {'username': username, 'role': role};
  factory User.fromJson(Map<String, dynamic> j)
    => User(username: j['username'], role: j['role']);
}

// --------- Medicine ---------
class MedicineLot {
  final String lotId;
  final DateTime expiry;
  final int quantity;
  final String warehouseId;

  const MedicineLot({
    required this.lotId,
    required this.expiry,
    required this.quantity,
    required this.warehouseId,
  });

  Map<String, dynamic> toJson() => {
    'lotId': lotId,
    'expiry': expiry.toIso8601String(),
    'quantity': quantity,
    'warehouseId': warehouseId,
  };

  factory MedicineLot.fromJson(Map<String, dynamic> j) => MedicineLot(
    lotId: j['lotId'],
    expiry: DateTime.parse(j['expiry']),
    quantity: j['quantity'],
    warehouseId: j['warehouseId'],
  );
}

class Medicine {
  final String id;
  final String name;
  final String unit; // vỉ, gói, chai, hộp, bịch, bộ, cái...
  final List<MedicineLot> lots;
  const Medicine({required this.id, required this.name, required this.unit, required this.lots});

  int get totalQuantity => lots.fold(0, (s, l) => s + l.quantity);

  DateTime? get nearestExpiry {
    if (lots.isEmpty) return null;
    final sorted = [...lots]..sort((a,b)=>a.expiry.compareTo(b.expiry));
    return sorted.first.expiry;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'lots': lots.map((e)=>e.toJson()).toList(),
  };

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
    id: j['id'],
    name: j['name'],
    unit: j['unit'],
    lots: (j['lots'] as List)
      .map((e)=>MedicineLot.fromJson(Map<String, dynamic>.from(e)))
      .toList(),
  );
}

// --------- Movement (thêm reason cho xuất) ---------
class Movement {
  final String id;
  final String medicineId;
  final String warehouseId; // 'KHO_1'
  final String type;        // 'in' | 'out'
  final int quantity;
  final DateTime time;
  final String? reason;     // chỉ dùng cho 'out'

  const Movement({
    required this.id,
    required this.medicineId,
    required this.warehouseId,
    required this.type,
    required this.quantity,
    required this.time,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicineId': medicineId,
    'warehouseId': warehouseId,
    'type': type,
    'quantity': quantity,
    'time': time.toIso8601String(),
    'reason': reason,
  };

  factory Movement.fromJson(Map<String, dynamic> j) => Movement(
    id: j['id'],
    medicineId: j['medicineId'],
    warehouseId: j['warehouseId'],
    type: j['type'],
    quantity: j['quantity'],
    time: DateTime.parse(j['time']),
    reason: j['reason'],
  );
}

// --------- StockInRequest (yêu cầu nhập – duyệt bởi admin) ---------
class StockInRequest {
  final String id;
  final String medicineId;
  final int qty;
  final String requester; // người tạo (staff)
  final String status;    // 'pending' | 'approved' | 'rejected'
  final String? reviewer; // admin xét duyệt
  final String note;      // ghi chú nhân viên hoặc admin
  final DateTime createdAt;

  const StockInRequest({
    required this.id,
    required this.medicineId,
    required this.qty,
    required this.requester,
    required this.status,
    required this.note,
    required this.createdAt,
    this.reviewer,
  });

  StockInRequest copyWith({
    String? status,
    String? reviewer,
    String? note,
  }) => StockInRequest(
    id: id,
    medicineId: medicineId,
    qty: qty,
    requester: requester,
    status: status ?? this.status,
    note: note ?? this.note,
    reviewer: reviewer ?? this.reviewer,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicineId': medicineId,
    'qty': qty,
    'requester': requester,
    'status': status,
    'reviewer': reviewer,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory StockInRequest.fromJson(Map<String, dynamic> j) => StockInRequest(
    id: j['id'],
    medicineId: j['medicineId'],
    qty: j['qty'],
    requester: j['requester'],
    status: j['status'],
    reviewer: j['reviewer'],
    note: j['note'] ?? '',
    createdAt: DateTime.parse(j['createdAt']),
  );

  static String encodeList(List<StockInRequest> xs)
    => jsonEncode(xs.map((e)=>e.toJson()).toList());

  static List<StockInRequest> decodeList(String s) {
    final a = (jsonDecode(s) as List);
    return a.map((e)=>StockInRequest.fromJson(Map<String,dynamic>.from(e))).toList();
  }
}
