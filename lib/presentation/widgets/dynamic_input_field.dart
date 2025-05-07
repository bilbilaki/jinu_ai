// lib/presentation/widgets/dynamic_input_field.dart
import 'dart:async';
import 'dart:io'; // Required for File
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/data/models/chat_message.dart'; // For ContentType
import 'package:jinu/presentation/providers/file_service_provider.dart';
import 'package:jinu/data/models/file_model.dart';// FileModel likely from your project

typedef SendFileCallback = void Function(File file, ContentType type);
typedef SendAudioCallback = void Function(File audioFile);

class DynamicInputField extends ConsumerStatefulWidget {
  final bool isLoading;
  final Function(String) onSend;
  final SendAudioCallback onSendAudio;
  final SendFileCallback onSendFile;

  const DynamicInputField({
    super.key,
    required this.isLoading,
    required this.onSend,
    required this.onSendAudio,
    required this.onSendFile,
  });

  @override
  ConsumerState<DynamicInputField> createState() => _DynamicInputFieldState();
}

enum _PickSource { gallery, camera, fileStorage }

class _DynamicInputFieldState extends ConsumerState<DynamicInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSendButton = false;

  bool _isRecording = false;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateSendButtonVisibility);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSendButtonVisibility);
    _controller.dispose();
    _focusNode.dispose();
    _recordingTimer?.cancel();
    // Auto-cancel recording if widget is disposed while recording
    final fileService = ref.read(fileServiceProvider);
    if (fileService.isRecording) {
      fileService.cancelRecording().catchError((e) {
        debugPrint("Error cancelling recording on dispose: $e");
      });
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
      // _focusNode.requestFocus(); // Keep focus after sending for quick follow-up
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      if (event.physicalKey == PhysicalKeyboardKey.shiftRight ||
          event.physicalKey == PhysicalKeyboardKey.shiftLeft) {
        // Shift + Enter: Insert newline
        _controller.text += '\n';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        // Allow default behavior (newline) when Shift is pressed
        return KeyEventResult.ignored;
      } else {
        if (_showSendButton && !_isRecording && !widget.isLoading) {
          _handleSendText();
          return KeyEventResult.handled; // Consume the event
        }
        return KeyEventResult.ignored; // If cannot send (e.g. empty text)
      }
    }
    return KeyEventResult.ignored;
  }


  Future<void> _handleFileUpload() async {
    if (widget.isLoading || _isRecording) return;

    // Dismiss keyboard before showing bottom sheet
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900], // Darker background for sheet
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Wrap(
            children: <Widget>[
              _buildFileUploadOption(
                icon: Icons.photo_library_outlined,
                text: 'Pick Image from Gallery',
                onTap: () => _pickFileAndSend(_PickSource.gallery),
              ),
              _buildFileUploadOption(
                icon: Icons.camera_alt_outlined,
                text: 'Take Photo with Camera',
                onTap: () => _pickFileAndSend(_PickSource.camera),
              ),
              _buildFileUploadOption(
                icon: Icons.attach_file_outlined,
                text: 'Pick General File',
                onTap: () => _pickFileAndSend(_PickSource.fileStorage),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFileUploadOption({required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[400], size: 26),
      title: Text(text, style: TextStyle(color: Colors.grey[200], fontSize: 16)),
      onTap: () {
        Navigator.pop(context); // Close bottom sheet
        onTap();
      },
      horizontalTitleGap: 8.0,
    );
  }


  Future<void> _pickFileAndSend(_PickSource source) async {
    if (widget.isLoading) return; // Double check loading state

    final fileService = ref.read(fileServiceProvider);
    File? pickedFile;
    ContentType contentType = ContentType.file; // Default

    try {
      switch (source) {
        case _PickSource.gallery:
          final fileModel = await fileService.pickImageFromGallery();
          pickedFile = fileModel?.file;
          if (pickedFile != null) contentType = ContentType.image;
          break;
        case _PickSource.camera:
final fileModel = await fileService.pickImageFromGallery();
          pickedFile = fileModel?.file;
          break;
        case _PickSource.fileStorage:
final fileModel = await fileService.pickFile();
          if (pickedFile != null) {
            final mime = fileService.getMimeType(pickedFile.path);
            if (mime != null) {
              if (mime.startsWith('image/')) contentType = ContentType.image;
              else if (mime.startsWith('audio/')) contentType = ContentType.audio;
              // else keep ContentType.file
            }
          }
          break;
      }

      if (pickedFile != null) {
        widget.onSendFile(pickedFile, contentType);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File selection cancelled or failed.'), duration: Duration(seconds: 2)),
          );
        }
      }
    } catch (e, s) {
      debugPrint("Error picking/sending file: $e\n$s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: ${e.toString().substring(0,min(e.toString().length, 50))}...'), duration: Duration(seconds: 3)),
        );
      }
    }
  }


  Future<void> _startRecording() async {
    if (widget.isLoading || _isRecording) return;

    final fileService = ref.read(fileServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final granted = await fileService.requestMicrophonePermission();
    if (!granted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Microphone permission denied. Please enable it in settings.')),
      );
      return;
    }

    try {
      bool success = await fileService.startRecording();
      if (success) {
        if (mounted) {
          setState(() {
            _isRecording = true;
            _recordingDuration = Duration.zero;
          });
        }
        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || !_isRecording) {
            timer.cancel();
            return;
          }
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        });
      } else {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to start recording.')));
      }
    } catch (e) {
       debugPrint("Error starting recording: $e");
       scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!mounted || !_isRecording) return;

    _recordingTimer?.cancel();
    final fileService = ref.read(fileServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show a brief "processing" state for recording stop
    if(mounted) setState(() => _isRecording = false); // Optimistically update UI

    try {
      FileModel? audioFileModel = await fileService.stopRecording();
      // Final UI update after operation.
      if (mounted) {
        setState(() {
          // _isRecording = false; // Already set above, but ensures consistency
          _recordingDuration = Duration.zero;
        });
      }

      if (audioFileModel != null) {
        widget.onSendAudio(audioFileModel.file);
      } else if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Recording captured no audio or failed.')));
      }
    } catch (e) {
      debugPrint("Error stopping/sending_recording: $e");
      if (mounted) {
        setState(() {
          _isRecording = false; // Ensure UI reflects stop on error
          _recordingDuration = Duration.zero;
        });
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error processing recording: $e')));
      }
    }
  }

  Future<void> _cancelRecording() async {
    if (!mounted || !_isRecording) return;
    _recordingTimer?.cancel();
    final fileService = ref.read(fileServiceProvider);
    
    try {
      await fileService.cancelRecording();
    } catch (e) {
      debugPrint("Error cancelling recording: $e");
       // Optionally show a snackbar if cancel fails, though often silent cancel is fine.
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDuration = Duration.zero;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final bool canInteract = !widget.isLoading && !_isRecording;
    final bool canSendText = !widget.isLoading && _showSendButton; 

    return Focus( // Use Focus instead of RawKeyboardListener for better integration
      onKeyEvent: _handleKeyEvent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Increased vertical padding
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.grey[850], // Visual cue for recording
          borderRadius: BorderRadius.circular(30.0), // More rounded
          border: Border.all(
            color: _focusNode.hasFocus ? Theme.of(context).colorScheme.primary.withOpacity(0.8) : Colors.grey[700]!,
            width: _focusNode.hasFocus ? 1.8 : 1.2,
          ),
          boxShadow: _focusNode.hasFocus ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              blurRadius: 5,
              spreadRadius: 1
            )
          ] : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end, // Align items to the bottom of the row
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: widget.isLoading || _isRecording ? null : _handleFileUpload,
              tooltip: 'Attach Image or File',
              color: (widget.isLoading || _isRecording) ? Colors.grey[600] : Colors.grey[300],
              iconSize: 26, // Slightly larger
              splashRadius: 22,
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Max height for e.g., 5 lines of text + padding
                  maxHeight: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16.0) * 7.0 + 30.0,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: _isRecording
                        ? 'Recording... Tap stop to send'
                        : 'Type a message (Shift+Enter for new line)',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15.5),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12), // Balanced padding
                    isCollapsed: true, // Important for contentPadding to work well
                  ),
                  style: const TextStyle(fontSize: 15.5, color: Colors.white, height: 1.4), // Improved line height
                  maxLines: null, // Allow multiline input
                  minLines: 1,
                  enabled: canInteract,
                  textInputAction: TextInputAction.newline, // Will be handled by onKeyEvent
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                   onTapOutside: (event) { // Dismiss keyboard on tap outside
                       if (_focusNode.hasFocus) {
                          _focusNode.unfocus();
                       }
                   },
                ),
              ),
            ),
            const SizedBox(width: 6),
            _buildDynamicButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicButton(BuildContext context) {
    final bool generalLoading = widget.isLoading && !_isRecording; // Show general loading only if not recording

    return SizedBox(
      height: 48, // Consistent height for the button area
      width: _isRecording ? null : 48, // Fixed width unless recording (then intrinsic)
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeInOutQuart,
          switchOutCurve: Curves.easeInOutQuart,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                ...previousChildren.map((child) => Positioned.fill(child: child)),
                if (currentChild != null) Positioned.fill(child: currentChild),
              ],
            );
          },
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: generalLoading
              ? _buildLoadingIndicator()
              : _isRecording
                  ? _buildRecordingControls()
                  : _showSendButton
                      ? _buildSendButton()
                      : _buildMicButton(),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return IconButton(
      key: const ValueKey('loading_indicator'),
      icon: SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.grey[500])),
      onPressed: null, // Disabled
      tooltip: 'Processing...',
      padding: EdgeInsets.zero,
      splashRadius: 22,
    );
  }

  Widget _buildRecordingControls() {
    return Row(
      key: const ValueKey('recording_controls'),
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent, size: 28),
          onPressed: _stopRecordingAndSend, // Can be pressed even if parent widget.isLoading (e.g. sending text, then stop audio)
          tooltip: 'Stop and Send Recording',
          splashRadius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        // Optional Cancel Button
        IconButton(
           icon: Icon(Icons.cancel_rounded, color: Colors.grey[400], size: 22),
           onPressed: _cancelRecording,
           tooltip: 'Cancel Recording',
           splashRadius: 18,
           padding: const EdgeInsets.symmetric(horizontal: 2),
        ),
        Padding(
          padding: const EdgeInsets.only(left:2.0, right: 8.0),
          child: Text(
            _formatDuration(_recordingDuration),
            style: TextStyle(color: Colors.grey[200], fontSize: 14.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return IconButton(
      key: const ValueKey('send_button'),
      icon: Icon(Icons.send_rounded, size: 24, color: Colors.blueAccent[100]),
      onPressed: widget.isLoading ? null : _handleSendText, // Check isLoading again for safety
      tooltip: 'Send Message (Enter)',
      splashRadius: 22,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildMicButton() {
    return IconButton(
      key: const ValueKey('mic_button'),
      icon: Icon(Icons.mic_none_rounded, size: 26, color: Colors.grey[300]),
      onPressed: widget.isLoading ? null : _startRecording, // Disable if general loading
      tooltip: 'Record Audio (Hold or Tap)', // Consider hold vs tap logic if desired
      splashRadius: 22,
      padding: EdgeInsets.zero,
    );
  }
}