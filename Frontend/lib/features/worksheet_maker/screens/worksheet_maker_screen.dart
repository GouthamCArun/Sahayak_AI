import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:convert';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../widgets/image_preview.dart';
import '../widgets/worksheet_result_display.dart';
import '../../shared/widgets/loading_overlay.dart';

class WorksheetMakerScreen extends ConsumerStatefulWidget {
  const WorksheetMakerScreen({super.key});

  @override
  ConsumerState<WorksheetMakerScreen> createState() =>
      _WorksheetMakerScreenState();
}

class _WorksheetMakerScreenState extends ConsumerState<WorksheetMakerScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _generatedWorksheet;
  String _selectedLanguage = 'en';
  String _selectedSubject = 'general';
  List<String> _selectedGrades = ['Grade 3-4'];

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'हिंदी'},
    {'code': 'mr', 'name': 'मराठी'},
    {'code': 'ta', 'name': 'தமিழ்'},
    {'code': 'bn', 'name': 'বাংলা'},
    {'code': 'gu', 'name': 'ગુજરાતી'},
  ];

  final List<String> _subjects = [
    'general',
    'mathematics',
    'science',
    'language',
    'social_studies'
  ];

  final List<Map<String, String>> _gradeOptions = [
    {'code': 'grade_1_2', 'name': 'Grade 1-2'},
    {'code': 'grade_3_4', 'name': 'Grade 3-4'},
    {'code': 'grade_5_6', 'name': 'Grade 5-6'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Worksheet Maker',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (_generatedWorksheet != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetWorksheet,
              tooltip: 'Start New Worksheet',
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _generatedWorksheet != null
                ? _buildWorksheetResult()
                : _buildImageCapture(),
          ),
          if (_isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildImageCapture() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How it works',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Take a photo of textbook page or upload from gallery\n'
                    '2. Select target grade levels and subject\n'
                    '3. AI will extract content and create worksheets\n'
                    '4. Get downloadable worksheets for your students',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Image Selection Section
          if (_selectedImage != null) ...[
            ImagePreview(
              image: _selectedImage!,
              onRemove: () => setState(() => _selectedImage = null),
              onReplace: () => _showImageSourceDialog(),
            ),
            const SizedBox(height: 24),
          ] else ...[
            // Image Picker Buttons
            _buildImagePickerSection(),
            const SizedBox(height: 24),
          ],

          // Configuration Section
          if (_selectedImage != null) ...[
            _buildConfigurationSection(),
            const SizedBox(height: 32),

            // Generate Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _generateWorksheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Generate Worksheet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      children: [
        // Camera Button
        Card(
          elevation: 2,
          child: InkWell(
            onTap: () => _pickImage(ImageSource.camera),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.1),
                    AppTheme.primaryBlue.withOpacity(0.1)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 48,
                    color: AppTheme.primaryPurple,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Capture textbook page',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Gallery Button
        Card(
          elevation: 2,
          child: InkWell(
            onTap: () => _pickImage(ImageSource.gallery),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryOrange.withOpacity(0.1),
                    AppTheme.primaryGreen.withOpacity(0.1)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library,
                    size: 48,
                    color: AppTheme.primaryOrange,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Choose existing image',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worksheet Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Language Selection
            _buildDropdownField(
              label: 'Language',
              value: _selectedLanguage,
              items: _languages
                  .map((lang) => DropdownMenuItem(
                        value: lang['code'],
                        child: Text(lang['name']!),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedLanguage = value!),
            ),

            const SizedBox(height: 16),

            // Subject Selection
            _buildDropdownField(
              label: 'Subject',
              value: _selectedSubject,
              items: _subjects
                  .map((subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(_getSubjectDisplayName(subject)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedSubject = value!),
            ),

            const SizedBox(height: 16),

            // Grade Selection
            Text(
              'Target Grades',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _gradeOptions
                  .map((grade) => FilterChip(
                        label: Text(grade['name']!),
                        selected: _selectedGrades.contains(grade['code']),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedGrades.add(grade['code']!);
                            } else {
                              _selectedGrades.remove(grade['code']);
                            }
                          });
                        },
                        selectedColor: AppTheme.primaryPink.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryPink,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryPink),
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildWorksheetResult() {
    return WorksheetResultDisplay(
      worksheet: _generatedWorksheet!,
      onRegenerate: () => _generateWorksheet(),
      onStartNew: _resetWorksheet,
    );
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateWorksheet() async {
    if (_selectedImage == null || _selectedGrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image and at least one grade level'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert image to base64
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call API
      final result = await ApiService.generateWorksheet(
        image: 'data:image/jpeg;base64,$base64Image',
        targetGrades: _selectedGrades,
        language: _selectedLanguage,
        subject: _selectedSubject,
      );

      if (result['success'] == true) {
        setState(() {
          _generatedWorksheet = result;
        });
      } else {
        throw Exception(result['error'] ?? 'Failed to generate worksheet');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate worksheet: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetWorksheet() {
    setState(() {
      _selectedImage = null;
      _generatedWorksheet = null;
      _selectedLanguage = 'en';
      _selectedSubject = 'general';
      _selectedGrades = ['grade_3_4'];
    });
  }
}
