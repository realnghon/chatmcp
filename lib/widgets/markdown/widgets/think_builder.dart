import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:markdown_widget/markdown_widget.dart';
import 'package:ChatMcp/utils/color.dart';
import '../markit_widget.dart';

// 属性匹配正则表达式
final attributeRegex =
    RegExp(r'''([\w-]+)\s*=\s*(?:["']([^"'>]+)["']|([^\s>"']+))''');

class ThinkInlineSyntax extends md.InlineSyntax {
  static const defaultTagName = 'think';
  final String tag;

  ThinkInlineSyntax({String? tag, bool caseSensitive = false})
      : tag = tag ?? defaultTagName,
        super(_getPattern(tag ?? defaultTagName), caseSensitive: caseSensitive);

  static String _getPattern(String tag) =>
      r'<' + tag + r'\s*([^>]*)>([^<]*)(?:</' + tag + r'\s*([^>]*)>)?';

  Map<String, String> _parseAttributes(String attributeString) {
    final attributes = <String, String>{};
    final matches = attributeRegex.allMatches(attributeString);

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

    final element = md.Element(tag, [md.Text(content)]);

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
  static const defaultTagName = 'think';
  final String tag;

  ThinkBlockSyntax({String? tag}) : tag = tag ?? defaultTagName;

  @protected
  RegExp get startPattern => RegExp(r'^<' + tag + r'\s*([^>]*)>$');

  @protected
  RegExp get endPattern => RegExp(r'^</' + tag + r'\s*([^>]*)>$');

  @override
  RegExp get pattern => startPattern;

  Map<String, String> _parseAttributes(String attributeString) {
    final attributes = <String, String>{};
    final matches = attributeRegex.allMatches(attributeString);

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
    final match = startPattern.firstMatch(parser.current.content);
    return match != null;
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final startMatch = startPattern.firstMatch(parser.current.content);
    final openingAttributes = startMatch != null
        ? _parseAttributes(startMatch[1] ?? '')
        : <String, String>{};

    final lines = <String>[];
    parser.advance(); // Skip the opening tag

    bool isClosed = false;
    Map<String, String> closingAttributes = {};

    while (!parser.isDone) {
      final line = parser.current.content;
      final endMatch = endPattern.firstMatch(line);
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
    md.Element el = md.Element.text(tag, content);

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
        color: AppColors.getThemeColor(context,
            lightColor: AppColors.grey[100], darkColor: AppColors.grey[900]),
        border: Border.all(
            color: AppColors.getThemeColor(context,
                lightColor: AppColors.grey[300],
                darkColor: AppColors.grey[700])),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: AppColors.getThemeColor(context,
                      lightColor: Colors.orange, darkColor: Colors.orange)),
              const SizedBox(width: 8),
              Expanded(
                child: Text("$prefix$durationTips",
                    style: TextStyle(
                        color: AppColors.getThemeColor(context,
                            lightColor: AppColors.grey[500],
                            darkColor: AppColors.grey[300]))),
              ),
              if (!widget.isClosed)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: AppColors.getThemeColor(context,
                        lightColor: Colors.orange, darkColor: Colors.orange),
                    strokeWidth: 1.5,
                  ),
                )
              else
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.getThemeColor(context,
                        lightColor: AppColors.grey[600],
                        darkColor: AppColors.grey[300]),
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
