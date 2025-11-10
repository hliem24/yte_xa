import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms_yte_xa_ai/src/services/openai_client.dart';
import 'package:wms_yte_xa_ai/src/services/agent_actions.dart' as acts;
import '../../widgets/app_header.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});
  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _Msg {
  final String role;
  final String content;
  final acts.AgentAction? embeddedAction;
  _Msg(this.role, this.content, {this.embeddedAction});
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _input = TextEditingController();
  final _listCtrl = ScrollController();
  bool _busy = false;

  /// Prompt chuẩn hoá theo schema mới (nhập cần duyệt)
  static const String _systemPrompt = '''
Bạn là trợ lý AI tiếng Việt cho **quản lý kho 1 kho**.
Trả lời tự nhiên. Chỉ khi cần thao tác kho thì chèn đúng **một** khối:

wms {
  "type": "<action>",
  "params": { ... }
}

Các action HỢP LỆ:

1) stockInRequest { "medicineId": "PARA500", "qty": 30, "note": "viện trợ" }
   → Nhân viên tạo **phiếu nhập** chờ duyệt.

2) approveRequest { "requestId": "123", "approve": true, "note": "ok" }
   → Quản trị **duyệt** (approve=false = từ chối).

3) stockOut { "medicineId": "PARA500", "qty": 5, "reason": "cấp phát" }
   → **Xuất kho** trực tiếp (không cần duyệt).

4) createMedicine { "id": "ZINC50", "name": "Kẽm 50mg", "unit": "vỉ" }

5) quickReport { }
   → Báo cáo nhanh (tổng tồn, sắp hết hạn, tồn thấp).

❗ Không dùng type khác ngoài danh sách trên. Nếu không thao tác kho, hãy trả lời ngắn gọn.
''';

  final List<_Msg> _history = [_Msg('system', _systemPrompt)];

  // Ollama (Android emulator → 10.0.2.2)
  late final OpenAiClient _client =
      OpenAiClient(baseUrl: 'http://10.0.2.2:11434', model: 'llama3.2');

  Future<void> _ask(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _busy) return;

    // 1) Parser nội bộ → thực thi ngay
    final natural = acts.parseVietnameseFreeText(trimmed);
    if (natural != null) {
      final res = await acts.executeAction(ref, natural);
      setState(() {
        _history.add(_Msg('user', trimmed));
        _history.add(_Msg('assistant', res));
        _input.clear();
      });
      _scroll();
      return;
    }

    // 2) Gọi LLM
    setState(() {
      _busy = true;
      _history.add(_Msg('user', trimmed));
      _input.clear();
    });
    _scroll();

    final msgs = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      ..._history
          .where((m) => m.role != 'system')
          .map((m) => {'role': m.role, 'content': m.content}),
    ];

    final answer = await _client.chatWithMessages(msgs);
    final act = acts.extractActionFromAssistant(answer);

    if (act != null) {
      final res = await acts.executeAction(ref, act);
      setState(() {
        _history.add(_Msg('assistant', '$answer\n\n✅ $res', embeddedAction: act));
        _busy = false;
      });
    } else {
      setState(() {
        _history.add(_Msg('assistant', answer));
        _busy = false;
      });
    }
    _scroll();
  }

  void _scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listCtrl.hasClients) {
        _listCtrl.animateTo(
          _listCtrl.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(icon: Icons.smart_toy_rounded, title: 'Trợ lý AI'),

          Expanded(
            child: ListView.builder(
              controller: _listCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _history.length,
              itemBuilder: (_, i) {
                final m = _history[i];
                if (m.role == 'system') return const SizedBox.shrink();
                final isUser = m.role == 'user';
                return Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 620),
                      decoration: BoxDecoration(
                        color: isUser ? cs.primary.withValues(alpha: .12)
                                      : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(m.content, style: const TextStyle(fontSize: 15)),
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Ô nhập + Gửi (khung giống nút gửi)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.primary, width: 1.6),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 3,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: _ask,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(80, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _busy ? null : () => _ask(_input.text),
                    icon: const Icon(Icons.send),
                    label: const Text('Gửi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
