import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MarkdownWebView extends StatefulWidget {
  final String markdown;

  const MarkdownWebView({super.key, required this.markdown});

  @override
  State<MarkdownWebView> createState() => _MarkdownWebViewState();
}

class _MarkdownWebViewState extends State<MarkdownWebView> {
  double _height = 300;

  @override
  Widget build(BuildContext context) {
    // 使用 marked.js 来渲染 markdown
    String htmlContent = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/github-markdown-css/github-markdown.min.css">
          <style>
            body {
              margin: 0;
              padding: 16px;
              background: transparent;
            }
            .markdown-body {
              box-sizing: border-box;
              min-width: 200px;
              max-width: 100%;
              margin: 0 auto;
            }
            pre {
              background-color: #f6f8fa;
              border-radius: 6px;
              padding: 16px;
              overflow: auto;
            }
            code {
              font-family: ui-monospace,SFMono-Regular,SF Mono,Menlo,Consolas,Liberation Mono,monospace;
              font-size: 12px;
            }
          </style>
        </head>
        <body>
          <div class="markdown-body" id="content"></div>
          <script>
            document.getElementById('content').innerHTML = marked.parse(`\${widget.markdown}`);
          </script>
        </body>
      </html>
    ''';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: SizedBox(
            width: constraints.maxWidth,
            height: _height,
            child: InAppWebView(
              initialData: InAppWebViewInitialData(
                data: htmlContent,
                mimeType: 'text/html',
                encoding: 'utf-8',
              ),
              initialSettings: InAppWebViewSettings(
                transparentBackground: true,
                disableContextMenu: true,
                supportZoom: false,
              ),
              gestureRecognizers: {},
              onLoadStop: (controller, url) async {
                // 注入 markdown 内容
                await controller.evaluateJavascript(
                  source:
                      "document.getElementById('content').innerHTML = marked.parse(`\${widget.markdown}`);",
                );
                // 获取内容高度并更新容器高度
                final height = await controller.evaluateJavascript(
                  source: "document.documentElement.scrollHeight;",
                );
                if (height != null) {
                  setState(() {
                    _height = double.parse(height.toString()) + 32;
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }
}
