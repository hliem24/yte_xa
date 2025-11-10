import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class LocalStorageRepo {
  static const _kMeds   = 'medicines';
  static const _kMoves  = 'movements';
  static const _kReqs   = 'stock_in_requests';
  static const _kUser   = 'auth_user';

  Future<void> saveUser(User? u) async {
    final sp = await SharedPreferences.getInstance();
    if (u == null) {
      await sp.remove(_kUser);
    } else {
      await sp.setString(_kUser, jsonEncode(u.toJson()));
    }
  }

  Future<User?> getUser() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kUser);
    if (s == null) return null;
    return User.fromJson(jsonDecode(s));
  }

  // ---- Medicines ----
  Future<void> saveMedicines(List<Medicine> meds) async {
    final sp = await SharedPreferences.getInstance();
    final s = jsonEncode(meds.map((e)=>e.toJson()).toList());
    await sp.setString(_kMeds, s);
  }

  Future<List<Medicine>> loadMedicines() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kMeds);
    if (s == null) return const [];
    final a = (jsonDecode(s) as List);
    return a.map((e)=>Medicine.fromJson(Map<String,dynamic>.from(e))).toList();
  }

  // ---- Movements ----
  Future<void> saveMovements(List<Movement> mvs) async {
    final sp = await SharedPreferences.getInstance();
    final s = jsonEncode(mvs.map((e)=>e.toJson()).toList());
    await sp.setString(_kMoves, s);
  }

  Future<List<Movement>> loadMovements() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kMoves);
    if (s == null) return const [];
    final a = (jsonDecode(s) as List);
    return a.map((e)=>Movement.fromJson(Map<String,dynamic>.from(e))).toList();
  }

  // ---- StockInRequests ----
  Future<void> saveStockInRequests(List<StockInRequest> rs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kReqs, StockInRequest.encodeList(rs));
  }

  Future<List<StockInRequest>> loadStockInRequests() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kReqs);
    if (s == null) return const [];
    return StockInRequest.decodeList(s);
  }
}
