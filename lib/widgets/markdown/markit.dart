import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/code_builder.dart';
import 'package:ChatMcp/utils/color.dart';

class Markit extends StatelessWidget {
  final String data;

  const Markit({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: false,
      onTapLink: (text, href, title) async {
        if (href != null) {
          if (href.startsWith('#')) {
            debugPrint('内部锚点链接: $href');
            return;
          }

          try {
            final uri = Uri.parse(href);
            if (!await launchUrl(uri)) {
              debugPrint('无法打开链接: $href');
            }
          } catch (e) {
            debugPrint('打开链接时出错: $e');
          }
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: AppColors.black,
        ),
        code: TextStyle(
          backgroundColor: AppColors.grey[200],
          color: AppColors.black87,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        a: const TextStyle(
          color: AppColors.blue,
          decoration: TextDecoration.none,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              width: 1,
              color: AppColors.grey,
            ),
          ),
        ),
      ),
      builders: {
        'code': CodeElementBuilder(),
      },
    );
  }
}
