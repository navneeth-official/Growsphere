import 'package:flutter/material.dart';

/// Display metadata for streak & achievement badges (ids match [GrowSession.earnedBadgeIds]).
class BadgeCatalog {
  BadgeCatalog._();

  static IconData iconFor(String id) {
    final d = _defs[id];
    if (d != null) return d.icon;
    if (id.startsWith('badge_streak_day_')) return Icons.local_fire_department;
    return Icons.military_tech_outlined;
  }

  static Color accentFor(String id, ColorScheme cs) {
    final d = _defs[id];
    if (d != null) return d.accent;
    if (id.startsWith('badge_streak_day_')) return Colors.orange.shade700;
    return cs.primary;
  }

  static String titleFor(String id) {
    if (id.startsWith('badge_streak_day_')) {
      final n = int.tryParse(id.replaceFirst('badge_streak_day_', ''));
      if (n != null) return streakMilestoneTitle(n);
      return 'Streak milestone';
    }
    return _defs[id]?.title ?? _humanizeId(id);
  }

  static String descriptionFor(String id) {
    if (id.startsWith('badge_streak_day_')) {
      final n = int.tryParse(id.replaceFirst('badge_streak_day_', ''));
      if (n != null) {
        return 'Hit $n perfect day${n == 1 ? '' : 's'} in a row (every task due that day completed).';
      }
      return 'Reach this streak length with perfect task days.';
    }
    return _defs[id]?.description ?? 'Keep growing to unlock more badges.';
  }

  /// Fun names for common AI streak milestone lengths.
  static String streakMilestoneTitle(int days) {
    return switch (days) {
      3 => 'Hat Trick',
      7 => 'Week Warrior',
      14 => '2-Week Warrior',
      21 => 'Habit Former',
      30 => 'Streak Legend',
      60 => 'Season Grinder',
      100 => 'Centurion',
      _ => '$days-Day Blaze',
    };
  }

  static String _humanizeId(String id) =>
      id.replaceFirst('badge_', '').replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');

  /// All non-milestone badge ids we may award (for gallery / empty states).
  static List<String> get allStaticBadgeIds => _defs.keys.toList();

  static const _defs = <String, _BadgeDef>{
    'badge_first_water': _BadgeDef(
      title: 'First Seed',
      description: 'Logged your first watering for this crop.',
      icon: Icons.water_drop_outlined,
      accent: Color(0xFF2563EB),
    ),
    'badge_thriving': _BadgeDef(
      title: 'Green Thumb',
      description: 'Plant vitality reached 90% or higher.',
      icon: Icons.eco,
      accent: Color(0xFF16A34A),
    ),
    'badge_task_master': _BadgeDef(
      title: 'Task Master',
      description: 'Completed 20 or more care tasks.',
      icon: Icons.task_alt,
      accent: Color(0xFF7C3AED),
    ),
    'badge_plant_parent': _BadgeDef(
      title: 'Plant Parent',
      description: 'Logged 8+ watering sessions — consistent care.',
      icon: Icons.favorite_outline,
      accent: Color(0xFFDB2777),
    ),
    'badge_harvest_master': _BadgeDef(
      title: 'Harvest Master',
      description: 'Finished 5+ harvest-stage tasks like a pro.',
      icon: Icons.agriculture,
      accent: Color(0xFFCA8A04),
    ),
    'badge_garden_guru': _BadgeDef(
      title: 'Garden Guru',
      description: 'Vitality 95%+ with 30+ tasks completed.',
      icon: Icons.spa,
      accent: Color(0xFF059669),
    ),
    'badge_speed_grower': _BadgeDef(
      title: 'Speed Grower',
      description: 'Short-cycle crop with a 3+ day perfect streak.',
      icon: Icons.bolt,
      accent: Color(0xFFEAB308),
    ),
    'badge_microgreen_master': _BadgeDef(
      title: 'Microgreen Master',
      description: 'Microgreens crop with a 5+ day streak.',
      icon: Icons.grass,
      accent: Color(0xFF22C55E),
    ),
    'badge_steady_roots': _BadgeDef(
      title: 'Steady Roots',
      description: 'Completed 40+ tasks — slow and steady wins.',
      icon: Icons.park,
      accent: Color(0xFF78716C),
    ),
    'badge_centurion_streak': _BadgeDef(
      title: 'Centurion',
      description: 'Best streak reached 100 perfect days.',
      icon: Icons.emoji_events,
      accent: Color(0xFFD97706),
    ),
    'badge_weather_watcher': _BadgeDef(
      title: 'Weather Watcher',
      description: 'Kept vitality above 70% across 15+ watering logs.',
      icon: Icons.wb_sunny_outlined,
      accent: Color(0xFF0EA5E9),
    ),
    'badge_disease_detective': _BadgeDef(
      title: 'Disease Detective',
      description: 'Stayed thriving (85%+) after 25 tasks — sharp eye on plant health.',
      icon: Icons.biotech_outlined,
      accent: Color(0xFF6366F1),
    ),
    'badge_soil_savior': _BadgeDef(
      title: 'Soil Savior',
      description: 'Soil-prep stage: completed every soil-week task on time.',
      icon: Icons.landscape_outlined,
      accent: Color(0xFF92400E),
    ),
    'badge_night_owl_farmer': _BadgeDef(
      title: 'Night Owl Farmer',
      description: 'Logged water or tasks across 10+ different calendar days.',
      icon: Icons.nights_stay_outlined,
      accent: Color(0xFF4F46E5),
    ),
    'badge_sun_chaser': _BadgeDef(
      title: 'Sun Chaser',
      description: 'High-sun setup with vitality still 88%+.',
      icon: Icons.wb_shade,
      accent: Color(0xFFF97316),
    ),
    'badge_water_whisperer': _BadgeDef(
      title: 'Water Whisperer',
      description: '15+ water logs with no severe overwater streak.',
      icon: Icons.opacity,
      accent: Color(0xFF0284C7),
    ),
    'badge_pollinator_pal': _BadgeDef(
      title: 'Pollinator Pal',
      description: 'Completed feeding stage tasks across two weeks.',
      icon: Icons.local_florist_outlined,
      accent: Color(0xFFEC4899),
    ),
    'badge_canopy_king': _BadgeDef(
      title: 'Canopy King',
      description: 'Long harvest (90d+) with streak still growing past 5.',
      icon: Icons.forest,
      accent: Color(0xFF15803D),
    ),
    'badge_seed_scientist': _BadgeDef(
      title: 'Seed Scientist',
      description: 'Seeding stage: 10+ on-time tasks completed.',
      icon: Icons.science_outlined,
      accent: Color(0xFF7DD3FC),
    ),
    'badge_rain_ready': _BadgeDef(
      title: 'Rain Ready',
      description: 'Balanced care: 12+ tasks done with vitality 80–95%.',
      icon: Icons.umbrella,
      accent: Color(0xFF64748B),
    ),
    'badge_compost_champion': _BadgeDef(
      title: 'Compost Champion',
      description: 'Heavy feeding crop with 20+ completed tasks.',
      icon: Icons.recycling,
      accent: Color(0xFF65A30D),
    ),
    'badge_urban_farmer': _BadgeDef(
      title: 'Urban Farmer',
      description: 'Balcony or indoor grow with a 7+ day streak.',
      icon: Icons.apartment,
      accent: Color(0xFF0D9488),
    ),
  };
}

class _BadgeDef {
  const _BadgeDef({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}
