import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

/// Content type selector widget
///
/// Allows users to choose between different types of educational content
/// like stories, explanations, lessons, and activities.
class ContentTypeSelector extends StatelessWidget {
  final List<Map<String, String>> contentTypes;
  final String selectedType;
  final Function(String) onTypeSelected;

  const ContentTypeSelector({
    super.key,
    required this.contentTypes,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: contentTypes.length,
      itemBuilder: (context, index) {
        final contentType = contentTypes[index];
        final isSelected = selectedType == contentType['id'];

        return GestureDetector(
          onTap: () => onTypeSelected(contentType['id']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryPink : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryPink : AppTheme.lightGray,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.15 : 0.05),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon based on content type
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : AppTheme.primaryPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForContentType(contentType['id']!),
                      size: 24,
                      color: isSelected ? Colors.white : AppTheme.primaryPink,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Text(
                    contentType['title']!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    contentType['subtitle']!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForContentType(String contentType) {
    switch (contentType) {
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
}
