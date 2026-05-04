import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/widgets/ai_progress_dialog.dart';
import '../../data/ai_chat_repository.dart';
import '../../providers/providers.dart';
import '../shell/grow_tool_shell.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _ChatLine {
  _ChatLine({required this.user, required this.text, this.imageRelPath});

  final bool user;
  final String text;
  final String? imageRelPath;
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _c = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_ChatLine>[];
  final _speech = stt.SpeechToText();
  String? _threadId;
  bool _speechAvailable = false;
  bool _speechListening = false;
  XFile? _pendingImage;
  bool _loadingThread = true;

  static const _popular = <String>[
    'How do I grow tomatoes?',
    'What fertilizer for rice?',
    'When to harvest wheat?',
    'Pest control for corn?',
    'Soil pH for vegetables?',
    'Watering schedule tips?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureThread());
    _speech.initialize(
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          setState(() => _speechListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _speechListening = false);
      },
    ).then((ok) {
      if (mounted) setState(() => _speechAvailable = ok);
    });
  }

  @override
  void dispose() {
    if (_speech.isListening) {
      _speech.stop();
    }
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ensureThread() async {
    final storage = ref.read(growStorageProvider);
    var id = storage.activeAiChatThreadId;
    final threads = storage.loadAiChatThreads();
    if (id == null || !threads.any((e) => e['id'] == id)) {
      id = await storage.createAiChatThread();
    }
    _threadId = id;
    _loadMsgsFromStorage();
    if (mounted) setState(() => _loadingThread = false);
  }

  void _loadMsgsFromStorage() {
    final storage = ref.read(growStorageProvider);
    final tid = _threadId;
    if (tid == null) return;
    final threads = storage.loadAiChatThreads();
    Map<String, dynamic>? t;
    for (final e in threads) {
      if (e['id'] == tid) {
        t = e;
        break;
      }
    }
    _msgs.clear();
    if (t == null) return;
    for (final m in (t['msgs'] as List<dynamic>? ?? [])) {
      final map = Map<String, dynamic>.from(m as Map);
      _msgs.add(
        _ChatLine(
          user: map['u'] == true,
          text: map['t'] as String? ?? '',
          imageRelPath: map['img'] as String?,
        ),
      );
    }
  }

  Future<String?> _persistChatImage(XFile file, String threadId) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'ai_chat_media', threadId));
    await dir.create(recursive: true);
    final ext = p.extension(file.path).isNotEmpty ? p.extension(file.path) : '.jpg';
    final name = 'img_${DateTime.now().microsecondsSinceEpoch}$ext';
    final outPath = p.join(dir.path, name);
    await File(file.path).copy(outPath);
    return p.join('ai_chat_media', threadId, name);
  }

  Future<File?> _imageFile(String? rel) async {
    if (rel == null || rel.isEmpty) return null;
    final root = await getApplicationDocumentsDirectory();
    final path = p.join(root.path, rel);
    final f = File(path);
    if (await f.exists()) return f;
    return null;
  }

  Future<void> _newChat() async {
    final storage = ref.read(growStorageProvider);
    await storage.createAiChatThread();
    _msgs.clear();
    await _ensureThread();
    if (mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (img != null && mounted) setState(() => _pendingImage = img);
  }

  Future<void> _toggleMic() async {
    if (_speechListening) {
      await _speech.stop();
      if (mounted) setState(() => _speechListening = false);
      return;
    }
    if (!_speechAvailable) {
      final ok = await _speech.initialize();
      if (!mounted) return;
      setState(() => _speechAvailable = ok);
      if (!ok) return;
    }
    setState(() => _speechListening = true);
    await _speech.listen(
      listenMode: stt.ListenMode.dictation,
      onResult: (r) {
        if (!mounted) return;
        _c.text = r.recognizedWords;
        if (r.finalResult) {
          setState(() => _speechListening = false);
          _speech.stop();
        }
      },
    );
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    final img = _pendingImage;
    if (t.isEmpty && img == null) return;
    final tid = _threadId;
    if (tid == null) return;

    final storage = ref.read(growStorageProvider);
    String? relPath;
    if (img != null) {
      relPath = await _persistChatImage(img, tid);
    }
    final userVisible = t.isEmpty && img != null ? '(Image)' : t;
    setState(() {
      _msgs.add(_ChatLine(user: true, text: userVisible, imageRelPath: relPath));
      _pendingImage = null;
    });
    _c.clear();
    await storage.appendAiChatMessage(threadId: tid, isUser: true, text: userVisible, imageRelativePath: relPath);

    final session = ref.read(sessionControllerProvider);
    final ctx = session == null ? null : 'Growing ${session.plantName}';
    final prior = <AiChatPriorTurn>[
      for (var i = 0; i < _msgs.length - 1; i++)
        (isUser: _msgs[i].user, text: _msgs[i].text),
    ];

    Uint8List? imageBytes;
    String? imageMime;
    if (relPath != null) {
      final root = await getApplicationDocumentsDirectory();
      final f = File(p.join(root.path, relPath));
      if (await f.exists()) {
        imageBytes = await f.readAsBytes();
        final lower = relPath.toLowerCase();
        imageMime = lower.endsWith('.png')
            ? 'image/png'
            : lower.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
      }
    }

    try {
      final reply = await runWithAiProgress(
        context,
        title: 'Grow assistant',
        messages: kAiStatusChatReply,
        task: ref.read(aiChatRepositoryProvider).sendMessage(
              t.isEmpty ? 'Describe this crop image and suggest next care steps.' : t,
              plantContext: ctx,
              priorTurns: prior.isEmpty ? null : prior,
              imageBytes: imageBytes,
              imageMimeType: imageMime,
            ),
      );
      if (!mounted) return;
      setState(() => _msgs.add(_ChatLine(user: false, text: reply)));
      await storage.appendAiChatMessage(threadId: tid, isUser: false, text: reply);
    } catch (e) {
      if (!mounted) return;
      setState(() => _msgs.add(_ChatLine(user: false, text: 'Sorry, something went wrong: $e')));
    }
    ref.read(localDataRevisionProvider.notifier).state++;
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

    if (_loadingThread) {
      return GrowToolShell(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GrowToolShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'New chat',
                  onPressed: _newChat,
                  icon: const Icon(Icons.add_comment_outlined),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.spa_rounded, color: cs.primary, size: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.aiChatAssistantTitle,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: cs.onSurface),
                      ),
                      Text(
                        'Saved chats · follow-ups · photos · voice',
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
          const SizedBox(height: 4),
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
                      final user = m.user;
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
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (m.imageRelPath != null)
                                            FutureBuilder<File?>(
                                              future: _imageFile(m.imageRelPath),
                                              builder: (_, snap) {
                                                final f = snap.data;
                                                if (f == null) {
                                                  return Icon(Icons.image_not_supported, color: cs.onSurfaceVariant);
                                                }
                                                return ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.file(
                                                    f,
                                                    width: 220,
                                                    fit: BoxFit.cover,
                                                  ),
                                                );
                                              },
                                            ),
                                          if (m.imageRelPath != null && m.text.isNotEmpty)
                                            const SizedBox(height: 8),
                                          SelectableText(
                                            m.text,
                                            style: GoogleFonts.inter(
                                              fontSize: 14.5,
                                              height: 1.45,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ],
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
          if (_pendingImage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _pendingImage!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _pendingImage = null),
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 10 + bottom),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.28))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Attach image',
                  onPressed: _pickImage,
                  icon: Icon(Icons.image_outlined, color: cs.primary),
                ),
                IconButton(
                  tooltip: _speechListening ? 'Stop dictation' : 'Voice input',
                  onPressed: _toggleMic,
                  icon: Icon(
                    _speechListening ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
                    color: _speechListening ? cs.error : cs.onSurfaceVariant,
                  ),
                ),
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
                const SizedBox(width: 4),
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
