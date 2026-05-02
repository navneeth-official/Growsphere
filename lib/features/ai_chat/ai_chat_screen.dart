import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/grow_colors.dart';
import '../../core/widgets/ai_progress_dialog.dart';
import '../../providers/providers.dart';
import '../shell/grow_tool_shell.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _c = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <(bool user, String text)>[];

  static const _popular = <String>[
    'How do I grow tomatoes?',
    'What fertilizer for rice?',
    'When to harvest wheat?',
    'Pest control for corn?',
    'Soil pH for vegetables?',
    'Watering schedule tips?',
  ];

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final session = ref.read(sessionControllerProvider);
    setState(() => _msgs.add((true, t)));
    _c.clear();
    final ctx = session == null ? null : 'Growing ${session.plantName}';
    try {
      final reply = await runWithAiProgress(
        context,
        title: 'Grow assistant',
        messages: kAiStatusChatReply,
        task: ref.read(aiChatRepositoryProvider).sendMessage(t, plantContext: ctx),
      );
      if (!mounted) return;
      setState(() => _msgs.add((false, reply)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _msgs.add((false, 'Sorry, something went wrong: $e')));
    }
    await Future<void>.delayed(Duration.zero);
    if (_scroll.hasClients) {
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GrowToolShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.aiChatAssistantTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: GrowColors.green100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Expert Mode',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: GrowColors.green700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _msgs.isEmpty
                      ? ListView(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: GrowColors.gray50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: GrowColors.gray200),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 48, color: GrowColors.gray400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Ask me anything about farming!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Expert agricultural knowledge at your fingertips.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: GrowColors.gray600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Popular questions:',
                              style: TextStyle(color: GrowColors.gray600, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 2.8,
                              children: _popular
                                  .map(
                                    (q) => OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        alignment: Alignment.center,
                                      ),
                                      onPressed: () => _send(q),
                                      child: Text(q, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scroll,
                          itemCount: _msgs.length,
                          itemBuilder: (_, i) {
                            final m = _msgs[i];
                            return Align(
                              alignment: m.$1 ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
                                decoration: BoxDecoration(
                                  color: m.$1 ? GrowColors.green600.withValues(alpha: 0.12) : GrowColors.gray50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: GrowColors.gray200),
                                ),
                                child: Text(m.$2),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _c,
                        decoration: const InputDecoration(
                          hintText: 'Ask about farming, pests, fertilizer...',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: _send,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: GrowColors.gray400,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _send(_c.text),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
