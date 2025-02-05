import 'package:flutter/material.dart';

class UploadMenu extends StatelessWidget {
  final bool disabled;
  final VoidCallback onPickImages;
  final VoidCallback onPickFiles;

  const UploadMenu({
    super.key,
    required this.disabled,
    required this.onPickImages,
    required this.onPickFiles,
  });

  void _showUploadOptions(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final buttonSize = button.size;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

    final double menuWidth = 150.0;
    final double menuHeight = 96.0;

    final double left = buttonPosition.dx + (buttonSize.width - menuWidth) / 2;
    final double top = buttonPosition.dy - menuHeight - 4;

    final RelativeRect position = RelativeRect.fromLTRB(
      left,
      top,
      left + menuWidth,
      top + menuHeight,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              const Icon(Icons.image, size: 20),
              const SizedBox(width: 8),
              Text('从图库选择'),
            ],
          ),
          onTap: () => Future(() => onPickImages()),
        ),
        PopupMenuItem(
          child: Row(
            children: [
              const Icon(Icons.file_present, size: 20),
              const SizedBox(width: 8),
              Text('选择文件'),
            ],
          ),
          onTap: () => Future(() => onPickFiles()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.file_present_outlined),
      onPressed: disabled ? null : () => _showUploadOptions(context),
      tooltip: '上传文件',
    );
  }
}
