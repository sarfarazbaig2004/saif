import 'package:flutter/material.dart';

class InquiryFilterResult {
  final String status;
  final String priority;
  final String vertical;

  const InquiryFilterResult({
    required this.status,
    required this.priority,
    required this.vertical,
  });
}

class InquiryFilterSheet extends StatefulWidget {
  final String statusFilter;
  final String priorityFilter;
  final String verticalFilter;
  final List<String> verticalOptions;

  const InquiryFilterSheet({
    super.key,
    required this.statusFilter,
    required this.priorityFilter,
    required this.verticalFilter,
    required this.verticalOptions,
  });

  static const statuses = [
    'All',
    'Draft',
    'Open',
    'Qualified',
    'Quotation Pending',
    'Quotation Sent',
    'Follow-up Pending',
    'Won',
    'Lost',
    'Not Qualified',
  ];

  static const priorities = ['All', 'Hot', 'Warm', 'Cold'];

  @override
  State<InquiryFilterSheet> createState() => _InquiryFilterSheetState();
}

class _InquiryFilterSheetState extends State<InquiryFilterSheet> {
  late String tempStatus;
  late String tempPriority;
  late String tempVertical;

  @override
  void initState() {
    super.initState();
    tempStatus = widget.statusFilter;
    tempPriority = widget.priorityFilter;
    tempVertical = widget.verticalFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        6,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: InquiryFilterSheet.statuses.contains(tempStatus)
                  ? tempStatus
                  : 'All',
              decoration: const InputDecoration(
                labelText: 'Status',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: InquiryFilterSheet.statuses
                  .toSet()
                  .toList()
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  tempStatus = value ?? 'All';
                });
              },
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: widget.verticalOptions.contains(tempVertical)
                  ? tempVertical
                  : 'All Verticals',
              decoration: const InputDecoration(
                labelText: 'Business Vertical',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: widget.verticalOptions
                  .toSet()
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() => tempVertical = value ?? 'All Verticals');
              },
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: tempPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: InquiryFilterSheet.priorities
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  tempPriority = value ?? 'All';
                });
              },
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        const InquiryFilterResult(
                          status: 'All',
                          priority: 'All',
                          vertical: 'All Verticals',
                        ),
                      );
                    },
                    child: const Text('Reset'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        InquiryFilterResult(
                          status: tempStatus,
                          priority: tempPriority,
                          vertical: tempVertical,
                        ),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
