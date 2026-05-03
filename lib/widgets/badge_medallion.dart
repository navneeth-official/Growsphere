import 'package:flutter/material.dart';

import '../domain/badge_catalog.dart';

/// Circular “badge image” used in streaks, notifications, and profile (gradient + icon).
class BadgeMedallion extends StatelessWidget {
  const BadgeMedallion({
    super.key,
    required this.badgeId,
    this.size = 48,
    this.unlocked = true,
  });

  final String badgeId;
  final double size;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = BadgeCatalog.accentFor(badgeId, cs);
    final icon = BadgeCatalog.iconFor(badgeId);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: unlocked
                    ? [
                        accent.withValues(alpha: 0.35),
                        accent.withValues(alpha: 0.92),
                      ]
                    : [
                        cs.surfaceContainerHighest,
                        cs.outline.withValues(alpha: 0.5),
                      ],
                stops: const [0.0, 1.0],
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: size * 0.12,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: const SizedBox.expand(),
          ),
          Icon(
            unlocked ? icon : Icons.lock_outline,
            color: unlocked ? Colors.white : cs.onSurfaceVariant,
            size: size * 0.44,
          ),
        ],
      ),
    );
  }
}
