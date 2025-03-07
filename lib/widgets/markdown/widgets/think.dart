import 'package:flutter/material.dart';

import 'package:markdown_widget/markdown_widget.dart';
import 'package:chatmcp/utils/color.dart';
import '../markit_widget.dart';
import 'tag.dart';

class ThinkInlineSyntax extends TagInlineSyntax {
  ThinkInlineSyntax() : super(tag: "think");
}

class ThinkBlockSyntax extends TagBlockSyntax {
  ThinkBlockSyntax() : super(tag: "think");
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
