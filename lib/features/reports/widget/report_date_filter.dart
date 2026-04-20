import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/constants/translations.dart';

/// Loyverse-style date filter tabs: Today | This Week | This Month | Custom
class ReportDateFilter extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTimeRange> onChanged;
  final String lang;

  const ReportDateFilter({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
    required this.lang,
  });

  String get _activeTab {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_isSameDay(startDate, todayStart) && _isSameDay(endDate, todayEnd) ||
        _isSameDay(startDate, todayStart) && _isSameDay(endDate, now)) {
      return 'today';
    }

    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    if (_isSameDay(startDate, DateTime(weekStart.year, weekStart.month, weekStart.day))) {
      final diff = endDate.difference(startDate).inDays;
      if (diff <= 7) return 'week';
    }

    if (startDate.year == now.year && startDate.month == now.month && startDate.day == 1) {
      return 'month';
    }

    return 'custom';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final active = _activeTab;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              _tab(Translations.get('today', lang), 'today', active, () {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                onChanged(DateTimeRange(start: today, end: now));
              }),
              const SizedBox(width: 8),
              _tab(Translations.get('this_week', lang), 'week', active, () {
                final now = DateTime.now();
                final weekStart = now.subtract(Duration(days: now.weekday - 1));
                onChanged(DateTimeRange(
                  start: DateTime(weekStart.year, weekStart.month, weekStart.day),
                  end: now,
                ));
              }),
              const SizedBox(width: 8),
              _tab(Translations.get('this_month', lang), 'month', active, () {
                final now = DateTime.now();
                onChanged(DateTimeRange(
                  start: DateTime(now.year, now.month, 1),
                  end: now,
                ));
              }),
              const SizedBox(width: 8),
              _tab(
                active == 'custom'
                    ? '${DateFormat('d/M').format(startDate)} - ${DateFormat('d/M').format(endDate)}'
                    : Translations.get('custom_range', lang),
                'custom',
                active,
                () => _pickRange(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, String key, String active, VoidCallback onTap) {
    final isActive = key == active;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryOrange : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }
}
