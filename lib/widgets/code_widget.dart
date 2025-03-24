import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';

class CodeWidget extends StatelessWidget {
  final String code;
  final String language;

  const CodeWidget({
    super.key,
    required this.code,
    this.language = 'dart',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: HighlightView(
        code,
        language: language,
        theme: {
          'root': TextStyle(color: Colors.white, backgroundColor: Colors.black),
          'keyword': TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          'string': TextStyle(color: Colors.green),
          'comment': TextStyle(color: Colors.grey),
          'number': TextStyle(color: Colors.orange),
          'function': TextStyle(color: Colors.yellow),
        },
        padding: const EdgeInsets.all(8.0),
        textStyle: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 14.0,
        ),
      ),
    );
  }
}
