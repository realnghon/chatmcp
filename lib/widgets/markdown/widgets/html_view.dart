import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HtmlView extends StatefulWidget {
  final String html;

  const HtmlView({
    super.key,
    required this.html,
  });

  @override
  State<HtmlView> createState() => _HtmlViewState();
}

class _HtmlViewState extends State<HtmlView> {
  double _height = 100;
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            final height = await controller.runJavaScriptReturningResult(
              'document.body.scrollHeight',
            );
            setState(() {
              _height = (height as num).toDouble();
            });
          },
        ),
      )
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          WebViewWidget(
            controller: controller,
          ),
          // webview 组件在 消息列表中, 当鼠标在 webview 上滚动时, 无法触发 ListView 的滚动事件
          // 这里用一个透明的容器来覆盖 webview , 使得滚动事件可以传递到 ListView 上
          Container(
            color: Colors.transparent.withAlpha(1),
          ),
        ],
      ),
    );
  }
}
