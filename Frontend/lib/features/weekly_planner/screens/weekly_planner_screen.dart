import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../widgets/lesson_plan_card.dart';
import '../widgets/subject_selector.dart';
import '../widgets/week_selector.dart';
import '../../shared/widgets/loading_overlay.dart';

class WeeklyPlannerScreen extends ConsumerStatefulWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  ConsumerState<WeeklyPlannerScreen> createState() =>
      _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends ConsumerState<WeeklyPlannerScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _generatedPlan;
  String _selectedSubject = 'mathematics';
  List<String> _selectedGrades = ['grade_3_4'];
  String _selectedLanguage = 'en';
  String _resourceLevel = 'basic';
  String? _specificTopic;
  DateTime _selectedWeek = DateTime.now();

  final TextEditingController _topicController = TextEditingController();

  final List<Map<String, String>> _subjects = [
    {'code': 'mathematics', 'name': 'Mathematics', 'icon': '🔢'},
    {'code': 'science', 'name': 'Science', 'icon': '🔬'},
    {'code': 'language', 'name': 'Language Arts', 'icon': '📚'},
    {'code': 'social_studies', 'name': 'Social Studies', 'icon': '🌍'},
    {'code': 'general', 'name': 'General Studies', 'icon': '📖'},
  ];

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'हिंदी'},
    {'code': 'mr', 'name': 'मराठी'},
    {'code': 'ta', 'name': 'தமிழ்'},
    {'code': 'bn', 'name': 'বাংলা'},
    {'code': 'gu', 'name': 'ગુજરાતી'},
  ];

  final List<Map<String, String>> _gradeOptions = [
    {'code': 'grade_1_2', 'name': 'Grade 1-2'},
    {'code': 'grade_3_4', 'name': 'Grade 3-4'},
    {'code': 'grade_5_6', 'name': 'Grade 5-6'},
  ];

  final List<Map<String, String>> _resourceLevels = [
    {'code': 'basic', 'name': 'Basic (Limited Resources)'},
    {'code': 'enhanced', 'name': 'Enhanced (Some Resources)'},
    {'code': 'digital', 'name': 'Digital (Tech Available)'},
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Weekly Planner',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (_generatedPlan != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetPlanner,
              tooltip: 'Create New Plan',
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child:
                _generatedPlan != null ? _buildPlanResult() : _buildPlanSetup(),
          ),
          if (_isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPlanSetup() {
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
                        Icons.calendar_today,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI-Powered Weekly Lesson Planner',
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
                    'Create comprehensive weekly lesson plans:\n'
                    '• Structured daily lessons with activities\n'
                    '• Assessment strategies and rubrics\n'
                    '• Resource optimization for rural schools\n'
                    '• Multi-grade differentiation support',
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

          // Week Selector
          WeekSelector(
            selectedWeek: _selectedWeek,
            onWeekChanged: (week) => setState(() => _selectedWeek = week),
          ),

          const SizedBox(height: 20),

          // Subject Selector
          SubjectSelector(
            subjects: _subjects,
            selectedSubject: _selectedSubject,
            onSubjectChanged: (subject) =>
                setState(() => _selectedSubject = subject),
          ),

          const SizedBox(height: 20),

          // Topic Input (Optional)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specific Topic (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Focus the lesson plan on a specific topic or concept',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _topicController,
                    decoration: InputDecoration(
                      hintText:
                          'e.g., "Fractions", "Water cycle", "Indian freedom struggle"...',
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
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: TextStyle(
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
                  Text(
                    'Lesson Plan Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grade Selection
                  Text(
                    'Grade Levels',
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
                              selectedColor:
                                  AppTheme.primaryGreen.withOpacity(0.2),
                              checkmarkColor: AppTheme.primaryGreen,
                            ))
                        .toList(),
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
                          label: 'Resources',
                          value: _resourceLevel,
                          items: _resourceLevels
                              .map((level) => DropdownMenuItem(
                                    value: level['code'],
                                    child: Text(level['name']!),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _resourceLevel = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Generate Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _selectedGrades.isNotEmpty ? _generateLessonPlan : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: AppTheme.lightGray,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Generate Weekly Plan',
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

          // Quick Templates
          _buildQuickTemplates(),
        ],
      ),
    );
  }

  Widget _buildQuickTemplates() {
    final templates = [
      {'subject': 'mathematics', 'topic': 'Basic Addition & Subtraction'},
      {'subject': 'science', 'topic': 'Plants and Animals'},
      {'subject': 'language', 'topic': 'Story Writing & Reading'},
      {'subject': 'social_studies', 'topic': 'Our Community'},
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Templates',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...templates.map((template) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSubject = template['subject']!;
                        _topicController.text = template['topic']!;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightGray),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _subjects.firstWhere((s) =>
                                s['code'] == template['subject'])['icon']!,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _subjects.firstWhere((s) =>
                                      s['code'] ==
                                      template['subject'])['name']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  template['topic']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
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
              borderSide: BorderSide(color: AppTheme.primaryGreen),
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

  Widget _buildPlanResult() {
    final planData = _generatedPlan!['lesson_plan'] ?? {};

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
                          'Weekly Lesson Plan Created!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${_getSubjectDisplayName(_selectedSubject)} • Week of ${_formatWeek(_selectedWeek)}',
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

          // Daily Lessons
          if (planData['detailed_lessons'] != null) ...[
            ...((planData['detailed_lessons'] as List)
                .asMap()
                .entries
                .map((entry) => LessonPlanCard(
                      day: entry.key + 1,
                      lesson: entry.value,
                      subject: _selectedSubject,
                    ))),
          ],

          const SizedBox(height: 20),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _generateLessonPlan,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Regenerate Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
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
                onPressed: _resetPlanner,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('New Plan'),
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
                onPressed: () => _exportPlan(),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _sharePlan(),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _printPlan(),
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

  Future<void> _generateLessonPlan() async {
    if (_selectedGrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one grade level'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.generateLessonPlan(
        subject: _selectedSubject,
        gradeLevels: _selectedGrades,
        topic: _topicController.text.trim().isNotEmpty
            ? _topicController.text.trim()
            : null,
        language: _selectedLanguage,
        resourceLevel: _resourceLevel,
      );

      if (result['success'] == true) {
        setState(() {
          _generatedPlan = result;
        });
      } else {
        throw Exception(result['error'] ?? 'Failed to generate lesson plan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate lesson plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetPlanner() {
    setState(() {
      _generatedPlan = null;
      _topicController.clear();
      _selectedSubject = 'mathematics';
      _selectedGrades = ['grade_3_4'];
      _selectedLanguage = 'en';
      _resourceLevel = 'basic';
      _selectedWeek = DateTime.now();
    });
  }

  String _getSubjectDisplayName(String subject) {
    return _subjects.firstWhere((s) => s['code'] == subject,
        orElse: () => {'name': 'General'})['name']!;
  }

  String _formatWeek(DateTime week) {
    final startOfWeek = week.subtract(Duration(days: week.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}';
  }

  void _exportPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon!')),
    );
  }

  void _sharePlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _printPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon!')),
    );
  }
}
