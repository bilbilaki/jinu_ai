// lib/presentation/widgets/dynamic_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For keyboard shortcuts

class DynamicInputField extends StatefulWidget {
  final bool isLoading;
  final Function(String) onSend;
  // Add future callbacks:
  // final VoidCallback? onRecordStart;
  // final VoidCallback? onFileUpload;

  const DynamicInputField({
    super.key,
    required this.isLoading,
    required this.onSend,
    // this.onRecordStart,
    // this.onFileUpload,
  });

  @override
  State<DynamicInputField> createState() => _DynamicInputFieldState();
}

class _DynamicInputFieldState extends State<DynamicInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateSendButtonVisibility);
     // Add listener for Shift+Enter for newline
    // This requires RawKeyboardListener or HardwareKeyboard if FocusNode isn't enough
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSendButtonVisibility);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateSendButtonVisibility() {
    if (mounted) {
      setState(() {
        _showSendButton = _controller.text.trim().isNotEmpty;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (!widget.isLoading && text.isNotEmpty) {
       widget.onSend(text);
      _controller.clear(); // Clear text after sending
      // Request focus back? Optional.
      // FocusScope.of(context).requestFocus(_focusNode);
    }
  }

   // Handles key events: Send on Enter (if not Shift+Enter)
   KeyEventResult _handleKeyEvent(RawKeyEvent event) {
     // Check for Enter press (without Shift)
     if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
        if (!event.isShiftPressed) { // Send if Shift is NOT pressed
            _handleSend();
            return KeyEventResult.handled; // Prevent default newline action
         }
         // Allow default newline if Shift IS pressed
          return KeyEventResult.ignored;
     }
     return KeyEventResult.ignored; // Ignore other keys
   }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener( // Listener for keyboard shortcuts
       focusNode: FocusNode(onKey: (_, event) => _handleKeyEvent(event)), // Use a temporary focus node for listener
       child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Adjust padding
          decoration: BoxDecoration(
              color: Colors.grey[850], // Input area background
              borderRadius: BorderRadius.circular(28.0),
              border: Border.all(color: _focusNode.hasFocus ? Theme.of(context).colorScheme.primary : Colors.grey[700]!, width: _focusNode.hasFocus ? 1.5 : 1.0) // Subtle border, highlight on focus
          ),
          child: Row(
             crossAxisAlignment: CrossAxisAlignment.end, // Align items to bottom
             children: [
             // Optional: File Upload Button
                // IconButton(
                 // icon: const Icon(Icons.add_circle_outline),
                 // onPressed: widget.isLoading ? null : () {/* TODO: Implement Upload */},
                 // tooltip: 'Add Image or File',
                 // color: Colors.grey[400],
                 // splashRadius: 20,
                // ),

             // Text Field
               Expanded(
                 child: ConstrainedBox( // Limit the vertical growth
                    constraints: BoxConstraints(
                       // Max height based on font size roughly (e.g., 10 lines)
                         maxHeight: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) * 10 + 40,
                      ),
                   child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                         hintText: 'Enter a prompt here (Shift+Enter for newline)',
                         hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                         border: InputBorder.none,
                         filled: false,
                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Adjust padding
                          isCollapsed: true, // Reduces intrinsic padding

                      ),
                      style: const TextStyle(fontSize: 15),
                      maxLines: null, // Allows multi-line input and growth
                      minLines: 1,
                      enabled: !widget.isLoading,
                      // textInputAction: TextInputAction.newline, // Let RawKeyboardListener handle Enter
                       keyboardType: TextInputType.multiline,
                      // Send on IME action button (mobile)
                      onSubmitted: (value) => _handleSend(),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                 ),
               ),

                 const SizedBox(width: 4), // Small gap

             // Dynamic Send/Record Button (or just Send)
              //  Consider if Record button is truly needed or just Send
               SizedBox( // Constrain button height
                   height: 44, // Match text field approx height
                   child: Center(
                         child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                             layoutBuilder: (currentChild, previousChildren) {
                                 return Stack(
                                    alignment: Alignment.center,
                                     children: <Widget>[
                                        ...previousChildren,
                                         if (currentChild != null) currentChild,
                                       ],
                                     );
                             },
                             transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                            child: _showSendButton
                               ? IconButton( // Send Button
                                   key: const ValueKey('send'),
                                   icon: Icon( widget.isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded, size: 20,),
                                   onPressed: widget.isLoading ? null : _handleSend,
                                   tooltip: 'Send Message (Enter)',
                                   color: Colors.blue[300],
                                   splashRadius: 20,
                                   padding: EdgeInsets.zero,
                                )
                                : IconButton( // Placeholder for Record or Upload? Or just disabled Send?
                                    key: const ValueKey('mic_or_disabled'),
                                     // Use mic icon if implementing recording later
                                    // icon: const Icon(Icons.mic_none_outlined, size: 20),
                                     // Use disabled send icon if no recording planned
                                      icon: Icon(Icons.send_rounded, size: 20, color: Colors.grey[600]),
                                    onPressed: null, // Disabled state
                                    tooltip: 'Enter a message to send', // Tooltip for disabled state
                                    color: Colors.grey[400],
                                    splashRadius: 20,
                                     padding: EdgeInsets.zero,
                                 ),
                         ),
                        ),
                 ),
             ],
           ),
         ),
      );
  }
}