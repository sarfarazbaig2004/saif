// FILE PATH: lib/modules/sales/quotations/screens_quotation_list.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/tenancy/tenant_context.dart';
import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_number_service.dart';
import 'package:QUIK/modules/sales/quotations/quotation_screen_local.dart';
import 'quotation_pdf_generator.dart';

const Color primaryColor = Color(0xFF1E3A8A);
const Color accentColor = Color(0xFF2563EB);
const Color backgroundLight = Color(0xFFF8FAFC);

const String _kCollectionCompanies = 'companies';
const String _kCollectionUsers = 'users';
const String _kCollectionQuotations = 'quotations';
const String _kCollectionCustomerPos = 'customer_pos';

class ScreensQuotationList extends StatefulWidget {
  final int userId;

  const ScreensQuotationList({super.key, required this.userId});

  @override
  State<ScreensQuotationList> createState() => _ScreensQuotationListState();
}

class _ScreensQuotationListState extends State<ScreensQuotationList> {
  final TextEditingController _searchController = TextEditingController();

  String? _companyId;
  String? _currentUserUid;
  String _currentUserRole = 'sales';
  String _currentUserName = '';
  bool _isLoadingContext = true;
  String? _errorMessage;

  String _searchText = '';
  String _statusFilter = 'All';
  String _sortOption = 'Date: Newest';

  final Map<String, bool> _convertingDocs = {};
  final Map<String, String> _userNameCache = {};

  final List<String> _statuses = [
    'All',
    'Draft',
    'Sent',
    'Viewed',
    'Follow-up',
    'Negotiation',
    'Approved',
    'Rejected',
    'Converted',
    'Cancelled',
  ];

  final List<String> _sortOptions = [
    'Date: Newest',
    'Date: Oldest',
    'Amount: High to Low',
    'Amount: Low to High',
  ];

  Query<Map<String, dynamic>>? _primaryQuery;
  CollectionReference<Map<String, dynamic>>? _quotationCollection;
  String? _loadedTenantId;

  bool get _isAdminOrManager {
    final role = _currentUserRole.trim().toLowerCase().replaceAll('_', '');
    return [
      'admin',
      'manager',
      'owner',
      'founder',
      'ceo',
      'superadmin',
      'director',
      'md',
    ].contains(role);
  }

  bool _hasQuotationPermission(Map<String, dynamic> userData) {
    return true;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tenantId = context.watchTenant.selectedTenantId.trim();
    if (tenantId.isEmpty && _loadedTenantId == null) {
      _loadedTenantId = '';
      setState(() {
        _errorMessage = 'Select a company workspace first.';
        _isLoadingContext = false;
      });
      return;
    }
    if (tenantId.isNotEmpty && tenantId != _loadedTenantId) {
      _loadedTenantId = tenantId;
      _loadUserContext(tenantId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserContext(String tenantId) async {
    try {
      final safeTenantId = TenantFirestore.requireTenantId(tenantId);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'User authentication required. Please log in again.';
            _isLoadingContext = false;
          });
        }
        return;
      }

      _currentUserUid = user.uid;
      _companyId = safeTenantId;
      Map<String, dynamic> userData = {
        'companyId': safeTenantId,
        'tenantId': safeTenantId,
      };

      final companyUserDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(safeTenantId)
          .collection('users')
          .doc(user.uid)
          .get();
      if (companyUserDoc.exists && companyUserDoc.data() != null) {
        userData.addAll(companyUserDoc.data()!);
      }

      _currentUserRole = (userData['role'] ?? 'sales').toString().trim();
      _currentUserName =
          (userData['name'] ??
                  userData['fullName'] ??
                  userData['displayName'] ??
                  user.email ??
                  '')
              .toString()
              .trim();

      if (!_hasQuotationPermission(userData)) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Access Denied: You lack permissions to view quotations.';
            _isLoadingContext = false;
          });
        }
        return;
      }

      _setupQueries(safeTenantId);

      if (mounted) {
        setState(() {
          _isLoadingContext = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to load user context safely. Please try again.';
          _isLoadingContext = false;
        });
      }
    }
  }

  void _setupQueries(String companyId) {
    _quotationCollection = TenantFirestore(
      tenantId: companyId,
    ).collection('quotations');
    Query<Map<String, dynamic>> query = _quotationCollection!;

    if (!_isAdminOrManager && _currentUserUid != null) {
      query = query.where('createdBy', isEqualTo: _currentUserUid);
    }

    _primaryQuery = query;
  }

  String _safeString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final str = value.toString().trim();
    return str.isEmpty ? fallback : str;
  }

  String _parseSafeString(dynamic val, {String fallback = ''}) {
    if (val == null) return fallback;
    final str = val.toString().trim();
    return str.isEmpty ? fallback : str;
  }

  String _formatCompactDate(DateTime? date) {
    if (date == null) return '-';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String _money(dynamic value) {
    final parsed = double.tryParse(value?.toString() ?? '0') ?? 0.0;
    return '₹ ${parsed.toStringAsFixed(2)}';
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  List<Map<String, dynamic>> _mapQuotationItemsToCustomerPoItems(
    List<dynamic> rawItems,
  ) {
    return rawItems
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw);
          final quantity = _number(item['quantity']);
          final rate = _number(
            item['unitPrice'] ?? item['unitRate'] ?? item['rate'],
          );
          final amount = _number(
            item['subtotal'] ??
                item['basicAmount'] ??
                item['totalAmount'] ??
                quantity * rate,
          );
          final gstPercent =
              _number(item['gstPercent']) +
              _number(item['cgstPercent']) +
              _number(item['sgstPercent']) +
              _number(item['igstPercent']);

          return {
            ...item,
            'id': item['id']?.toString() ?? '',
            'quotationItemId': item['id']?.toString() ?? '',
            'itemName': _firstText([item['itemName'], item['name']]),
            'description': _firstText([
              item['description'],
              item['itemName'],
              item['name'],
            ]),
            'quantity': quantity,
            'uom': _firstText([item['uom'], item['unit']]).isEmpty
                ? 'Nos'
                : _firstText([item['uom'], item['unit']]),
            'unit': _firstText([item['uom'], item['unit']]).isEmpty
                ? 'Nos'
                : _firstText([item['uom'], item['unit']]),
            'unitRate': rate,
            'rate': rate,
            'gstPercent': gstPercent,
            'basicAmount': amount,
            'amount': amount,
            'totalAmount': amount + (amount * gstPercent / 100),
          };
        })
        .toList(growable: false);
  }

  Future<String> _getUserName(String uid) async {
    if (uid.isEmpty) return 'Unknown';
    if (_userNameCache.containsKey(uid)) {
      return _userNameCache[uid]!;
    }
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection(_kCollectionUsers)
          .doc(uid)
          .get();

      if (docSnap.exists) {
        final data = docSnap.data();
        final name = _safeString(
          data?['name'] ?? data?['fullName'],
          fallback: 'Unknown',
        );
        _userNameCache[uid] = name;
        return name;
      }
    } catch (e) {
      debugPrint('Error fetching user name for $uid: $e');
    }
    _userNameCache[uid] = 'Unknown';
    return 'Unknown';
  }

  Future<void> _openCreateQuotation() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            QuotationScreenLocal(userId: widget.userId, companyId: _companyId),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openQuotationForEdit(
    String docId,
    Map<String, dynamic> data,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuotationScreenLocal(
          userId: widget.userId,
          companyId: _companyId,
          quotationId: docId,
          existingQuotation: data,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openQuotationPreview(Map<String, dynamic> data) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      final safeData = Map<String, dynamic>.from(data);

      final quoteDate =
          (safeData['quoteDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      safeData['quoteDateStr'] =
          '${quoteDate.day.toString().padLeft(2, '0')}/${quoteDate.month.toString().padLeft(2, '0')}/${quoteDate.year}';

      if (safeData['companyName'] == null && _companyId != null) {
        final companyDoc = await FirebaseFirestore.instance
            .collection(_kCollectionCompanies)
            .doc(_companyId)
            .get();
        if (companyDoc.exists) {
          final companyData = companyDoc.data() ?? {};

          safeData['companyName'] ??=
              companyData['companyName'] ?? companyData['name'] ?? '';
          safeData['companyAddress'] ??=
              companyData['companyAddress'] ?? companyData['address'] ?? '';
          safeData['companyPhone'] ??=
              companyData['companyPhone'] ?? companyData['phone'] ?? '';
          safeData['companyEmail'] ??=
              companyData['companyEmail'] ?? companyData['email'] ?? '';
          safeData['companyLogoUrl'] ??=
              companyData['companyLogoUrl'] ?? companyData['logoUrl'] ?? '';
          safeData['companyGst'] ??=
              companyData['companyGst'] ??
              companyData['gstin'] ??
              companyData['gstNo'] ??
              '';
          safeData['companyPan'] ??=
              companyData['companyPan'] ?? companyData['pan'] ?? '';
          safeData['companyIec'] ??=
              companyData['companyIec'] ?? companyData['iec'] ?? '';
          safeData['companyWebsite'] ??=
              companyData['companyWebsite'] ?? companyData['website'] ?? '';
        }
      }

      final itemsList = (safeData['items'] is List)
          ? (safeData['items'] as List)
          : [];
      final parsedItems = itemsList
          .map(
            (e) =>
                QuotationLineItem.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              QuotationPreviewScreen(quotation: safeData, items: parsedItems),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      _showSnack('Failed to load preview: $e', isError: true);
    }
  }

  Future<void> _convertToCustomerPo(
    String docId,
    Map<String, dynamic> data,
  ) async {
    if (_companyId == null) {
      _showSnack('Company context missing. Cannot convert.', isError: true);
      return;
    }

    if (_convertingDocs[docId] == true) {
      _showSnack('Conversion in progress. Please wait.');
      return;
    }

    final hasCustomerPo =
        data['convertedToCustomerPo'] == true ||
        _parseSafeString(data['convertedToCustomerPoId']).isNotEmpty;
    if (hasCustomerPo) {
      _showSnack('Already converted to Customer PO.', isError: true);
      return;
    }

    final String status = data['status']?.toString() ?? 'Draft';
    final String approval = data['approvalStatus']?.toString() ?? 'Pending';
    bool isApproved = status == 'Approved' || approval == 'Approved';

    if (!isApproved) {
      _showSnack(
        'Quotation must be Approved before converting to Customer PO.',
        isError: true,
      );
      return;
    }
    if ((_companyId ?? '').trim().isEmpty) {
      _showSnack(
        'Missing company workspace. Customer PO was not created.',
        isError: true,
      );
      return;
    }

    final confirm = await _showConfirmDialog(
      'Convert to Customer PO',
      'Convert quotation ${data['quoteNumber']} to a Customer PO draft?',
    );
    if (confirm != true) return;

    if (!mounted) return;

    setState(() => _convertingDocs[docId] = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection(_kCollectionCompanies)
          .doc(_companyId)
          .collection(_kCollectionQuotations)
          .doc(docId);

      final poCollection = FirebaseFirestore.instance
          .collection(_kCollectionCompanies)
          .doc(_companyId)
          .collection(_kCollectionCustomerPos);

      final existingPo = await poCollection
          .where('linkedQuotationId', isEqualTo: docId)
          .limit(1)
          .get();
      if (existingPo.docs.isNotEmpty) {
        await docRef.update({
          'convertedToCustomerPo': true,
          'convertedToCustomerPoId': existingPo.docs.first.id,
          'isConverting': false,
          'convertingStartedAt': null,
        });
        _showSnack('Customer PO already exists for this quotation.');
        return;
      }

      final newPoRef = poCollection.doc();

      bool canProceed = false;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Quotation not found.');
        }

        final docData = snapshot.data()!;
        final isConvertedToCustomerPo =
            docData['convertedToCustomerPo'] == true ||
            _parseSafeString(docData['convertedToCustomerPoId']).isNotEmpty;
        final isConvertingFlag = docData['isConverting'] == true;

        if (isConvertedToCustomerPo) {
          throw Exception('Already converted to Customer PO.');
        }

        if (isConvertingFlag) {
          final convertingStartedAt =
              docData['convertingStartedAt'] as Timestamp?;
          if (convertingStartedAt != null) {
            final elapsed = DateTime.now().difference(
              convertingStartedAt.toDate(),
            );
            if (elapsed.inMinutes < 2) {
              throw Exception(
                'Another user is currently converting this quotation.',
              );
            }
          } else {
            throw Exception(
              'Another user is currently converting this quotation.',
            );
          }
        }

        transaction.update(docRef, {
          'isConverting': true,
          'convertingStartedAt': FieldValue.serverTimestamp(),
        });
        canProceed = true;
      });

      if (!canProceed) return;

      final poNumber = await CustomerPoNumberService.nextInternalPoNumber(
        companyId: _companyId!,
      );
      final customerPoData = {
        'id': newPoRef.id,
        'companyId': _companyId,
        'tenantId': _companyId,
        'internalPoNo': poNumber,
        'customerPoNumber': '',
        'customerPoNo': poNumber,
        'poNumber': poNumber,
        'linkedQuotationId': docId,
        'quotationId': docId,
        'quotationNumber': _parseSafeString(data['quoteNumber']),
        'linkedQuotationRevisionId': _parseSafeString(data['version']),
        'customerId': _parseSafeString(data['customerId']),
        'customerName': _parseSafeString(data['clientName']),
        'customerEmail': _parseSafeString(data['clientEmail']),
        'customerMobile': _parseSafeString(data['clientMobile']),
        'customerAddress': _parseSafeString(data['clientAddress']),
        'customerGstNumber': _parseSafeString(data['gstNo']),
        'customerGstin': _parseSafeString(data['gstNo']),
        'projectName': _parseSafeString(data['subject']),
        'subject': _parseSafeString(data['subject']),
        'siteLocation': _parseSafeString(data['siteLocation']),
        'status': 'Draft',
        'documentType': 'customer_po',
        'items': _mapQuotationItemsToCustomerPoItems(
          data['items'] as List? ?? [],
        ),
        'basicValue': _number(data['totalSubtotal'] ?? data['subtotal']),
        'totalBasic': _number(data['totalSubtotal'] ?? data['subtotal']),
        'gstAmount': _number(
          data['totalTax'] ??
              (_number(data['totalCgst']) +
                  _number(data['totalSgst']) +
                  _number(data['totalIgst'])),
        ),
        'totalTax': _number(
          data['totalTax'] ??
              (_number(data['totalCgst']) +
                  _number(data['totalSgst']) +
                  _number(data['totalIgst'])),
        ),
        'grandTotal': _number(data['grandTotal'] ?? data['finalTotal']),
        'totalValue': _number(data['grandTotal'] ?? data['finalTotal']),
        'poDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _currentUserUid,
        'createdByName': _currentUserName,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _currentUserUid,
        'activities': [
          {
            'type': 'Created',
            'note': 'Customer PO draft generated from Quotation $docId',
            'timestamp': Timestamp.now(),
            'byUid': _currentUserUid ?? 'system',
          },
        ],
      };

      await newPoRef.set(customerPoData);

      await docRef.update({
        'status': 'Converted',
        'convertedToCustomerPo': true,
        'convertedToCustomerPoId': newPoRef.id,
        'internalPoNo': poNumber,
        'convertedAt': FieldValue.serverTimestamp(),
        'convertedBy': _currentUserUid,
        'isConverting': false,
        'convertingStartedAt': null,
        'activities': FieldValue.arrayUnion([
          {
            'type': 'Converted',
            'quotationId': docId,
            'customerPoId': newPoRef.id,
            'timestamp': Timestamp.now(),
            'user': {
              'uid': _currentUserUid,
              'name': _currentUserName,
              'role': _currentUserRole,
            },
            'system': {
              'platform': 'flutter',
              'module': 'quotation_to_customer_po',
              'version': '1.0',
            },
            'note': 'Quotation successfully converted to Customer PO',
          },
        ]),
      });

      _showSnack('Quotation successfully converted to Customer PO.');
    } catch (e) {
      _showSnack(
        'Conversion failed: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );

      try {
        final docRef = FirebaseFirestore.instance
            .collection(_kCollectionCompanies)
            .doc(_companyId)
            .collection(_kCollectionQuotations)
            .doc(docId);
        await docRef.update({
          'isConverting': false,
          'convertingStartedAt': null,
        });
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() {
          _convertingDocs.remove(docId);
        });
      }
    }
  }

  Future<void> _createRevision(String docId, Map<String, dynamic> data) async {
    final inquiryId = data['inquiryId'] ?? data['inquiryRefNo'];
    if (inquiryId == null || inquiryId.toString().trim().isEmpty) {
      _showSnack(
        'Warning: Cannot revise a quotation that is not linked to an Inquiry.',
        isError: true,
      );
      return;
    }

    final confirm = await _showConfirmDialog(
      'Create Revision',
      'Create a new version of quotation ${data['quoteNumber']}?',
    );
    if (confirm != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      final oldRef = _quotationCollection!.doc(docId);
      batch.update(oldRef, {
        'isLatest': false,
        'status': 'Revised',
        'lastEditedAt': FieldValue.serverTimestamp(),
        'lastEditedBy': _currentUserUid,
      });

      final newRef = _quotationCollection!.doc();
      final currentVersion = (data['version'] as int?) ?? 1;

      final newData = Map<String, dynamic>.from(data)
        ..['id'] = newRef.id
        ..['version'] = currentVersion + 1
        ..['parentQuotationId'] = docId
        ..['isLatest'] = true
        ..['status'] = 'Draft'
        ..['approvalStatus'] = 'Pending'
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['createdBy'] = _currentUserUid
        ..['createdByName'] = _currentUserName
        ..['lastEditedAt'] = FieldValue.serverTimestamp()
        ..['lastEditedBy'] = _currentUserUid
        ..['activities'] = [
          {
            'type': 'Revised',
            'quotationId': newRef.id,
            'parentQuotationId': docId,
            'timestamp': Timestamp.now(),
            'user': {
              'uid': _currentUserUid,
              'name': _currentUserName,
              'role': _currentUserRole,
            },
            'system': {
              'platform': 'flutter',
              'module': 'quotation_revision',
              'version': '1.0',
            },
            'note': 'Revision ${currentVersion + 1} created from $docId',
          },
        ];

      batch.set(newRef, newData);
      await batch.commit();

      _showSnack('Revision ${currentVersion + 1} created successfully.');
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack('Failed to create revision: $e', isError: true);
    }
  }

  Future<void> _updateApproval(String docId, String status) async {
    try {
      await _quotationCollection!.doc(docId).update({
        'approvalStatus': status,
        if (status == 'Approved') 'status': 'Approved',
        'approvedBy': status == 'Approved' ? _currentUserUid : null,
        'lastEditedAt': FieldValue.serverTimestamp(),
        'lastEditedBy': _currentUserUid,
        'activities': FieldValue.arrayUnion([
          {
            'type': 'Approval Update',
            'quotationId': docId,
            'timestamp': Timestamp.now(),
            'user': {
              'uid': _currentUserUid,
              'name': _currentUserName,
              'role': _currentUserRole,
            },
            'system': {
              'platform': 'flutter',
              'module': 'quotation_approval',
              'version': '1.0',
            },
            'note': 'Approval set to $status',
          },
        ]),
      });
      _showSnack('Quotation $status');
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack('Failed to update approval: $e', isError: true);
    }
  }

  Future<void> _cancelQuotation(String docId) async {
    final confirm = await _showConfirmDialog(
      'Cancel Quotation',
      'Are you sure you want to cancel this quotation?',
    );
    if (confirm != true) return;

    try {
      await _quotationCollection!.doc(docId).update({
        'status': 'Cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': _currentUserUid,
        'activities': FieldValue.arrayUnion([
          {
            'type': 'Cancelled',
            'quotationId': docId,
            'timestamp': Timestamp.now(),
            'user': {
              'uid': _currentUserUid,
              'name': _currentUserName,
              'role': _currentUserRole,
            },
            'system': {
              'platform': 'flutter',
              'module': 'quotation_cancel',
              'version': '1.0',
            },
            'note': 'Quotation cancelled',
          },
        ]),
      });

      _showSnack('Quotation Cancelled');
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack('Failed to cancel: $e', isError: true);
    }
  }

  Future<void> _deleteQuotation(String quotationId) async {
    final companyId = _companyId;
    if (companyId == null || companyId.trim().isEmpty) {
      _showSnack(
        'Missing company workspace. Quotation was not deleted.',
        isError: true,
      );
      return;
    }

    final confirm = await _showConfirmDialog(
      'Delete Quotation',
      'Delete this quotation permanently from Firestore?',
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('quotations')
          .doc(quotationId)
          .delete();

      _showSnack('Quotation deleted.');
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack('Failed to delete quotation: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyLocalFilters(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final search = _searchText.trim().toLowerCase();

    var filtered = docs.where((doc) {
      final data = doc.data();

      if (data['quoteNumber'] == null) {
        return false;
      }

      final quoteNumber = data['quoteNumber'].toString().toLowerCase();
      final customer = (data['clientName'] ?? '').toString().toLowerCase();
      final status = (data['status'] ?? 'Draft').toString();
      final isDeleted = data['isDeleted'] == true;
      final isLatest = data['isLatest'] != false;

      final matchesSearch =
          search.isEmpty ||
          quoteNumber.contains(search) ||
          customer.contains(search);
      final matchesStatus =
          _statusFilter == 'All' ||
          status.toLowerCase() == _statusFilter.toLowerCase();

      return !isDeleted && isLatest && matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      final dataA = a.data();
      final dataB = b.data();

      if (_sortOption.startsWith('Amount')) {
        final amtA =
            double.tryParse(dataA['grandTotal']?.toString() ?? '0') ?? 0;
        final amtB =
            double.tryParse(dataB['grandTotal']?.toString() ?? '0') ?? 0;
        return _sortOption.contains('High')
            ? amtB.compareTo(amtA)
            : amtA.compareTo(amtB);
      } else {
        final dateA =
            (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final dateB =
            (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return _sortOption.contains('Newest')
            ? dateB.compareTo(dateA)
            : dateA.compareTo(dateB);
      }
    });

    return filtered;
  }

  Future<void> _openFilterSheet() async {
    String tempStatus = _statusFilter;
    String tempSort = _sortOption;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
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
                      'Filters & Sort',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: tempStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _statuses
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          tempStatus = value ?? 'All';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: tempSort,
                      decoration: const InputDecoration(
                        labelText: 'Sort By',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _sortOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          tempSort = value ?? 'Date: Newest';
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _statusFilter = 'All';
                                _sortOption = 'Date: Newest';
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _statusFilter = tempStatus;
                                _sortOption = tempSort;
                              });
                              Navigator.pop(context);
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
          },
        );
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _statusFilter = 'All';
      _sortOption = 'Date: Newest';
    });
  }

  bool get _hasActiveFilters =>
      _statusFilter != 'All' || _sortOption != 'Date: Newest';

  @override
  Widget build(BuildContext context) {
    if (_isLoadingContext) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    if (_primaryQuery == null) {
      return const Scaffold(
        body: Center(child: Text('System initialization failed')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 6,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Quote',
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: _openCreateQuotation,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _primaryQuery!.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading quotations:\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final filteredDocs = _applyLocalFilters(docs);

          int totalQuotes = filteredDocs.length;
          int approved = 0;
          int converted = 0;
          int sent = 0;

          for (final doc in filteredDocs) {
            final status = (doc.data()['status'] ?? '')
                .toString()
                .toLowerCase();
            final approvalStatus = (doc.data()['approvalStatus'] ?? '')
                .toString()
                .toLowerCase();

            if (status == 'sent') sent++;
            if (status == 'approved' || approvalStatus == 'approved') {
              approved++;
            }
            if (status == 'converted') converted++;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchText = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search quotation, customer...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: _searchText.trim().isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear',
                                    icon: const Icon(Icons.close, size: 17),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchText = '';
                                      });
                                    },
                                  ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 38,
                      width: 38,
                      child: Material(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _openFilterSheet,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: Colors.grey.shade800,
                              ),
                              if (_hasActiveFilters)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade700,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _MiniStatText(
                      label: 'Total',
                      value: totalQuotes.toString(),
                    ),
                    const SizedBox(width: 10),
                    _MiniStatText(label: 'Sent', value: sent.toString()),
                    const SizedBox(width: 10),
                    _MiniStatText(
                      label: 'Approved',
                      value: approved.toString(),
                    ),
                    const SizedBox(width: 10),
                    _MiniStatText(
                      label: 'Converted',
                      value: converted.toString(),
                    ),
                  ],
                ),
              ),
              if (_hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filters applied',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: filteredDocs.isEmpty
                    ? _EmptyQuotationsState(
                        hasSearch:
                            _searchText.trim().isNotEmpty || _hasActiveFilters,
                        onReset: () {
                          _searchController.clear();
                          setState(() {
                            _searchText = '';
                          });
                          _resetFilters();
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        itemCount: filteredDocs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data();

                          final rawQNo =
                              data['quoteNumber']?.toString().trim() ?? '';
                          final qNo = rawQNo.isEmpty ? 'Draft' : rawQNo;
                          final version = data['version']?.toString() ?? '1';
                          final customer =
                              data['clientName']?.toString() ??
                              'Unknown Customer';

                          final amt = _money(data['grandTotal']);
                          final status = data['status']?.toString() ?? 'Draft';
                          final approval =
                              data['approvalStatus']?.toString() ?? 'Pending';
                          final paymentStat =
                              data['paymentStatus']?.toString() ?? 'Pending';
                          final inqRef =
                              (data['inquiryRefNo'] ??
                                      data['inquiryNumber'] ??
                                      data['inquiryId'] ??
                                      '')
                                  .toString();

                          bool isCancelled =
                              status.toLowerCase() == 'cancelled';
                          bool isApproved =
                              status.toLowerCase() == 'approved' ||
                              approval.toLowerCase() == 'approved';
                          final hasCustomerPo =
                              data['convertedToCustomerPo'] == true ||
                              _parseSafeString(
                                data['convertedToCustomerPoId'],
                              ).isNotEmpty;

                          bool isConverting = _convertingDocs[doc.id] == true;

                          final String createdByUid = _parseSafeString(
                            data['createdBy'],
                          );
                          final String explicitlyStoredName =
                              data['createdByName']?.toString().trim() ?? '';

                          final Timestamp? createdAtRaw =
                              data['createdAt'] as Timestamp?;
                          final Timestamp? nextFollowUpRaw =
                              data['nextFollowUpDate'] as Timestamp?;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 0.8,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                10,
                              ), // Condensed padding
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius:
                                            18, // Slightly more compact avatar
                                        backgroundColor: Colors.blue.shade50,
                                        child: Text(
                                          customer.isNotEmpty
                                              ? customer[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$qNo (v$version)',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 1,
                                            ), // Tighter spacing
                                            Text(
                                              customer,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          tooltip: 'Actions',
                                          icon: Icon(
                                            Icons.more_vert,
                                            size: 20,
                                            color: Colors.grey.shade600,
                                          ),
                                          onSelected: (val) {
                                            if (val == 'view') {
                                              _openQuotationPreview(data);
                                            } else if (val == 'edit') {
                                              _openQuotationForEdit(
                                                doc.id,
                                                data,
                                              );
                                            } else if (val == 'delete') {
                                              _deleteQuotation(doc.id);
                                            } else if (val == 'approve') {
                                              _updateApproval(
                                                doc.id,
                                                'Approved',
                                              );
                                            } else if (val == 'reject') {
                                              _updateApproval(
                                                doc.id,
                                                'Rejected',
                                              );
                                            } else if (val == 'convert') {
                                              _convertToCustomerPo(
                                                doc.id,
                                                data,
                                              );
                                            } else if (val == 'revision') {
                                              _createRevision(doc.id, data);
                                            } else if (val == 'cancel') {
                                              _cancelQuotation(doc.id);
                                            }
                                          },
                                          itemBuilder: (context) {
                                            List<PopupMenuEntry<String>> items =
                                                [
                                                  const PopupMenuItem(
                                                    value: 'view',
                                                    child: Text(
                                                      'View Quotation',
                                                    ),
                                                  ),
                                                ];

                                            items.add(
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit Quotation'),
                                              ),
                                            );

                                            items.add(
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text(
                                                  'Delete Quotation',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            );

                                            if (!isCancelled) {
                                              items.add(
                                                const PopupMenuDivider(),
                                              );

                                              if (approval.toLowerCase() !=
                                                      'approved' &&
                                                  approval.toLowerCase() !=
                                                      'rejected') {
                                                items.add(
                                                  const PopupMenuItem(
                                                    value: 'approve',
                                                    child: Text('Approve'),
                                                  ),
                                                );
                                                items.add(
                                                  const PopupMenuItem(
                                                    value: 'reject',
                                                    child: Text('Reject'),
                                                  ),
                                                );
                                              }

                                              if (isApproved &&
                                                  !hasCustomerPo &&
                                                  !isConverting) {
                                                items.add(
                                                  const PopupMenuItem(
                                                    value: 'convert',
                                                    child: Text(
                                                      'Convert to Customer PO',
                                                    ),
                                                  ),
                                                );
                                              }

                                              items.add(
                                                const PopupMenuItem(
                                                  value: 'revision',
                                                  child: Text(
                                                    'Create Revision',
                                                  ),
                                                ),
                                              );

                                              items.add(
                                                const PopupMenuDivider(),
                                              );
                                              items.add(
                                                const PopupMenuItem(
                                                  value: 'cancel',
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }

                                            return items;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _InfoChip(
                                        label: status,
                                        backgroundColor: _getQuotationStatusBg(
                                          status,
                                        ),
                                        textColor: _getQuotationStatusFg(
                                          status,
                                        ),
                                      ),
                                      if (approval != 'Pending')
                                        _InfoChip(
                                          label: approval,
                                          backgroundColor:
                                              _getQuotationStatusBg(
                                                approval,
                                                isApproval: true,
                                              ),
                                          textColor: _getQuotationStatusFg(
                                            approval,
                                            isApproval: true,
                                          ),
                                        ),
                                      if (status.toLowerCase() == 'converted')
                                        _InfoChip(
                                          label: paymentStat,
                                          backgroundColor:
                                              _getQuotationStatusBg(
                                                paymentStat,
                                                isPayment: true,
                                              ),
                                          textColor: _getQuotationStatusFg(
                                            paymentStat,
                                            isPayment: true,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (inqRef.isNotEmpty)
                                        _InlineInfo(
                                          icon: Icons.tag_outlined,
                                          text: 'INQ: $inqRef',
                                        ),
                                      if (explicitlyStoredName.isNotEmpty)
                                        _InlineInfo(
                                          icon: Icons.person_outline,
                                          text: explicitlyStoredName,
                                        )
                                      else
                                        FutureBuilder<String>(
                                          future: _getUserName(createdByUid),
                                          builder: (context, snapshot) {
                                            return _InlineInfo(
                                              icon: Icons.person_outline,
                                              text: snapshot.data ?? '...',
                                            );
                                          },
                                        ),
                                      _InlineInfo(
                                        icon: Icons.currency_rupee_outlined,
                                        text: amt,
                                      ),
                                      _InlineInfo(
                                        icon: Icons.add_circle_outline,
                                        text:
                                            'Created: ${_formatCompactDate(createdAtRaw?.toDate())}',
                                      ),
                                      if (nextFollowUpRaw != null)
                                        _InlineInfo(
                                          icon: Icons.event_repeat_outlined,
                                          text:
                                              'Next: ${_formatCompactDate(nextFollowUpRaw.toDate())}',
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getQuotationStatusBg(
    String status, {
    bool isApproval = false,
    bool isPayment = false,
  }) {
    String s = status.toLowerCase();
    if (isPayment) {
      if (s == 'paid') return Colors.green.shade50;
      if (s == 'partial') return Colors.orange.shade50;
      return Colors.red.shade50;
    } else {
      if (s == 'draft') return Colors.orange.shade50;
      if (s == 'sent' || s == 'viewed') return Colors.blue.shade50;
      if (s == 'approved' || s == 'converted') return Colors.green.shade50;
      if (s == 'rejected') return Colors.red.shade50;
      if (s == 'follow-up' || s == 'negotiation') return Colors.purple.shade50;
      if (s == 'cancelled') return Colors.red.shade100;
      return Colors.grey.shade100;
    }
  }

  Color _getQuotationStatusFg(
    String status, {
    bool isApproval = false,
    bool isPayment = false,
  }) {
    String s = status.toLowerCase();
    if (isPayment) {
      if (s == 'paid') return Colors.green.shade800;
      if (s == 'partial') return Colors.orange.shade800;
      return Colors.red.shade800;
    } else {
      if (s == 'draft') return Colors.orange.shade800;
      if (s == 'sent' || s == 'viewed') return Colors.blue.shade800;
      if (s == 'approved' || s == 'converted') return Colors.green.shade800;
      if (s == 'rejected') return Colors.red.shade800;
      if (s == 'follow-up' || s == 'negotiation') return Colors.purple.shade800;
      if (s == 'cancelled') return Colors.red.shade900;
      return Colors.grey.shade800;
    }
  }
}

class _MiniStatText extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStatText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ), // Slightly smaller, softer icon
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12, // Condensed size
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _InfoChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // Tighter padding
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11, // Condensed font for secondary chips
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _EmptyQuotationsState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onReset;

  const _EmptyQuotationsState({required this.hasSearch, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: IntrinsicHeight(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(
                        hasSearch ? Icons.search_off : Icons.inbox_outlined,
                        size: 34,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      hasSearch
                          ? 'No matching quotations found'
                          : 'No quotations found',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasSearch
                          ? 'Try changing the search text or filter.'
                          : 'No quotation records are available yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (hasSearch)
                      OutlinedButton(
                        onPressed: onReset,
                        child: const Text('Reset Filters'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
