import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';

Widget bomTableText(String value, double width, {bool bold = false}) {
  return SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.only(top: 14, right: 10),
      child: Text(
        value,
        style: TextStyle(
          color: zText,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    ),
  );
}

Widget bomFieldBox(double width, Widget child) {
  return SizedBox(
    width: width,
    child: Padding(padding: const EdgeInsets.only(right: 10), child: child),
  );
}
