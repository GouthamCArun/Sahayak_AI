import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';

class DiagramResultDisplay extends StatelessWidget {
  final Map<String, dynamic> diagram;
  final VoidCallback onRegenerate;
  final VoidCallback onStartNew;

  const DiagramResultDisplay({
    super.key,
    required this.diagram,
    required this.onRegenerate,
    required this.onStartNew,
  });

  @override
  Widget build(BuildContext context) {
    final diagramData = diagram['diagram_data'] ?? {};
    final metadata = diagram['metadata'] ?? {};

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
                    AppTheme.primaryPurple.withOpacity(0.1),
                    AppTheme.primaryBlue.withOpacity(0.1),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diagram Generated Successfully!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (metadata['processing_time'] != null)
                          Text(
                            'Generated in ${metadata['processing_time']}',
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

          // Diagram Display
          _buildDiagramDisplay(diagramData),

          const SizedBox(height: 20),

          // Diagram Description
          if (diagramData['description'] != null) ...[
            _buildDescriptionCard(diagramData['description']),
            const SizedBox(height: 20),
          ],

          // Teaching Instructions
          if (diagramData['teaching_instructions'] != null) ...[
            _buildTeachingInstructionsCard(
                diagramData['teaching_instructions']),
            const SizedBox(height: 20),
          ],

          // Diagram Info
          _buildDiagramInfoCard(diagramData, metadata),

          const SizedBox(height: 20),

          // Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildDiagramDisplay(Map<String, dynamic> diagramData) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.image,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    diagramData['title'] ?? 'Generated Diagram',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (diagramData['diagram_type'] != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getDiagramTypeDisplayName(diagramData['diagram_type']),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Diagram Image or Placeholder
          Container(
            height: 300,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.lightGray),
              color: AppTheme.surfaceColor,
            ),
            child: diagramData['image_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: diagramData['image_url'],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildDiagramPlaceholder(),
                    ),
                  )
                : _buildDiagramPlaceholder(),
          ),

          // Download Instructions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Diagram is ready for classroom use. You can download, print, or project it.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramPlaceholder() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Diagram Generated Successfully',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The AI has created your educational diagram.\nUse the download button to save it.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
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
                  Icons.description,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Diagram Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(description),
                  tooltip: 'Copy Description',
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
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachingInstructionsCard(Map<String, dynamic> instructions) {
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
                  Icons.school,
                  color: AppTheme.accentOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Teaching Instructions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (instructions['how_to_use'] != null) ...[
              Text(
                'How to Use:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                instructions['how_to_use'],
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (instructions['discussion_points'] != null) ...[
              Text(
                'Discussion Points:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...(instructions['discussion_points'] as List)
                  .map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                color: AppTheme.primaryPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                point.toString(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDiagramInfoCard(
      Map<String, dynamic> diagramData, Map<String, dynamic> metadata) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagram Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                'Type:',
                _getDiagramTypeDisplayName(
                    diagramData['diagram_type'] ?? 'auto')),
            _buildInfoRow('Subject:',
                _getSubjectDisplayName(metadata['subject'] ?? 'general')),
            _buildInfoRow(
                'Grade Level:',
                _getGradeLevelDisplayName(
                    metadata['grade_level'] ?? 'grade_3_4')),
            _buildInfoRow('Language:',
                _getLanguageDisplayName(metadata['language'] ?? 'en')),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
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
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Regenerate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
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
                label: const Text('New Diagram'),
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
                onPressed: () => _downloadDiagram(context),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _shareDiagram(context),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _printDiagram(context),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Print'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryOrange,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getDiagramTypeDisplayName(String type) {
    switch (type) {
      case 'concept_map':
        return 'Concept Map';
      case 'flowchart':
        return 'Flowchart';
      case 'timeline':
        return 'Timeline';
      case 'bar_chart':
        return 'Bar Chart';
      case 'pie_chart':
        return 'Pie Chart';
      case 'line_graph':
        return 'Line Graph';
      case 'scatter_plot':
        return 'Scatter Plot';
      default:
        return 'Auto-Selected';
    }
  }

  String _getSubjectDisplayName(String subject) {
    switch (subject) {
      case 'mathematics':
        return 'Mathematics';
      case 'science':
        return 'Science';
      case 'language':
        return 'Language Arts';
      case 'social_studies':
        return 'Social Studies';
      default:
        return 'General';
    }
  }

  String _getGradeLevelDisplayName(String grade) {
    switch (grade) {
      case 'grade_1_2':
        return 'Grade 1-2';
      case 'grade_3_4':
        return 'Grade 3-4';
      case 'grade_5_6':
        return 'Grade 5-6';
      default:
        return 'Grade 3-4';
    }
  }

  String _getLanguageDisplayName(String language) {
    switch (language) {
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      case 'ta':
        return 'தமிழ்';
      case 'bn':
        return 'বাংলা';
      case 'gu':
        return 'ગુજરાતી';
      default:
        return 'English';
    }
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
  }

  void _downloadDiagram(BuildContext context) {
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality coming soon!')),
    );
  }

  void _shareDiagram(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _printDiagram(BuildContext context) {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon!')),
    );
  }
}
