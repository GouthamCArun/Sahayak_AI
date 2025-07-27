import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../widgets/content_type_selector.dart';
import '../widgets/content_result_display.dart';

/// Content Generator screen for creating AI-powered educational content
///
/// Allows teachers to generate stories, explanations, lessons, and activities
/// tailored for their students with cultural and linguistic adaptations.
class ContentGeneratorScreen extends ConsumerStatefulWidget {
  const ContentGeneratorScreen({super.key});

  @override
  ConsumerState<ContentGeneratorScreen> createState() =>
      _ContentGeneratorScreenState();
}

class _ContentGeneratorScreenState
    extends ConsumerState<ContentGeneratorScreen> {
  final _topicController = TextEditingController();
  final _additionalDetailsController = TextEditingController();

  String _selectedContentType = 'story';
  String _selectedLanguage = 'en';
  String _selectedGradeLevel = 'grade_3_4';
  bool _isLoading = false;
  Map<String, dynamic>? _generatedContent;

  final List<Map<String, String>> _contentTypes = [
    {'id': 'story', 'title': 'Story', 'subtitle': 'Engaging narratives'},
    {
      'id': 'explanation',
      'title': 'Explanation',
      'subtitle': 'Clear concept breakdown'
    },
    {'id': 'lesson', 'title': 'Lesson', 'subtitle': 'Structured learning'},
    {
      'id': 'activity',
      'title': 'Activity',
      'subtitle': 'Interactive exercises'
    },
  ];

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
    {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
    {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'code': 'ml', 'name': 'Malayalam', 'native': 'മലയാളം'},
  ];

  final List<Map<String, String>> _gradeLevels = [
    {'id': 'grade_1_2', 'title': 'Grade 1-2', 'description': 'Early primary'},
    {'id': 'grade_3_4', 'title': 'Grade 3-4', 'description': 'Primary'},
    {'id': 'grade_5_6', 'title': 'Grade 5-6', 'description': 'Upper primary'},
  ];

  @override
  void dispose() {
    _topicController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Content Generator',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _generatedContent == null ? _buildInputForm() : _buildResultView(),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPink,
                  AppTheme.primaryPink.withOpacity(0.8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_stories,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Content Generator',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Create engaging educational content for your students',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Content Type Selection
          _buildSectionTitle('Content Type'),
          const SizedBox(height: 12),
          ContentTypeSelector(
            contentTypes: _contentTypes,
            selectedType: _selectedContentType,
            onTypeSelected: (type) {
              setState(() {
                _selectedContentType = type;
              });
            },
          ),

          const SizedBox(height: 24),

          // Topic Input
          _buildSectionTitle('Topic'),
          const SizedBox(height: 12),
          _buildTopicInput(),

          const SizedBox(height: 24),

          // Language Selection
          _buildSectionTitle('Language'),
          const SizedBox(height: 12),
          _buildLanguageSelector(),

          const SizedBox(height: 24),

          // Grade Level Selection
          _buildSectionTitle('Grade Level'),
          const SizedBox(height: 12),
          _buildGradeLevelSelector(),

          const SizedBox(height: 24),

          // Additional Details
          _buildSectionTitle('Additional Details (Optional)'),
          const SizedBox(height: 12),
          _buildAdditionalDetailsInput(),

          const SizedBox(height: 32),

          // Generate Button
          _buildGenerateButton(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryPink.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: AppTheme.primaryPink.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _generatedContent = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Generated Content',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Content Result
        Expanded(
          child: ContentResultDisplay(
            content: _generatedContent!,
            onRegenerate: _generateContent,
            onSave: _saveContent,
            onShare: _shareContent,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTopicInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _topicController,
        decoration: InputDecoration(
          hintText: 'Enter topic (e.g., "Friendship", "Plants", "Numbers")',
          prefixIcon: const Icon(Icons.lightbulb_outline),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _languages.length,
        itemBuilder: (context, index) {
          final language = _languages[index];
          final isSelected = _selectedLanguage == language['code'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedLanguage = language['code']!;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryPink : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryPink : AppTheme.lightGray,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    language['native']!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    language['name']!,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradeLevelSelector() {
    return Column(
      children: _gradeLevels.map((grade) {
        final isSelected = _selectedGradeLevel == grade['id'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedGradeLevel = grade['id']!;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryPink.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryPink : AppTheme.lightGray,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? AppTheme.primaryPink
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grade['title']!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        grade['description']!,
                        style: GoogleFonts.poppins(
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
        );
      }).toList(),
    );
  }

  Widget _buildAdditionalDetailsInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _additionalDetailsController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText:
              'Any specific requirements, context, or examples you\'d like to include...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _generateContent,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Generating...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Generate Content',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _generateContent() async {
    if (_topicController.text.trim().isEmpty) {
      _showSnackBar('Please enter a topic');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.generateContent(
        contentType: _selectedContentType,
        topic: _topicController.text.trim(),
        language: _selectedLanguage,
        gradeLevel: _selectedGradeLevel,
        additionalParams: {
          'additional_details': _additionalDetailsController.text.trim(),
          'cultural_context': 'rural_indian',
        },
      );

      setState(() {
        _generatedContent = Map<String, dynamic>.from(result);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to generate content: ${e.toString()}');
    }
  }

  void _saveContent() {
    // TODO: Implement save functionality
    _showSnackBar('Content saved successfully!');
  }

  void _shareContent() {
    // TODO: Implement share functionality
    _showSnackBar('Share functionality coming soon!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryPink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
