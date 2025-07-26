import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

/// Content result display widget
///
/// Shows the generated AI content with formatting, actions,
/// and user interaction options.
class ContentResultDisplay extends StatelessWidget {
  final Map<String, dynamic> content;
  final VoidCallback onRegenerate;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const ContentResultDisplay({
    super.key,
    required this.content,
    required this.onRegenerate,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Content Display
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content Header
                _buildContentHeader(),

                const SizedBox(height: 20),

                // Main Content
                _buildMainContent(),

                const SizedBox(height: 20),

                // Metadata
                _buildMetadata(),

                const SizedBox(height: 100), // Space for action buttons
              ],
            ),
          ),
        ),

        // Action Buttons
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildContentHeader() {
    final title = content['title'] ?? 'Generated Content';
    final contentType = content['content_type'] ?? 'content';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryPink, AppTheme.primaryPink.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForContentType(contentType),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (content['topic'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Topic: ${content['topic']}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final generatedText = content['generated_text'] ??
        content['content'] ??
        'No content available';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Generated Content',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () => _copyToClipboard(generatedText),
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            generatedText,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textPrimary,
            ),
          ),

          // Learning objectives if available
          if (content['learning_objectives'] != null) ...[
            const SizedBox(height: 20),
            _buildSection(
                'Learning Objectives', content['learning_objectives']),
          ],

          // Key vocabulary if available
          if (content['key_vocabulary'] != null) ...[
            const SizedBox(height: 20),
            _buildSection('Key Vocabulary', content['key_vocabulary']),
          ],

          // Activities if available
          if (content['activities'] != null) ...[
            const SizedBox(height: 20),
            _buildSection('Activities', content['activities']),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, dynamic content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryPink,
          ),
        ),
        const SizedBox(height: 8),
        if (content is List)
          ...content
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary)),
                        Expanded(
                          child: Text(
                            item.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList()
        else
          Text(
            content.toString(),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildMetadata() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Details',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow('Language', content['language'] ?? 'English'),
          _buildMetadataRow(
              'Grade Level', content['grade_level'] ?? 'Not specified'),
          _buildMetadataRow(
              'Content Type', content['content_type'] ?? 'General'),
          if (content['estimated_reading_time'] != null)
            _buildMetadataRow(
                'Reading Time', content['estimated_reading_time']),
          if (content['word_count'] != null)
            _buildMetadataRow('Word Count', content['word_count'].toString()),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Primary actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark, size: 18),
                  label: Text(
                    'Save',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share, size: 18),
                  label: Text(
                    'Share',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Secondary action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRegenerate,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Generate Again',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryPink,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryPink),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForContentType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'story':
        return Icons.menu_book;
      case 'explanation':
        return Icons.lightbulb_outline;
      case 'lesson':
        return Icons.school;
      case 'activity':
        return Icons.extension;
      default:
        return Icons.article;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // Note: In a real app, you'd show a snackbar here
  }
}
