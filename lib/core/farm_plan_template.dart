import 'package:flutter/material.dart';

const _months = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Parses user text like "January", "jan", "March" → 1–12 or null.
int? parseFarmStartMonth(String raw) {
  final t = raw.trim().toLowerCase();
  if (t.isEmpty) return null;
  for (var i = 0; i < _months.length; i++) {
    final m = _months[i].toLowerCase();
    if (m == t || m.startsWith(t)) return i + 1;
  }
  return null;
}

class FarmPlanTask {
  const FarmPlanTask({
    required this.title,
    required this.subtitle,
    required this.weekLabel,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final String weekLabel;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
}

class FarmPlanMonthBlock {
  const FarmPlanMonthBlock({required this.header, required this.tasks});

  final String header;
  final List<FarmPlanTask> tasks;
}

/// All template rows in display order (month blocks → tasks).
List<FarmPlanTask> flattenFarmPlanTemplate(int startMonth1To12) {
  return buildFarmPlanMonths(startMonth1To12).expand((b) => b.tasks).toList();
}

/// Parses labels like "Week 12" → 12.
int? parseWeekNumberFromLabel(String weekLabel) {
  final m = RegExp(r'Week\s+(\d+)', caseSensitive: false).firstMatch(weekLabel);
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

int _monthAt(int start1To12, int offset) {
  var m = start1To12 + offset - 1;
  m %= 12;
  if (m < 0) m += 12;
  return m + 1;
}

/// Four blocks: three farm months + harvest month, aligned with reference UI.
List<FarmPlanMonthBlock> buildFarmPlanMonths(int startMonth1To12) {
  String header(int blockIndex) {
    final cal = _monthAt(startMonth1To12, blockIndex);
    final name = _months[cal - 1];
    if (blockIndex < 3) {
      return '$name - Month ${blockIndex + 1}';
    }
    return '$name - Harvest month';
  }

  return [
    FarmPlanMonthBlock(
      header: header(0),
      tasks: const [
        FarmPlanTask(
          title: 'Soil Preparation',
          subtitle: 'Prepare and test soil, add organic matter',
          weekLabel: 'Week 1',
          icon: Icons.spa_outlined,
          iconBg: Color(0xFFF3F4F6),
          iconColor: Color(0xFF111827),
        ),
        FarmPlanTask(
          title: 'Seeding/Planting',
          subtitle: 'Plant seeds or seedlings according to spacing requirements.',
          weekLabel: 'Week 2',
          icon: Icons.eco,
          iconBg: Color(0xFFDCFCE7),
          iconColor: Color(0xFF15803D),
        ),
        FarmPlanTask(
          title: 'Fertilizing',
          subtitle: 'Apply fertilizer as per plant requirements.',
          weekLabel: 'Week 4',
          icon: Icons.water_drop_outlined,
          iconBg: Color(0xFFDBEAFE),
          iconColor: Color(0xFF1D4ED8),
        ),
      ],
    ),
    FarmPlanMonthBlock(
      header: header(1),
      tasks: const [
        FarmPlanTask(
          title: 'Pest Control',
          subtitle: 'Check for pests and apply control measures.',
          weekLabel: 'Week 6',
          icon: Icons.bug_report_outlined,
          iconBg: Color(0xFFFEE2E2),
          iconColor: Color(0xFFB91C1C),
        ),
        FarmPlanTask(
          title: 'Fertilizing',
          subtitle: 'Apply fertilizer as per plant requirements.',
          weekLabel: 'Week 8',
          icon: Icons.water_drop_outlined,
          iconBg: Color(0xFFDBEAFE),
          iconColor: Color(0xFF1D4ED8),
        ),
      ],
    ),
    FarmPlanMonthBlock(
      header: header(2),
      tasks: const [
        FarmPlanTask(
          title: 'Growth monitoring',
          subtitle: 'Check plant height, prune if needed, support vines.',
          weekLabel: 'Week 10',
          icon: Icons.show_chart,
          iconBg: Color(0xFFF3E8FF),
          iconColor: Color(0xFF7C3AED),
        ),
        FarmPlanTask(
          title: 'Irrigation tuning',
          subtitle: 'Adjust watering based on weather and soil moisture.',
          weekLabel: 'Week 11',
          icon: Icons.water,
          iconBg: Color(0xFFE0F2FE),
          iconColor: Color(0xFF0369A1),
        ),
      ],
    ),
    FarmPlanMonthBlock(
      header: header(3),
      tasks: const [
        FarmPlanTask(
          title: 'Pre-harvest prep',
          subtitle: 'Reduce nitrogen, monitor ripeness, plan storage.',
          weekLabel: 'Week 12',
          icon: Icons.inventory_2_outlined,
          iconBg: Color(0xFFFFEDD5),
          iconColor: Color(0xFFC2410C),
        ),
        FarmPlanTask(
          title: 'Harvest',
          subtitle: 'Harvest at peak quality; cure or cool as needed.',
          weekLabel: 'Week 13',
          icon: Icons.agriculture,
          iconBg: Color(0xFFFFE4E6),
          iconColor: Color(0xFFBE123C),
        ),
      ],
    ),
  ];
}
