import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../core/theme/app_theme.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String)? onVoiceInput;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onVoiceInput,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with TickerProviderStateMixin {
  bool _isEmpty = true;
  bool _isRecording = false;
  FlutterSoundRecorder? _recorder;
  String? _recordingPath;

  late AnimationController _recordingController;
  late Animation<double> _recordingAnimation;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _initializeRecorder();
    _setupAnimations();
  }

  void _setupAnimations() {
    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _recordingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _recordingController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _recordingController.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  void _onTextChanged() {
    final isEmpty = widget.controller.text.trim().isEmpty;
    if (isEmpty != _isEmpty) {
      setState(() {
        _isEmpty = isEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Voice Input Button
          if (widget.onVoiceInput != null) ...[
            _buildVoiceButton(),
            Container(
              width: 1,
              height: 32,
              color: AppTheme.lightGray,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ],

          // Text Input
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: _isRecording
                    ? 'Recording... Tap stop when done'
                    : 'Ask Sahaayak anything...',
                hintStyle: TextStyle(
                  color: _isRecording
                      ? AppTheme.primaryOrange
                      : AppTheme.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isRecording,
            ),
          ),

          // Send Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(8),
            child: InkWell(
              onTap: _isEmpty && !_isRecording ? null : _handleSend,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isEmpty && !_isRecording
                      ? AppTheme.lightGray
                      : AppTheme.primaryPink,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecording ? Icons.send : Icons.send,
                  color: _isEmpty && !_isRecording
                      ? AppTheme.textSecondary
                      : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    return AnimatedBuilder(
      animation: _recordingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRecording ? _recordingAnimation.value : 1.0,
          child: InkWell(
            onTap: _isRecording ? _stopRecording : _startRecording,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red[400] : AppTheme.primaryOrange,
                shape: BoxShape.circle,
                boxShadow: _isRecording
                    ? [
                        BoxShadow(
                          color: Colors.red[400]!.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startRecording() async {
    // Request permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice input'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      _recordingPath =
          '${tempDir.path}/voice_input_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Start recording
      await _recorder!.startRecorder(
        toFile: _recordingPath,
        codec: Codec.pcm16WAV,
      );

      setState(() {
        _isRecording = true;
      });

      // Start animation
      _recordingController.repeat(reverse: true);

      // Show recording indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.mic,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Recording... Tap the microphone to stop'),
            ],
          ),
          backgroundColor: AppTheme.primaryOrange,
          duration: const Duration(days: 1), // Keep until dismissed
          action: SnackBarAction(
            label: 'Stop',
            textColor: Colors.white,
            onPressed: _stopRecording,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder!.stopRecorder();

      setState(() {
        _isRecording = false;
      });

      // Stop animation
      _recordingController.stop();

      // Dismiss recording snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Process the recorded audio
      if (_recordingPath != null && widget.onVoiceInput != null) {
        // Show processing indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Processing voice input...'),
              ],
            ),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );

        // Simulate voice-to-text processing
        await Future.delayed(const Duration(seconds: 2));

        // For demo purposes, add placeholder text
        widget.controller.text =
            'Voice input: ${DateTime.now().toString().substring(11, 19)}';
        _onTextChanged();

        // Dismiss processing indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Voice input processed successfully!'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      _recordingController.stop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSend() {
    if (_isRecording) {
      _stopRecording();
    } else if (!_isEmpty) {
      widget.onSend();
    }
  }
}
