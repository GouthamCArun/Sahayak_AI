import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/theme/app_theme.dart';

/// Enhanced markdown renderer with Mermaid diagram support
///
/// Renders markdown content with custom styling and Mermaid diagram support
/// for educational content display.
class MarkdownRenderer extends StatelessWidget {
  final String content;
  final bool showCopyButton;
  final VoidCallback? onCopy;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const MarkdownRenderer({
    super.key,
    required this.content,
    this.showCopyButton = true,
    this.onCopy,
    this.padding,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: MarkdownBody(
        data: content,
        styleSheet: _buildMarkdownStyleSheet(),
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Content copied to clipboard!'),
                  backgroundColor: Colors.green,
                ),
              );
              onCopy?.call();
            },
            tooltip: 'Copy to clipboard',
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    return MarkdownStyleSheet(
      h1: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
      h2: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
      h3: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      h4: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      h5: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      h6: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      p: textStyle ??
          TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            height: 1.6,
          ),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
      em: TextStyle(
        fontStyle: FontStyle.italic,
        color: AppTheme.textPrimary,
      ),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        backgroundColor: AppTheme.surfaceColor,
        color: AppTheme.primaryPurple,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightGray),
      ),
      blockquote: TextStyle(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: AppTheme.textSecondary,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryPurple,
            width: 4,
          ),
        ),
        color: AppTheme.primaryPurple.withOpacity(0.1),
      ),
      listBullet: TextStyle(
        color: AppTheme.primaryPurple,
        fontSize: 16,
      ),
      tableHead: TextStyle(
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
      tableBody: TextStyle(
        color: AppTheme.textPrimary,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.lightGray,
            width: 1,
          ),
        ),
      ),
    );
  }
}

/// Widget to display Mermaid diagrams
class MermaidDiagramWidget extends StatelessWidget {
  final String code;

  const MermaidDiagramWidget({
    super.key,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
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
            children: [
              Icon(
                Icons.account_tree,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Diagram',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.lightGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mermaid Diagram Code:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                _buildDrawingInstructions(code),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingInstructions(String code) {
    final instructions = _parseDrawingInstructions(code);

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

  List<String> _parseDrawingInstructions(String code) {
    final instructions = <String>[];

    if (code.contains('flowchart') || code.contains('graph')) {
      instructions.add('Draw boxes for each step or component');
      instructions.add('Connect the boxes with arrows showing the flow');
      instructions.add('Add clear labels to each box');
    } else if (code.contains('mindmap')) {
      instructions.add('Draw the main topic in the center');
      instructions.add('Add branches for subtopics around it');
      instructions.add('Connect with lines to show relationships');
    } else if (code.contains('gantt')) {
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
}

/// Widget to display code blocks with syntax highlighting
class CustomCodeBlockWidget extends StatelessWidget {
  final String code;
  final String language;

  const CustomCodeBlockWidget({
    super.key,
    required this.code,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.code,
                  color: AppTheme.primaryPurple,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  language.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  tooltip: 'Copy code',
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
