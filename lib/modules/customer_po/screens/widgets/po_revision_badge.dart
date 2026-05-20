import 'package:flutter/material.dart';

class PoRevisionBadge extends StatelessWidget {
  final int revisionNo;
  final bool isAmended;

  const PoRevisionBadge({
    super.key,
    required this.revisionNo,
    required this.isAmended,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isAmended ? 'Rev $revisionNo Amended' : 'Rev $revisionNo'),
      visualDensity: VisualDensity.compact,
    );
  }
}
