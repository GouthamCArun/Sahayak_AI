import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/markdown_renderer.dart';

/// Chat message widget for displaying individual messages
///
/// Shows messages from both user and AI with appropriate styling,
/// timestamps, and interactive elements.
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isLastMessage;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.isLastMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: isLastMessage ? 16 : 8,
        left: message.isUser ? 40 : 0,
        right: message.isUser ? 0 : 40,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageBubble(context),
                const SizedBox(height: 4),
                _buildTimestamp(),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (message.isUser) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryPink, AppTheme.primaryOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 18,
        ),
      );
    } else {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryGreen, AppTheme.primaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            message.avatar ?? '🤖',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }
  }

  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isUser ? AppTheme.primaryPink : Colors.white,
        borderRadius: BorderRadius.circular(20).copyWith(
          topLeft: message.isUser
              ? const Radius.circular(20)
              : const Radius.circular(4),
          topRight: message.isUser
              ? const Radius.circular(4)
              : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: message.isUser ? null : Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message text
          if (message.isUser)
            Text(
              message.text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                height: 1.4,
              ),
            )
          else
            MarkdownRenderer(
              content: message.text,
            ),

          // Metadata if available for AI messages
          if (!message.isUser && message.metadata != null) ...[
            const SizedBox(height: 8),
            _buildMetadata(),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    final metadata = message.metadata!;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata['processing_time'] != null)
            _buildMetadataRow(
              'Response time',
              '${metadata['processing_time']}s',
              Icons.timer,
            ),
          if (metadata['confidence'] != null)
            _buildMetadataRow(
              'Confidence',
              '${(metadata['confidence'] * 100).toInt()}%',
              Icons.verified,
            ),
          if (metadata['agent'] != null)
            _buildMetadataRow(
              'Agent',
              metadata['agent'],
              Icons.smart_toy,
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Text(
      timeStr,
      style: GoogleFonts.poppins(
        fontSize: 10,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

/// Chat message model (imported from ask_ai_screen.dart)
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? avatar;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.avatar,
    this.metadata,
  });
}
