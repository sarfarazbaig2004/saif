// Screen for Customer PO List
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';
import 'package:intl/intl.dart';

class CustomerPoListScreen extends StatefulWidget {
  final String companyId;

  const CustomerPoListScreen({super.key, required this.companyId});

  @override
  State<CustomerPoListScreen> createState() => _CustomerPoListScreenState();
}

class _CustomerPoListScreenState extends State<CustomerPoListScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: zBorder),
          _buildToolbar(),
          const Divider(height: 1, color: zBorder),
          Expanded(
            child: _buildLiveList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: zBlueSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.request_quote_outlined, color: zBlue, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Purchase Orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: zText,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage incoming POs and hand them over to Planning',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: zMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add PO Form coming next!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: zBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'New PO',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 36,
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search PO number, project, or client...',
                  hintStyle: const TextStyle(color: zMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 16, color: zMuted),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: zCanvasBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: zBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: zBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: zBlue),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('customer_pos')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: zBlue));
        }

        final docs = snapshot.data?.docs ?? [];

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final poNum = (data['poNumber'] ?? '').toString().toLowerCase();
          final client = (data['customerName'] ?? '').toString().toLowerCase();
          final project = (data['projectName'] ?? '').toString().toLowerCase();
          return poNum.contains(searchQuery) ||
                 client.contains(searchQuery) ||
                 project.contains(searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final poModel = CustomerPoModel.fromMap(data, doc.id);

            return _buildPoCard(poModel);
          },
        );
      },
    );
  }

  Widget _buildPoCard(CustomerPoModel po) {
    final formattedDelivery = DateFormat('dd MMM yyyy').format(po.expectedDeliveryDate);
    final formattedPoDate = DateFormat('dd MMM yyyy').format(po.poDate);

    Color statusColor = zOrange;
    Color statusBg = zOrangeSoft;
    if (po.status.toLowerCase().contains('approved')) {
      statusColor = zSuccess;
      statusBg = zSuccessSoft;
    } else if (po.status.toLowerCase().contains('project created')) {
      statusColor = zPurple;
      statusBg = zPurpleSoft;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: zBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // TODO: Open PO Details / Handoff to Planning
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: zCanvasBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: zBorder),
                  ),
                  child: const Icon(Icons.description_outlined, color: zText, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            po.poNumber.isNotEmpty ? po.poNumber : 'DRAFT PO',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: zText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              po.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        po.projectName.isNotEmpty ? po.projectName : 'Project Name Not Specified',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: zText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.domain, size: 14, color: zMuted),
                          const SizedBox(width: 4),
                          Text(
                            po.customerName.isNotEmpty ? po.customerName : 'Unknown Client',
                            style: const TextStyle(fontSize: 12, color: zMuted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.event, size: 14, color: zMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Delivery: $formattedDelivery',
                            style: const TextStyle(fontSize: 12, color: zMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${po.totalOrderValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: zText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: $formattedPoDate',
                      style: const TextStyle(
                        fontSize: 11,
                        color: zMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right, color: zMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: zCanvasBg, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_outlined, size: 48, color: zMuted),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Customer POs Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: zText),
          ),
        ],
      ),
    );
  }
}