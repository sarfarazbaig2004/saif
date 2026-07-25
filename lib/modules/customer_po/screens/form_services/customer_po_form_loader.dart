import 'package:QUIK/modules/sales/shared/constants/sales_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_data.dart';
import 'package:QUIK/modules/customer_po/widgets/customer_po_item_row.dart';

class CustomerPoFormLoader {
  const CustomerPoFormLoader._();

  static Future<CustomerPoFormData?> load({
    required String companyId,
    required String? existingDocId,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(SalesCollections.customerPos)
        .doc(existingDocId)
        .get();

    if (!doc.exists) return null;

    final d = doc.data()!;
    final rawItems = (d['items'] as List<dynamic>?) ?? [];

    final items = rawItems.map((item) {
      final m = item as Map<String, dynamic>;
      return CustomerPoItemRow(
        description: (m['description'] ?? '').toString(),
        quantity: (m['quantity'] is num)
            ? (m['quantity'] as num).toDouble()
            : 1.0,
        unit: (m['unit'] ?? 'Nos').toString(),
        rate: (m['rate'] is num) ? (m['rate'] as num).toDouble() : 0.0,
      );
    }).toList();

    return CustomerPoFormData(
      id: doc.id,
      verticalId: (d['verticalId'] ?? '').toString(),
      verticalName: (d['verticalName'] ?? d['businessVertical'] ?? '')
          .toString(),
      status: (d['status'] ?? 'Draft').toString(),
      poDate: _date(d['poDate']) ?? DateTime.now(),
      internalPoNo:
          (d['internalPoNo'] ?? d['customerPoNo'] ?? d['poNumber'] ?? '')
              .toString(),
      customerPoNumber: (d['customerPoNumber'] ?? '').toString(),
      customerId: (d['customerId'] ?? '').toString(),
      customerName: (d['customerName'] ?? '').toString(),
      customerEmail: (d['customerEmail'] ?? '').toString(),
      customerMobile: (d['customerMobile'] ?? '').toString(),
      customerAddress: (d['customerAddress'] ?? '').toString(),
      customerGstNumber: (d['customerGstNumber'] ?? '').toString(),
      projectName: (d['projectName'] ?? '').toString(),
      siteLocation: (d['siteLocation'] ?? '').toString(),
      subject: (d['subject'] ?? '').toString(),
      gstPercent: (d['gstPercent'] ?? 18).toString(),
      paymentTerms: (d['paymentTerms'] ?? '').toString(),
      deliveryTerms: (d['deliveryTerms'] ?? '').toString(),
      inspectionRequirement: (d['inspectionRequirement'] ?? '').toString(),
      warranty: (d['warranty'] ?? '').toString(),
      ldClause: (d['ldClause'] ?? '').toString(),
      poDocumentUrl: d['poDocumentUrl'] as String?,
      poFileName: d['poFileName'] as String?,
      uploadedAt: _date(d['uploadedAt']),
      items: items,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
