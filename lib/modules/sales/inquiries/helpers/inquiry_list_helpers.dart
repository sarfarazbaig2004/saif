import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryListHelpers {
  static String getString(Map<String, dynamic>? data, String key) {
    if (data == null || !data.containsKey(key)) return '';
    return (data[key] ?? '').toString().trim();
  }

  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  static String formatCompactDate(DateTime? date) {
    if (date == null) return '-';
    return formatDate(date);
  }

  static bool isAdminOrManager(String role) {
    final r = role.trim().toLowerCase();
    return const [
      'admin',
      'manager',
      'owner',
      'founder',
      'ceo',
      'superadmin',
    ].contains(r);
  }

  static bool hasInquiryPermission(Map<String, dynamic> userData) {
    final role = getString(userData, 'role').toLowerCase();

    if (isAdminOrManager(role)) return true;

    final permissions = userData['permissions'];
    if (permissions is Map) {
      final salesPerms = permissions['sales'];
      if (salesPerms is Map) {
        final inquiryPerms = salesPerms['inquiries'];
        if (inquiryPerms is Map && inquiryPerms['view'] == true) {
          return true;
        }
      }
      if (permissions['inquiries'] == true) return true;
    }

    return false;
  }

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> applyLocalFilters({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String role,
    required String currentUserUid,
    required String searchText,
    required String statusFilter,
    required String priorityFilter,
  }) {
    final normalizedSearch = searchText.toLowerCase();
    final isAdmin = isAdminOrManager(role);

    final filtered = docs.where((doc) {
      final data = doc.data();

      bool matchesRole = true;

      if (!isAdmin) {
        final assignedToUid = getString(data, 'assignedToUid');
        final createdByUid = getString(data, 'createdByUid').isEmpty
            ? getString(data, 'createdBy')
            : getString(data, 'createdByUid');

        matchesRole =
            assignedToUid == currentUserUid || createdByUid == currentUserUid;
      }

      final inquiryCode = getString(data, 'inquiryCode').isEmpty
          ? getString(data, 'inquiryNumber').toLowerCase()
          : getString(data, 'inquiryCode').toLowerCase();

      final customerCode = getString(data, 'customerCode').toLowerCase();

      final customerName = getString(data, 'customerName').isEmpty
          ? getString(data, 'companyName').toLowerCase()
          : getString(data, 'customerName').toLowerCase();

      final subject = getString(data, 'subject').isEmpty
          ? getString(data, 'inquirySubject').toLowerCase()
          : getString(data, 'subject').toLowerCase();

      final contactName = getString(data, 'contactName').isEmpty
          ? getString(data, 'contactPerson').toLowerCase()
          : getString(data, 'contactName').toLowerCase();

      final mobile = getString(data, 'contactMobile').isEmpty
          ? (getString(data, 'contactPhone').isEmpty
                ? getString(data, 'mobile').toLowerCase()
                : getString(data, 'contactPhone').toLowerCase())
          : getString(data, 'contactMobile').toLowerCase();

      final projectName = getString(data, 'projectName').toLowerCase();
      final source = getString(data, 'source').toLowerCase();
      final requiredProducts = getString(
        data,
        'requiredProducts',
      ).toLowerCase();

      final status = getString(data, 'status');
      final priority = getString(data, 'priority');

      final matchesSearch =
          normalizedSearch.isEmpty ||
          inquiryCode.contains(normalizedSearch) ||
          customerCode.contains(normalizedSearch) ||
          customerName.contains(normalizedSearch) ||
          subject.contains(normalizedSearch) ||
          contactName.contains(normalizedSearch) ||
          mobile.contains(normalizedSearch) ||
          projectName.contains(normalizedSearch) ||
          source.contains(normalizedSearch) ||
          requiredProducts.contains(normalizedSearch);

      final matchesStatus = statusFilter == 'All' || status == statusFilter;
      final matchesPriority =
          priorityFilter == 'All' || priority == priorityFilter;

      return matchesRole && matchesSearch && matchesStatus && matchesPriority;
    }).toList();

    filtered.sort((a, b) {
      final aTs = a.data()['createdAt'];
      final bTs = b.data()['createdAt'];

      final aDate = aTs is Timestamp ? aTs.toDate() : null;
      final bDate = bTs is Timestamp ? bTs.toDate() : null;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return filtered;
  }
}
