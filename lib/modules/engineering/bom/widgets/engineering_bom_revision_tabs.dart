import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';

class EngineeringBomRevisionTabs extends StatelessWidget {
  final String bomNo;
  final String revision;
  final String status;
  final String revisionReason;

  const EngineeringBomRevisionTabs({
    super.key,
    required this.bomNo,
    required this.revision,
    required this.status,
    required this.revisionReason,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: zBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Revision History'),
                Tab(text: 'Audit Trail'),
              ],
            ),
            SizedBox(
              height: 110,
              child: TabBarView(
                children: [
                  _line('Current', '$bomNo Rev $revision - $status'),
                  _line(
                    'Latest audit',
                    revisionReason.isEmpty
                        ? 'Saved changes are tracked in Firestore auditTrail.'
                        : revisionReason,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
