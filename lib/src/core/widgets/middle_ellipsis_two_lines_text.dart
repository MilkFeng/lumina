import 'package:flutter/material.dart';

class MiddleEllipsisTwoLinesText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MiddleEllipsisTwoLinesText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        final textScaler =
            MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
        final textDirection =
            Directionality.maybeOf(context) ?? TextDirection.ltr;

        final textPainter = TextPainter(
          textDirection: textDirection,
          maxLines: 2,
          textScaler: textScaler,
        );

        // Check if a given text fits within the constraints
        bool fits(String t) {
          textPainter.text = TextSpan(text: t, style: style);
          textPainter.layout(
            maxWidth: maxWidth > 2.0 ? maxWidth - 2.0 : maxWidth,
          );
          return !textPainter.didExceedMaxLines;
        }

        // 0. If the full text fits, just return it directly
        if (fits(text)) {
          return Text(text, style: style, maxLines: 2);
        }

        // 1. First binary search: find the maximum total character
        // count that can be symmetrically placed, thus determining the first half (half)
        int low = 0;
        int high = text.length;
        int bestSymmetricLength = 0;

        while (low <= high) {
          int mid = low + ((high - low) ~/ 2);
          int fLen = mid ~/ 2;
          int bLen = mid - fLen;
          String testText =
              '${text.substring(0, fLen)}...${text.substring(text.length - bLen)}';

          if (fits(testText)) {
            bestSymmetricLength = mid;
            low = mid + 1;
          } else {
            high = mid - 1;
          }
        }

        int frontLen = bestSymmetricLength ~/ 2;

        // 2. Second binary search: with the first half fixed, find the maximum
        // length of the second half that can fit
        int backLow = bestSymmetricLength - frontLen;
        int backHigh = text.length - frontLen;
        int bestBackLen = backLow;

        while (backLow <= backHigh) {
          int mid = backLow + ((backHigh - backLow) ~/ 2);
          String testText =
              '${text.substring(0, frontLen)}...${text.substring(text.length - mid)}';

          if (fits(testText)) {
            bestBackLen = mid;
            backLow = mid + 1;
          } else {
            backHigh = mid - 1;
          }
        }

        // 3. Construct the final string using the determined front and back lengths
        String finalResult =
            '${text.substring(0, frontLen)}...${text.substring(text.length - bestBackLen)}';
        return Text(finalResult, style: style, maxLines: 2);
      },
    );
  }
}
