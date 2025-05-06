// lib/presentation/widgets/chat_message_widget.dart
import 'dart:async' show StreamSubscription;
import 'dart:io'; // For File operations
import 'dart:math';

import 'package:audioplayers/audioplayers.dart'; // Audio player
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
//import 'package:image_gallery_saver/image_gallery_saver.dart'; // Optional gallery save
import 'package:jinu/presentation/providers/file_service_provider.dart'; // Import file service prov
import 'package:url_launcher/url_launcher.dart';
// import 'package:intl/intl.dart';

import '../../data/models/chat_message.dart';
//import '../../data/services/file_service.dart'; // Import File Service for saving
import '../../data/models/file_model.dart';
class ChatMessageWidget extends ConsumerStatefulWidget { // Change to ConsumerStatefulWidget
  final ChatMessage message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  ConsumerState<ChatMessageWidget> createState() => _ChatMessageWidgetState(); // Change state type
}

class _ChatMessageWidgetState extends ConsumerState<ChatMessageWidget> { // Change state type
  // --- Audio Player State ---
  late AudioPlayer _audioPlayer;
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;
  StreamSubscription? _playerErrorSubscription; // Add error listener

  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _isPaused => _playerState == PlayerState.paused;

  @override
  void initState() {
    super.initState();
    // Initialize player only if it's an audio message
    if (widget.message.contentType == ContentType.audio) {
      _audioPlayer = AudioPlayer();
      // Set release mode to keep resources minimal when not playing
      _audioPlayer.setReleaseMode(ReleaseMode.stop);

      // Listen to states and position
      _playerStateChangeSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _playerState = state);
      }, onError: (msg) { // Add error listener here
        debugPrint('Audio Player State Error: $msg');
        if (mounted) setState(() => _playerState = PlayerState.stopped); // Or completed/error state
      });

      _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
         if (mounted) setState(() => _duration = duration);
      });

      _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
         if (mounted) setState(() => _position = p);
      });

      _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
         if (mounted) setState(() {
              _playerState = PlayerState.completed;
               _position = Duration.zero; // Reset position on completion
           });
      });

       // Set the source when the widget initializes
      _initAudioSource();
    }
  }

  // --- Initialize Audio Source ---
  Future<void> _initAudioSource() async {
    Source? source;
    if (widget.message.filePath != null && widget.message.filePath!.isNotEmpty) {
        // Ensure file exists before setting source
        final file = File(widget.message.filePath!);
        if(await file.exists()) {
             source = DeviceFileSource(widget.message.filePath!);
        } else {
             debugPrint("Audio file not found at local path: ${widget.message.filePath}");
             // Show error state in UI?
        }
    } else if (widget.message.fileUrl != null && widget.message.fileUrl!.isNotEmpty) {
        source = UrlSource(widget.message.fileUrl!);
    }

    if (source != null) {
       try {
             await _audioPlayer.setSource(source);
             debugPrint("Audio source set successfully.");
             // Duration might load after setting source, handled by listener
         } catch (e) {
            debugPrint("Error setting audio source: $e");
            // Optionally show an error message in the UI
             if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error loading audio'), duration: Duration(seconds: 2)),
                );
             }
        }
    } else {
        debugPrint("No valid audio source found for message: ${widget.message.id}");
     }
  }


  @override
  void dispose() {
    // Release player resources ONLY if it was initialized
    if (widget.message.contentType == ContentType.audio) {
       _durationSubscription?.cancel();
        _positionSubscription?.cancel();
       _playerCompleteSubscription?.cancel();
       _playerStateChangeSubscription?.cancel();
       _playerErrorSubscription?.cancel();
       _audioPlayer.dispose(); // Dispose the player itself
    }
    super.dispose();
  }

  // --- Play/Pause/Seek Logic ---
  Future<void> _play() async {
     if (_audioPlayer.source == null) {
         debugPrint("Attempted to play but source is null. Initializing...");
         await _initAudioSource(); // Try to set source again
         if(_audioPlayer.source == null) { // Check if still null
             debugPrint("Failed to initialize source on play.");
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot play audio: Source unavailable.')));
             return;
         }
     }

    try {
        await _audioPlayer.resume();
        if (mounted) setState(() => _playerState = PlayerState.playing);
    } catch (e) {
        debugPrint("Error playing audio: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
    }
  }

  Future<void> _pause() async {
    try {
       await _audioPlayer.pause();
       if (mounted) setState(() => _playerState = PlayerState.paused);
    } catch (e) {
        debugPrint("Error pausing audio: $e");
        // Handle error (e.g., show message)
    }
  }

  Future<void> _seek(Duration position) async {
    try {
        await _audioPlayer.seek(position);
    } catch (e) {
        debugPrint("Error seeking audio: $e");
        // Handle error
    }
  }

  // --- File Saving Logic ---
  Future<void> _saveFile() async {
     final fileService = ref.read(fileServiceProvider);
     final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture context
     String? sourcePath = widget.message.filePath;
     String? sourceUrl = widget.message.fileUrl;
     String defaultFileName = widget.message.fileName ?? // Use provided name or generate one
        (widget.message.contentType == ContentType.image ? 'image_${widget.message.id}.jpg' : // Adjust extension based on type
         widget.message.contentType == ContentType.audio ? 'audio_${widget.message.id}.m4a' :
         'file_${widget.message.id}');

     File? sourceFile;

     // Prioritize local file path if available
     if (sourcePath != null && sourcePath.isNotEmpty) {
         sourceFile = File(sourcePath);
         if (!await sourceFile.exists()) {
             scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Error: Local file not found.')));
             return;
         }
     }
     // TODO: Implement download from URL if only URL is available
     else if(sourceUrl != null && sourceUrl.isNotEmpty) {
         scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Downloading from URL not yet implemented.')));
         // Here you would use http package or similar to download the file
         // then save it using the service.
         return;
     }
      else {
         scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Error: No file source available to save.')));
         return;
     }

     // Save the file
     bool success = false;
     String? savedPath;
     try {
           if (widget.message.contentType == ContentType.image && Platform.isAndroid || Platform.isIOS) {
                // Try saving image specifically to gallery (if package included)
                  await fileService.saveImageToGallery;
                if (!success) { // If gallery save fails, fall back to general save
                        savedPath = await fileService.saveFileToAppDirectory(FileModel.fromFile(sourceFile), defaultFileName);
                      success = savedPath != null;
                }
           } else {
                // Save audio or other files to app directory/downloads
               savedPath = await fileService.saveFileToAppDirectory(FileModel.fromFile(sourceFile), defaultFileName);
                success = savedPath != null;
           }


         if (success) {
             scaffoldMessenger.showSnackBar(SnackBar(content: Text('File saved${savedPath != null ? " to $savedPath" : ""}')));
         } else {
             scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to save file.')));
         }
     } catch (e) {
         debugPrint("Error saving file: $e");
         scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving file: $e')));
     }
  }


  // --- Basic function to attempt launching URLs ---
  Future<void> _launchUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch URL: $url");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message; // Use widget.message
    final isUser = message.sender == MessageSender.user;
    final isAi = message.sender == MessageSender.ai;
    final isSystem = message.sender == MessageSender.system;
    final isError = isSystem && message.metadata?['error'] == true;
    final theme = Theme.of(context);

    Color bubbleColor = isUser
        ? (theme.colorScheme.primaryContainer)
        : (isError
            ? Colors.red[900]!.withOpacity(0.8)
        // Use slightly different color for AI files vs text? Optional.
            : isAi && message.isFileBased
                 ? theme.cardColor.withOpacity(0.9) // Slightly different shade for files
                 : theme.cardColor); // AI text or System message color
    Color textColor = isUser
        ? theme.colorScheme.onPrimaryContainer
        : (isError ? Colors.red[100]! : theme.textTheme.bodyLarge?.color ?? Colors.white);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        margin: EdgeInsets.only(
          top: 5.0, bottom: 10.0, // Increased bottom margin slightly
          left: isUser ? 40.0 : 8.0,
          right: isUser ? 8.0 : 40.0,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18.0).subtract(
            isUser
                ? const BorderRadius.only(bottomRight: Radius.circular(18), topRight: Radius.circular(5))
                : const BorderRadius.only(bottomLeft: Radius.circular(18), topLeft: Radius.circular(5)),
          ),
          boxShadow: isAi && !isError && theme.brightness == Brightness.light ? [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))
          ] : null,
          border: isError ? Border.all(color: Colors.red[400]!, width: 0.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important for Column containing Flexible/Expanded
          children: [
            // --- Build Content based on Type ---
            _buildContent(context, textColor),

            // --- Action Buttons (Copy/Save) ---
             // Show actions centered below the content if it's AI/System and not text-only error
             if ((isAi || (isSystem && !isError)) && message.contentType != ContentType.text)
                 Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Row(
                         mainAxisAlignment: MainAxisAlignment.end,
                         children: [
                            // Save Button (for Image/Audio/File)
                           if (message.isFileBased && (message.filePath != null || message.fileUrl != null))
                                IconButton(
                                    icon: Icon(Icons.save_alt_outlined, size: 18, color: textColor.withOpacity(0.8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    constraints: const BoxConstraints(),
                                    tooltip: "Save File",
                                    visualDensity: VisualDensity.compact,
                                    splashRadius: 18,
                                    onPressed: _saveFile,
                                ),
                                // Copy Button (Always show for AI/System non-errors)
                             if (message.content.isNotEmpty) // Only show copy if there's text content
                                 IconButton(
                                     icon: Icon(Icons.copy_all_outlined, size: 16, color: textColor.withOpacity(0.7)),
                                     padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "Copy Text",
                                    visualDensity: VisualDensity.compact,
                                     splashRadius: 16,
                                     onPressed: () {
                                         Clipboard.setData(ClipboardData(text: message.content));
                                         ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text('Copied text to clipboard'), duration: Duration(seconds: 1)),
                                         );
                                     },
                                 ),
                           ],
                     ),
                 )
             // Show only copy button for purely text messages from AI/System
                else if ((isAi || isError) && message.contentType == ContentType.text)
                     Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                         padding: const EdgeInsets.only(top: 4.0),
                         child: IconButton(
                             icon: Icon(Icons.copy_all_outlined, size: 16, color: textColor.withOpacity(0.7)),
                             padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                             tooltip: "Copy Text",
                             splashRadius: 16,
                             onPressed: () {
                             Clipboard.setData(ClipboardData(text: message.content));
                             ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Copied text to clipboard'), duration: Duration(seconds: 1)),
                             );
                             },
                         ),
                         ),
                     )
          ],
        ),
      ),
    );
  }

  // --- Content Building Logic based on ContentType ---
  Widget _buildContent(BuildContext context, Color textColor) {
    final message = widget.message; // Access message here

    switch (message.contentType) {
      case ContentType.image:
        return _buildImageContent(context, message, textColor);
      case ContentType.audio:
        return _buildAudioContent(context, message, textColor);
      case ContentType.file: // Generic file placeholder
        return _buildFilePlaceholderContent(context, message, textColor);
      case ContentType.text:
      // Fallback to text rendering
        return _buildTextContent(context, message, textColor);
    }
  }

  // --- Text Content Builder ---
  Widget _buildTextContent(BuildContext context, ChatMessage message, Color textColor) {
     if (message.content.isEmpty) { // Avoid empty Markdown widget
         return const SizedBox.shrink();
     }
    final bool isCodeDominant = _isLikelyCode(message.content);
    return MarkdownBody(
        data: message.content,
        selectable: true,
        onTapLink: (text, href, title) {
          if (href != null) {
            _launchUrl(href);
          }
        },
        styleSheetTheme: isCodeDominant
            ? MarkdownStyleSheetBaseTheme.platform
            : MarkdownStyleSheetBaseTheme.material, // Or try .cupertino
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
             p: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor, fontSize: 15),
             // Add other styling as before...
             code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: 13.5,
                backgroundColor: textColor.withOpacity(0.1),
                color: textColor.withOpacity(0.9), // Slightly less intense than bg
             ),
              codeblockDecoration: BoxDecoration(
                 color: Colors.black.withOpacity(0.5), // Darker code block
                 borderRadius: BorderRadius.circular(6),
                 border: Border.all(color: Colors.grey[700]!)
             ),
            // Ensure other styles use textColor...
             h1: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600),
            h2: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600),
            // ... copy other styles from your original code ...
        ),
        // Syntax highlighting setup (if using flutter_highlight)
        // syntaxHighlighter: ...,
    );
  }

  // --- Image Content Builder ---
  Widget _buildImageContent(BuildContext context, ChatMessage message, Color textColor) {
    Widget imageWidget = const SizedBox(
      height: 150, // Placeholder size
      child: Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey , size: 40)),
    ); // Placeholder

    final imageFile = message.filePath != null ? File(message.filePath!) : null;
    final imageUrl = message.fileUrl;

    if (imageFile != null && imageFile.existsSync()) {
        imageWidget = Image.file(
            imageFile,
           fit: BoxFit.contain, // Or BoxFit.cover depending on desired layout
           // Add loading/error builder if needed, though less common for local files
        );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        // Add loading progress and error handling for network images
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                 strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
            ),
          );
        },
      );
    }

    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       mainAxisSize: MainAxisSize.min,
       children: [
           // Display text content *above* the image if present
           if (message.content.isNotEmpty) ...[
                _buildTextContent(context, message, textColor), // Render markdown text
               const SizedBox(height: 8),
           ],
            // Display the image, maybe with rounded corners
            ClipRRect(
                 borderRadius: BorderRadius.circular(12.0), // Rounded corners for image
                child: imageWidget,
             ),
            // Optional: Display filename below image
            if(message.fileName != null && message.fileName!.isNotEmpty)
                 Padding(
                     padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                         message.fileName!,
                         style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7)),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                      ),
                 )
       ],
    );
  }

   // --- Audio Content Builder ---
  Widget _buildAudioContent(BuildContext context, ChatMessage message, Color textColor) {
     final currentPosition = _position ?? Duration.zero;
     final totalDuration = _duration ?? Duration.zero;

     // Show loading if duration is null and state isn't stopped/completed/paused initially
     final bool isLoading = _duration == null && !(_playerState == PlayerState.stopped || _playerState == PlayerState.completed || _playerState == PlayerState.paused);
     final String durationText = totalDuration != Duration.zero
         ? "${_formatDuration(currentPosition)} / ${_formatDuration(totalDuration)}"
         : "--:-- / --:--"; // Placeholder if duration not loaded

     return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         mainAxisSize: MainAxisSize.min,
         children: [
             // Display text content *above* the player if present
             if (message.content.isNotEmpty) ...[
                 _buildTextContent(context, message, textColor),
                 const SizedBox(height: 8),
             ],

             // Audio Player Row
             Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                     color: textColor.withOpacity(0.1), // Subtle background for player
                     borderRadius: BorderRadius.circular(20),
                 ),
                 child: Row(
                     mainAxisSize: MainAxisSize.min, // Important for Row size
                     children: [
                         // Play/Pause Button
                         IconButton(
                            icon: isLoading
                                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
                                : Icon(
                                     _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                                     size: 32.0, // Larger button
                                     color: textColor,
                                 ),
                             onPressed: isLoading ? null : (_isPlaying ? _pause : _play),
                             tooltip: _isPlaying ? 'Pause' : 'Play',
                             padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                         ),
                         // Slider and Duration Text
                         Expanded( // Make slider take available space
                           child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch slider
                                children: [
                                    // Only show slider if duration is known
                                    if(!isLoading && totalDuration > Duration.zero)
                                      SliderTheme(
                                           data: SliderTheme.of(context).copyWith(
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                             overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                                             trackHeight: 2.0,
                                            activeTrackColor: textColor.withOpacity(0.8),
                                             inactiveTrackColor: textColor.withOpacity(0.3),
                                             thumbColor: textColor,
                                             overlayColor: textColor.withOpacity(0.2),
                                           ),
                                          child: Slider(
                                             value: (totalDuration > Duration.zero
                                                 ? currentPosition.inMicroseconds.clamp(0, totalDuration.inMicroseconds) / totalDuration.inMicroseconds
                                                 : 0.0),
                                             min: 0.0,
                                             max: 1.0, // Normalized value
                                            onChanged: (value) {
                                                final newPosition = totalDuration * value;
                                                 _seek(newPosition);
                                             },
                                         ),
                                      )
                                    else // Show placeholder or just spacer if no duration/loading
                                      const SizedBox(height: 16), // Placeholder height to align text
                                    // Duration Text aligned to the right
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                             durationText,
                                             style: TextStyle(fontSize: 11.5, color: textColor.withOpacity(0.8)),
                                         ),
                                      ),
                                    ),
                               ],
                           ),
                         ),
                     ],
                 ),
             ),
             // Optional: Display filename below player
             if(message.fileName != null && message.fileName!.isNotEmpty)
                 Padding(
                     padding: const EdgeInsets.only(top: 4.0, left: 4.0), // Align slightly with player
                    child: Text(
                         message.fileName!,
                         style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7)),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                      ),
                 )
         ],
     );
 }

 // --- Generic File Placeholder Builder ---
 Widget _buildFilePlaceholderContent(BuildContext context, ChatMessage message, Color textColor) {
     IconData fileIcon = Icons.insert_drive_file_outlined; // Default icon
     final mime = message.mimeType?.toLowerCase();
     if (mime != null) {
         if (mime.startsWith('application/pdf')) fileIcon = Icons.picture_as_pdf_outlined;
         else if (mime.startsWith('application/vnd.openxmlformats-officedocument.wordprocessingml') || mime.startsWith('application/msword')) fileIcon = Icons.description_outlined; // Word doc
         else if (mime.startsWith('application/vnd.openxmlformats-officedocument.spreadsheetml') || mime.startsWith('application/vnd.ms-excel')) fileIcon = Icons.calculate_outlined; // Excel
         // Add more specific icons based on MIME type if desired
     }

   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     mainAxisSize: MainAxisSize.min,
     children: [
       // Display text content *above* the file info if present
       if (message.content.isNotEmpty) ...[
         _buildTextContent(context, message, textColor),
         const SizedBox(height: 8),
       ],
       // File Info Row
       Container(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
         decoration: BoxDecoration(
           color: textColor.withOpacity(0.08),
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: textColor.withOpacity(0.2), width: 0.5)
         ),
         child: Row(
           mainAxisSize: MainAxisSize.min, // Use min size
           children: [
             Icon(fileIcon, color: textColor.withOpacity(0.8), size: 28),
             const SizedBox(width: 10),
             Flexible( // Allow text to wrap or ellipsis
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    Text(
                       message.fileName ?? "附件文件" , // "Attached File" or use filename
                       style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                    ),
                   if(message.fileSize != null && message.fileSize! > 0)
                       Text(
                          _formatFileSize(message.fileSize!), // Helper to format size
                           style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7)),
                           maxLines: 1,
                       ),
                 ],
               ),
             ),
             // Note: Removed explicit Save button from here, handled in the general action button area below content
           ],
         ),
       ),
     ],
   );
 }

  // Helper to format duration for display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

   // Helper to format file size
    String _formatFileSize(int bytes) {
       if (bytes <= 0) return "0 B";
        const suffixes = ["B", "KB", "MB", "GB", "TB"];
       int i = (log(bytes) / log(1024)).floor();
       return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
     }

  // Simple heuristic to check if the content is mostly code (keep your implementation)
  bool _isLikelyCode(String text) {
       if (text.trim().isEmpty) return false; // Handle empty string
       if (text.contains('```')) return true; // Markdown code block
       final lines = text.split('\n');
       if (lines.length < 3) return false;
       int codeLikeLines = 0;
        for (var line in lines) {
         final trimmed = line.trim();
         if (trimmed.isEmpty) continue;

         // Check for common code patterns/symbols
         if (trimmed.contains(RegExp(r'[{}<>\(\)\[\];]'))) {
            codeLikeLines++;
         }
         if (RegExp(r'[=#$%^&*\-_+/:?@\\|~`]').allMatches(trimmed).length > 3) { // Count special chars
             codeLikeLines++;
         }
         if (trimmed.startsWith(RegExp(r'\s*(def|class|public|private|static|void|function|import|require|const|let|var|if|else|for|while|try|catch|@|\/\/|#)')) ||
            trimmed.endsWith(';') || trimmed.endsWith('{') || trimmed.endsWith('}') || trimmed.endsWith('/>'))
          {
            codeLikeLines++;
         }
      }
        return lines.isNotEmpty && (codeLikeLines / lines.length > 0.4); // Adjust threshold
  }
}