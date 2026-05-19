import 'package:flutter/material.dart';

Color customerPoStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'submitted':
      return Colors.blue.shade700;
    case 'approved':
      return Colors.green.shade700;
    case 'rejected':
      return Colors.red.shade700;
    case 'in production':
      return Colors.orange.shade800;
    case 'partially dispatched':
      return Colors.deepPurple.shade600;
    case 'completed':
      return Colors.teal.shade700;
    case 'closed':
      return Colors.blueGrey.shade700;
    default:
      return Colors.grey.shade600;
  }
}

Color customerPoStatusBg(String status) {
  switch (status.toLowerCase()) {
    case 'submitted':
      return Colors.blue.shade50;
    case 'approved':
      return Colors.green.shade50;
    case 'rejected':
      return Colors.red.shade50;
    case 'in production':
      return Colors.orange.shade50;
    case 'partially dispatched':
      return Colors.deepPurple.shade50;
    case 'completed':
      return Colors.teal.shade50;
    case 'closed':
      return Colors.blueGrey.shade50;
    default:
      return Colors.grey.shade100;
  }
}

class CustomerPoStatusChip extends StatelessWidget {
  final String status;

  const CustomerPoStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: customerPoStatusColor(status),
        ),
      ),
      backgroundColor: customerPoStatusBg(status),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }
}
