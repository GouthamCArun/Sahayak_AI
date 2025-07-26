import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class WeekSelector extends StatelessWidget {
  final DateTime selectedWeek;
  final ValueChanged<DateTime> onWeekChanged;

  const WeekSelector({
    super.key,
    required this.selectedWeek,
    required this.onWeekChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Week',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Previous Week Button
                IconButton(
                  onPressed: () {
                    final previousWeek =
                        selectedWeek.subtract(const Duration(days: 7));
                    onWeekChanged(previousWeek);
                  },
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: AppTheme.primaryGreen,
                  ),
                  tooltip: 'Previous Week',
                ),

                // Current Week Display
                Expanded(
                  child: InkWell(
                    onTap: () => _showWeekPicker(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatWeekRange(selectedWeek),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getWeekLabel(selectedWeek),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Next Week Button
                IconButton(
                  onPressed: () {
                    final nextWeek = selectedWeek.add(const Duration(days: 7));
                    onWeekChanged(nextWeek);
                  },
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.primaryGreen,
                  ),
                  tooltip: 'Next Week',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quick Week Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickWeekOption(
                  'This Week',
                  DateTime.now(),
                  context,
                ),
                _buildQuickWeekOption(
                  'Next Week',
                  DateTime.now().add(const Duration(days: 7)),
                  context,
                ),
                _buildQuickWeekOption(
                  'Following Week',
                  DateTime.now().add(const Duration(days: 14)),
                  context,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickWeekOption(
      String label, DateTime week, BuildContext context) {
    final isSelected = _isSameWeek(selectedWeek, week);

    return InkWell(
      onTap: () => onWeekChanged(week),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withOpacity(0.2)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.lightGray,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _showWeekPicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedWeek,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select any day in the week',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onWeekChanged(picked);
    }
  }

  String _formatWeekRange(DateTime week) {
    final startOfWeek = week.subtract(Duration(days: week.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    if (startOfWeek.month == endOfWeek.month) {
      return '${startOfWeek.day}-${endOfWeek.day} ${months[startOfWeek.month]}';
    } else {
      return '${startOfWeek.day} ${months[startOfWeek.month]} - ${endOfWeek.day} ${months[endOfWeek.month]}';
    }
  }

  String _getWeekLabel(DateTime week) {
    final now = DateTime.now();
    final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfSelectedWeek = week.subtract(Duration(days: week.weekday - 1));

    final diffInDays = startOfSelectedWeek.difference(startOfThisWeek).inDays;

    if (diffInDays == 0) {
      return 'This Week';
    } else if (diffInDays == 7) {
      return 'Next Week';
    } else if (diffInDays == -7) {
      return 'Last Week';
    } else if (diffInDays > 0) {
      final weeks = (diffInDays / 7).round();
      return '$weeks week${weeks > 1 ? 's' : ''} ahead';
    } else {
      final weeks = (diffInDays.abs() / 7).round();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    }
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final startOfWeek1 = date1.subtract(Duration(days: date1.weekday - 1));
    final startOfWeek2 = date2.subtract(Duration(days: date2.weekday - 1));

    return startOfWeek1.year == startOfWeek2.year &&
        startOfWeek1.month == startOfWeek2.month &&
        startOfWeek1.day == startOfWeek2.day;
  }
}
