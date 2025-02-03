import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import 'widgets/code_builder.dart';
import 'utils/text_converter.dart';

class Markit extends StatelessWidget {
  final String data;

  const Markit({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final document = md.Document(
      extensionSet: md.ExtensionSet.commonMark,
      encodeHtml: false,
    );
    final nodes = document.parse(data);
    final String plainText =
        MarkdownTextConverter.convertNodesToPlainText(nodes);

    return Stack(
      children: [
        SelectableText(
          plainText,
          style: const TextStyle(
            color: Colors.transparent,
            height: 1.5,
          ),
        ),
        MarkdownBody(
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
              color: Colors.black,
            ),
            code: TextStyle(
              backgroundColor: Colors.grey[200],
              color: Colors.black87,
            ),
            codeblockDecoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            a: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.none,
            ),
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 1,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          builders: {
            'code': CodeElementBuilder(),
          },
        ),
      ],
    );
  }
}
