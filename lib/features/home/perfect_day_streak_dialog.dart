import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LeetCode-style “perfect day” celebration: dark card, accent streak number, medal.
Future<void> showPerfectDayStreakDialog(
  BuildContext context, {
  required int streakDays,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.88 + (0.12 * curved.value),
          child: Center(
            child: _StreakDialogCard(
              streakDays: streakDays,
              onClose: () => Navigator.of(ctx).pop(),
            ),
          ),
        ),
      );
    },
  );
}

class _StreakDialogCard extends StatelessWidget {
  const _StreakDialogCard({
    required this.streakDays,
    required this.onClose,
  });

  final int streakDays;
  final VoidCallback onClose;

  static const _accentBlue = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardBg = const Color(0xFF1E1E1E);
    final subtle = Colors.white.withValues(alpha: 0.72);
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Daily grow goals completed!',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: Icon(Icons.close, color: subtle, size: 22),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Perfect-day streak: '),
                        TextSpan(
                          text: '$streakDays',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: _accentBlue,
                          ),
                        ),
                        TextSpan(
                          text: streakDays == 1 ? ' day' : ' days',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Consistency is key — see you tomorrow for the next perfect day.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: subtle,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _MedalBadge(accent: cs.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MedalBadge extends StatelessWidget {
  const _MedalBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFE08A),
                  const Color(0xFFD97706),
                  const Color(0xFFB45309),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.45),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: 10,
            right: 18,
            child: Container(
              width: 28,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Icon(Icons.eco, size: 44, color: accent.withValues(alpha: 0.92)),
        ],
      ),
    );
  }
}
