import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../widgets/assessment_result_display.dart';
import '../widgets/audio_recorder.dart';
import '../../shared/widgets/loading_overlay.dart';

class ReadingAssessmentScreen extends ConsumerStatefulWidget {
  const ReadingAssessmentScreen({super.key});

  @override
  ConsumerState<ReadingAssessmentScreen> createState() =>
      _ReadingAssessmentScreenState();
}

class _ReadingAssessmentScreenState
    extends ConsumerState<ReadingAssessmentScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _assessmentResult;
  String? _recordedAudioPath;
  String _selectedLanguage = 'en';
  String _selectedGradeLevel = 'grade_3_4';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'हिंदी'},
    {'code': 'mr', 'name': 'मराठी'},
    {'code': 'ta', 'name': 'தமிழ்'},
    {'code': 'bn', 'name': 'বাংলা'},
    {'code': 'gu', 'name': 'ગુજરાતી'},
  ];

  final List<Map<String, String>> _gradeLevels = [
    {'code': 'grade_1_2', 'name': 'Grade 1-2'},
    {'code': 'grade_3_4', 'name': 'Grade 3-4'},
    {'code': 'grade_5_6', 'name': 'Grade 5-6'},
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Reading Assessment',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (_assessmentResult != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetAssessment,
              tooltip: 'New Assessment',
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _assessmentResult != null
                ? _buildAssessmentResult()
                : _buildAssessmentSetup(),
          ),
          if (_isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildAssessmentSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions Card
          const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mic,
                        color: AppTheme.primaryOrange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reading Fluency Assessment',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Help students improve their reading skills:\n'
                    '• Record student reading aloud\n'
                    '• Get instant fluency feedback\n'
                    '• Receive improvement suggestions\n'
                    '• Track reading progress over time',
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

          // Text Input Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Text to Read (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Provide text for more accurate assessment',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Paste the text that the student will read, or leave empty for free reading assessment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.lightGray),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.lightGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryOrange),
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Configuration Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assessment Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Language',
                          value: _selectedLanguage,
                          items: _languages
                              .map((lang) => DropdownMenuItem(
                                    value: lang['code'],
                                    child: Text(lang['name']!),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedLanguage = value!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Grade Level',
                          value: _selectedGradeLevel,
                          items: _gradeLevels
                              .map((grade) => DropdownMenuItem(
                                    value: grade['code'],
                                    child: Text(grade['name']!),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedGradeLevel = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Audio Recording Section
          AudioRecorder(
            onRecordingComplete: (audioPath) {
              setState(() {
                _recordedAudioPath = audioPath;
              });
            },
            onRecordingDeleted: () {
              setState(() {
                _recordedAudioPath = null;
              });
            },
          ),

          const SizedBox(height: 32),

          // Assess Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _recordedAudioPath != null ? _performAssessment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: AppTheme.lightGray,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Assess Reading',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick Tips
          _buildQuickTips(),
        ],
      ),
    );
  }

  Widget _buildQuickTips() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.accentOrange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Assessment Tips',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...[
              'Record in a quiet environment',
              'Hold device close to student (arm\'s length)',
              'Encourage natural reading pace',
              'Let student finish completely before stopping',
              'Use familiar text for best results',
            ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
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
          style: const TextStyle(
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
              borderSide: const BorderSide(color: AppTheme.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryOrange),
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

  Widget _buildAssessmentResult() {
    return AssessmentResultDisplay(
      assessment: _assessmentResult!,
      onReassess: _performAssessment,
      onStartNew: _resetAssessment,
    );
  }

  Future<void> _performAssessment() async {
    if (_recordedAudioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record audio first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert audio to base64
      final audioFile = File(_recordedAudioPath!);
      final audioBytes = await audioFile.readAsBytes();
      final base64Audio = base64Encode(audioBytes);

      // Call API
      final result = await ApiService.assessReading(
        audio: 'data:audio/wav;base64,$base64Audio',
        expectedText: _textController.text.trim().isNotEmpty
            ? _textController.text.trim()
            : null,
        gradeLevel: _selectedGradeLevel,
        language: _selectedLanguage,
      );

      if (result['success'] == true) {
        setState(() {
          _assessmentResult = result;
        });
      } else {
        throw Exception(result['error'] ?? 'Failed to assess reading');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assessment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetAssessment() {
    setState(() {
      _assessmentResult = null;
      _recordedAudioPath = null;
      _textController.clear();
      _selectedLanguage = 'en';
      _selectedGradeLevel = 'grade_3_4';
    });
  }
}
