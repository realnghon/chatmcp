import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MermaidDiagramView extends StatefulWidget {
  final String code;

  const MermaidDiagramView({
    super.key,
    required this.code,
  });

  @override
  State<MermaidDiagramView> createState() => _MermaidDiagramViewState();
}

class _MermaidDiagramViewState extends State<MermaidDiagramView> {
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
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
          <script>
            mermaid.initialize({
              startOnLoad: true,
              theme: 'default',
              sequence: {
                diagramMarginX: 50,
                diagramMarginY: 10,
                actorMargin: 50,
                width: 150,
                height: 65,
                boxMargin: 10,
                boxTextMargin: 5,
                noteMargin: 10,
              },
              flowchart: {
                diagramPadding: 8,
                htmlLabels: true,
                curve: 'basis',
              },
              gantt: {
                titleTopMargin: 25,
                barHeight: 20,
                barGap: 4,
                topPadding: 50,
                leftPadding: 75,
                gridLineStartPadding: 35,
                fontSize: 11,
                sectionFontSize: 11,
                numberSectionStyles: 4,
              },
              pie: {
                textPosition: 0.5,
              },
            });
            
            // 监听图表渲染完成事件
            document.addEventListener('DOMContentLoaded', function() {
              const observer = new MutationObserver(function(mutations) {
                const height = document.body.scrollHeight;
                window.flutter_inappwebview?.callHandler('onHeightChanged', height);
              });
              
              observer.observe(document.body, {
                attributes: true,
                childList: true,
                subtree: true
              });
            });
          </script>
          <style>
            html, body {
              margin: 0;
              padding: 0;
              height: auto;
              overflow-y: visible;
              background-color: transparent;
            }
            .mermaid-container {
              display: flex;
              justify-content: center;
              width: 100%;
              padding: 16px;
              box-sizing: border-box;
            }
            .mermaid {
              width: 100%;
              background-color: white;
              padding: 16px;
              box-sizing: border-box;
              border-radius: 8px;
            }
          </style>
        </head>
        <body>
          <div class="mermaid-container">
            <div class="mermaid">
              ${widget.code}
            </div>
          </div>
        </body>
        </html>
      ''');
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
