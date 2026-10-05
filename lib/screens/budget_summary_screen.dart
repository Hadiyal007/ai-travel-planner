import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/activity.dart';
import '../models/itinerary.dart';
import '../models/trip.dart';

/// Shows the AI's per-activity cost estimates rolled up against the
/// trip's budget: a total, how it compares to what was budgeted, a
/// breakdown by activity type, and a day-by-day subtotal. Reached from
/// a "Budget Summary" button on both the just-generated itinerary
/// screen and a saved trip's itinerary screen.
class BudgetSummaryScreen extends StatelessWidget {
  final Trip trip;
  final Itinerary itinerary;

  const BudgetSummaryScreen({super.key, required this.trip, required this.itinerary});

  String _iconLabelFor(ActivityType type) {
    switch (type) {
      case ActivityType.meal:
        return 'Food';
      case ActivityType.sightseeing:
        return 'Sightseeing';
      case ActivityType.travel:
        return 'Travel';
      case ActivityType.checkin:
        return 'Stay';
      case ActivityType.leisure:
        return 'Leisure';
      case ActivityType.adventure:
        return 'Adventure';
    }
  }

  IconData _iconFor(ActivityType type) {
    switch (type) {
      case ActivityType.meal:
        return Icons.restaurant;
      case ActivityType.sightseeing:
        return Icons.photo_camera_outlined;
      case ActivityType.travel:
        return Icons.directions_car_outlined;
      case ActivityType.checkin:
        return Icons.hotel_outlined;
      case ActivityType.leisure:
        return Icons.self_improvement;
      case ActivityType.adventure:
        return Icons.hiking;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allActivities = itinerary.days.expand((day) => day.activities).toList();

    final estimated = allActivities.where((a) => a.estimatedCost != null).toList();
    final missing = allActivities.length - estimated.length;
    final total = estimated.fold<double>(0, (sum, a) => sum + a.estimatedCost!);

    final byType = <ActivityType, double>{};
    for (final activity in estimated) {
      byType[activity.type] = (byType[activity.type] ?? 0) + activity.estimatedCost!;
    }
    final sortedTypes = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final remaining = trip.budget - total;
    final isOverBudget = remaining < 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Summary')),
      body: SafeArea(
        child: estimated.isEmpty
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No cost estimates are available for this trip — it may have been '
                  'planned before budget estimates were added.',
              textAlign: TextAlign.center,
            ),
          ),
        )
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TotalCard(
              total: total,
              budget: trip.budget,
              remaining: remaining,
              isOverBudget: isOverBudget,
            ),
            if (missing > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.marigold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppTheme.marigoldDeep),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$missing activit${missing == 1 ? 'y has' : 'ies have'} no cost '
                            'estimate and ${missing == 1 ? 'is' : 'are'} excluded from this total.',
                        style: const TextStyle(fontSize: 12, color: AppTheme.marigoldDeep),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('By category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: sortedTypes.map((entry) {
                    final fraction = total == 0 ? 0.0 : entry.value / total;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_iconFor(entry.key), size: 16, color: AppTheme.inkMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_iconLabelFor(entry.key),
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ),
                              Text(
                                '₹${entry.value.toStringAsFixed(0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 6,
                              backgroundColor: AppTheme.hairline,
                              color: AppTheme.marigold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('By day', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...itinerary.days.map((day) {
              final dayTotal = day.activities
                  .where((a) => a.estimatedCost != null)
                  .fold<double>(0, (sum, a) => sum + a.estimatedCost!);
              return Card(
                child: ListTile(
                  title: Text('Day ${day.dayNumber}'),
                  trailing: Text(
                    '₹${dayTotal.toStringAsFixed(0)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: AppTheme.indigoNight),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  final double budget;
  final double remaining;
  final bool isOverBudget;

  const _TotalCard({
    required this.total,
    required this.budget,
    required this.remaining,
    required this.isOverBudget,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOverBudget ? AppTheme.chili : AppTheme.banyan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.indigoNight, AppTheme.indigoNightLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estimated total', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '₹${total.toStringAsFixed(0)}',
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('of ₹${budget.toStringAsFixed(0)} budgeted',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOverBudget ? Icons.trending_up : Icons.check_circle_outline,
                  size: 16,
                  color: statusColor == AppTheme.chili ? Colors.redAccent.shade100 : Colors.greenAccent.shade100,
                ),
                const SizedBox(width: 6),
                Text(
                  isOverBudget
                      ? '₹${remaining.abs().toStringAsFixed(0)} over budget'
                      : '₹${remaining.toStringAsFixed(0)} left in budget',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}