import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/grow_colors.dart';
import '../../core/util/local_image_bytes.dart';
import '../../core/widgets/ai_progress_dialog.dart';
import '../../data/gemini_crop_research_repository.dart';
import '../../domain/plant.dart';
import '../../providers/providers.dart';
import '../shell/grow_layout.dart';

/// Add Plant form — persists to local catalog as a custom plant.
class AddCropScreen extends ConsumerStatefulWidget {
  const AddCropScreen({super.key});

  @override
  ConsumerState<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends ConsumerState<AddCropScreen> {
  final _name = TextEditingController();
  final _months = TextEditingController();
  final _imageUrl = TextEditingController();
  final _climate = TextEditingController();
  final _soil = TextEditingController();
  final _fert = TextEditingController();

  /// Bytes from gallery/camera pick (local path alone is not readable on all platforms).
  Uint8List? _pickedImageBytes;

  bool get _canResearch {
    final name = _name.text.trim().isNotEmpty;
    final m = int.tryParse(_months.text.trim());
    final monthsOk = m != null && m > 0 && m <= 120;
    final img = _imageUrl.text.trim().isNotEmpty;
    return name && monthsOk && img;
  }

  @override
  void dispose() {
    _name.dispose();
    _months.dispose();
    _imageUrl.dispose();
    _climate.dispose();
    _soil.dispose();
    _fert.dispose();
    super.dispose();
  }

  Future<void> _pickImageForUrl() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
      _imageUrl.text = x.path;
    });
  }

  Future<({Uint8List bytes, String mime})?> _resolveImageForGemini() async {
    final spec = _imageUrl.text.trim();
    if (spec.isEmpty) return null;

    if (spec.startsWith('http://') || spec.startsWith('https://')) {
      final b = await tryLoadImageFromUrl(spec);
      if (b == null || b.isEmpty) return null;
      return (bytes: b, mime: mimeTypeForPathOrUrl(spec));
    }

    if (_pickedImageBytes != null && _pickedImageBytes!.isNotEmpty) {
      return (bytes: _pickedImageBytes!, mime: mimeTypeForPathOrUrl(spec));
    }

    if (kIsWeb) return null;

    final b = await readLocalImageBytesIfAvailable(spec);
    if (b == null || b.isEmpty) return null;
    return (bytes: b, mime: mimeTypeForPathOrUrl(spec));
  }

  Future<void> _runGoogleResearch() async {
    final repo = ref.read(geminiCropResearchRepositoryProvider);
    if (repo == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add GEMINI_API_KEY at run time to use Google Research.')),
      );
      return;
    }
    final months = int.tryParse(_months.text.trim()) ?? 3;
    final plantName = _name.text.trim();

    final draft = await runWithAiProgress(
      context,
      title: 'Researching your crop',
      messages: kAiStatusCropResearch,
      task: () async {
        final img = await _resolveImageForGemini();
        return repo.suggestFromBasics(
          plantName: plantName,
          growthMonths: months,
          imageBytes: img?.bytes,
          imageMimeType: img?.mime,
          imageUrlHint: _imageUrl.text.trim(),
        );
      }(),
    );

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final h = MediaQuery.sizeOf(ctx).height * 0.9;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SizedBox(
            height: h,
            child: _GrowingRequirementsPreview(
              initial: draft,
              plantName: plantName,
              growthMonths: months,
              researchRepo: repo,
              onApply: (c, s, f) {
                _climate.text = c;
                _soil.text = s;
                _fert.text = f;
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a plant name')));
      return;
    }
    final months = int.tryParse(_months.text.trim()) ?? 3;
    final days = (months * 30).clamp(30, 800);
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final plant = Plant(
      id: id,
      name: name,
      aliases: <String>[],
      difficulty: 'medium',
      wateringLevel: 'medium',
      climate: _climate.text.trim().isEmpty ? 'Add climate details from research.' : _climate.text.trim(),
      soil: _soil.text.trim().isEmpty ? 'Add soil details from research.' : _soil.text.trim(),
      fertilizers: _fert.text.trim().isEmpty ? 'Add fertilizer notes from research.' : _fert.text.trim(),
      harvestDurationDays: days,
      nutrientHeavy: true,
      pestNotes: 'Scout weekly; use IPM practices for your region.',
      typicalPricePerKg: 0,
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
    );
    await ref.read(growStorageProvider).addCustomPlant(plant);
    ref.read(localDataRevisionProvider.notifier).state++;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $name')));
    context.go('/plants');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GrowLayout(
      innerTitle: l.addNewCropTitle,
      innerActions: [
        Tooltip(
          message: _canResearch
              ? 'Fill growing requirements with Gemini from your basics + image'
              : 'Enter plant name, growth period (1–120 months), and plant image first',
          child: OutlinedButton.icon(
            onPressed: _canResearch
                ? () async {
                    try {
                      await _runGoogleResearch();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Research failed: $e')),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.public, size: 18),
            label: Text(l.googleResearch, style: const TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 4),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          Text('+ ${l.basicInformation}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          _field(context, l.plantNameLabel, _name, 'Enter plant name (e.g., tomato, rice, wheat)', () => setState(() {})),
          const SizedBox(height: 4),
          Text(
            "Enter plant name, growth period, and image — then tap '${l.googleResearch}' for a preview you can edit.",
            style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600),
          ),
          const SizedBox(height: 12),
          _field(context, l.growthPeriodMonthsLabel, _months, 'Enter growth period in months', () => setState(() {})),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(context, l.plantImageLabel, _imageUrl, 'Image URL or pick from gallery', () => setState(() {})),
              ),
              IconButton(
                tooltip: 'Pick image',
                onPressed: _pickImageForUrl,
                icon: const Icon(Icons.upload),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(l.growingRequirements, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            "Preview AI drafts before they land here — you can still edit everything before Add Crop.",
            style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600),
          ),
          const SizedBox(height: 12),
          _multiline(context, 'Climate Requirements *', _climate, 'Climate requirements…'),
          const SizedBox(height: 12),
          _multiline(context, 'Soil Requirements *', _soil, 'Soil requirements…'),
          const SizedBox(height: 12),
          _multiline(context, 'Fertilizer Needs *', _fert, 'Fertilizer requirements…'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF1D4ED8), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'One-Click Complete Research',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Uses Gemini (optional GEMINI_RESEARCH_MODEL; else GEMINI_MODEL from dart-define)\n'
                  '• Preview and per-field enhance before applying\n'
                  '• You keep full control of every line',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: const Color(0xFF1E40AF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/plants'),
                  child: Text(l.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                  onPressed: _save,
                  child: const Text('Add Crop'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    TextEditingController c,
    String hint,
    VoidCallback onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(controller: c, decoration: InputDecoration(hintText: hint), onChanged: (_) => onChanged()),
      ],
    );
  }

  Widget _multiline(BuildContext context, String label, TextEditingController c, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(controller: c, maxLines: 4, decoration: InputDecoration(hintText: hint, alignLabelWithHint: true)),
      ],
    );
  }
}

class _GrowingRequirementsPreview extends StatefulWidget {
  const _GrowingRequirementsPreview({
    required this.initial,
    required this.plantName,
    required this.growthMonths,
    required this.researchRepo,
    required this.onApply,
  });

  final GrowingRequirementsDraft initial;
  final String plantName;
  final int growthMonths;
  final GeminiCropResearchRepository researchRepo;
  final void Function(String climate, String soil, String fertilizer) onApply;

  @override
  State<_GrowingRequirementsPreview> createState() => _GrowingRequirementsPreviewState();
}

class _GrowingRequirementsPreviewState extends State<_GrowingRequirementsPreview> {
  late final TextEditingController _climate;
  late final TextEditingController _soil;
  late final TextEditingController _fert;

  @override
  void initState() {
    super.initState();
    _climate = TextEditingController(text: widget.initial.climate);
    _soil = TextEditingController(text: widget.initial.soil);
    _fert = TextEditingController(text: widget.initial.fertilizer);
  }

  @override
  void dispose() {
    _climate.dispose();
    _soil.dispose();
    _fert.dispose();
    super.dispose();
  }

  Future<void> _enhance(BuildContext sheetContext, String key, TextEditingController c) async {
    try {
      final next = await runWithAiProgress(
        sheetContext,
        title: 'Enhancing $key',
        messages: kAiStatusCropResearch,
        task: widget.researchRepo.enhanceField(
          fieldKey: key,
          currentText: c.text,
          plantName: widget.plantName,
          growthMonths: widget.growthMonths,
        ),
      );
      if (!mounted) return;
      setState(() => c.text = next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text('Enhance failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: GrowColors.gray300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Preview — growing requirements',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Review or edit each field. Use Enhance to ask Gemini for a fresh version of one section. '
            'Apply copies into the form; you can still edit there before Add Crop.',
            style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600, height: 1.35),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              _previewBlock(
                context,
                title: 'Climate requirements',
                key: 'climate',
                c: _climate,
              ),
              const SizedBox(height: 14),
              _previewBlock(
                context,
                title: 'Soil requirements',
                key: 'soil',
                c: _soil,
              ),
              const SizedBox(height: 14),
              _previewBlock(
                context,
                title: 'Fertilizer needs',
                key: 'fertilizer',
                c: _fert,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.onApply(_climate.text, _soil.text, _fert.text);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply to form'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewBlock(
    BuildContext context, {
    required String title,
    required String key,
    required TextEditingController c,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15))),
            TextButton.icon(
              onPressed: () => _enhance(context, key, c),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Enhance'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Edit the draft…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
