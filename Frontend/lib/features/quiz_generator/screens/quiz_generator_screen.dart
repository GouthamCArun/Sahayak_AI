import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../widgets/quiz_result_display.dart';
import '../../shared/widgets/loading_overlay.dart';

class QuizGeneratorScreen extends ConsumerStatefulWidget {
  const QuizGeneratorScreen({super.key});

  @override
  ConsumerState<QuizGeneratorScreen> createState() =>
      _QuizGeneratorScreenState();
}

class _QuizGeneratorScreenState extends ConsumerState<QuizGeneratorScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _generatedQuiz;
  String _selectedLanguage = 'en';
  String _selectedGrade = 'grade_3_4';
  String _topic = '';
  int _numQuestions = 10;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'हिंदी'},
    {'code': 'mr', 'name': 'मराठी'},
    {'code': 'ta', 'name': 'தமிழ்'},
    {'code': 'bn', 'name': 'বাংলা'},
    {'code': 'gu', 'name': 'ગુજરાતી'},
    {'code': 'kn', 'name': 'ಕನ್ನಡ'},
    {'code': 'ml', 'name': 'മലയാളം'},
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
          'Quiz Generator',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _testQuizGeneration,
            tooltip: 'Test Quiz Generation',
          ),
          if (_generatedQuiz != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetQuiz,
              tooltip: 'Generate New Quiz',
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child:
                _generatedQuiz != null ? _buildQuizResult() : _buildQuizForm(),
          ),
          if (_isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildQuizForm() {
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
                        Icons.quiz,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Generate Educational Quiz',
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
                    '1. Enter a topic for your quiz\n'
                    '2. Select grade level and language\n'
                    '3. AI will create 10 educational questions\n'
                    '4. Get ready-to-use quiz with answers',
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

          // Topic Input
          _buildTopicInputSection(),

          const SizedBox(height: 24),

          // Configuration Section
          _buildConfigurationSection(),

          const SizedBox(height: 32),

          // Generate Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _generateQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Generate Quiz',
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
      ),
    );
  }

  Widget _buildTopicInputSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Topic',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _topic,
              onChanged: (value) => setState(() => _topic = value),
              decoration: InputDecoration(
                hintText:
                    'Enter topic (e.g., Water Cycle, Addition, Photosynthesis)',
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
                  borderSide: BorderSide(color: AppTheme.primaryPurple),
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
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
              'Quiz Configuration',
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

            // Grade Selection
            _buildDropdownField(
              label: 'Grade Level',
              value: _selectedGrade,
              items: _gradeOptions
                  .map((grade) => DropdownMenuItem(
                        value: grade['code'],
                        child: Text(grade['name']!),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedGrade = value!),
            ),

            const SizedBox(height: 16),

            // Number of Questions
            _buildDropdownField(
              label: 'Number of Questions',
              value: _numQuestions.toString(),
              items: [5, 10, 15, 20]
                  .map((num) => DropdownMenuItem(
                        value: num.toString(),
                        child: Text('$num questions'),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _numQuestions = int.parse(value!)),
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
          isExpanded: true,
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
              borderSide: BorderSide(color: AppTheme.primaryPurple),
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizResult() {
    return QuizResultDisplay(
      quiz: _generatedQuiz!,
      onRegenerate: () => _generateQuiz(),
      onStartNew: _resetQuiz,
    );
  }

  Future<void> _generateQuiz() async {
    if (_topic.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a topic'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.generateQuiz(
        topic: _topic,
        language: _selectedLanguage,
        gradeLevel: _selectedGrade,
        numQuestions: _numQuestions,
      );

            setState(() {
        _generatedQuiz = Map<String, dynamic>.from(result);
      });
      
      // Debug: Print the response structure
      print('🔍 Quiz Response Structure:');
      print('Keys: ${result.keys.toList()}');
      if (result['data'] != null) {
        print('Data keys: ${(result['data'] as Map).keys.toList()}');
        if ((result['data'] as Map)['content'] != null) {
          print('Content preview: ${(result['data'] as Map)['content'].toString().substring(0, 200)}...');
        }
      }
      if (result['quiz_data'] != null) {
        print('Quiz data keys: ${(result['quiz_data'] as Map).keys.toList()}');
        print(
            'Quiz data questions: ${(result['quiz_data'] as Map)['questions']?.length ?? 0}');
      }
      print('Full result: $result');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate quiz: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _testQuizGeneration() {
    setState(() {
      _topic = 'Photosynthesis';
      _selectedLanguage = 'en';
      _selectedGrade = 'grade_3_4';
      _numQuestions = 5;
    });
    _generateQuiz();
  }

  void _resetQuiz() {
    setState(() {
      _generatedQuiz = null;
      _topic = '';
      _selectedLanguage = 'en';
      _selectedGrade = 'grade_3_4';
      _numQuestions = 10;
    });
  }
}
