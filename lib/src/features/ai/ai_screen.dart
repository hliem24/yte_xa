import 'dart:convert' as convert; // ✅ cần cho jsonDecode và JsonEncoder
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms_yte_xa_ai/src/services/openai_client.dart';
import 'package:wms_yte_xa_ai/src/services/agent_actions.dart' as acts;
import '../../widgets/app_header.dart';
import '../../state.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});
  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _Msg {
  final String role; // 'user' | 'assistant'
  final String content;
  final acts.AgentAction? embeddedAction;
  final String? embeddedRawJson; // hiển thị wms {…}
  _Msg(this.role, this.content, {this.embeddedAction, this.embeddedRawJson});

  Map<String, String> toMap() => {'role': role, 'content': content};
  static _Msg fromMap(Map j) => _Msg(j['role'] as String, j['content'] as String);
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _input = TextEditingController();
  final _listCtrl = ScrollController();
  bool _busy = false;

  static const String _baseSystemPrompt = '''
Bạn là trợ lý AI tiếng Việt cho **quản lý kho (1 kho)**.
- TRẢ LỜI TỰ NHIÊN cho câu hỏi y tế/kiến thức chung.
- CHỈ sinh đúng **một** khối `wms { "type":..., "params":{...} }` khi người dùng thực sự yêu cầu thao tác kho.
- Nếu thiếu tham số, hãy hỏi lại; không sinh wms.

Các action hợp lệ:
1) stockInRequest { "medicineId":"PARA500", "qty":30, "note":"..." }
2) approveRequest { "requestId":"RQ-...", "approve":true, "note":"..." }
3) stockOut { "medicineId":"PARA500", "qty":5, "reason":"..." }
4) createMedicine { "id":"ZINC50","name":"Kẽm 50mg","unit":"vỉ" }
5) quickReport { }
''';

  final List<_Msg> _history = [];

  late final OpenAiClient _client =
      OpenAiClient(baseUrl: 'http://10.0.2.2:11434', model: 'llama3.2');

  @override
  void initState() {
    super.initState();
    _restoreHistory();
  }

  Future<void> _restoreHistory() async {
    final repo = ref.read(storageProvider);
    final saved = await repo.loadAiHistory();
    setState(() {
      _history
        ..clear()
        ..addAll(saved.map(_Msg.fromMap));
    });
  }

  Future<void> _persistHistory() async {
    final repo = ref.read(storageProvider);
    await repo.saveAiHistory(_history.map((m) => m.toMap()).toList());
  }

  String _buildRealtimeContext() {
    final inv = ref.read(inventoryProvider);
    final auth = ref.read(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final role = user?.role ?? 'staff';

    final total = inv.medicines.fold<int>(0, (s, m) => s + m.totalQuantity);
    final pending = inv.requests.where((r) => r.status == 'pending').length;

    final meds = inv.medicines.take(80).map((m) {
      final days = m.nearestExpiry?.difference(DateTime.now()).inDays;
      return {
        'id': m.id,
        'name': m.name,
        'unit': m.unit,
        'total': m.totalQuantity,
        'nearestExpiryDays': days,
      };
    }).toList();

    return '''
# Context (Realtime)
userRole: $role
totalStock: $total
pendingRequests: $pending
knownMedicines: ${meds.toString()}
(Chỉ sinh wms cho thao tác kho.)
''';
  }

  bool _looksLikeWarehouseIntent(String userText, String llmAnswer) {
    final t = '$userText $llmAnswer'.toLowerCase();
    return RegExp(
      r'(nhap|nhập|xuat|xuất|kho|tồn|báo cáo|bao cao|phiếu|approve|request|stock|quickreport)',
    ).hasMatch(t);
  }

  Future<void> _ask(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _busy) return;

    // 1️⃣ Parser nội bộ → thực thi nhanh
    final natural = acts.parseVietnameseFreeText(trimmed);
    if (natural != null) {
      final res = await acts.executeAction(ref, natural);
      setState(() {
        _history.add(_Msg('user', trimmed));
        _history.add(_Msg('assistant', res));
        _input.clear();
      });
      await _persistHistory();
      _scroll();
      return;
    }

    // 2️⃣ Gọi LLM
    setState(() {
      _busy = true;
      _history.add(_Msg('user', trimmed));
      _input.clear();
    });
    _scroll();

    final sys = '$_baseSystemPrompt\n${_buildRealtimeContext()}';
    final msgs = <Map<String, String>>[
      {'role': 'system', 'content': sys},
      ..._history.map((m) => {'role': m.role, 'content': m.content}),
    ];

    final answer = await _client.chatWithMessages(msgs);

    // Trích wms
    final act = acts.extractActionFromAssistantStrict(answer);

    if (act != null &&
        _looksLikeWarehouseIntent(trimmed, answer) &&
        acts.validateActionAgainstState(ref, act)) {
      final res = await acts.executeAction(ref, act);

      final rawMatch = RegExp(r'({[\s\S]*?})', dotAll: true).firstMatch(answer);
      final rawJson = rawMatch?.group(1);

      setState(() {
        _history.add(_Msg('assistant', rawJson ?? answer,
            embeddedAction: act, embeddedRawJson: rawJson));
        _history.add(_Msg('assistant', '✅ $res'));
        _busy = false;
      });
    } else {
      setState(() {
        _history.add(_Msg('assistant', answer));
        _busy = false;
      });
    }
    await _persistHistory();
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
                final isUser = m.role == 'user';
                final isCode = m.embeddedRawJson != null;

                return Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 620),
                      decoration: BoxDecoration(
                        color: isUser
                            ? cs.primary.withValues(alpha: .12)
                            : (isCode
                                ? const Color(0xFF1C2240)
                                : cs.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: isCode
                          ? _CodeBubble(jsonText: m.embeddedRawJson!)
                          : Text(m.content, style: const TextStyle(fontSize: 15)),
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1),

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
                          hintText: 'Nhập câu hỏi hoặc lệnh…',
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
                      shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

/// Hiển thị khối JSON dạng code bubble (màu tối, monospace)
class _CodeBubble extends StatelessWidget {
  final String jsonText;
  const _CodeBubble({required this.jsonText});

  @override
  Widget build(BuildContext context) {
    return Text(
      'wms ${_pretty(jsonText)}',
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13.5,
        height: 1.35,
        color: Colors.white,
      ),
    );
  }

  static String _pretty(String s) {
    try {
      final obj = convert.jsonDecode(s);
      return const convert.JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return s;
    }
  }
}
