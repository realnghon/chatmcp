import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputArea extends StatelessWidget {
  final TextEditingController textController;
  final bool isComposing;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<String> onSubmitted;

  const InputArea({
    super.key,
    required this.textController,
    required this.isComposing,
    required this.onTextChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        HardwareKeyboard.instance.isShiftPressed &&
                        isComposing) {
                      onSubmitted(textController.text);
                      textController.clear();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: textController,
                    onChanged: onTextChanged,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 14.0),
                    scrollPhysics: const BouncingScrollPhysics(),
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      hintStyle: TextStyle(fontSize: 14.0),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: isComposing
                    ? () {
                        onSubmitted(textController.text);
                        textController.clear();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
