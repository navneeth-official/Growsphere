import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/ai_progress_dialog.dart';
import '../../data/disease_analysis_repository.dart';
import '../../domain/pest_guide_catalog.dart';
import '../../providers/providers.dart';
import '../shell/grow_tool_shell.dart';

class PestScreen extends ConsumerStatefulWidget {
  const PestScreen({super.key});

  @override
  ConsumerState<PestScreen> createState() => _PestScreenState();
}

class _PestScreenState extends ConsumerState<PestScreen> {
  Uint8List? _pestPhoto;
  bool _busy = false;
  DiseaseReport? _lastReport;
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    const guideBg = Color(0xFFE8F5E9);

    return GrowToolShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ColoredBox(
          color: guideBg,
          child: ListView(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            children: [
              Material(
                elevation: 0,
                color: const Color(0xFFC62828),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Text('🐛', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.pestControlGuideTitle,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tap a pest to see symptoms, treatment, and organic solutions.',
                style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface, height: 1.35),
              ),
              const SizedBox(height: 12),
              ...List.generate(PestGuideEntry.catalog.length, (i) {
                final e = PestGuideEntry.catalog[i];
                final open = _expandedIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    elevation: open ? 4 : 2,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _expandedIndex = open ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.emoji, style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.title,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        e.hostPlants,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  open ? Icons.expand_less : Icons.expand_more,
                                  color: cs.onSurfaceVariant,
                                ),
                              ],
                            ),
                            if (open) ...[
                              const Divider(height: 20),
                              Text(
                                'Symptoms',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.symptoms,
                                style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: cs.onSurface),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Organic / IPM',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.organicControls,
                                style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: cs.onSurface),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Chip(
                                  label: Text('Typical impact: ${e.severityHint}'),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (_pestPhoto != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_pestPhoto!, height: 120, fit: BoxFit.cover),
                ),
              ],
              if (_lastReport != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Photo analysis',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _lastReport!.label,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: cs.onSurface),
                        ),
                        Text(
                          _lastReport!.severity,
                          style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _lastReport!.advice,
                          style: GoogleFonts.inter(fontSize: 13, height: 1.35, color: cs.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _busy
                    ? null
                    : () async {
                        final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
                        if (x == null) return;
                        final b = await x.readAsBytes();
                        setState(() {
                          _pestPhoto = b;
                          _lastReport = null;
                          _busy = true;
                        });
                        try {
                          final r = await runWithAiProgress(
                            context,
                            title: 'Identifying pests',
                            messages: kAiStatusPestAnalysis,
                            task: ref.read(diseaseRepositoryProvider).analyzeImageBytes(
                                  b,
                                  intent: ImageAnalysisIntent.pestIdentification,
                                ),
                          );
                          if (!mounted) return;
                          setState(() => _lastReport = r);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Analysis failed: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.photo_camera_outlined),
                label: Text(_busy ? 'Analyzing…' : 'Identify pest from photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
