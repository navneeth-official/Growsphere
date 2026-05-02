import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
      setState(() => _msgs.add((false, 'Sorry, something went wrong: $e'));
    }
    await Future<void>.delayed(Duration.zero);
    if (_scroll.hasClients) {
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return GrowToolShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.spa_rounded, color: cs.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.aiChatAssistantTitle,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: cs.onSurface),
                      ),
                      Text(
                        'Crop-aware answers · grounded in your catalog',
                        style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant, height: 1.25),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'Beta',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.25)),
          Expanded(
            child: _msgs.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 40, color: cs.primary),
                            const SizedBox(height: 12),
                            Text(
                              'Ask anything about farming',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tips, pests, fertilizer timing, and harvest cues — like a field agronomist in your pocket.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Try asking',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _popular
                            .map(
                              (q) => ActionChip(
                                label: Text(q, style: GoogleFonts.inter(fontSize: 12)),
                                onPressed: () => _send(q),
                                side: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                                backgroundColor: cs.surface,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) {
                      final m = _msgs[i];
                      final user = m.$1;
                      final maxW = MediaQuery.sizeOf(context).width * 0.86;
                      return Align(
                        alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxW),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!user) ...[
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: cs.primary.withValues(alpha: 0.2),
                                    child: Icon(Icons.spa_rounded, size: 16, color: cs.primary),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: user
                                          ? cs.primary.withValues(alpha: 0.22)
                                          : cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(user ? 18 : 4),
                                        bottomRight: Radius.circular(user ? 4 : 18),
                                      ),
                                      border: Border.all(
                                        color: user
                                            ? cs.primary.withValues(alpha: 0.35)
                                            : cs.outline.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                      child: SelectableText(
                                        m.$2,
                                        style: GoogleFonts.inter(
                                          fontSize: 14.5,
                                          height: 1.45,
                                          color: user ? cs.onSurface : cs.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (user) ...[
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: cs.surfaceContainerHighest,
                                    child: Icon(Icons.person, size: 16, color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + bottom),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.28))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Message…',
                      hintStyle: GoogleFonts.inter(color: cs.onSurfaceVariant),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(_c.text),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _send(_c.text),
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
