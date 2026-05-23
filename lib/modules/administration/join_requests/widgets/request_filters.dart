import 'package:flutter/material.dart';

const _kStatuses = ['All', 'Pending', 'Completed'];

/// Filter chips to narrow join requests by status.
class RequestFilters extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  const RequestFilters({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _kStatuses.map((s) {
        final isSelected = s == selectedStatus;
        return ChoiceChip(
          label: Text(s),
          selected: isSelected,
          selectedColor: const Color(0xFF1A3A52),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF1A3A52)
                : const Color(0xFFE2E8F0),
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          onSelected: (_) => onStatusChanged(s),
        );
      }).toList(),
    );
  }
}
