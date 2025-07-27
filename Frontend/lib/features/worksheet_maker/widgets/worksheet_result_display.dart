import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/markdown_renderer.dart';

class WorksheetResultDisplay extends StatelessWidget {
  final Map<String, dynamic> worksheet;
  final VoidCallback onRegenerate;
  final VoidCallback onStartNew;

  const WorksheetResultDisplay({
    super.key,
    required this.worksheet,
    required this.onRegenerate,
    required this.onStartNew,
  });

  @override
  Widget build(BuildContext context) {
    final worksheetData = worksheet['worksheet_data'] ?? {};
    final metadata = worksheet['metadata'] ?? {};

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
                    AppTheme.primaryGreen.withOpacity(0.1),
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
                          'Worksheet Generated Successfully!',
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

          // Worksheet Content
          if (worksheetData['worksheets'] != null) ...[
            ...((worksheetData['worksheets'] as Map<String, dynamic>)
                .values
                .map((ws) => _buildWorksheetCard(ws))),
          ] else ...[
            _buildSingleWorksheetCard(worksheetData),
          ],

          const SizedBox(height: 20),

          // Extracted Content Summary
          if (worksheetData['extracted_content'] != null) ...[
            _buildExtractedContentCard(worksheetData['extracted_content']),
            const SizedBox(height: 20),
          ],

          // Teaching Suggestions
          if (worksheetData['teaching_suggestions'] != null) ...[
            _buildTeachingSuggestionsCard(
                worksheetData['teaching_suggestions']),
            const SizedBox(height: 20),
          ],

          // Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildWorksheetCard(Map<String, dynamic> worksheetData) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    worksheetData['title'] ?? 'Generated Worksheet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(
                    worksheetData['content'] ?? '',
                  ),
                  tooltip: 'Copy Content',
                ),
              ],
            ),

            if (worksheetData['grade_level'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Grade: ${worksheetData['grade_level']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.lightGray),
              ),
              child: MarkdownRenderer(
                content: worksheetData['content'] ?? 'No content available',
              ),
            ),

            // Instructions
            if (worksheetData['instructions'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Instructions for Students:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                worksheetData['instructions'],
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleWorksheetCard(Map<String, dynamic> worksheetData) {
    return _buildWorksheetCard(worksheetData);
  }

  Widget _buildExtractedContentCard(Map<String, dynamic> extractedContent) {
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
                  Icons.visibility,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Extracted Content',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (extractedContent['text'] != null) ...[
              Text(
                'Detected Text:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  extractedContent['text'],
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
            if (extractedContent['concepts'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Key Concepts:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (extractedContent['concepts'] as List)
                    .map((concept) => Chip(
                          label: Text(
                            concept.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor:
                              AppTheme.primaryPurple.withOpacity(0.1),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeachingSuggestionsCard(Map<String, dynamic> suggestions) {
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
                  Icons.lightbulb_outline,
                  color: AppTheme.accentOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Teaching Suggestions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (suggestions['activities'] != null) ...[
              Text(
                'Suggested Activities:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...(suggestions['activities'] as List).map((activity) => Padding(
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
                            activity.toString(),
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
            if (suggestions['tips'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Teaching Tips:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                suggestions['tips'],
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
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
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Regenerate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
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
                label: const Text('New Worksheet'),
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
                onPressed: () => _shareWorksheet(context),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _downloadWorksheet(context),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryPurple,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _printWorksheet(context),
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

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
  }

  void _shareWorksheet(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _downloadWorksheet(BuildContext context) {
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality coming soon!')),
    );
  }

  void _printWorksheet(BuildContext context) {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon!')),
    );
  }
}
