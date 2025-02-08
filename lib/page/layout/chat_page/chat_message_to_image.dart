import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:ChatMcp/llm/model.dart';
import 'chat_message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ChatMcp/provider/provider_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ChatMcp/utils/platform.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

class ListViewToImageScreen extends StatefulWidget {
  final List<ChatMessage> messages;
  const ListViewToImageScreen({super.key, required this.messages});

  @override
  _ListViewToImageScreenState createState() => _ListViewToImageScreenState();
}

class _ListViewToImageScreenState extends State<ListViewToImageScreen> {
  final ScrollController _scrollController = ScrollController();
  final screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    List<List<ChatMessage>> groupedMessages = [];
    List<ChatMessage> currentGroup = [];

    for (var msg in widget.messages) {
      if (msg.role == MessageRole.user) {
        if (currentGroup.isNotEmpty) {
          groupedMessages.add(currentGroup);
          currentGroup = [];
        }
        currentGroup.add(msg);
        groupedMessages.add(currentGroup);
        currentGroup = [];
      } else {
        currentGroup.add(msg);
      }
    }

    if (currentGroup.isNotEmpty) {
      groupedMessages.add(currentGroup);
    }
    return Scaffold(
      backgroundColor: Colors.grey[300], // 设置背景色为浅灰色
      appBar: AppBar(
        title: Text('Share Chat Image'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.camera),
            onPressed: _captureListViewAsImage,
          ),
        ],
      ),
      body: Screenshot(
        controller: screenshotController,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false, // 完全禁用滚动条
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ProviderManager.chatProvider.activeChat?.title !=
                      null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Text(
                            ProviderManager.chatProvider.activeChat!.title!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Text(
                            "by ChatMcp",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                  ],
                  ...groupedMessages.map((group) {
                    return ChatUIMessage(
                      messages: group,
                      onRetry: (ChatMessage message) {},
                      onSwitch: (String messageId) {},
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _captureListViewAsImage() async {
    final BuildContext context = this.context;
    try {
      final List<Uint8List> imageParts = [];
      final viewportHeight = MediaQuery.of(context).size.height;

      if (_scrollController.position.maxScrollExtent <= viewportHeight * 0.2) {
        final image = await screenshotController.capture(
          pixelRatio: 3.0,
        );
        if (image != null) {
          imageParts.add(image);
        }
      } else {
        final scrollStep = (viewportHeight * 0.8).toInt();
        double currentScroll = 0;

        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(milliseconds: 200));

        while (true) {
          final image = await screenshotController.capture(
            pixelRatio: 3.0,
          );

          if (image != null) {
            imageParts.add(image);
          }

          if (currentScroll >=
              _scrollController.position.maxScrollExtent - scrollStep * 0.1) {
            break;
          }

          currentScroll += scrollStep;
          final nextScroll = currentScroll.clamp(
              0.0, _scrollController.position.maxScrollExtent);

          await _scrollController.animateTo(
            nextScroll,
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear,
          );

          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      if (imageParts.isEmpty) {
        Logger.root.severe('截图失败: 无法获取图片');
        return;
      }

      final firstImage = await ui.instantiateImageCodec(imageParts[0]);
      final firstFrame = await firstImage.getNextFrame();
      final width = firstFrame.image.width;
      final singleHeight = firstFrame.image.height.toDouble();
      final overlapHeight = singleHeight * 0.2; // 20%的重叠区域

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      double finalHeight = singleHeight; // 第一张图完整高度
      if (imageParts.length > 1) {
        finalHeight += (imageParts.length - 2) * (singleHeight - overlapHeight);
        finalHeight += singleHeight - overlapHeight;
      }

      canvas.drawImage(firstFrame.image, Offset.zero, Paint());
      double currentHeight = singleHeight - overlapHeight;

      for (int i = 1; i < imageParts.length; i++) {
        final codec = await ui.instantiateImageCodec(imageParts[i]);
        final frameInfo = await codec.getNextFrame();
        canvas.drawImage(frameInfo.image, Offset(0, currentHeight), Paint());
        if (i < imageParts.length - 1) {
          currentHeight += singleHeight - overlapHeight;
        } else {
          currentHeight += singleHeight;
        }
      }

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(
        width,
        finalHeight.toInt(),
      );
      final finalByteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List finalImageBytes = finalByteData!.buffer.asUint8List();

      if (kIsDesktop) {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: ProviderManager.chatProvider.activeChat?.title ??
              'Save chat image',
          fileName:
              'ChatMcp-${ProviderManager.chatProvider.activeChat?.title ?? DateTime.now().millisecondsSinceEpoch}.png',
          type: FileType.custom,
          allowedExtensions: ['png'],
        );
        if (path != null) {
          await io.File(path).writeAsBytes(finalImageBytes);
        }
      }

      if (kIsMobile) {
        final title =
            ProviderManager.chatProvider.activeChat?.title ?? 'Chat Image';
        final safeTitle = title
            .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
            .replaceAll(RegExp(r'\s+'), '_');

        final tempDir = await getTemporaryDirectory();
        final tempFile = io.File(
            '${tempDir.path}/ChatMcp_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(finalImageBytes);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: "ChatMcp $title",
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      Logger.root.severe('截图失败: $e');
    }
  }
}
