import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../../../core/theme/app_theme.dart';

class QuizResultDisplay extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final VoidCallback onRegenerate;
  final VoidCallback onStartNew;

  const QuizResultDisplay({
    super.key,
    required this.quiz,
    required this.onRegenerate,
    required this.onStartNew,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
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
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          quiz['title'] ?? 'Generated Quiz',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Topic: ${quiz['topic'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Grade: ${quiz['grade_level'] ?? 'N/A'} | Language: ${quiz['language'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quiz Content
          _buildQuizContent(),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRegenerate,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryPurple,
                    side: BorderSide(color: AppTheme.primaryPurple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onStartNew,
                  icon: const Icon(Icons.add),
                  label: const Text('New Quiz'),
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
            ],
          ),

          const SizedBox(height: 16),

          // Copy Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyQuizToClipboard(context),
              icon: const Icon(Icons.copy),
              label: const Text('Copy to Clipboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryOrange,
                side: BorderSide(color: AppTheme.primaryOrange),
                padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildQuizContent() {
    print('🔍 Quiz keys: ${quiz.keys.toList()}');
    if (quiz['quiz_data'] != null && (quiz['quiz_data'] as Map).isNotEmpty) {
      print('🔍 Using quiz_data path');
      return _buildQuizQuestions(quiz['quiz_data']);
    } else if (quiz['data'] != null &&
        quiz['data']['data'] != null &&
        quiz['data']['data']['content'] != null) {
      print('🔍 Using data.data.content path');
      return _buildQuizQuestionsFromContent(quiz['data']['data']['content']);
    } else if (quiz['data'] != null && quiz['data']['content'] != null) {
      print('🔍 Using data.content path');
      return _buildQuizQuestionsFromContent(quiz['data']['content']);
    } else if (quiz['quiz_text'] != null) {
      print('🔍 Using quiz_text path');
      return _buildQuizText(quiz['quiz_text']);
    } else {
      print('❌ No quiz content found in any path');
      print('🔍 Full quiz object: $quiz');
      return _buildQuizText(
          'No quiz content available\n\nDebug: ${quiz.toString()}');
    }
  }

  Widget _buildQuizQuestionsFromContent(String content) {
    try {
      print('🔍 Parsing content length: ${content.length}');
      print(
          '🔍 Content preview: ${content.substring(0, content.length > 300 ? 300 : content.length)}...');

      // First, try to clean the content
      String cleanContent = content.trim();

      // Remove any leading/trailing whitespace and newlines
      cleanContent = cleanContent.replaceAll(RegExp(r'^\s+|\s+$'), '');

      // Try to extract JSON from markdown code blocks
      RegExpMatch? jsonMatch;
      final patterns = [
        r'```json\s*(\{[\s\S]*?\})\s*```',
        r'```\s*(\{[\s\S]*?\})\s*```',
        r'`(\{[\s\S]*?\})`',
      ];

      for (final pattern in patterns) {
        jsonMatch = RegExp(pattern, dotAll: true).firstMatch(cleanContent);
        if (jsonMatch != null) {
          print('🔍 Found JSON with pattern: $pattern');
          break;
        }
      }

      String jsonString;
      if (jsonMatch != null) {
        jsonString = jsonMatch.group(1)!;
        print('🔍 Extracted JSON length: ${jsonString.length}');
      } else {
        // If no markdown found, try to parse the entire content as JSON
        print('🔍 No markdown found, trying direct JSON parse...');
        jsonString = cleanContent;
      }

      // Clean the JSON string
      jsonString = jsonString.trim();
      
      // Additional cleaning for common JSON issues
      jsonString = jsonString.replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
      jsonString = jsonString.replaceAll(RegExp(r',\s*}'), '}'); // Remove trailing commas
      jsonString = jsonString.replaceAll(RegExp(r',\s*]'), ']'); // Remove trailing commas in arrays

      // Try to parse the JSON
      final quizData = Map<String, dynamic>.from(json.decode(jsonString));
      print('🔍 Successfully parsed JSON with keys: ${quizData.keys.toList()}');

      if (quizData.containsKey('questions')) {
        final questions = quizData['questions'] as List<dynamic>;
        print('🔍 Found ${questions.length} questions');
        return _buildQuizQuestions(quizData);
      } else {
        print('❌ No questions found in parsed data');
        return _buildQuizText('No questions found in the quiz data');
      }
    } catch (e) {
      print('❌ JSON parsing failed: $e');
      print('🔍 Full content that failed: $content');

      // Last resort: try to extract JSON manually
      try {
        final startIndex = content.indexOf('{');
        final endIndex = content.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          final jsonString = content.substring(startIndex, endIndex + 1);
          print(
              '🔍 Manual extraction attempt with length: ${jsonString.length}');
          final quizData = Map<String, dynamic>.from(json.decode(jsonString));
          print(
              '🔍 Manual parse successful with keys: ${quizData.keys.toList()}');
          return _buildQuizQuestions(quizData);
        }
      } catch (e2) {
        print('❌ Manual extraction also failed: $e2');
      }

      // If all parsing fails, show a formatted error with debug info
      return _buildQuizText(
          'Unable to parse quiz data. Please try regenerating the quiz.\n\nDebug info:\nContent length: ${content.length}\nContent preview: ${content.substring(0, content.length > 200 ? 200 : content.length)}...');
    }
  }

  Widget _buildQuizQuestions(Map<String, dynamic> quizData) {
    final questions = quizData['questions'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value as Map<String, dynamic>;
              return _buildQuestionCard(index + 1, question);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int questionNumber, Map<String, dynamic> question) {
    final questionText = question['question'] ?? 'No question text';
    final questionType = question['type'] ?? 'unknown';
    final options = question['options'] as List<dynamic>?;
    final correctAnswer = question['correct_answer'] ?? 'No answer provided';
    final explanation = question['explanation'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$questionNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  questionText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              questionType.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Options (for multiple choice)
          if (options != null && options.isNotEmpty) ...[
            ...options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${String.fromCharCode(65 + optionIndex)}. ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        option.toString(),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
          ],

          // Correct Answer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct Answer:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  correctAnswer,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Explanation
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explanation:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    explanation,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizText(String text) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyQuizToClipboard(BuildContext context) {
    String quizText = '';

    if (quiz['quiz_data'] != null) {
      final quizData = quiz['quiz_data'] as Map<String, dynamic>;
      final questions = quizData['questions'] as List<dynamic>? ?? [];

      quizText = '${quiz['title'] ?? 'Generated Quiz'}\n';
      quizText += 'Topic: ${quiz['topic'] ?? 'N/A'}\n';
      quizText += 'Grade: ${quiz['grade_level'] ?? 'N/A'}\n';
      quizText += 'Language: ${quiz['language'] ?? 'N/A'}\n\n';

      for (int i = 0; i < questions.length; i++) {
        final question = questions[i] as Map<String, dynamic>;
        quizText += '${i + 1}. ${question['question'] ?? 'No question'}\n';

        final options = question['options'] as List<dynamic>?;
        if (options != null) {
          for (int j = 0; j < options.length; j++) {
            quizText += '   ${String.fromCharCode(65 + j)}. ${options[j]}\n';
          }
        }

        quizText += '   Answer: ${question['correct_answer'] ?? 'No answer'}\n';
        if (question['explanation'] != null) {
          quizText += '   Explanation: ${question['explanation']}\n';
        }
        quizText += '\n';
      }
    } else if (quiz['quiz_text'] != null) {
      quizText = quiz['quiz_text'];
    }

    Clipboard.setData(ClipboardData(text: quizText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quiz copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
