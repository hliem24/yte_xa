import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class LocalStorageRepo {
  static const _kMeds   = 'medicines';
  static const _kMoves  = 'movements';
  static const _kReqs   = 'stock_in_requests';
  static const _kUser   = 'auth_user';
  static const _kAiHist = 'ai_history_v1';

  // ---------- USER ----------
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

  // ---------- MEDICINES ----------
  Future<void> saveMedicines(List<Medicine> meds) async {
    final sp = await SharedPreferences.getInstance();
    final s = jsonEncode(meds.map((e) => e.toJson()).toList());
    await sp.setString(_kMeds, s);
  }

  Future<List<Medicine>> loadMedicines() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kMeds);
    if (s == null || s.isEmpty) return const [];
    final a = jsonDecode(s) as List;
    return a.map((e) => Medicine.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // ---------- MOVEMENTS ----------
  Future<void> saveMovements(List<Movement> mvs) async {
    final sp = await SharedPreferences.getInstance();
    final s = jsonEncode(mvs.map((e) => e.toJson()).toList());
    await sp.setString(_kMoves, s);
  }

  Future<List<Movement>> loadMovements() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kMoves);
    if (s == null || s.isEmpty) return const [];
    final a = jsonDecode(s) as List;
    return a.map((e) => Movement.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // ---------- STOCK-IN REQUESTS ----------
  Future<void> saveStockInRequests(List<StockInRequest> rs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kReqs, StockInRequest.encodeList(rs));
  }

  Future<List<StockInRequest>> loadStockInRequests() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_kReqs);
    if (s == null || s.isEmpty) return const [];
    return StockInRequest.decodeList(s);
  }

  // ---------- AI CHAT HISTORY ----------
  /// Lưu danh sách tin nhắn AI (user + assistant)
  Future<void> saveAiHistory(List<Map<String, String>> messages) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAiHist, jsonEncode(messages));
  }

  /// Đọc lại lịch sử chat AI (dạng [{role:'user',content:'...'},...])
  Future<List<Map<String, String>>> loadAiHistory() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kAiHist);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => {
                  'role': (e['role'] ?? '').toString(),
                  'content': (e['content'] ?? '').toString()
                })
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Xoá sạch lịch sử chat AI
  Future<void> clearAiHistory() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAiHist);
  }
}
