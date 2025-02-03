import 'package:markdown/markdown.dart' as md;

class MarkdownTextConverter {
  static String convertNodesToPlainText(List<md.Node> nodes) {
    final buffer = StringBuffer();

    void traverse(md.Node node) {
      if (node is md.Text) {
        buffer.write(node.text);
      } else if (node is md.Element) {
        if (node.tag == 'code') {
          if (!node.textContent.startsWith('\n') &&
              !buffer.toString().endsWith('\n')) {
            buffer.write('\n');
          }
          buffer.write(node.textContent);
          if (!node.textContent.endsWith('\n')) {
            buffer.write('\n');
          }
        } else if (node.tag == 'p') {
          if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) {
            buffer.write('\n');
          }
          for (var child in node.children!) {
            traverse(child);
          }
          if (!buffer.toString().endsWith('\n')) {
            buffer.write('\n');
          }
        } else if (node.tag == 'a') {
          buffer.write(node.textContent);
        } else if (node.tag == 'li') {
          buffer.write('• ${node.textContent}\n');
        } else if (node.tag == 'h1') {
          buffer.write('# ${node.textContent}\n');
        } else if (node.tag == 'h2') {
          buffer.write('## ${node.textContent}\n');
        } else if (node.tag == 'h3') {
          buffer.write('### ${node.textContent}\n');
        } else {
          for (var child in node.children ?? <md.Node>[]) {
            traverse(child);
          }
        }
      }
    }

    for (var node in nodes) {
      traverse(node);
    }

    return buffer.toString().trim();
  }
}
