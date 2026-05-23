import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'request_status_chip.dart';

/// Scrollable list of join-request cards for the admin screen.
class JoinRequestsTable extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const JoinRequestsTable({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.how_to_reg_outlined,
                size: 52,
                color: Color(0xFFCBD5E1),
              ),
              SizedBox(height: 14),
              Text(
                'No join requests found',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Requests appear here when employees initiate\nworkspace joining via an invite code.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFCBD5E1),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _RequestCard(doc: docs[index]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _RequestCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final name = (d['fullName'] ?? '').toString();
    final email = (d['email'] ?? '').toString();
    final status = (d['status'] ?? 'pending').toString();
    final inviteCode = (d['inviteCode'] ?? '').toString();

    final ts = d['updatedAt'];
    final date = ts is Timestamp ? ts.toDate() : null;
    final dateStr = date != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
        : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : '(No name)',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                if (inviteCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Invite: $inviteCode',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RequestStatusChip(status: status),
              const SizedBox(height: 6),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
