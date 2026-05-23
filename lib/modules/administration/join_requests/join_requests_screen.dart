import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'widgets/join_requests_table.dart';
import 'widgets/request_filters.dart';

/// Admin-facing screen listing all workspace join requests for this company.
///
/// Data source: `join_company_requests` (root collection), filtered by companyId.
/// The documents are created by [JoinCompanyService] via the Cloud Function
/// `sendJoinCompanyOtp` and updated to `status: completed` on successful OTP
/// verification.  No new collections or Cloud Functions are introduced here.
class JoinRequestsScreen extends StatefulWidget {
  final String companyId;

  const JoinRequestsScreen({super.key, required this.companyId});

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  String _selectedStatus = 'All';

  // Build the Firestore query based on current filter.
  Query<Map<String, dynamic>> get _query {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('join_company_requests')
        .where('companyId', isEqualTo: widget.companyId)
        .orderBy('updatedAt', descending: true);

    if (_selectedStatus != 'All') {
      q = q.where('status', isEqualTo: _selectedStatus.toLowerCase());
    }

    return q;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Join Requests',
          style: TextStyle(
            color: Color(0xFF1A3A52),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(),
          Expanded(child: _buildStream()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Employees who initiated workspace joining via an invite code.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          RequestFilters(
            selectedStatus: _selectedStatus,
            onStatusChanged: (s) => setState(() => _selectedStatus = s),
          ),
        ],
      ),
    );
  }

  Widget _buildStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        return JoinRequestsTable(docs: docs);
      },
    );
  }
}
