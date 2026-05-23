import 'package:flutter/material.dart';

/// Badge showing join request status (pending / completed / unknown).
class RequestStatusChip extends StatelessWidget {
  final String status;

  const RequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.border),
      ),
      child: Text(
        cfg.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: cfg.fg,
        ),
      ),
    );
  }

  _ChipConfig _config(String s) {
    switch (s.toLowerCase()) {
      case 'completed':
        return const _ChipConfig(
          label: 'Completed',
          bg: Color(0xFFDCFCE7),
          fg: Color(0xFF166534),
          border: Color(0xFFBBF7D0),
        );
      case 'pending':
        return const _ChipConfig(
          label: 'Pending OTP',
          bg: Color(0xFFFFF7ED),
          fg: Color(0xFF9A3412),
          border: Color(0xFFFED7AA),
        );
      default:
        return _ChipConfig(
          label: s.isEmpty ? 'Unknown' : _capitalize(s),
          bg: const Color(0xFFF1F5F9),
          fg: const Color(0xFF475569),
          border: const Color(0xFFCBD5E1),
        );
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _ChipConfig {
  final String label;
  final Color bg, fg, border;

  const _ChipConfig({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });
}
