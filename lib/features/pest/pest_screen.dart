import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../core/widgets/ai_progress_dialog.dart';
import '../../data/disease_analysis_repository.dart';
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bug_report_outlined, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.pestControlGuideTitle,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      _pestRow(
                        'Aphids',
                        'Treatment: Neem oil spray',
                        'High',
                        Colors.red.shade700,
                        Colors.white,
                      ),
                      const SizedBox(height: 10),
                      _pestRow(
                        'Spider Mites',
                        'Treatment: Increase humidity',
                        'Medium',
                        Colors.black87,
                        Colors.white,
                      ),
                      const SizedBox(height: 10),
                      _pestRow(
                        'Whiteflies',
                        'Treatment: Yellow sticky traps',
                        'Low',
                        GrowColors.gray200,
                        GrowColors.gray700,
                      ),
                      if (_pestPhoto != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_pestPhoto!, height: 120, fit: BoxFit.cover),
                        ),
                      ],
                      if (_lastReport != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _lastReport!.label,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          _lastReport!.severity,
                          style: GoogleFonts.inter(color: GrowColors.gray600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(_lastReport!.advice, style: GoogleFonts.inter(fontSize: 13, height: 1.35)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                            final session = ref.read(sessionControllerProvider);
                            final r = await runWithAiProgress(
                              context,
                              title: 'Identifying pests',
                              messages: kAiStatusPestAnalysis,
                              task: ref.read(diseaseRepositoryProvider).analyzeImageBytes(
                                    b,
                                    plantName: session?.plantName,
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
                  label: Text(_busy ? 'Analyzing…' : 'Identify Pest from Photo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pestRow(String title, String subtitle, String badge, Color badgeBg, Color badgeFg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: GrowColors.gray200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: badgeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
