import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

class AssessmentResultDisplay extends StatelessWidget {
  final Map<String, dynamic> assessment;
  final VoidCallback onReassess;
  final VoidCallback onStartNew;

  const AssessmentResultDisplay({
    super.key,
    required this.assessment,
    required this.onReassess,
    required this.onStartNew,
  });

  @override
  Widget build(BuildContext context) {
    final assessmentData = assessment['assessment_data'] ?? {};
    final metadata = assessment['metadata'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success Header
          Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryOrange.withOpacity(0.1),
                    AppTheme.accentOrange.withOpacity(0.1),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assessment,
                    color: AppTheme.primaryOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reading Assessment Complete!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (metadata['processing_time'] != null)
                          Text(
                            'Analyzed in ${metadata['processing_time']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Reading Metrics
          _buildReadingMetrics(assessmentData['reading_metrics'] ?? {}),

          const SizedBox(height: 20),

          // Transcription
          if (assessmentData['transcription'] != null) ...[
            _buildTranscriptionCard(assessmentData['transcription']),
            const SizedBox(height: 20),
          ],

          // Assessment Feedback
          if (assessmentData['assessment_feedback'] != null) ...[
            _buildFeedbackCard(assessmentData['assessment_feedback']),
            const SizedBox(height: 20),
          ],

          // Improvement Plan
          if (assessmentData['improvement_plan'] != null) ...[
            _buildImprovementPlanCard(assessmentData['improvement_plan']),
            const SizedBox(height: 20),
          ],

          // Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildReadingMetrics(Map<String, dynamic> metrics) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Score Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard(
                  'Reading Speed',
                  '${metrics['words_per_minute']?.toStringAsFixed(0) ?? '0'} WPM',
                  AppTheme.primaryBlue,
                  Icons.speed,
                ),
                _buildMetricCard(
                  'Accuracy',
                  '${metrics['accuracy_percentage']?.toStringAsFixed(0) ?? '0'}%',
                  AppTheme.primaryGreen,
                  Icons.check_circle,
                ),
                _buildMetricCard(
                  'Fluency Score',
                  '${metrics['fluency_score']?.toStringAsFixed(0) ?? '0'}/100',
                  AppTheme.primaryPurple,
                  Icons.trending_up,
                ),
                _buildMetricCard(
                  'Pronunciation',
                  '${metrics['pronunciation_score']?.toStringAsFixed(0) ?? '0'}%',
                  AppTheme.primaryOrange,
                  Icons.record_voice_over,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Reading Level Badge
            if (metrics['reading_level'] != null) ...[
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _getReadingLevelColor(metrics['reading_level'])
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _getReadingLevelColor(metrics['reading_level']),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getReadingLevelIcon(metrics['reading_level']),
                        color: _getReadingLevelColor(metrics['reading_level']),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getReadingLevelDisplayName(metrics['reading_level']),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              _getReadingLevelColor(metrics['reading_level']),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionCard(Map<String, dynamic> transcription) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.transcribe,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'What We Heard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () =>
                      _copyToClipboard(transcription['transcript'] ?? ''),
                  tooltip: 'Copy Transcription',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.lightGray),
              ),
              child: Text(
                transcription['transcript'] ?? 'No transcription available',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            if (transcription['confidence'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.volume_up,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Audio Clarity: ${(transcription['confidence'] * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.feedback,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Teacher Feedback',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (feedback['strengths'] != null) ...[
              _buildFeedbackSection(
                'Strengths',
                feedback['strengths'] as List,
                AppTheme.primaryGreen,
                Icons.star,
              ),
              const SizedBox(height: 12),
            ],
            if (feedback['improvement_areas'] != null) ...[
              _buildFeedbackSection(
                'Areas for Improvement',
                feedback['improvement_areas'] as List,
                AppTheme.primaryOrange,
                Icons.trending_up,
              ),
              const SizedBox(height: 12),
            ],
            if (feedback['encouragement'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: AppTheme.primaryBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feedback['encouragement'],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(
      String title, List items, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
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
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildImprovementPlanCard(Map<String, dynamic> plan) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.map,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Improvement Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.lightGray),
              ),
              child: Text(
                plan['improvement_plan'] ?? 'No improvement plan available',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            if (plan['practice_duration'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended Practice: ${plan['practice_duration']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onReassess,
                icon: const Icon(Icons.mic, size: 20),
                label: const Text('Record Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onStartNew,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('New Assessment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryPink,
                  side: BorderSide(color: AppTheme.primaryPink),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Secondary Actions
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => _shareAssessment(context),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _saveAssessment(context),
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _printAssessment(context),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Print'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryPurple,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getReadingLevelColor(String level) {
    switch (level) {
      case 'excellent':
        return AppTheme.primaryGreen;
      case 'good':
        return AppTheme.primaryBlue;
      case 'fair':
        return AppTheme.primaryOrange;
      case 'needs_improvement':
        return Colors.red[400]!;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getReadingLevelIcon(String level) {
    switch (level) {
      case 'excellent':
        return Icons.emoji_events;
      case 'good':
        return Icons.thumb_up;
      case 'fair':
        return Icons.trending_up;
      case 'needs_improvement':
        return Icons.support;
      default:
        return Icons.help_outline;
    }
  }

  String _getReadingLevelDisplayName(String level) {
    switch (level) {
      case 'excellent':
        return 'Excellent Reader';
      case 'good':
        return 'Good Reader';
      case 'fair':
        return 'Fair Reader';
      case 'needs_improvement':
        return 'Needs Support';
      default:
        return 'Unknown Level';
    }
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
  }

  void _shareAssessment(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _saveAssessment(BuildContext context) {
    // TODO: Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save functionality coming soon!')),
    );
  }

  void _printAssessment(BuildContext context) {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon!')),
    );
  }
}
