import 'package:flutter/material.dart';

class SimpleMarkdown extends StatelessWidget {
  final String text;

  const SimpleMarkdown({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    List<String> lines = text.split('\n');
    List<Widget> widgets = [];

    for (String line in lines) {
      String trimmedLine = line.trim();

      if (trimmedLine.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (trimmedLine.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              trimmedLine.substring(4),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else if (trimmedLine.startsWith('#### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              trimmedLine.substring(5),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else if (trimmedLine.startsWith('* ') || trimmedLine.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("•  ", style: TextStyle(fontSize: 16)),
                Expanded(
                  child: _buildInlineBold(context, trimmedLine.substring(2)),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildInlineBold(context, trimmedLine),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildInlineBold(BuildContext context, String text) {
    if (!text.contains('**')) {
      return Text(text, style: const TextStyle(fontSize: 14));
    }

    List<TextSpan> spans = [];
    RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int currentIndex = 0;

    for (final match in exp.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
        children: spans,
      ),
    );
  }
}
