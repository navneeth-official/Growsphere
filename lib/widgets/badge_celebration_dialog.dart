import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'badge_medallion.dart';

/// LeetCode-inspired achievement overlay (center card, warm accent, tap outside to dismiss).
Future<void> showBadgeCelebrationOverlay(
  BuildContext context, {
  required String badgeId,
  required String headline,
  required String subtitle,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim, secAnim) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (ctx, anim, _, __) {
      final t = Curves.easeOutBack.transform(anim.value);
      return Center(
        child: Transform.scale(
          scale: t,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
                border: Border.all(color: Color(0xFFF97316), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFF97316).withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ACHIEVEMENT UNLOCKED',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: const Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(height: 14),
                  BadgeMedallion(badgeId: badgeId, size: 88, unlocked: true),
                  const SizedBox(height: 12),
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Nice!', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
