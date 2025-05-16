// lib/presentation/widgets/chat_message_widget.dart
import 'dart:async' show StreamSubscription;
import 'dart:io'; // For File operations
import 'dart:math';

// import 'package:audioplayers/audioplayers.dart'; // Audio player
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinu/presentation/providers/file_service_provider.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:intl/intl.dart'; // For date formatting if needed

import '../../data/models/chat_message.dart';
import '../../data/models/file_model.dart'; // For FileModel if used by fileService

class ChatMessageWidget extends ConsumerStatefulWidget {
  final ChatMessage message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  ConsumerState<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends ConsumerState<ChatMessageWidget> {
  /*
  // --- Audio Player State ---
  
  AudioPlayer? _audioPlayer; // Nullable, initialized if needed
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;
  StreamSubscription? _playerErrorSubscription;
  
  bool get _isPlaying => _playerState == PlayerState.playing;
  
  @override
  void initState() {
  super.initState();
  if (widget.message.contentType == ContentType.audio) {
  _audioPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  _playerState = PlayerState.stopped; // Initial state
  
  _playerStateChangeSubscription =
  _audioPlayer!.onPlayerStateChanged.listen((state) {
  if (mounted) setState(() => _playerState = state);
  }, onError: (msg) {
  debugPrint('Audio Player State Error: $msg');
  if (mounted) {
  setState(() => _playerState = PlayerState.stopped);
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Audio player error: $msg')),
  );
  }
  });
  
  _durationSubscription = _audioPlayer!.onDurationChanged.listen((duration) {
  if (mounted) setState(() => _duration = duration);
  });
  
  _positionSubscription = _audioPlayer!.onPositionChanged.listen((p) {
  if (mounted) setState(() => _position = p);
  });
  
  _playerCompleteSubscription =
  _audioPlayer!.onPlayerComplete.listen((event) {
  if (mounted) {
  setState(() {
  _playerState = PlayerState.completed;
  _position = Duration.zero;
  });
  }
  });
  _initAudioSource();
  }
  }
  
  Future<void> _initAudioSource() async {
  if (_audioPlayer == null || widget.message.contentType != ContentType.audio) return;
  
  Source? source;
  if (widget.message.filePath != null && widget.message.filePath!.isNotEmpty) {
  final file = File(widget.message.filePath!);
  if (await file.exists()) {
  source = DeviceFileSource(widget.message.filePath!);
  } else {
  debugPrint("Audio file not found at local path: ${widget.message.filePath}");
  }
  } else if (widget.message.fileUrl != null && widget.message.fileUrl!.isNotEmpty) {
  source = UrlSource(widget.message.fileUrl!);
  }
  
  if (source != null) {
  try {
  await _audioPlayer!.setSource(source);
  debugPrint("Audio source set for message: ${widget.message.id}");
  } catch (e) {
  debugPrint("Error setting audio source for ${widget.message.id}: $e");
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Error loading audio: ${e.toString().substring(0,min(e.toString().length, 50))}...')),
  );
  }
  }
  } else {
  debugPrint("No valid audio source found for message: ${widget.message.id}");
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Audio source not available.')),
  );
  }
  }
  }
  
  @override
  void dispose() {
  _durationSubscription?.cancel();
  _positionSubscription?.cancel();
  _playerCompleteSubscription?.cancel();
  _playerStateChangeSubscription?.cancel();
  _playerErrorSubscription?.cancel();
  _audioPlayer?.dispose(); // Dispose player only if it was created
  super.dispose();
  }
  
  Future<void> _play() async {
  if (_audioPlayer == null) return;
  if (_audioPlayer!.source == null) {
  debugPrint("Attempted to play but source is null for ${widget.message.id}. Initializing...");
  await _initAudioSource();
  if (_audioPlayer!.source == null) {
  debugPrint("Failed to initialize source on play for ${widget.message.id}.");
  if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot play audio: Source unavailable.')));
  return;
  }
  }
  try {
  await _audioPlayer!.resume();
  // setState is called by the onPlayerStateChanged listener
  } catch (e) {
  debugPrint("Error playing audio for ${widget.message.id}: $e");
  if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
  }
  }
  
  Future<void> _pause() async {
  if (_audioPlayer == null) return;
  try {
  await _audioPlayer!.pause();
  } catch (e) {
  debugPrint("Error pausing audio for ${widget.message.id}: $e");
  if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error pausing audio: $e')));
  }
  }
  
  Future<void> _seek(Duration position) async {
  if (_audioPlayer == null) return;
  try {
  await _audioPlayer!.seek(position);
  } catch (e) {
  debugPrint("Error seeking audio for ${widget.message.id}: $e");
  }
  }
  */

  Future<void> _saveFile() async {
    final fileService = ref.read(fileServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String? sourcePath = widget.message.filePath;
    String? sourceUrl = widget.message.fileUrl;
    String defaultFileName = widget.message.fileName ??
        'downloaded_file_${widget.message.id.substring(0, 8)}';

    File? sourceFile;

    if (sourcePath != null && sourcePath.isNotEmpty) {
      sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Error: Local file not found.')));
        return;
      }
    } else if (sourceUrl != null && sourceUrl.isNotEmpty) {
      // Implement download from URL then save
      // This is a more complex operation usually involving http package and progress indication
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Downloading from URL and saving is not yet fully implemented.')));
      // Placeholder:
      // try {
      //   File downloadedFile = await fileService.downloadFile(sourceUrl, defaultFileName);
      //   sourceFile = downloadedFile;
      // } catch (e) {
      //   scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to download file: $e')));
      //   return;
      // }
      return; // For now, prevent proceeding if only URL exists until download is implemented
    } else {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Error: No file source available to save.')));
      return;
    }

    if (sourceFile == null) { // Should have been caught above, but as a safeguard
         scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Error: File source is null.')));
         return;
    }

    try {
      String? savedPath;
      if (widget.message.contentType == ContentType.image && (Platform.isAndroid || Platform.isIOS)) {
        // Example: savedPath = await fileService.saveImageToGallery(sourceFile);
        // Falling back to general save for simplicity now
        savedPath = await fileService.saveFileToAppDirectory(FileModel.fromFile(sourceFile), defaultFileName);
      } else {
        savedPath = await fileService.saveFileToAppDirectory(FileModel.fromFile(sourceFile), defaultFileName);
      }

      if (savedPath != null) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('File saved to $savedPath')));
      } else {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to save file.')));
      }
    } catch (e) {
      debugPrint("Error saving file: $e");
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving file: $e')));
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not launch URL: $url");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $url')));
      }
    } else {
       debugPrint("Invalid URL format: $url");
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid link format: $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isUser = message.sender == MessageSender.user;
    final isAi = message.sender == MessageSender.ai;
    final isSystemError = message.sender == MessageSender.system && message.metadata?['error'] == true;

    final Brightness brightness = Theme.of(context).brightness;
    final bool isDarkTheme = brightness == Brightness.dark;

    Color bubbleColor;
    Color textColor;

    if (isUser) {
      bubbleColor = isDarkTheme ? Colors.blueGrey[700]! : Theme.of(context).colorScheme.primary;
      textColor = isDarkTheme ? Colors.white : Theme.of(context).colorScheme.onPrimary;
    } else if (isSystemError) {
      bubbleColor = isDarkTheme ? Colors.red[800]! : Colors.red[100]!;
      textColor = isDarkTheme ? Colors.red[100]! : Colors.red[900]!;
    } else { // AI or non-error System
      bubbleColor = isDarkTheme ? Colors.grey[800]! : Colors.grey[200]!;
      textColor = isDarkTheme ? Colors.grey[200]! : Colors.black87;
    }

    // Special background for AI file messages for better distinction
    if (isAi && message.isFileBased) {
       bubbleColor = isDarkTheme ? Colors.grey[700]!.withOpacity(0.9) : Colors.blueGrey[50]!;
    }


    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        margin: EdgeInsets.only(
          top: 6.0, bottom: 6.0,
          left: isUser ? (MediaQuery.of(context).size.width * 0.15) : 10.0, // More margin for user to push left
          right: isUser ? 10.0 : (MediaQuery.of(context).size.width * 0.15), // More margin for AI to push right
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Max width of bubble
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18.0),
            topRight: const Radius.circular(18.0),
            bottomLeft: isUser ? const Radius.circular(18.0) : const Radius.circular(4.0),
            bottomRight: isUser ? const Radius.circular(4.0) : const Radius.circular(18.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkTheme ? 0.15 : 0.08),
              spreadRadius: 0.5,
              blurRadius: 3,
              offset: const Offset(0, 1.5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContent(context, textColor),
            _buildActionButtons(context, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color textColor) {
    final message = widget.message;
    final isUser = message.sender == MessageSender.user;
    final isSystemError = message.sender == MessageSender.system && message.metadata?['error'] == true;

    // No action buttons for user messages or system errors for now
    if (isUser || isSystemError) return const SizedBox.shrink();

    bool canSave = message.isFileBased && (message.filePath != null || message.fileUrl != null);
    bool canCopy = message.content.isNotEmpty;

    if (!canSave && !canCopy) return const SizedBox.shrink();


    return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min, // Important for Row within Column
          children: [
            if (canSave)
              _MessageActionButton(
                icon: Icons.save_alt_outlined,
                tooltip: "Save File",
                color: textColor.withOpacity(0.8),
                onPressed: _saveFile,
              ),
            if (canCopy) ...[
              if(canSave) const SizedBox(width: 8), // spacing if both buttons are present
              _MessageActionButton(
                icon: Icons.copy_all_outlined,
                tooltip: "Copy Text",
                color: textColor.withOpacity(0.8),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied text to clipboard'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ]
          ],
        ),
      );
  }


  Widget _buildContent(BuildContext context, Color textColor) {
    switch (widget.message.contentType) {
      case ContentType.image:
        return _buildImageContent(context, widget.message, textColor);
      case ContentType.audio:
      // return _buildAudioContent(context, widget.message, textColor);
      return _buildTextContent(context, widget.message.copyWith(content: "[Audio content removed]"), textColor); // Placeholder
      case ContentType.file:
        return _buildFilePlaceholderContent(context, widget.message, textColor);
      case ContentType.text:
      default:
        return _buildTextContent(context, widget.message, textColor);
    }
  }

  Widget _buildTextContent(BuildContext context, ChatMessage message, Color textColor) {
    if (message.content.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final bool isCodeDominant = _isLikelyCode(message.content);
     final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;


    return MarkdownBody(
      data: message.content,
      selectable: true,
      softLineBreak: true, // Ensure soft line breaks work as expected
      onTapLink: (text, href, title) {
        if (href != null) _launchUrl(href);
      },
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor, fontSize: 15, height: 1.4),
        a: TextStyle(color: isDarkTheme ? Colors.blue[300] : Colors.blue[700], decoration: TextDecoration.underline),
        code: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontSize: 13.0, // Slightly smaller for better density
          backgroundColor: textColor.withOpacity(0.08),
          color: textColor.withOpacity(0.9),
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.black.withOpacity(isDarkTheme ? 0.4 : 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.withOpacity(isDarkTheme ? 0.5 : 0.2)),
      //    padding: const EdgeInsets.all(10),
        ),
        blockquoteDecoration: BoxDecoration(
          color: textColor.withOpacity(0.05),
          border: Border(left: BorderSide(color: textColor.withOpacity(0.3), width: 3)),
  //        padding: const EdgeInsets.symmetric(horizontal:12, vertical: 6)
        ),
        h1: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 20),
        h2: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 18),
        h3: Theme.of(context).textTheme.titleSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
        listBullet: TextStyle(color: textColor, fontSize: 15),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(width: 1.0, color: textColor.withOpacity(0.3)))
        )
      ),
      // syntaxHighlighter: DartSyntaxHighlighter(SyntaxTheme.dracula()), // Example if using a highlighter
    );
  }

  Widget _buildImageContent(BuildContext context, ChatMessage message, Color textColor) {
    Widget imageDisplayWidget;
    final imageFile = message.filePath != null ? File(message.filePath!) : null;
    final imageUrl = message.fileUrl;
    bool hasLocalFile = imageFile != null && imageFile.existsSync();

    if (hasLocalFile) {
      imageDisplayWidget = Image.file(imageFile!, fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildMediaErrorPlaceholder(Icons.broken_image_outlined, "Cannot display image")
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageDisplayWidget = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2.5, color: textColor.withOpacity(0.7)
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildMediaErrorPlaceholder(Icons.broken_image_outlined, "Failed to load image");
        },
      );
    } else {
      imageDisplayWidget = _buildMediaErrorPlaceholder(Icons.image_not_supported_outlined, "Image not available");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.content.isNotEmpty && message.content != "[User sent an image: ${message.fileName}]"  && message.content != "[Sent Image]") ...[ // Avoid redundant default text
          _buildTextContent(context, message.copyWith(contentType: ContentType.text), textColor), // Render as text
          const SizedBox(height: 8),
        ],
        Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4), // Limit image height
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: imageDisplayWidget,
          ),
        ),
        if (message.fileName != null && message.fileName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              message.fileName!,
              style: TextStyle(fontSize: 11.5, color: textColor.withOpacity(0.75)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /*
  /*
  Widget _buildAudioContent(BuildContext context, ChatMessage message, Color textColor) {
  final currentPosition = _position ?? Duration.zero;
  final totalDuration = _duration ?? Duration.zero;
  final bool isAudioLoading = _playerState == null || (_playerState == PlayerState.stopped && totalDuration == Duration.zero && _audioPlayer?.source != null);
  final String durationText = totalDuration != Duration.zero
  ? "${_formatDuration(currentPosition)} / ${_formatDuration(totalDuration)}"
  : (isAudioLoading ? "Loading..." : "--:-- / --:--");
  
  return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [
  if (message.content.isNotEmpty && message.content != "[User sent audio: ${message.fileName}]" && message.content != "[Sent Audio]") ...[ // Avoid redundant text
  _buildTextContent(context, message.copyWith(contentType: ContentType.text), textColor),
  const SizedBox(height: 8),
  ],
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  decoration: BoxDecoration(
  color: textColor.withOpacity(0.07),
  borderRadius: BorderRadius.circular(25),
  ),
  child: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
  IconButton(
  icon: isAudioLoading
  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
  : Icon(
  _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
  size: 30.0,
  color: textColor,
  ),
  onPressed: (_audioPlayer?.source == null && !isAudioLoading) ? null : (_isPlaying ? _pause : _play), // Disable if no source and not loading
  tooltip: _isPlaying ? 'Pause' : (isAudioLoading? 'Loading audio' : 'Play'),
  padding: const EdgeInsets.all(4), // Smaller padding
  visualDensity: VisualDensity.compact,
  ),
  const SizedBox(width: 4),
  Expanded(
  child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
  if (!isAudioLoading && totalDuration > Duration.zero)
  SliderTheme(
  data: SliderTheme.of(context).copyWith(
  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
  trackHeight: 2.5,
  activeTrackColor: textColor.withOpacity(0.85),
  inactiveTrackColor: textColor.withOpacity(0.35),
  thumbColor: textColor,
  overlayColor: textColor.withOpacity(0.25),
  ),
  child: Slider(
  value: (totalDuration.inMicroseconds > 0
  ? currentPosition.inMicroseconds.clamp(0, totalDuration.inMicroseconds).toDouble() / totalDuration.inMicroseconds
  : 0.0),
  min: 0.0,
  max: 1.0,
  onChanged: (value) {
  final newPosition = totalDuration * value;
  _seek(newPosition);
  },
  ),
  )
  else
  const SizedBox(height: 18), // Placeholder for slider height
  Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8.0),
  child: Text(
  durationText,
  style: TextStyle(fontSize: 11.0, color: textColor.withOpacity(0.8)),
  textAlign: TextAlign.right,
  ),
  ),
  ],
  ),
  ),
  ],
  ),
  ),
  if (message.fileName != null && message.fileName!.isNotEmpty)
  Padding(
  padding: const EdgeInsets.only(top: 6.0, left: 4.0),
  child: Text(
  message.fileName!,
  style: TextStyle(fontSize: 11.5, color: textColor.withOpacity(0.75)),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  ),
  ),
  ],
  );
  }
  */
  */

  Widget _buildFilePlaceholderContent(BuildContext context, ChatMessage message, Color textColor) {
    IconData fileIcon = Icons.insert_drive_file_outlined;
    final mime = message.mimeType?.toLowerCase();
    if (mime != null) {
      if (mime.startsWith('application/pdf')) fileIcon = Icons.picture_as_pdf_rounded;
      else if (mime.startsWith('application/vnd.openxmlformats-officedocument.wordprocessingml') || mime.startsWith('application/msword')) fileIcon = Icons.description_rounded;
      else if (mime.startsWith('application/vnd.openxmlformats-officedocument.spreadsheetml') || mime.startsWith('application/vnd.ms-excel')) fileIcon = Icons.calculate_rounded;
      else if (mime.startsWith('application/zip') || mime.startsWith('application/x-zip-compressed')) fileIcon = Icons.folder_zip_outlined;
      else if (mime.startsWith('text/')) fileIcon = Icons.article_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.content.isNotEmpty && message.content != "[User sent a file: ${message.fileName}]") ...[ // Avoid redundant text
           _buildTextContent(context, message.copyWith(contentType: ContentType.text), textColor),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: textColor.withOpacity(0.15), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(fileIcon, color: textColor.withOpacity(0.85), size: 30),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.fileName ?? "Attached File",
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 14.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (message.fileSize != null && message.fileSize! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          _formatFileSize(message.fileSize!),
                          style: TextStyle(fontSize: 11.5, color: textColor.withOpacity(0.7)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMediaErrorPlaceholder(IconData icon, String text) {
    return Container(
      height: 100, // Standard height for error placeholder
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[600], size: 36),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [
      if (hours > 0) hours.toString(),
      minutes,
      seconds,
    ].join(':');
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  bool _isLikelyCode(String text) {
    if (text.trim().isEmpty) return false;
    if (text.contains('```')) return true; // Markdown code block
    
    final lines = text.split('\n');
    if (lines.length < 2 && text.length < 50) return false; // Too short to be primarily code
    
    int codeChars = 0;
    int nonWhitespaceChars = 0;
    
    for (var charCode in text.runes) {
      final char = String.fromCharCode(charCode);
      if (char.trim().isNotEmpty) {
        nonWhitespaceChars++;
        // Common code characters (simplistic check)
        if ('{}[]()<>;:#!/+-*=&|^%@.,'.contains(char) || (char.toUpperCase() != char.toLowerCase() && char == char.toUpperCase() && char != 'I' && char != 'A')) { // Heuristic for uppercase variables etc.
          codeChars++;
        } else if (RegExp(r'[0-9]').hasMatch(char)) {
           codeChars++; // Count digits as potentially code-like
        }
      }
    }

    if (nonWhitespaceChars == 0) return false;
    
    // If more than N% of non-whitespace characters are code-like, or if many lines start with typical code indents/keywords
    double codeCharRatio = codeChars / nonWhitespaceChars;

    int structuredLines = 0;
    if (lines.length > 1) {
        for(var line in lines) {
            final trimmedLine = line.trim();
            if(trimmedLine.startsWith(RegExp(r'^(def|class|public|private|static|fn|func|function|import|from|require|const|let|var|if|else|for|while|try|catch|@|\/\/|#|\*|\s{2,})')) ||
               RegExp(r'[{};:]$').hasMatch(trimmedLine) ||
               (trimmedLine.contains('=>') && !trimmedLine.contains(' '))) { // Arrow functions
                structuredLines++;
            }
        }
    }
    double structuredLineRatio = lines.isEmpty ? 0 : structuredLines / lines.length;

    return codeCharRatio > 0.3 || structuredLineRatio > 0.3; // Adjust thresholds as needed
  }
}

class _MessageActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  const _MessageActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      padding: const EdgeInsets.all(6.0), // Reduced padding
      constraints: const BoxConstraints(), // Compact
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      onPressed: onPressed,
    );
  }
}

// Helper to allow modifying ChatMessage content type for rendering a part of message as text.
// This is a simplified version. For robust state management, consider immutable patterns or custom classes.
extension ChatMessageCopyWith on ChatMessage {
    ChatMessage copyWith({
        String? id,
        MessageSender? sender,
        String? content,
        DateTime? timestamp,
        ContentType? contentType,
        String? filePath,
        String? fileUrl,
        String? fileName,
        int? fileSize,
        String? mimeType,
        Map<String, dynamic>? metadata,
    }) {
        return ChatMessage(
            id: id ?? this.id,
            sender: sender ?? this.sender,
            content: content ?? this.content,
            timestamp: timestamp ?? this.timestamp,
            contentType: contentType ?? this.contentType,
            filePath: filePath ?? this.filePath,
            fileUrl: fileUrl ?? this.fileUrl,
            fileName: fileName ?? this.fileName,
            fileSize: fileSize ?? this.fileSize,
            mimeType: mimeType ?? this.mimeType,
            metadata: metadata ?? this.metadata,
        );
    }
}