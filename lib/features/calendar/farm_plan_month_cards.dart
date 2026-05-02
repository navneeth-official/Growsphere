import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/farm_plan_template.dart';
import '../../core/theme/grow_colors.dart';

/// Month cards + task rows (reference Calendar tab).
class FarmPlanMonthCards extends StatelessWidget {
  const FarmPlanMonthCards({
    super.key,
    required this.startMonth1To12,
    required this.sectionTitle,
  });

  final int startMonth1To12;
  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    final blocks = buildFarmPlanMonths(startMonth1To12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sectionTitle,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...blocks.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: GrowColors.gray200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.header,
                        style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < b.tasks.length; i++) ...[
                        if (i > 0) Divider(height: 20, color: GrowColors.gray200.withValues(alpha: 0.8)),
                        _TaskRow(task: b.tasks[i]),
                      ],
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final FarmPlanTask task;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: task.iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(task.icon, color: task.iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                task.subtitle,
                style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: GrowColors.gray200.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            task.weekLabel,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: GrowColors.gray700),
          ),
        ),
      ],
    );
  }
}
