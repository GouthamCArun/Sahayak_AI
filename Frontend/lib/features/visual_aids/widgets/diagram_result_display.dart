import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/markdown_renderer.dart';

class DiagramResultDisplay extends StatefulWidget {
  final Map<String, dynamic> diagram;
  final VoidCallback onRegenerate;
  final VoidCallback onStartNew;

  const DiagramResultDisplay({
    super.key,
    required this.diagram,
    required this.onRegenerate,
    required this.onStartNew,
  });

  @override
  State<DiagramResultDisplay> createState() => _DiagramResultDisplayState();
}

class _DiagramResultDisplayState extends State<DiagramResultDisplay> {
  bool _showVisualDiagram = true;

  @override
  Widget build(BuildContext context) {
    // Handle both old format (diagram_data) and new format (direct fields)
    final diagramData = Map<String, dynamic>.from(
        widget.diagram['diagram_data'] ?? widget.diagram);
    final metadata =
        Map<String, dynamic>.from(widget.diagram['metadata'] ?? {});

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
                    AppTheme.primaryPurple.withOpacity(0.1),
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
                          'Diagram Generated Successfully!',
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

          // Diagram Display
          _buildDiagramDisplay(diagramData),

          const SizedBox(height: 20),

          // Diagram Description
          if (diagramData['diagram_description'] != null ||
              diagramData['description'] != null) ...[
            _buildDescriptionCard(diagramData['diagram_description'] ??
                diagramData['description']),
            const SizedBox(height: 20),
          ],

          // ASCII Art Display
          if (diagramData['ascii_art'] != null) ...[
            _buildAsciiArtCard(diagramData['ascii_art']),
            const SizedBox(height: 20),
          ],

          // Drawing Instructions
          if (diagramData['drawing_instructions'] != null ||
              diagramData['teaching_instructions'] != null) ...[
            _buildDrawingInstructionsCard(diagramData['drawing_instructions'] ??
                diagramData['teaching_instructions']),
            const SizedBox(height: 20),
          ],

          // Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildDiagramDisplay(Map<String, dynamic> diagramData) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.image,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    diagramData['title'] ?? 'Generated Diagram',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (diagramData['diagram_type'] != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getDiagramTypeDisplayName(diagramData['diagram_type']),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Diagram Content (Image, Mermaid, or Placeholder)
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.lightGray),
              color: AppTheme.surfaceColor,
            ),
            child: _buildDiagramContent(diagramData),
          ),

          // Download Instructions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Diagram is ready for classroom use. You can download, print, or project it.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramContent(Map<String, dynamic> diagramData) {
    // Debug logging
    print('🔍 Diagram Data Keys: ${diagramData.keys.toList()}');
    print('🔍 Has mermaid_code: ${diagramData['mermaid_code'] != null}');
    print('🔍 mermaid_code value: ${diagramData['mermaid_code']}');
    print('🔍 Has image_base64: ${diagramData['image_base64'] != null}');
    print(
        '🔍 image_base64 length: ${diagramData['image_base64']?.toString().length ?? 0}');

    // Check for Mermaid diagram first (new format)
    if (diagramData['mermaid_code'] != null &&
        diagramData['mermaid_code'].toString().isNotEmpty) {
      print('🎨 Using Mermaid diagram');
      return _buildMermaidDiagram(diagramData['mermaid_code']);
    }

    // Check for image URL
    if (diagramData['image_url'] != null) {
      print('🖼️ Using image URL');
      return Container(
        height: 300,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: diagramData['image_url'],
            fit: BoxFit.contain,
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryPurple,
              ),
            ),
            errorWidget: (context, url, error) => _buildDiagramPlaceholder(),
          ),
        ),
      );
    }

    // Check for base64 image (only if it's not empty)
    if (diagramData['image_base64'] != null &&
        diagramData['image_base64'].toString().isNotEmpty &&
        diagramData['image_base64'].toString().length > 100) {
      print('🖼️ Using base64 image');
      try {
        return Container(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(diagramData['image_base64']),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                print('Image decoding error: $error');
                return _buildDiagramPlaceholder();
              },
            ),
          ),
        );
      } catch (e) {
        print('Base64 decode error: $e');
        return _buildDiagramPlaceholder();
      }
    }

    // Fallback to placeholder
    print('📝 Using placeholder diagram');
    return _buildDiagramPlaceholder();
  }

  Widget _buildMermaidDiagram(String mermaidCode) {
    return Builder(
        builder: (context) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_tree,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showVisualDiagram ? 'Visual Diagram' : 'Diagram Code',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // Toggle Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showVisualDiagram = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _showVisualDiagram
                                      ? AppTheme.primaryPurple
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Visual',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _showVisualDiagram
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showVisualDiagram = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: !_showVisualDiagram
                                      ? AppTheme.primaryPurple
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Code',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: !_showVisualDiagram
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: mermaidCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Diagram code copied!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        tooltip: 'Copy diagram code',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Diagram Display (Visual or Code)
                  Container(
                    width: double.infinity,
                    height: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.lightGray),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _showVisualDiagram
                        ? _buildVisualDiagram(mermaidCode)
                        : _buildCodeView(mermaidCode),
                  ),

                  const SizedBox(height: 12),

                  // Drawing Instructions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.lightGray),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Drawing Instructions:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDrawingInstructions(mermaidCode),
                      ],
                    ),
                  ),
                ],
              ),
            ));
  }

  Widget _buildCodeView(String mermaidCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mermaid Diagram Code:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.lightGray),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                mermaidCode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualDiagram(String mermaidCode) {
    // Parse the Mermaid code to create a visual representation
    if (mermaidCode.contains('graph TD') ||
        mermaidCode.contains('flowchart TD')) {
      return _buildFlowchartDiagram(mermaidCode);
    } else if (mermaidCode.contains('mindmap')) {
      return _buildMindmapDiagram(mermaidCode);
    } else if (mermaidCode.contains('gantt')) {
      return _buildGanttDiagram(mermaidCode);
    } else {
      return _buildSimpleDiagram(mermaidCode);
    }
  }

  Widget _buildFlowchartDiagram(String mermaidCode) {
    // Extract nodes and connections from the Mermaid code
    final lines = mermaidCode.split('\n');
    final nodes = <String>[];
    final connections = <List<String>>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.contains('-->')) {
        final parts = trimmedLine.split('-->');
        if (parts.length == 2) {
          final from = parts[0].trim().replaceAll(RegExp(r'[\[\]]'), '');
          final to = parts[1].trim().replaceAll(RegExp(r'[\[\]]'), '');
          nodes.add(from);
          nodes.add(to);
          connections.add([from, to]);
        }
      }
    }

    // Remove duplicates
    final uniqueNodes = nodes.toSet().toList();

    return Column(
      children: [
        Text(
          'Flowchart Diagram',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Display nodes with connections
                ...uniqueNodes.map((node) {
                  final outgoingConnections =
                      connections.where((conn) => conn[0] == node).toList();
                  final incomingConnections =
                      connections.where((conn) => conn[1] == node).toList();

                  return Column(
                    children: [
                      // Node
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryPurple),
                        ),
                        child: Text(
                          node,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      // Show connections
                      if (outgoingConnections.isNotEmpty)
                        ...outgoingConnections.map((conn) => Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, top: 4, bottom: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: AppTheme.primaryPurple,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '→ ${conn[1]}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMindmapDiagram(String mermaidCode) {
    // Extract mindmap structure
    final lines = mermaidCode.split('\n');
    final nodes = <String>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('mindmap')) {
        final node = trimmedLine.replaceAll(RegExp(r'^\s*'), '');
        if (node.isNotEmpty) {
          nodes.add(node);
        }
      }
    }

    return Column(
      children: [
        Text(
          'Mind Map',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: nodes.map((node) {
                final indent = node.length - node.trimLeft().length;
                return Container(
                  margin: EdgeInsets.only(
                    left: indent * 20.0,
                    top: 4,
                    bottom: 4,
                  ),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryBlue),
                  ),
                  child: Text(
                    node.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGanttDiagram(String mermaidCode) {
    return Column(
      children: [
        Text(
          'Timeline Diagram',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timeline Structure',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      'This diagram shows a timeline with activities and their durations.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDiagram(String mermaidCode) {
    return Column(
      children: [
        Text(
          'Simple Diagram',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryOrange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagram Structure',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      'This diagram shows relationships and connections between concepts.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawingInstructions(String mermaidCode) {
    final instructions = _parseDrawingInstructions(mermaidCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: instructions
          .map((instruction) => Padding(
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
                        instruction,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  List<String> _parseDrawingInstructions(String mermaidCode) {
    final instructions = <String>[];

    if (mermaidCode.contains('flowchart') || mermaidCode.contains('graph')) {
      instructions.add('Draw boxes for each step or component');
      instructions.add('Connect the boxes with arrows showing the flow');
      instructions.add('Add clear labels to each box');
    } else if (mermaidCode.contains('mindmap')) {
      instructions.add('Draw the main topic in the center');
      instructions.add('Add branches for subtopics around it');
      instructions.add('Connect with lines to show relationships');
    } else if (mermaidCode.contains('gantt')) {
      instructions.add('Draw a timeline with dates or steps');
      instructions.add('Add bars to show duration of activities');
      instructions.add('Label each activity clearly');
    } else {
      instructions.add('Draw the main concept in the center');
      instructions.add('Add related elements around it');
      instructions.add('Connect with lines or arrows as needed');
    }

    instructions.add('Use clear, simple shapes that are easy to draw');
    instructions.add('Add labels to explain each part');

    return instructions;
  }

  Widget _buildDiagramPlaceholder() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Diagram Generated Successfully',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The AI has created your educational diagram.\nUse the download button to save it.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
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
                  Icons.description,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Diagram Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(description),
                  tooltip: 'Copy Description',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.lightGray),
              ),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachingInstructionsCard(Map<String, dynamic> instructions) {
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
                  Icons.school,
                  color: AppTheme.accentOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Teaching Instructions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (instructions['how_to_use'] != null) ...[
              Text(
                'How to Use:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                instructions['how_to_use'],
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (instructions['discussion_points'] != null) ...[
              Text(
                'Discussion Points:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...(instructions['discussion_points'] as List)
                  .map((point) => Padding(
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
                                point.toString(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDiagramInfoCard(
      Map<String, dynamic> diagramData, Map<String, dynamic> metadata) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagram Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                'Type:',
                _getDiagramTypeDisplayName(
                    diagramData['diagram_type'] ?? 'auto')),
            _buildInfoRow('Subject:',
                _getSubjectDisplayName(metadata['subject'] ?? 'general')),
            _buildInfoRow(
                'Grade Level:',
                _getGradeLevelDisplayName(
                    metadata['grade_level'] ?? 'grade_3_4')),
            _buildInfoRow('Language:',
                _getLanguageDisplayName(metadata['language'] ?? 'en')),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
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
                onPressed: widget.onRegenerate,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Regenerate'),
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
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onStartNew,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('New Diagram'),
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
                onPressed: () => _downloadDiagram(context),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _shareDiagram(context),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _printDiagram(context),
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

  String _getDiagramTypeDisplayName(String type) {
    switch (type) {
      case 'concept_map':
        return 'Concept Map';
      case 'flowchart':
        return 'Flowchart';
      case 'timeline':
        return 'Timeline';
      case 'bar_chart':
        return 'Bar Chart';
      case 'pie_chart':
        return 'Pie Chart';
      case 'line_graph':
        return 'Line Graph';
      case 'scatter_plot':
        return 'Scatter Plot';
      default:
        return 'Auto-Selected';
    }
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

  String _getGradeLevelDisplayName(String grade) {
    switch (grade) {
      case 'grade_1_2':
        return 'Grade 1-2';
      case 'grade_3_4':
        return 'Grade 3-4';
      case 'grade_5_6':
        return 'Grade 5-6';
      default:
        return 'Grade 3-4';
    }
  }

  String _getLanguageDisplayName(String language) {
    switch (language) {
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      case 'ta':
        return 'தமிழ்';
      case 'bn':
        return 'বাংলা';
      case 'gu':
        return 'ગુજરાતી';
      default:
        return 'English';
    }
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
  }

  void _downloadDiagram(BuildContext context) {
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality coming soon!')),
    );
  }

  void _shareDiagram(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _printDiagram(BuildContext context) {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon!')),
    );
  }

  Widget _buildAsciiArtCard(String asciiArt) {
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
                  Icons.grid_on,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Blackboard Diagram',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(asciiArt),
                  tooltip: 'Copy ASCII art',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.lightGray),
              ),
              child: Text(
                asciiArt,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This simple diagram can be drawn on any blackboard or whiteboard',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingInstructionsCard(dynamic instructions) {
    List<String> instructionList = [];

    if (instructions is List) {
      instructionList = instructions.cast<String>();
    } else if (instructions is String) {
      instructionList =
          instructions.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }

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
                  Icons.format_list_numbered,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Step-by-Step Drawing Instructions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...instructionList.asMap().entries.map((entry) {
              final index = entry.key;
              final instruction = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instruction,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primaryBlue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Follow these steps to draw the diagram on your blackboard',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
