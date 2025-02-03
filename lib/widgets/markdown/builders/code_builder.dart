import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlighter/themes/github.dart';
import 'package:markdown/markdown.dart' as md;

import '../widgets/highlight_view.dart';
import '../widgets/mermaid_diagram_view.dart' show MermaidDiagramView;
import '../widgets/html_view.dart';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Widget previewWidget;

    if (widget.language == 'mermaid' &&
        (widget.code.contains('sequenceDiagram') ||
            widget.code.contains('flowchart') ||
            widget.code.contains('classDiagram') ||
            widget.code.contains('stateDiagram') ||
            widget.code.contains('gantt') ||
            widget.code.contains('pie') ||
            widget.code.contains('erDiagram') ||
            widget.code.contains('journey'))) {
      previewWidget = MermaidDiagramView(code: widget.code);
    } else if (widget.language == 'html') {
      previewWidget = HtmlView(html: widget.code);
    } else {
      previewWidget = HighlightView(
        widget.code,
        language: widget.language,
        theme: githubTheme,
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
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isPreviewVisible
                ? previewWidget
                : Text(
                    widget.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isPreviewVisible = !_isPreviewVisible;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(204),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isPreviewVisible ? 'Code' : 'Preview',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
