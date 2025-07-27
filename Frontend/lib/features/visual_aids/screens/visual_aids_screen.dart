import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../widgets/diagram_type_selector.dart';
import '../widgets/diagram_result_display.dart';
import '../../shared/widgets/loading_overlay.dart';

class VisualAidsScreen extends ConsumerStatefulWidget {
  const VisualAidsScreen({super.key});

  @override
  ConsumerState<VisualAidsScreen> createState() => _VisualAidsScreenState();
}

class _VisualAidsScreenState extends ConsumerState<VisualAidsScreen> {
  final TextEditingController _conceptController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _generatedDiagram;
  String _selectedDiagramType = 'simple';
  String _selectedLanguage = 'en';
  String _selectedGradeLevel = 'grade_3_4';

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

  final List<Map<String, String>> _gradeLevels = [
    {'code': 'grade_1_2', 'name': 'Grade 1-2'},
    {'code': 'grade_3_4', 'name': 'Grade 3-4'},
    {'code': 'grade_5_6', 'name': 'Grade 5-6'},
  ];

  @override
  void dispose() {
    _conceptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Visual Aids Designer',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (_generatedDiagram != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetDiagram,
              tooltip: 'Create New Diagram',
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _generatedDiagram != null
                ? _buildDiagramResult()
                : _buildDiagramInput(),
          ),
          if (_isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildDiagramInput() {
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
                        Icons.auto_awesome,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI-Powered Diagram Generator',
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
                    'Describe any concept and AI will create educational diagrams:\n'
                    '• Concept maps and flowcharts\n'
                    '• Timeline and process diagrams\n'
                    '• Charts and graphs\n'
                    '• Labeled illustrations',
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

          // Concept Input
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Describe your concept',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _conceptController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Example: "Water cycle with evaporation, condensation, and precipitation" or "Parts of a plant with roots, stem, and leaves"',
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

          // Diagram Type Selector
          DiagramTypeSelector(
            selectedType: _selectedDiagramType,
            onTypeChanged: (type) =>
                setState(() => _selectedDiagramType = type),
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
                    'Diagram Settings',
                    style: TextStyle(
                      fontSize: 16,
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
                    onChanged: (value) =>
                        setState(() => _selectedLanguage = value!),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
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

          const SizedBox(height: 32),

          // Generate Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _conceptController.text.trim().isNotEmpty
                  ? _generateDiagram
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
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
                  const Icon(Icons.create, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Generate Diagram',
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

          // Quick Examples
          _buildQuickExamples(),
        ],
      ),
    );
  }

  Widget _buildQuickExamples() {
    final examples = [
      'Water cycle process',
      'Solar system planets',
      'Human digestive system',
      'Food chain in forest',
      'Photosynthesis process',
      'Parts of a flower',
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Examples',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: examples
                  .map((example) => ActionChip(
                        label: Text(
                          example,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          _conceptController.text = example;
                          setState(() {});
                        },
                        backgroundColor:
                            AppTheme.primaryPurple.withOpacity(0.1),
                        side: BorderSide(
                            color: AppTheme.primaryPurple.withOpacity(0.3)),
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
          isExpanded: true, // Added to prevent overflow
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
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10), // Reduced padding
          ),
        ),
      ],
    );
  }

  Widget _buildDiagramResult() {
    return DiagramResultDisplay(
      diagram: _generatedDiagram!,
      onRegenerate: _generateDiagram,
      onStartNew: _resetDiagram,
    );
  }

  Future<void> _generateDiagram() async {
    if (_conceptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe a concept first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.generateVisualAid(
        concept: _conceptController.text.trim(),
        diagramType: _selectedDiagramType,
        language: _selectedLanguage,
        gradeLevel: _selectedGradeLevel,
      );

      // Check if result contains diagram_description (new format)
      if (result['diagram_description'] != null &&
          result['diagram_description'].toString().isNotEmpty) {
        setState(() {
          _generatedDiagram = Map<String, dynamic>.from(result);
        });
      } else if (result['error'] != null) {
        throw Exception(result['error']);
      } else {
        throw Exception('No diagram content received');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate diagram: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetDiagram() {
    setState(() {
      _generatedDiagram = null;
      _conceptController.clear();
      _selectedDiagramType = 'simple';
      _selectedLanguage = 'en';
      _selectedGradeLevel = 'grade_3_4';
    });
  }
}
