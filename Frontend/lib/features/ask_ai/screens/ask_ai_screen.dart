import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../widgets/chat_message.dart' as chat_widget;
import '../widgets/chat_input.dart';

/// Ask AI screen with chat interface
///
/// Provides a conversational interface for teachers to ask questions
/// and get AI-powered answers with educational context.
class AskAIScreen extends ConsumerStatefulWidget {
  const AskAIScreen({super.key});

  @override
  ConsumerState<AskAIScreen> createState() => _AskAIScreenState();
}

class _AskAIScreenState extends ConsumerState<AskAIScreen> {
  final List<chat_widget.ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(
      chat_widget.ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            "नमस्ते! 🙏 I'm Sahaayak AI, your teaching assistant. I'm here to help you with:\n\n• Lesson planning and ideas\n• Student questions and explanations\n• Teaching strategies\n• Educational activities\n• Classroom management tips\n\nWhat would you like to know today?",
        isUser: false,
        timestamp: DateTime.now(),
        avatar: '🤖',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask Sahaayak',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'AI Teaching Assistant',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return chat_widget.ChatMessageWidget(
                        message: _messages[index],
                        isLastMessage: index == _messages.length - 1,
                      );
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient:  const LinearGradient(
                        colors: [AppTheme.primaryGreen, AppTheme.primaryBlue],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.smart_toy,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sahaayak is thinking...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          ChatInput(
            controller: _inputController,
            onSend: _sendMessage,
            onVoiceInput: _handleVoiceInput,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.chat_bubble_outline,
                color: Colors.white, size: 50),
          ),

          const SizedBox(height: 24),

          Text(
            'Start a conversation',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Ask me anything about teaching,\nlesson planning, or student activities',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Quick start suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('How do I teach fractions?'),
              _buildSuggestionChip('Fun math activities'),
              _buildSuggestionChip('Classroom management tips'),
              _buildSuggestionChip('Science experiments'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () {
        _inputController.text = suggestion;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
        ),
        child: Text(
          suggestion,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Add user message
    final userMessage = chat_widget.ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      // Call AI service
      final response = await ApiService.askQuestion(
        question: text,
        language: 'en', // TODO: Get from user preferences
        context: {
          'previous_messages': _messages
              .take(_messages.length - 1)
              .map((m) => {
                    'text': m.text,
                    'is_user': m.isUser,
                  })
              .toList(),
          'user_role': 'teacher',
          'context_type': 'rural_indian_classroom',
        },
      );

      // Add AI response
      final aiMessage = chat_widget.ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response['response'] ??
            response['generated_text'] ??
            'I apologize, but I couldn\'t generate a response.',
        isUser: false,
        timestamp: DateTime.now(),
        avatar: '🤖',
        metadata: response['metadata'],
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Add error message
      final errorMessage = chat_widget.ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'I apologize, but I encountered an error. Please try again or rephrase your question.',
        isUser: false,
        timestamp: DateTime.now(),
        avatar: '⚠️',
      );

      setState(() {
        _messages.add(errorMessage);
      });

      _scrollToBottom();
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleVoiceInput(String voiceText) {
    // Handle voice input text
    _inputController.text = voiceText;
    _sendMessage();
  }
}
