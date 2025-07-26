import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

class LessonPlanCard extends StatefulWidget {
  final int day;
  final Map<String, dynamic> lesson;
  final String subject;

  const LessonPlanCard({
    super.key,
    required this.day,
    required this.lesson,
    required this.subject,
  });

  @override
  State<LessonPlanCard> createState() => _LessonPlanCardState();
}

class _LessonPlanCardState extends State<LessonPlanCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = widget.day <= dayNames.length
        ? dayNames[widget.day - 1]
        : 'Day ${widget.day}';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getSubjectColor().withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getSubjectColor(),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.day.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          widget.lesson['topic'] ?? 'Lesson Topic',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (widget.lesson['duration'] != null)
                          Text(
                            widget.lesson['duration'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () => _copyLessonContent(),
                        tooltip: 'Copy Lesson',
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded ? null : 0,
            child:
                _isExpanded ? _buildLessonContent() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Objectives
          if (widget.lesson['objectives'] != null) ...[
                         _buildSection(
               'Learning Objectives',
               Icons.track_changes,
               AppTheme.primaryBlue,
              widget.lesson['objectives'] is List
                  ? (widget.lesson['objectives'] as List).join('\n• ')
                  : widget.lesson['objectives'].toString(),
            ),
            const SizedBox(height: 16),
          ],

          // Main Content
          if (widget.lesson['content'] != null) ...[
            _buildSection(
              'Lesson Content',
              Icons.article,
              AppTheme.primaryPurple,
              widget.lesson['content'].toString(),
            ),
            const SizedBox(height: 16),
          ],

          // Activities
          if (widget.lesson['activities'] != null) ...[
            _buildSection(
              'Activities',
              Icons.sports_esports,
              AppTheme.primaryOrange,
              widget.lesson['activities'] is List
                  ? (widget.lesson['activities'] as List).join('\n• ')
                  : widget.lesson['activities'].toString(),
            ),
            const SizedBox(height: 16),
          ],

          // Materials
          if (widget.lesson['materials'] != null) ...[
            _buildSection(
              'Materials Needed',
              Icons.inventory,
              AppTheme.accentOrange,
              widget.lesson['materials'] is List
                  ? (widget.lesson['materials'] as List).join(', ')
                  : widget.lesson['materials'].toString(),
            ),
            const SizedBox(height: 16),
          ],

          // Assessment
          if (widget.lesson['assessment'] != null) ...[
            _buildSection(
              'Assessment',
              Icons.assessment,
              AppTheme.primaryGreen,
              widget.lesson['assessment'].toString(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, Color color, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            content.startsWith('• ') ? content : '• $content',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Color _getSubjectColor() {
    switch (widget.subject) {
      case 'mathematics':
        return AppTheme.primaryBlue;
      case 'science':
        return AppTheme.primaryGreen;
      case 'language':
        return AppTheme.primaryPurple;
      case 'social_studies':
        return AppTheme.primaryOrange;
      default:
        return AppTheme.primaryPink;
    }
  }

  void _copyLessonContent() {
    final content = _formatLessonForCopy();
    Clipboard.setData(ClipboardData(text: content));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lesson content copied to clipboard'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatLessonForCopy() {
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = widget.day <= dayNames.length
        ? dayNames[widget.day - 1]
        : 'Day ${widget.day}';

    final buffer = StringBuffer();
    buffer.writeln('=== $dayName Lesson Plan ===');
    buffer.writeln('Topic: ${widget.lesson['topic'] ?? 'Lesson Topic'}');

    if (widget.lesson['duration'] != null) {
      buffer.writeln('Duration: ${widget.lesson['duration']}');
    }
    buffer.writeln();

    if (widget.lesson['objectives'] != null) {
      buffer.writeln('LEARNING OBJECTIVES:');
      if (widget.lesson['objectives'] is List) {
        for (var objective in widget.lesson['objectives']) {
          buffer.writeln('• $objective');
        }
      } else {
        buffer.writeln('• ${widget.lesson['objectives']}');
      }
      buffer.writeln();
    }

    if (widget.lesson['content'] != null) {
      buffer.writeln('LESSON CONTENT:');
      buffer.writeln(widget.lesson['content']);
      buffer.writeln();
    }

    if (widget.lesson['activities'] != null) {
      buffer.writeln('ACTIVITIES:');
      if (widget.lesson['activities'] is List) {
        for (var activity in widget.lesson['activities']) {
          buffer.writeln('• $activity');
        }
      } else {
        buffer.writeln('• ${widget.lesson['activities']}');
      }
      buffer.writeln();
    }

    if (widget.lesson['materials'] != null) {
      buffer.writeln('MATERIALS NEEDED:');
      if (widget.lesson['materials'] is List) {
        buffer.writeln('• ${(widget.lesson['materials'] as List).join(', ')}');
      } else {
        buffer.writeln('• ${widget.lesson['materials']}');
      }
      buffer.writeln();
    }

    if (widget.lesson['assessment'] != null) {
      buffer.writeln('ASSESSMENT:');
      buffer.writeln('• ${widget.lesson['assessment']}');
    }

    return buffer.toString();
  }
}
