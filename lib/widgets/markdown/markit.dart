import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/code_builder.dart';
import 'package:ChatMcp/utils/color.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;

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
        'latex': LatexElementBuilder(),
        'code': CodeElementBuilder(),
      },
      extensionSet: md.ExtensionSet(
        [
          LatexBlockSyntax(),
          md.FencedCodeBlockSyntax(),
          BracketLatexBlockSyntax(),
        ],
        [
          LatexInlineSyntax(),
          md.CodeSyntax(),
          BracketLatexInlineSyntax(),
        ],
      ),
    );
  }
}

class BracketLatexBlockSyntax extends md.BlockSyntax {
  static final _pattern =
      RegExp(r'^\s*\\\[([\s\S]*?)\\\]\s*$', multiLine: true, dotAll: true);

  @override
  RegExp get pattern => _pattern;

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    final latex = match.group(1)!.trim();
    parser.advance();
    return md.Element('latex', [md.Text(latex)]);
  }

  @override
  bool canParse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    return match != null;
  }
}

class BracketLatexInlineSyntax extends md.InlineSyntax {
  BracketLatexInlineSyntax() : super(r'\\\[([\s\S]*?)\\\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element('latex', [md.Text(match.group(1)!.trim())]));
    return true;
  }
}
