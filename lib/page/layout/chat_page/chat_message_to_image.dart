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
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
      body: Container(
        child: Screenshot(
          controller: screenshotController,
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

      // 获取总高度和视口高度
      final totalHeight = _scrollController.position.maxScrollExtent +
          MediaQuery.of(context).size.height;
      final viewportHeight = MediaQuery.of(context).size.height;

      // 如果内容高度小于或等于视口高度，只需要截取一次
      if (_scrollController.position.maxScrollExtent <= 0) {
        final image = await screenshotController.capture(
          pixelRatio: 3.0,
        );
        if (image != null) {
          imageParts.add(image);
        }
      } else {
        // 设置每次滚动的高度为视口高度的80%，确保有20%的重叠区域
        final scrollStep = (viewportHeight * 0.8).toInt();
        double currentScroll = 0;

        // 先滚动到顶部
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(milliseconds: 200));

        while (true) {
          // 截取当前视图
          final image = await screenshotController.capture(
            pixelRatio: 3.0,
          );

          if (image != null) {
            imageParts.add(image);
          }

          // 如果已经到达底部，退出循环
          if (currentScroll >= _scrollController.position.maxScrollExtent) {
            break;
          }

          // 计算下一次滚动的位置
          currentScroll += scrollStep;
          // 确保最后一次滚动不会超出范围
          final nextScroll = currentScroll.clamp(
              0.0, _scrollController.position.maxScrollExtent);

          await _scrollController.animateTo(
            nextScroll,
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear,
          );

          // 等待滚动和重绘完成
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      if (imageParts.isEmpty) {
        print('截图失败: 无法获取图片');
        return;
      }

      // 拼接图片
      final firstImage = await ui.instantiateImageCodec(imageParts[0]);
      final firstFrame = await firstImage.getNextFrame();
      final width = firstFrame.image.width;
      final singleHeight = firstFrame.image.height.toDouble();
      final overlapHeight = singleHeight * 0.2; // 20%的重叠区域

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 计算最终高度（考虑重叠区域）
      double finalHeight = singleHeight; // 第一张图完整高度
      if (imageParts.length > 1) {
        // 中间的图片每张减去重叠区域
        finalHeight += (imageParts.length - 2) * (singleHeight - overlapHeight);
        // 最后一张图片完整添加
        finalHeight += singleHeight - overlapHeight;
      }

      // 第一张图完整绘制
      canvas.drawImage(firstFrame.image, Offset.zero, Paint());
      double currentHeight = singleHeight - overlapHeight;

      // 从第二张图开始，每次跳过重叠区域
      for (int i = 1; i < imageParts.length; i++) {
        final codec = await ui.instantiateImageCodec(imageParts[i]);
        final frameInfo = await codec.getNextFrame();
        canvas.drawImage(frameInfo.image, Offset(0, currentHeight), Paint());
        // 如果不是最后一张图片，才减去重叠区域
        if (i < imageParts.length - 1) {
          currentHeight += singleHeight - overlapHeight;
        } else {
          // 最后一张图片完整显示
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

      // 保存或分享
      if (kIsDesktop) {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: ProviderManager.chatProvider.activeChat?.title ??
              'Save chat image',
          fileName:
              'chat-${ProviderManager.chatProvider.activeChat?.title ?? DateTime.now().millisecondsSinceEpoch}.png',
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
        final tempDir = await getTemporaryDirectory();
        final tempFile =
            io.File('${tempDir.path}/${title.replaceAll(' ', '_')}.png');
        await tempFile.writeAsBytes(finalImageBytes);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: title,
          // text: title,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }

      print('图片已保存');
    } catch (e) {
      print('截图失败: $e');
    }
  }
}
