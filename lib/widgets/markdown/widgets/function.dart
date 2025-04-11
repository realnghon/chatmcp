import 'package:flutter/material.dart';

import 'package:markdown_widget/markdown_widget.dart';
import 'package:chatmcp/utils/color.dart';
import '../markit_widget.dart';
import 'tag.dart';
import 'package:chatmcp/utils/event_bus.dart';

const _functionTag = 'function';

class FunctionInlineSyntax extends TagInlineSyntax {
  FunctionInlineSyntax() : super(tag: _functionTag);
}

class FunctionBlockSyntax extends TagBlockSyntax {
  FunctionBlockSyntax() : super(tag: _functionTag);
}

SpanNodeGeneratorWithTag functionGenerator = SpanNodeGeneratorWithTag(
    tag: _functionTag,
    generator: (e, config, visitor) =>
        FunctionNode(e.attributes, e.textContent, config));

class FunctionNode extends SpanNode {
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;

  FunctionNode(this.attributes, this.textContent, this.config);

  @override
  InlineSpan build() {
    bool isClosed = attributes['closed'] == 'true';
    return WidgetSpan(child: FunctionWidget(textContent, isClosed, attributes));
  }
}

class FunctionWidget extends StatefulWidget {
  final String textContent;
  final bool isClosed;
  final Map<String, String> attributes;

  const FunctionWidget(this.textContent, this.isClosed, this.attributes,
      {super.key});

  @override
  State<FunctionWidget> createState() => _FunctionWidgetState();
}

class _FunctionWidgetState extends State<FunctionWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.build_outlined,
                  color: AppColors.getThemeColor(context,
                      lightColor: Colors.orange, darkColor: Colors.orange)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    "${widget.attributes['name']}: ${widget.textContent}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              // run action
              if (widget.attributes['done'] != 'true')
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.play_arrow,
                    color: AppColors.getThemeColor(context,
                        lightColor: Colors.green, darkColor: Colors.green[300]),
                  ),
                  onPressed: () {
                    // 这里添加执行函数的逻辑
                    emit(RunFunctionEvent(
                        widget.attributes['name'] ?? '', widget.textContent));
                  },
                ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.getThemeColor(context,
                      lightColor: AppColors.grey[600],
                      darkColor: AppColors.grey[300]),
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
