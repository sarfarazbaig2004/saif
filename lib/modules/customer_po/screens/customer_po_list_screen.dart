import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/verticals/active_vertical_scope.dart';
import 'package:QUIK/modules/customer_po/screens/customer_po_detail_screen.dart';
import 'package:QUIK/modules/customer_po/screens/customer_po_form_screen.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/customer_po_search_bar.dart';
import 'package:QUIK/modules/customer_po/screens/widgets/customer_po_status_chip.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_record_status_service.dart';

class CustomerPoListScreen extends StatefulWidget {
  final String companyId;

  const CustomerPoListScreen({super.key, required this.companyId});

  @override
  State<CustomerPoListScreen> createState() => _CustomerPoListScreenState();
}

class _CustomerPoListScreenState extends State<CustomerPoListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final activeCompanyId = context.watchTenant.selectedTenantId.trim().isEmpty
        ? widget.companyId
        : context.watchTenant.selectedTenantId.trim();
    final collectionPath =
        'companies/$activeCompanyId/${SalesCollections.customerPos}';
    final verticalState = ActiveVerticalScope.maybeOf(context);
    final poCollection = FirebaseFirestore.instance
        .collection('companies')
        .doc(activeCompanyId)
        .collection(SalesCollections.customerPos);
    final poStream = verticalState?.isDataScoped == true
        ? poCollection
              .where('verticalId', isEqualTo: verticalState!.activeVerticalId)
              .snapshots()
        : poCollection.snapshots();
    debugPrint(
      'CUSTOMER_PO_LIST_QUERY widgetCompanyId=${widget.companyId} '
      'activeCompanyId=$activeCompanyId path=$collectionPath',
    );

    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer PO'),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerPoFormScreen(
                    companyId: activeCompanyId,
                    activeVerticalId: verticalState?.activeVerticalId ?? '',
                    activeVerticalName: verticalState?.activeVerticalName ?? '',
                    availableVerticals:
                        verticalState?.availableVerticals ??
                        const <ActiveVerticalOption>[],
                    canChangeVertical: verticalState?.allowAllVerticals == true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create PO'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: poStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load Customer POs: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          debugPrint(
            'CUSTOMER_PO_LIST_RESULT path=$collectionPath count=${snapshot.data!.docs.length}',
          );
          for (final doc in snapshot.data!.docs) {
            final data = doc.data();
            debugPrint(
              'CUSTOMER_PO_LIST_DOC path=$collectionPath/${doc.id} '
              'docId=${doc.id} '
              'internalPoNo=${data['internalPoNo'] ?? data['poNumber'] ?? ''} '
              'customerName=${data['customerName'] ?? ''} '
              'status=${data['status'] ?? ''} '
              'linkedQuotationId=${data['linkedQuotationId'] ?? data['quotationId'] ?? ''}',
            );
          }

          final rawDocs = snapshot.data!.docs;
          final mappedDocs = rawDocs.toList();
          final visibleDocs = mappedDocs.toList();
          visibleDocs.sort((a, b) {
            final aDate = _dateValue(a.data()['createdAt']);
            final bDate = _dateValue(b.data()['createdAt']);
            return bDate.compareTo(aDate);
          });
          debugPrint(
            'CUSTOMER_PO_LIST_COUNTS rawCount=${rawDocs.length} '
            'mappedCount=${mappedDocs.length} '
            'filteredCount=${visibleDocs.length} '
            'searchText="${_searchText.trim()}"',
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: CustomerPoSearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchText = value),
                ),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: visibleDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final poDoc = visibleDocs[index];
                      final data = poDoc.data();

                      final internalPoNo =
                          (data['internalPoNo'] ??
                                  data['customerPoNo'] ??
                                  data['poNumber'] ??
                                  '')
                              .toString();
                      final customerPoNumber = (data['customerPoNumber'] ?? '')
                          .toString()
                          .trim();
                      final customerName = (data['customerName'] ?? '')
                          .toString();
                      final projectName =
                          (data['subject'] ?? data['projectName'] ?? '')
                              .toString();
                      final verticalName =
                          (data['verticalName'] ??
                                  data['businessVertical'] ??
                                  '')
                              .toString()
                              .trim();
                      final status = (data['status'] ?? 'Draft').toString();
                      final totalValue =
                          (data['grandTotal'] ??
                          data['totalValue'] ??
                          data['finalTotal'] ??
                          0);
                      final totalAmount = totalValue is num
                          ? totalValue.toDouble()
                          : double.tryParse(totalValue.toString()) ?? 0.0;

                      debugPrint(
                        'CUSTOMER_PO_RENDER_CARD index=$index '
                        'docId=${poDoc.id} '
                        'internalPoNo=$internalPoNo '
                        'customerName=$customerName',
                      );

                      return Card(
                        child: ListTile(
                          isThreeLine: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerPoDetailScreen(
                                companyId: activeCompanyId,
                                docId: poDoc.id,
                                activeVerticalId:
                                    verticalState?.activeVerticalId ?? '',
                                activeVerticalName:
                                    verticalState?.activeVerticalName ?? '',
                                availableVerticals:
                                    verticalState?.availableVerticals ??
                                    const <ActiveVerticalOption>[],
                                canChangeVertical:
                                    verticalState?.allowAllVerticals == true,
                              ),
                            ),
                          ),
                          title: Text(
                            internalPoNo.isEmpty
                                ? 'Internal PO No Missing'
                                : 'Internal PO No : $internalPoNo',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              if (customerPoNumber.isNotEmpty)
                                'Customer PO No : $customerPoNumber',
                              if (verticalName.isNotEmpty)
                                'Vertical : $verticalName',
                              'Customer : $customerName',
                              if (projectName.isNotEmpty) projectName,
                            ].join('\n'),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: SizedBox(
                            width: 150,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currency.format(totalAmount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      CustomerPoStatusChip(status: status),
                                    ],
                                  ),
                                  const SizedBox(width: 6),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value != 'delete') return;

                                      await CustomerPoRecordStatusService.deleteForTesting(
                                        companyId: activeCompanyId,
                                        docId: poDoc.id,
                                      );

                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Customer PO deleted successfully',
                                          ),
                                        ),
                                      );
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete Customer PO'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
