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

// 属性匹配正则表达式
final _attributeRegex =
    RegExp(r'''([\w-]+)\s*=\s*(?:["']([^"'>]+)["']|([^\s>"']+))''');

class ThinkInlineSyntax extends md.InlineSyntax {
  static const _pattern = r'<think\s*([^>]*)>([^<]*)(?:</think\s*([^>]*)>)?';

  ThinkInlineSyntax() : super(_pattern, caseSensitive: false);

  Map<String, String> _parseAttributes(String attributeString) {
    final attributes = <String, String>{};
    final matches = _attributeRegex.allMatches(attributeString);

    for (final match in matches) {
      if (match.groupCount >= 1) {
        final key = match.group(1) ?? '';
        // 值可能在引号组或无引号组中
        final value = match.group(2) ?? match.group(3) ?? '';
        if (key.isNotEmpty) {
          attributes[key] = value;
        }
      }
    }
    return attributes;
  }

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final openingAttributes = _parseAttributes(match[1] ?? '');
    final content = match[2]!.trim();
    final closingAttributes =
        match[3] != null ? _parseAttributes(match[3]!) : <String, String>{};

    final element = md.Element('think', [md.Text(content)]);

    // 合并开始和结束标签的属性
    element.attributes.addAll(openingAttributes);
    element.attributes.addAll(closingAttributes);

    element.attributes['content'] = content;
    element.attributes['isInline'] = 'true';
    element.attributes['closed'] = match[3] != null ? 'true' : 'false';

    parser.addNode(element);
    return true;
  }
}

class ThinkBlockSyntax extends md.BlockSyntax {
  static final _startPattern = RegExp(r'^<think\s*([^>]*)>$');
  static final _endPattern = RegExp(r'^</think\s*([^>]*)>$');

  @override
  RegExp get pattern => _startPattern;

  ThinkBlockSyntax();

  Map<String, String> _parseAttributes(String attributeString) {
    final attributes = <String, String>{};
    final matches = _attributeRegex.allMatches(attributeString);

    for (final match in matches) {
      if (match.groupCount >= 1) {
        final key = match.group(1) ?? '';
        // 值可能在引号组或无引号组中
        final value = match.group(2) ?? match.group(3) ?? '';
        if (key.isNotEmpty) {
          attributes[key] = value;
        }
      }
    }
    return attributes;
  }

  @override
  bool canParse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    return match != null;
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final startMatch = pattern.firstMatch(parser.current.content);
    final openingAttributes = startMatch != null
        ? _parseAttributes(startMatch[1] ?? '')
        : <String, String>{};

    final lines = <String>[];
    parser.advance(); // Skip the opening tag

    bool isClosed = false;
    Map<String, String> closingAttributes = {};

    while (!parser.isDone) {
      final line = parser.current.content;
      final endMatch = _endPattern.firstMatch(line);
      if (endMatch != null) {
        isClosed = true;
        closingAttributes = _parseAttributes(endMatch[1] ?? '');
        parser.advance();
        break;
      }
      lines.add(line);
      parser.advance();
    }

    final content = lines.join('\n');
    md.Element el = md.Element.text(_thinkTag, content);

    // 合并开始和结束标签的属性
    el.attributes.addAll(openingAttributes);
    el.attributes.addAll(closingAttributes);

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
    return WidgetSpan(child: ThinkWidget(textContent, isClosed, attributes));
  }
}

class ThinkWidget extends StatefulWidget {
  final String textContent;
  final bool isClosed;
  final Map<String, String> attributes;

  const ThinkWidget(this.textContent, this.isClosed, this.attributes,
      {super.key});

  @override
  State<ThinkWidget> createState() => _ThinkWidgetState();
}

class _ThinkWidgetState extends State<ThinkWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    String startTime = widget.attributes['start-time'] ?? '';
    String endTime = widget.attributes['end-time'] ?? '';

    String prefix = '思考中';
    String durationTips = '';
    if (startTime.isNotEmpty) {
      if (endTime.isEmpty) {
        endTime = DateTime.now().toIso8601String();
        prefix = '思考中, 用时';
      } else {
        prefix = '思考结束, 用时';
      }
      Duration duration =
          DateTime.parse(endTime).difference(DateTime.parse(startTime));
      durationTips = '${duration.inSeconds}s';
    }

    if (widget.isClosed) {
      prefix = '思考结束';
      if (durationTips.isNotEmpty) {
        prefix += ', 用时';
      }
    }

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
                child: Text("$prefix$durationTips",
                    style: TextStyle(color: Colors.grey[500])),
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
