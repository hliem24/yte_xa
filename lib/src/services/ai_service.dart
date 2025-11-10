// lib/src/services/ai_service.dart
import 'dart:math';
import '../models.dart';

class AiService {
  /// Gợi ý đặt hàng dựa trên moving average các lần xuất gần nhất.
  int suggestReorderQty(
    String medId,
    List<Movement> moves, {
    int window = 5,
    int targetDays = 30,
  }) {
    final outMoves = moves
        .where((m) => m.medicineId == medId && m.type == 'out')
        .toList();
    if (outMoves.isEmpty) return 0;
    outMoves.sort((a, b) => a.time.compareTo(b.time));

    final recent = outMoves.reversed.take(window).toList();
    final avg = recent.map((m) => m.quantity).fold<int>(0, (s, x) => s + x) /
        recent.length;

    // Quy ước: avg theo lần (giả định ~7 ngày), suy ra mức dùng theo ngày
    final daily = avg / 7.0;
    return (daily * targetDays).round();
  }

  /// Phát hiện bất thường (xuất) theo z-score.
  List<Movement> detectOutlierExports(
    String medId,
    List<Movement> moves, {
    double z = 2.0,
  }) {
    final xs = moves
        .where((m) => m.medicineId == medId && m.type == 'out')
        .toList();
    if (xs.length < 3) return const [];
    final qs = xs.map((m) => m.quantity.toDouble()).toList();
    final mean = qs.reduce((a, b) => a + b) / qs.length;
    final sd = sqrt(qs.map((q) => pow(q - mean, 2)).reduce((a, b) => a + b) /
        qs.length);
    if (sd == 0) return const [];
    return xs.where((m) => ((m.quantity - mean) / sd).abs() > z).toList();
  }

  /// Điểm rủi ro hết hạn (0..1) dựa trên lô gần hết hạn nhất.
  double expiryRiskScore(Medicine med) {
    final now = DateTime.now();
    if (med.lots.isEmpty) return 0;
    final minDays =
        med.lots.map((l) => l.expiry.difference(now).inDays).reduce(min);
    if (minDays <= 0) return 1.0;
    if (minDays > 365) return 0.0;
    return (365 - minDays) / 365.0;
  }

  /// OCR demo: parse dòng "Tên thuốc x Số lượng" bằng regex unicode.
  List<Map<String, dynamic>> parseOcrText(String raw) {
    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final reg = RegExp(
      r'^(?<name>[\p{L}\p{N} \-\+\.%]+?)\s*[xX\*]?\s*(?<qty>\d+)',
      unicode: true,
    );
    final out = <Map<String, dynamic>>[];
    for (final ln in lines) {
      final m = reg.firstMatch(ln);
      if (m != null) {
        out.add({
          'name': m.namedGroup('name')!.trim(),
          'qty': int.parse(m.namedGroup('qty')!),
        });
      }
    }
    return out;
  }
}
