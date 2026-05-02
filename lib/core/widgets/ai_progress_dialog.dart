import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/grow_colors.dart';

/// Rotating status lines while an AI-backed task runs.
const List<String> kAiStatusCropResearch = [
  'Reading your plant name and growth timeline…',
  'Studying the plant image for visual cues…',
  'Drafting climate, soil, and fertilizer guidance…',
  'Almost ready — polishing the growing plan…',
];

const List<String> kAiStatusDiseaseAnalysis = [
  'Uploading image context…',
  'Scanning leaves and stems for patterns…',
  'Comparing against disease signatures…',
  'Preparing your diagnosis summary…',
];

const List<String> kAiStatusPestAnalysis = [
  'Inspecting the photo for pest traces…',
  'Matching damage patterns to common pests…',
  'Building treatment-friendly recommendations…',
];

const List<String> kAiStatusChatReply = [
  'Understanding your question…',
  'Pulling in crop and soil context…',
  'Composing a clear answer…',
];

const List<String> kAiStatusMarketPrices = [
  'Connecting to market intelligence…',
  'Gathering latest crop price signals…',
  'Normalizing trends for your dashboard…',
];

const List<String> kAiStatusSoilLab = [
  'Calibrating virtual soil sensors…',
  'Simulating NPK and pH readouts…',
  'Preparing your soil snapshot…',
];

/// Shows a non-dismissible overlay with a spinner and rotating [messages]
/// while [task] runs. Pops automatically when [task] completes or throws.
Future<T> runWithAiProgress<T>(
  BuildContext context, {
  required Future<T> task,
  required List<String> messages,
  String title = 'AI at work',
}) async {
  if (!context.mounted) return task;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black45,
    builder: (dialogContext) => _AiProgressDialog(
      title: title,
      messages: messages.isEmpty ? const ['Working…'] : messages,
    ),
  );
  // Let the dialog route paint before awaiting network work.
  await Future<void>.delayed(const Duration(milliseconds: 48));
  final nav = Navigator.of(context, rootNavigator: true);
  try {
    final result = await task;
    if (nav.mounted) nav.pop();
    return result;
  } catch (e) {
    if (nav.mounted) nav.pop();
    rethrow;
  }
}

class _AiProgressDialog extends StatefulWidget {
  const _AiProgressDialog({
    required this.title,
    required this.messages,
  });

  final String title;
  final List<String> messages;

  @override
  State<_AiProgressDialog> createState() => _AiProgressDialogState();
}

class _AiProgressDialogState extends State<_AiProgressDialog> {
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    if (widget.messages.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
        if (!mounted) return;
        setState(() => _i = (_i + 1) % widget.messages.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.messages[_i % widget.messages.length];
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: GrowColors.green600,
                backgroundColor: GrowColors.green100,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                msg,
                key: ValueKey<String>(msg),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: GrowColors.gray700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by Gemini',
              style: GoogleFonts.inter(fontSize: 11, color: GrowColors.gray500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
