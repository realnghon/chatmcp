import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlighter/themes/github.dart';
import 'package:markdown/markdown.dart' as md;

import 'highlight_view.dart';
import 'mermaid_diagram_view.dart' show MermaidDiagramView;
import 'html_view.dart';

// 添加 Mermaid 语法高亮主题
final mermaidTheme = {
  'root': TextStyle(color: Colors.black, backgroundColor: Colors.white),
  'keyword':
      TextStyle(color: Colors.blue[800]), // 关键字如 sequenceDiagram, participant 等
  'title':
      TextStyle(color: Colors.purple[800], fontWeight: FontWeight.bold), // 标题
  'string': TextStyle(color: Colors.green[800]), // 字符串
  'number': TextStyle(color: Colors.orange[800]), // 数字
  'operator': TextStyle(color: Colors.red[800]), // 操作符如 -->>, --, ==
  'comment': TextStyle(color: Colors.grey), // 注释
};

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';
    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      if (lg.startsWith('language-')) {
        language = lg.substring(9);
      } else {
        language = lg;
      }
    }

    final bool isInline = element.attributes['class'] == null;

    if (isInline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          element.textContent,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      );
    }

    return _CodeBlock(
      code: element.textContent.trim(),
      language: language,
    );
  }
}

class _CodeBlock extends StatefulWidget {
  final String code;
  final String language;

  const _CodeBlock({
    required this.code,
    required this.language,
  });

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock>
    with AutomaticKeepAliveClientMixin {
  bool _isPreviewVisible = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('代码已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Widget previewWidget;

    bool supportPreview = false;
    if (widget.language == 'mermaid') {
      supportPreview = true;
      previewWidget = MermaidDiagramView(code: widget.code);
    } else if (widget.language == 'html') {
      supportPreview = true;
      previewWidget = HtmlView(html: widget.code);
    } else {
      supportPreview = false;
      previewWidget = HighlightView(
        widget.code,
        language: widget.language,
        theme: widget.language == 'mermaid' ? mermaidTheme : githubTheme,
        padding: const EdgeInsets.all(8),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部区域
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[70],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.language.isEmpty ? 'plain text' : widget.language,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: _copyToClipboard,
                      child: const Text(
                        'copy',
                        style: TextStyle(fontSize: 9, height: 1),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (supportPreview)
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPreviewVisible = !_isPreviewVisible;
                          });
                        },
                        child: Text(
                          _isPreviewVisible ? 'Code' : 'Preview',
                          style: const TextStyle(fontSize: 9, height: 1),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // 内容区域
          SizedBox(
            width: double.infinity,
            child: _isPreviewVisible
                ? previewWidget
                : HighlightView(
                    widget.code,
                    language: widget.language,
                    theme: widget.language == 'mermaid'
                        ? mermaidTheme
                        : githubTheme,
                    padding: const EdgeInsets.all(8),
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
