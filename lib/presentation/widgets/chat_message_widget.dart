// lib/presentation/widgets/chat_message_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_markdown/flutter_markdown.dart'; // For rendering markdown
import 'package:url_launcher/url_launcher.dart'; // To open links in markdown
// Import syntax highlighter if using code blocks
// import 'package:flutter_highlight/themes/github-dark.dart'; // Example theme
// import 'package:flutter_highlight/flutter_highlight.dart';
import '../../data/models/chat_message.dart';
// Import intl for date formatting if needed
// import 'package:intl/intl.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({super.key, required this.message});

  // Basic function to attempt launching URLs
  Future<void> _launchUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Handle inability to launch URL, maybe show a Snackbar
      debugPrint("Could not launch URL: $url");
    }
  }


  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final isAi = message.sender == MessageSender.ai;
    final isError = message.sender == MessageSender.system && message.metadata?['error'] == true;
    final theme = Theme.of(context);

    // Define colors based on sender type
    Color bubbleColor = isUser
        ? (theme.colorScheme.primaryContainer) // User message color
        : (isError
            ? Colors.red[900]!.withOpacity(0.8)
            : theme.cardColor); // AI or System message color (use cardColor for theme consistency)
    Color textColor = isUser
        ? theme.colorScheme.onPrimaryContainer
        : (isError ? Colors.red[100]! : theme.textTheme.bodyLarge?.color ?? Colors.white);


    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        margin: EdgeInsets.only( // Add more margin based on sender
            top: 5.0, bottom: 5.0,
            left: isUser ? 40.0 : 8.0, // Indent user messages more
            right: isUser ? 8.0 : 40.0 // Indent AI messages more
        ),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.80 // Limit message width further
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18.0).subtract(
            // Nicer bubble corners
            isUser
                ? const BorderRadius.only(bottomRight: Radius.circular(18), topRight: Radius.circular(5))
                : const BorderRadius.only(bottomLeft: Radius.circular(18), topLeft: Radius.circular(5)),
          ),
          // Subtle shadow for AI messages?
           boxShadow: isAi && theme.brightness == Brightness.light ? [
                BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: Offset(0, 1))
           ] : null,
           border: isError ? Border.all(color: Colors.red[400]!, width: 0.5) : null
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                 _buildContent(context, textColor), // Build content based on type

                  // Add Copy button for AI messages
                 if (isAi || isError)
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
                                      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
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


  Widget _buildContent(BuildContext context, Color textColor) {
    switch (message.contentType) {
      case ContentType.text:
      case ContentType.image: // Render text part of image messages too
      case ContentType.audio: // Render text part of audio message if applicable
        final bool isCodeDominant = _isLikelyCode(message.content);
        // Use MarkdownBody for rich text rendering from AI/System
        return MarkdownBody(
          data: message.content,
          selectable: true, // Allow text selection
          onTapLink: (text, href, title) {
            if (href != null) {
              _launchUrl(href);
            }
          },
           styleSheetTheme: isCodeDominant
              ? MarkdownStyleSheetBaseTheme.platform // Minimal theme for code-heavy blocks
              : MarkdownStyleSheetBaseTheme.cupertino, // Use cupertino/material adapts better
           styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor, fontSize: 15), // Base text style
               h1: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600),
               h2: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600),
               h3: Theme.of(context).textTheme.titleSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600),
               code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                   fontFamily: 'monospace', // Use monospace for inline code
                   fontSize: 13.5,
                   backgroundColor: textColor.withOpacity(0.1), // Subtle background
                   color: textColor, // Ensure inline code color matches
                ),
                // Customize code blocks
                codeblockDecoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.4), // Darker background for code blocks
                   borderRadius: BorderRadius.circular(6),
                   border: Border.all(color: Colors.grey[700]!)
               ),
               codeblockPadding: const EdgeInsets.all(12),
               // Blockquote styling
                blockquoteDecoration: BoxDecoration(
                    color: textColor.withOpacity(0.05),
                    border: Border(left: BorderSide(color: textColor.withOpacity(0.3), width: 3)),
               ),
                 blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               // List styling
                 listBulletPadding: const EdgeInsets.only(left: 4, right: 6),
               // Table styling
                 tableBorder: TableBorder.all(color: textColor.withOpacity(0.3), width: 0.8),
                
                 tableHeadAlign: TextAlign.center,
                 tableColumnWidth: const MaxColumnWidth(FixedColumnWidth(100), IntrinsicColumnWidth()),
             ),
             // --- Code Syntax Highlighting (Optional) ---
             // Requires flutter_highlight package
             // builder: (context, child) {
               // return HighlightView(
                  // child.toPlainText(), // Extract text for highlighting
                   // language: 'plaintext', // Detect language automatically? (can be slow)
                   // theme: githubDarkTheme, // Choose a theme
                    // padding: const EdgeInsets.all(12),
                   // textStyle: TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.grey[300]),
                // );
             // },
             // syntaxHighlighter: YourSyntaxHighlighterImplementation(), // If using custom highlighter
        );

      // Original ContentType specific handling (keep if you want different placeholders)
      // case ContentType.image:
      //   // Placeholder for Image display
      //   // ... (As before) ...
      // case ContentType.audio:
      //   // Placeholder for Audio Player
      //   // ... (As before) ...
    }
  }

   // Simple heuristic to check if the content is mostly code
   bool _isLikelyCode(String text) {
       if (text.contains('```')) return true; // Markdown code block
       final lines = text.split('\n');
       if (lines.length < 3) return false; // Too short to be significant code block usually
       int codeLikeLines = 0;
       for (var line in lines) {
             final trimmed = line.trim();
             if (trimmed.startsWith(RegExp(r'[#/{<\[\*\-+]')) || trimmed.endsWith(RegExp(r'[;\]}>]').toString()) || trimmed.contains('=>') || trimmed.contains(' = ')) {
               codeLikeLines++;
           }
         }
        // If more than 50% of lines look like code, assume it is
       return lines.isNotEmpty && (codeLikeLines / lines.length > 0.5);
     }
}

// --- Add Syntax Highlighter Implementation if needed ---
// import 'package:highlight/highlight.dart' show highlight;
// import 'package:flutter_markdown/flutter_markdown.dart';
//
// class CodeSyntaxHighlighter extends SyntaxHighlighter {
//   @override
//   TextSpan format(String source) {
//     // TODO: Implement language detection or get from markdown attributes
//     String language = 'plaintext'; // Default
//     final result = highlight.parse(source, language: language, autoDetection: true);
//     return TextSpan(
//           style: const TextStyle(fontFamily: 'monospace', fontSize: 13.5, color: Colors.white), // Base style
//          children: _convertNodes(result.nodes),
//      );
//   }
//
//   List<TextSpan> _convertNodes(List<highlight.Node>? nodes) {
//    List<TextSpan> spans = [];
//     // TODO: Convert highlight.js nodes to TextSpans with appropriate styles
//     // This requires mapping highlight.js class names to Flutter TextStyle
//     // See flutter_highlight package for examples.
//      return spans;
//   }
// }