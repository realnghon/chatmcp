import 'package:flutter/material.dart';
import 'package:highlighter/highlighter.dart' show highlight, Node, Mode;

// 添加 Mermaid 语法规则
final mermaidMode = Mode(
  refs: {},
  contains: [
    Mode(
      className: 'keyword',
      begin:
          r'\b(sequenceDiagram|participant|actor|note|over|right of|left of|loop|alt|else|opt|par|and|rect|end|flowchart|subgraph|class|classDiagram|stateDiagram|state|gantt|pie|erDiagram|journey)\b',
    ),
    Mode(
      className: 'operator',
      begin: r'(-->|->|-->>|==|--)',
    ),
    Mode(
      className: 'string',
      begin: '"',
      end: '"',
    ),
    Mode(
      className: 'title',
      begin: r'title\s+',
      end: r'\n',
    ),
    Mode(
      className: 'comment',
      begin: r'%% ',
      end: r'\n',
    ),
  ],
);

// 注册 Mermaid 语法模式
void _registerMermaidMode() {
  highlight.registerLanguage('mermaid', mermaidMode);
}

class HighlightView extends StatelessWidget {
  static bool _mermaidModeRegistered = false;

  final String source;
  final String? language;
  final Map<String, TextStyle> theme;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  static const _rootKey = 'root';
  static const _defaultFontColor = Color(0xff000000);
  static const _defaultBackgroundColor = Color(0xffffffff);
  static const _defaultFontFamily = 'monospace';

  HighlightView(
    String input, {
    super.key,
    this.language,
    this.theme = const {},
    this.padding,
    this.textStyle,
    int tabSize = 8,
  }) : source = input.replaceAll('\t', ' ' * tabSize) {
    if (!_mermaidModeRegistered) {
      _registerMermaidMode();
      _mermaidModeRegistered = true;
    }
  }

  List<TextSpan> _convert(List<Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(text: node.value, style: theme[node.className!]));
      } else if (node.children != null) {
        List<TextSpan> tmp = [];
        currentSpans
            .add(TextSpan(children: tmp, style: theme[node.className!]));
        stack.add(currentSpans);
        currentSpans = tmp;

        for (var n in node.children!) {
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      traverse(node);
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    var textStyle = TextStyle(
      fontFamily: _defaultFontFamily,
      color: theme[_rootKey]?.color ?? _defaultFontColor,
    );
    textStyle = textStyle.merge(this.textStyle);

    return Container(
      color: theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor,
      padding: padding,
      child: SelectableText.rich(
        TextSpan(
          style: textStyle,
          children:
              _convert(highlight.parse(source, language: language).nodes!),
        ),
      ),
    );
  }
}
