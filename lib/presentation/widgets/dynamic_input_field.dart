// lib/presentation/widgets/dynamic_input_field.dart
import 'dart:async';
import 'dart:io'; // Required for File

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:jinu/data/models/chat_message.dart';
//import 'package:jinu/data/services/file_service.dart';
import 'package:jinu/presentation/providers/file_service_provider.dart';
import 'package:jinu/data/models/file_model.dart';
// Add Callbacks for file/audio sending
typedef SendFileCallback = void Function(File file, ContentType type);
typedef SendAudioCallback = void Function(File audioFile);

class DynamicInputField extends ConsumerStatefulWidget { // Change to ConsumerStatefulWidget
  final bool isLoading;
  final Function(String) onSend;
  final SendAudioCallback onSendAudio; // Callback for sending recorded audio
  final SendFileCallback onSendFile;   // Callback for sending other files/images
  // final VoidCallback? onRecordStart; // Keep if needed elsewhere
  // final VoidCallback? onFileUpload; // Keep if needed elsewhere

  const DynamicInputField({
    super.key,
    required this.isLoading,
    required this.onSend,
    required this.onSendAudio,
    required this.onSendFile,
    // this.onRecordStart,
    // this.onFileUpload,
  });

  @override
  ConsumerState<DynamicInputField> createState() => _DynamicInputFieldState(); // Change to ConsumerState
}

class _DynamicInputFieldState extends ConsumerState<DynamicInputField> { // Change to ConsumerState
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSendButton = false;

  // --- Audio Recording State ---
  bool _isRecording = false;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateSendButtonVisibility);
    // Listen to external recording state if necessary (e.g., from provider)
    // ref.listen(isRecordingProvider, (_, next) {
    //   if (mounted && next != _isRecording) {
    //     setState(() { _isRecording = next; });
    //     // Handle timer start/stop if state changes externally
    //   }
    // });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSendButtonVisibility);
    _controller.dispose();
    _focusNode.dispose();
    _recordingTimer?.cancel(); // Cancel timer on dispose
    // Consider cancelling recording if widget is disposed while recording
    final fileService = ref.read(fileServiceProvider);
    if (fileService.isRecording) {
      fileService.cancelRecording();
    }
    super.dispose();
  }

  void _updateSendButtonVisibility() {
    if (mounted) {
      setState(() {
        _showSendButton = _controller.text.trim().isNotEmpty;
      });
    }
  }

  void _handleSendText() {
    final text = _controller.text.trim();
    if (!widget.isLoading && text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  KeyEventResult _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      if (!event.isShiftPressed) {
        if (_showSendButton && !_isRecording && !widget.isLoading) { // Only send text if send button is visible
             _handleSendText();
             return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored; // Allow default newline if Shift or cannot send
    }
    return KeyEventResult.ignored;
  }

  // --- File Upload Logic ---
  Future<void> _handleFileUpload() async {
    if (widget.isLoading) return;
    // Show options (Gallery, Camera, File)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850],
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.grey),
              title: const Text('Pick Image from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendFile(FileModel.fromFile(File(FilePicker.platform.pickFiles().path)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
              title: const Text('Take Photo with Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendFile(FileModel.fromFile(File(FilePicker.platform.pickFiles().path)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined, color: Colors.grey),
              title: const Text('Pick File from Storage', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendFile(FileModel.fromFile(File(FilePicker.platform.pickFiles().path)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendFile(FileModel fileModel) async {
     final fileService = ref.read(fileServiceProvider);
     File? pickedFile;
     ContentType contentType = ContentType.file; // Default

     try {
       switch (fileModel.mimeType) {
         case '/image':
           pickedFile = (await fileService.pickImageFromGallery()) as File?;
           contentType = ContentType.image;
           break;
         case '/image/png':
           pickedFile = (await fileService.takePhotoWithCamera()) as File?;
           contentType = ContentType.image;
           break;
         case '/application/pdf':
           pickedFile = (await fileService.pickFile(
             // allowedExtensions: ['pdf', 'doc', 'txt', 'jpg', 'png'],
           )) as File?;
           // Determine content type based on MIME if needed
           final mime = pickedFile != null ? fileService.getMimeType(pickedFile.path) : null;
           if(mime != null) {
                if(mime.startsWith('image/')) contentType = ContentType.image;
                else if(mime.startsWith('audio/')) contentType = ContentType.audio;
                else contentType = ContentType.file; // Keep generic for others
           }
           break;
       }

       if (pickedFile != null) {
         widget.onSendFile(pickedFile, contentType);
       } else {
         // Optional: Show a message if picking was cancelled or failed
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File selection cancelled.'), duration: Duration(seconds: 2)));
       }
     } catch (e) {
         debugPrint("Error picking/sending file: $e");
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting file: $e'), duration: Duration(seconds: 2)));
     }
  }

  // --- Audio Recording Logic ---
  Future<void> _startRecording() async {
    if (widget.isLoading || _isRecording) return; // Prevent starting multiple times

    final fileService = ref.read(fileServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture context

    final granted = await fileService.requestMicrophonePermission();
    if (!granted) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Microphone permission denied.')));
      return;
    }

    bool success = await fileService.startRecording();
    if (success) {
      // Update state within this widget
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      // Also update global provider if used
      ref.read(fileService.isRecording as ProviderListenable<Object>) ;

      _recordingTimer?.cancel(); // Cancel any existing timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!_isRecording) { // Stop timer if recording flag is turned off
             timer.cancel();
             return;
          }
        setState(() {
             _recordingDuration += const Duration(seconds: 1);
         });

      });
      // widget.onRecordStart?.call(); // Call original callback if needed
    } else {
       scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to start recording.')));
    }
  }


  Future<void> _stopRecordingAndSend() async {
     if (!mounted || !_isRecording) return; // Guard against race conditions or stopping when not recording

     _recordingTimer?.cancel(); // Stop the timer
     final fileService = ref.read(fileServiceProvider);
     final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture context

     try {
         FileModel? audioFile = await fileService.stopRecording();

         // Update state *regardless* of success/failure to stop recording UI
         if (mounted) {
             setState(() {
                  _isRecording = false;
                  _recordingDuration = Duration.zero;
              });
             // Also update global provider if used
             ref.read(fileService.isRecording as ProviderListenable<Object>);
         }

         if (audioFile != null) {
             widget.onSendAudio(audioFile.file);
         } else if(mounted) { // Only show snackbar if mounted
             scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Recording stop failed or file was empty.')));
         }
     } catch (e) {
          debugPrint("Error stopping recording: $e");
          // Ensure state is updated even on error
         if (mounted) {
             setState(() {
                  _isRecording = false;
                  _recordingDuration = Duration.zero;
              });
             ref.read(fileService.isRecording as ProviderListenable<Object>);
         }
         if(mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error stopping recording: $e')));
     }
  }

  // Optional: Cancel Recording (e.g., on long press? or different button?)
  Future<void> _cancelRecording() async {
      if (!mounted || !_isRecording) return;
      _recordingTimer?.cancel();
      final fileService = ref.read(fileServiceProvider);
      await fileService.cancelRecording(); // Ignore errors, just try to cancel
      if (mounted) {
            setState(() {
                _isRecording = false;
                _recordingDuration = Duration.zero;
            });
           ref.read(fileService.isRecording as ProviderListenable<Object>);
       }
  }

  // Helper to format duration
  String _formatDuration(Duration duration) {
     String twoDigits(int n) => n.toString().padLeft(2, '0');
     final minutes = twoDigits(duration.inMinutes.remainder(60));
     final seconds = twoDigits(duration.inSeconds.remainder(60));
     return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // Read the file service if needed for direct checks (like fileService.isRecording)
    // final fileService = ref.watch(fileServiceProvider);
    // Could also watch the isRecordingProvider
    // final isCurrentlyRecording = ref.watch(isRecordingProvider);

    Color micIconColor = widget.isLoading ? Colors.grey[700]! : Colors.grey[400]!;
    Color sendIconColor = widget.isLoading ? Colors.grey[700]! : (Colors.blue[300] ?? Colors.blue);

    return RawKeyboardListener(
      focusNode: FocusNode(onKey: (_, event) => _handleKeyEvent(event)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(28.0),
          border: Border.all(color: _focusNode.hasFocus ? Theme.of(context).colorScheme.primary : Colors.grey[700]!, width: _focusNode.hasFocus ? 1.5 : 1.0)
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // File Upload Button
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: widget.isLoading || _isRecording ? null : _handleFileUpload, // Disable during recording/loading
              tooltip: 'Add Image or File',
              color: widget.isLoading || _isRecording ? Colors.grey[700] : Colors.grey[400],
              splashRadius: 20,
            ),

            // Text Field
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) * 10 + 40,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: _isRecording
                        ? 'Recording audio...'
                        : 'Enter a prompt (Shift+Enter for newline)',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    isCollapsed: true,
                  ),
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                  maxLines: null,
                  minLines: 1,
                  enabled: !widget.isLoading && !_isRecording, // Disable text input during recording
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  onSubmitted: (value) {
                    if (!_isRecording) _handleSendText(); // Submit only if not recording
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Dynamic Send/Record Button Area
            SizedBox(
              height: 44,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        ...previousChildren.map((child) => Positioned( // Keep previous centered
                            left: 0, right: 0, top: 0, bottom: 0, child: child)),
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: _buildDynamicButton(), // Use helper for clarity
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build the correct button based on state
  Widget _buildDynamicButton() {
    // Show loading indicator / Disabled during general loading state
    if (widget.isLoading && !_isRecording) { // Prioritize showing recording UI if recording AND loading
        return IconButton(
            key: const ValueKey('loading'),
            icon: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[600])),
            onPressed: null,
            tooltip: 'Processing...',
            padding: EdgeInsets.zero,
            splashRadius: 20,
        );
    }
    // Show Recording UI (Stop button + Duration)
    else if (_isRecording) {
      return Row(
        key: const ValueKey('recording'),
        mainAxisSize: MainAxisSize.min, // Take only needed space
        children: [
          IconButton(
            icon: const Icon(Icons.stop_circle_rounded, color: Colors.redAccent, size: 24),
            onPressed: _stopRecordingAndSend, // Can still be pressed if main widget is loading
            tooltip: 'Stop Recording',
            padding: EdgeInsets.zero,
            splashRadius: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 8.0), // Add padding
            child: Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(color: Colors.grey[300], fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
           // Optional: Cancel Button during recording?
          // IconButton(
          //   icon: Icon(Icons.cancel_outlined, color: Colors.grey[500], size: 20),
          //   onPressed: _cancelRecording,
          //   tooltip: 'Cancel Recording',
          //   padding: EdgeInsets.zero,
          //   splashRadius: 16,
          // ),
        ],
      );
    }
    // Show Send Button (if text entered)
    else if (_showSendButton) {
      return IconButton(
        key: const ValueKey('send'),
        icon: Icon(Icons.send_rounded, size: 20, color: Colors.blue[300]),
        onPressed: _handleSendText, // Already checks widget.isLoading internally
        tooltip: 'Send Message (Enter)',
        color: Colors.blue[300],
        splashRadius: 20,
        padding: EdgeInsets.zero,
      );
    }
    // Show Mic Button (default)
    else {
      return IconButton(
        key: const ValueKey('mic'),
        icon: Icon(Icons.mic_none_outlined, size: 22, color: Colors.grey[400]),
        onPressed: _startRecording, // Already guards against isLoading/isRecording
        tooltip: 'Record Audio',
        color: Colors.grey[400],
        splashRadius: 20,
        padding: EdgeInsets.zero,
      );
    }
  }
}

extension on Future<FilePickerResult?> {
  String get path => "";
}