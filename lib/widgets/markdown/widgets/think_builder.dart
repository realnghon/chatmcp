import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:markdown_widget/markdown_widget.dart';

import '../markit_widget.dart';

class ThinkElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final textContent = element.textContent;
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                '思考',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            textContent,
            style: preferredStyle ??
                const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
          ),
        ],
      ),
    );
  }
}

class ThinkInlineSyntax extends md.InlineSyntax {
  ThinkInlineSyntax()
      : super(r'<think>([^<]*)(?:</think>)*', caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match[1]!.trim();
    final element = md.Element('think', [md.Text(content)]);
    element.attributes['content'] = content;
    element.attributes['isInline'] = 'true';
    if (match.input.endsWith('</think>')) {
      element.attributes['closed'] = 'true';
    }
    parser.addNode(element);
    return true;
  }
}

class ThinkBlockSyntax extends md.BlockSyntax {
  static final _startPattern = RegExp(r'^<think>$');
  static final _endPattern = RegExp(r'^</think>$');

  @override
  RegExp get pattern => _startPattern;

  @override
  bool canParse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    return match != null;
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final lines = <String>[];
    parser.advance(); // Skip the opening tag

    bool isClosed = false;
    while (!parser.isDone) {
      final line = parser.current.content;
      if (_endPattern.hasMatch(line)) {
        isClosed = true;
        parser.advance();
        break;
      }
      lines.add(line);
      parser.advance();
    }

    final content = lines.join('\n');
    md.Element el = md.Element.text(_thinkTag, content);
    el.attributes['content'] = content;
    el.attributes['isInline'] = 'false';
    el.attributes['closed'] = isClosed ? 'true' : 'false';
    return el;
  }
}

SpanNodeGeneratorWithTag thinkGenerator = SpanNodeGeneratorWithTag(
    tag: _thinkTag,
    generator: (e, config, visitor) =>
        ThinkNode(e.attributes, e.textContent, config));

const _thinkTag = 'think';

class ThinkNode extends SpanNode {
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;

  ThinkNode(this.attributes, this.textContent, this.config);

  @override
  InlineSpan build() {
    bool isClosed = attributes['closed'] == 'true';

    return WidgetSpan(child: ThinkWidget(textContent, isClosed));
  }
}

class ThinkWidget extends StatefulWidget {
  final String textContent;
  final bool isClosed;

  const ThinkWidget(this.textContent, this.isClosed, {super.key});

  @override
  State<ThinkWidget> createState() => _ThinkWidgetState();
}

class _ThinkWidgetState extends State<ThinkWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: !widget.isClosed
                    ? Text("思考中", style: TextStyle(color: Colors.grey[500]))
                    : Text("思考结束"),
              ),
              if (!widget.isClosed)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: Colors.orange,
                    strokeWidth: 1.5,
                  ),
                )
              else
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
            ],
          ),
          if (_isExpanded) Markit(data: widget.textContent),
        ],
      ),
    );
  }
}
