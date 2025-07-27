import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class DiagramTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const DiagramTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final diagramTypes = [
      {
        'code': 'auto',
        'name': 'Auto-Select',
        'description': 'AI chooses best type',
        'icon': Icons.auto_awesome,
        'color': AppTheme.primaryPink,
      },
      {
        'code': 'concept_map',
        'name': 'Concept Map',
        'description': 'Connected ideas',
        'icon': Icons.account_tree,
        'color': AppTheme.primaryBlue,
      },
      {
        'code': 'flowchart',
        'name': 'Flowchart',
        'description': 'Process steps',
        'icon': Icons.call_split,
        'color': AppTheme.primaryGreen,
      },
      {
        'code': 'timeline',
        'name': 'Timeline',
        'description': 'Chronological order',
        'icon': Icons.timeline,
        'color': AppTheme.primaryOrange,
      },
      {
        'code': 'bar_chart',
        'name': 'Bar Chart',
        'description': 'Compare values',
        'icon': Icons.bar_chart,
        'color': AppTheme.primaryPurple,
      },
      {
        'code': 'pie_chart',
        'name': 'Pie Chart',
        'description': 'Parts of whole',
        'icon': Icons.pie_chart,
        'color': AppTheme.accentOrange,
      },
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagram Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: diagramTypes.length,
              itemBuilder: (context, index) {
                final type = diagramTypes[index];
                final isSelected = selectedType == type['code'];

                return InkWell(
                  onTap: () => onTypeChanged(type['code'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (type['color'] as Color)
                            : AppTheme.lightGray,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? (type['color'] as Color).withOpacity(0.1)
                          : AppTheme.surfaceColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10), // Reduced from 12
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min, // Added to prevent overflow
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                type['icon'] as IconData,
                                color: isSelected
                                    ? (type['color'] as Color)
                                    : AppTheme.textSecondary,
                                size: 18, // Reduced from 20
                              ),
                              const SizedBox(width: 6), // Reduced from 8
                              Expanded(
                                child: Text(
                                  type['name'] as String,
                                  style: TextStyle(
                                    fontSize: 12, // Reduced from 13
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? (type['color'] as Color)
                                        : AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2), // Reduced from 4
                          Text(
                            type['description'] as String,
                            style: TextStyle(
                              fontSize: 10, // Reduced from 11
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
