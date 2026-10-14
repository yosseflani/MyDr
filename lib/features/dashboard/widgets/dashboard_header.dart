import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/theme/app_colors.dart';
import 'package:mydr/features/dashboard/greeting.dart';

/// Gradient welcome banner with the app name, greeting and today's date.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatFullDate(date);
    const onBrand = Colors.white;
    final onBrandMuted = Colors.white.withValues(alpha: 0.85);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety, color: onBrand, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppStrings.appTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: onBrand,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            greetingFor(date),
            style: textTheme.headlineSmall?.copyWith(
              color: onBrand,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today, color: onBrandMuted, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  formattedDate,
                  style: textTheme.bodyMedium?.copyWith(color: onBrandMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.dashboardSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: onBrand),
          ),
        ],
      ),
    );
  }
}
