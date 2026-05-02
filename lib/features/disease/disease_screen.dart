import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../core/widgets/ai_progress_dialog.dart';
import '../../providers/providers.dart';
import '../shell/grow_tool_shell.dart';

class DiseaseScreen extends ConsumerStatefulWidget {
  const DiseaseScreen({super.key});

  @override
  ConsumerState<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends ConsumerState<DiseaseScreen> {
  Uint8List? _bytes;
  String? _report;

  Future<void> _pick(ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 88);
    if (x == null) return;
    final b = await x.readAsBytes();
    setState(() {
      _bytes = b;
      _report = null;
    });
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_camera_outlined, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l.plantPhotoDetectionTitle,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        child: DottedBorderPlaceholder(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(Icons.photo_camera_outlined, size: 56, color: GrowColors.gray400),
                                const SizedBox(height: 12),
                                Text(
                                  'Take or upload a photo of your plant',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(color: GrowColors.gray600),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.black87,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _pick(ImageSource.gallery),
                                      icon: const Icon(Icons.upload),
                                      label: const Text('Upload Photo'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () => _pick(ImageSource.camera),
                                      child: const Text('Camera'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'AI will identify the plant and detect any diseases or issues',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_bytes != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_bytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () async {
                            try {
                              final r = await runWithAiProgress(
                                context,
                                title: 'Analyzing your plant',
                                messages: kAiStatusDiseaseAnalysis,
                                task: ref.read(diseaseRepositoryProvider).analyzeImageBytes(
                                      _bytes!.toList(),
                                    ),
                              );
                              if (!mounted) return;
                              setState(() {
                                _report = '${r.label}\nSeverity: ${r.severity}\n\n${r.advice}';
                              });
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Analysis failed: $e')),
                              );
                            }
                          },
                          child: const Text('Analyze photo'),
                        ),
                        if (_report != null) ...[
                          const SizedBox(height: 12),
                          Text(_report!, style: GoogleFonts.inter(height: 1.35)),
                        ],
                      ],
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: GrowColors.green100.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: GrowColors.green600.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What we can detect:',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: GrowColors.green700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Plant species identification\n'
                              '• Disease detection\n'
                              '• Nutrient deficiencies\n'
                              '• Pest damage assessment',
                              style: GoogleFonts.inter(height: 1.45, color: GrowColors.green700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple dashed border without extra package.
class DottedBorderPlaceholder extends StatelessWidget {
  const DottedBorderPlaceholder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashPainter(color: GrowColors.gray400),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    final path = Path()..addRRect(r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final e = (d + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, e), paint);
        d = e + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
