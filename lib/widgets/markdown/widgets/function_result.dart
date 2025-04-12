import 'package:flutter/material.dart';

import 'package:markdown_widget/markdown_widget.dart';
import 'package:chatmcp/utils/color.dart';
import '../markit_widget.dart';
import 'tag.dart';

const _functionResultTag = 'call_function_result';

class FunctionResultInlineSyntax extends TagInlineSyntax {
  FunctionResultInlineSyntax() : super(tag: _functionResultTag);
}

class FunctionResultBlockSyntax extends TagBlockSyntax {
  FunctionResultBlockSyntax() : super(tag: _functionResultTag);
}

SpanNodeGeneratorWithTag functionResultGenerator = SpanNodeGeneratorWithTag(
    tag: _functionResultTag,
    generator: (e, config, visitor) =>
        FunctionResultNode(e.attributes, e.textContent, config));

class FunctionResultNode extends SpanNode {
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;

  FunctionResultNode(this.attributes, this.textContent, this.config);

  @override
  InlineSpan build() {
    bool isClosed = attributes['closed'] == 'true';
    return WidgetSpan(
        child: FunctionResultWidget(textContent, isClosed, attributes));
  }
}

class FunctionResultWidget extends StatefulWidget {
  final String textContent;
  final bool isClosed;
  final Map<String, String> attributes;

  const FunctionResultWidget(this.textContent, this.isClosed, this.attributes,
      {super.key});

  @override
  State<FunctionResultWidget> createState() => _FunctionResultWidgetState();
}

class _FunctionResultWidgetState extends State<FunctionResultWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // 根据工具名称选择图标
    IconData toolIcon = Icons.build_outlined;
    final toolName = widget.attributes['name']?.toLowerCase() ?? '';

    if (toolName == 'fetch') {
      toolIcon = Icons.cloud_download;
    } else if (toolName.contains('search')) {
      toolIcon = Icons.search;
    } else if (toolName.contains('google') || toolName.contains('sheet')) {
      toolIcon = Icons.table_chart;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.getFunctionBackgroundColor(context),
        border: Border.all(color: AppColors.getFunctionBorderColor(context)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(toolIcon, color: AppColors.getFunctionIconColor(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    "${widget.attributes['name']} result: ${widget.textContent}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.getFunctionTextColor(context))),
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
          if (_isExpanded) Text(widget.textContent),
        ],
      ),
    );
  }
}
