import 'package:flutter/material.dart';

void showModalBottom(BuildContext context, Widget child) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // 允许弹窗内容超过半屏高度
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6, // 初始高度为屏幕的60%
        minChildSize: 0.3, // 最小高度为屏幕的30%
        maxChildSize: 0.9, // 最大高度为屏幕的90%
        expand: false,
        builder: (context, scrollController) {
          return child;
        },
      );
    },
  );
}
