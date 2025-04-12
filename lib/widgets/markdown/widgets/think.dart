import 'package:flutter/material.dart';
import 'package:chatmcp/generated/app_localizations.dart';

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
    var t = AppLocalizations.of(context)!;
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
        color: AppColors.getThinkBackgroundColor(context),
        border: Border.all(color: AppColors.getThinkBorderColor(context)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppColors.getThinkIconColor(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$prefix$durationTips",
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getThinkTextColor(context)),
                ),
              ),
              if (!widget.isClosed)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: AppColors.getProgressIndicatorColor(context),
                    strokeWidth: 1.5,
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.getExpandIconColor(context),
                  ),
                ),
            ],
          ),
          if (_isExpanded) Markit(data: widget.textContent),
        ],
      ),
    );
  }
}
