import 'package:flutter/material.dart';

import '../helpers/quotation_local_constants.dart';

class QuotationSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const QuotationSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          if (trailing != null) const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
