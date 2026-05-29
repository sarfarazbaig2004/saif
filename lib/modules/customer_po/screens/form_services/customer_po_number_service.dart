import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPoNumberService {
  const CustomerPoNumberService._();

  static String financialYear(DateTime date) {
    final startYear = date.month >= 4 ? date.year : date.year - 1;
    final endYear = startYear + 1;
    return '$startYear-${(endYear % 100).toString().padLeft(2, '0')}';
  }

  static String cleanCode(String value, {String fallback = 'GEN'}) {
    final cleaned = value.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]+'),
      '',
    );

    if (cleaned.isEmpty) return fallback;
    return cleaned.length <= 6 ? cleaned : cleaned.substring(0, 6);
  }

  static Future<String> nextPoNumber({
    required String companyId,
    String customerName = '',
    String projectName = '',
  }) async {
    final fy = financialYear(DateTime.now());
    final counterRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('settings')
        .doc('internal_po_counter_$fy');

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snap = await transaction.get(counterRef);
      final current = (snap.data()?['currentNumber'] as num?)?.toInt() ?? 0;
      final next = current + 1;

      transaction.set(counterRef, {
        'currentNumber': next,
        'financialYear': fy,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final serial = next.toString().padLeft(3, '0');

      return 'AID/PO/$serial/$fy';
    });
  }

  static Future<String> nextInternalPoNumber({required String companyId}) {
    return nextPoNumber(companyId: companyId);
  }
}
