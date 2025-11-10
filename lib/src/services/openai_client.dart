import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client đơn giản: ưu tiên gọi Ollama (http://10.0.2.2:11434/api/chat),
/// fallback OpenAI-compatible (POST /v1/chat/completions).
class OpenAiClient {
  final String baseUrl;
  final String model;
  final String? apiKey;

  OpenAiClient({required this.baseUrl, required this.model, this.apiKey});

  Future<String> chatWithMessages(List<Map<String, String>> messages) async {
    // 1) Ollama style
    try {
      final uri = Uri.parse('$baseUrl/api/chat');
      final body = jsonEncode({
        'model': model,
        'messages': messages.map((m)=>{'role': m['role'], 'content': m['content']}).toList(),
        'stream': false,
      });
      final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
      if (res.statusCode == 200) {
        final obj = jsonDecode(res.body);
        final msg = obj['message'];
        if (msg!=null && msg['content'] is String) return msg['content'];
        if (obj['messages'] is List && (obj['messages'] as List).isNotEmpty) {
          return (obj['messages'].last['content'] ?? '').toString();
        }
      }
    } catch (_) {}

    // 2) OpenAI compatible
    try {
      final uri = Uri.parse('$baseUrl/v1/chat/completions');
      final body = jsonEncode({
        'model': model,
        'messages': messages,
        'stream': false,
      });
      final headers = {
        'Content-Type': 'application/json',
        if (apiKey != null && apiKey!.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };
      final res = await http.post(uri, headers: headers, body: body);
      if (res.statusCode == 200) {
        final obj = jsonDecode(res.body);
        final choices = obj['choices'] as List?;
        if (choices!=null && choices.isNotEmpty) {
          return (choices.first['message']['content'] ?? '').toString();
        }
      }
    } catch (_) {}

    // Fallback
    return 'Mình chưa kết nối được mô hình. Bạn vẫn có thể nhập như: "nhập 10 PARA500", "xuất 5 ORS", "tạo thuốc ZIN500 kẽm 500mg", hoặc "báo cáo/tổng".';
  }
}
