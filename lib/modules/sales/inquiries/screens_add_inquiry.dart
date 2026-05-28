// 📄 File Path: lib/modules/sales/inquiries/screens_add_inquiry.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'widgets/inquiry_items_grid.dart';
import 'package:intl/intl.dart';

import 'package:QUIK/core/tenancy/tenant_firestore.dart';
import 'package:QUIK/models/inquiry_model.dart';
import 'package:QUIK/modules/crm/customers/screens_add_customer.dart';
import 'package:QUIK/modules/sales/quotations/quotation_screen_local.dart';
import 'package:QUIK/modules/sales/inquiries/controllers/add_inquiry_controllers.dart';

part 'widgets/add_inquiry_insights_section.dart';
part 'widgets/add_inquiry_products_section.dart';
part 'widgets/add_inquiry_commercial_section.dart';
part 'widgets/add_inquiry_followup_section.dart';
part 'widgets/add_inquiry_activity_timeline.dart';

class ScreensAddInquiry extends StatefulWidget {
  final String companyId;
  final String currentUserUid;
  final String currentUserRole;
  final DocumentReference<Map<String, dynamic>>? existingDoc;
  final Inquiry? existingInquiry;

  const ScreensAddInquiry({
    super.key,
    required this.companyId,
    required this.currentUserUid,
    required this.currentUserRole,
    this.existingDoc,
    this.existingInquiry,
  });

  @override
  State<ScreensAddInquiry> createState() => _ScreensAddInquiryState();
}

class _ScreensAddInquiryState extends State<ScreensAddInquiry> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Core Identifiers & DRY Snapshots
  String? _selectedCustomerId;
  String? _selectedContactId;
  List<String> _additionalContactIds = [];
  String? _assignedToUid;

  String _customerNameSnapshot = '';
  String _customerIndustrySnapshot = '';
  String _customerCitySnapshot = '';

  // CRM Classification
  String? _selectedSource;
  String? _selectedType;
  String _selectedPriority = 'Warm';
  String _suggestedPriority = 'Warm';
  String _selectedStage = 'Lead';
  String _selectedStatus = 'Open';
  String? _previousStage;

  final List<String> _pipelineStages = [
    'Lead',
    'Qualified',
    'Proposal',
    'Negotiation',
    'Won',
    'Lost',
  ];

  // Follow-up
  DateTime? _nextFollowUpDate;
  String _followUpType = 'Call';
  DateTime? _expectedClosureDate;

  // Deal Intelligence
  double _probability = 50.0;
  int _dealScore = 0;
  List<String> _tags = [];

  final AddInquiryControllers _controllers = AddInquiryControllers();

  // Inquiry items become the shared source for quotation, BOM, production, and dispatch.
  List<Map<String, dynamic>> _structuredProducts = [];

  // State Flags
  bool _isSaving = false;
  String? _formMessage;
  final Map<String, bool> _sectionExpanded = {
    'Customer & Contacts': true,
    'Inquiry Basics': true,
    'Inquiry Items & Engineering Scope': true,
    'Commercial & Intelligence': true,
    'Follow-up & Activity': false,
    'Notes & Attachments': false,
  };

  // Enterprise Caching & Concurrency Control
  Map<String, dynamic>? _selectedCustomerData;
  Map<String, dynamic>? _selectedContactData;
  Map<String, dynamic>? _assignedUserData;
  Map<String, dynamic>? _existingRawData;

  Timer? _debounceTimer;
  final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _customerSearchCache = {};
  List<DocumentSnapshot<Map<String, dynamic>>> _customerSuggestions = [];

  bool get _isEditing => widget.existingDoc != null;
  String get _tenantId => widget.companyId.trim();

  bool get _isAdminOrManager {
    final role = widget.currentUserRole.trim().toLowerCase();
    return [
      'admin',
      'manager',
      'director',
      'md',
      'ceo',
      'superadmin',
    ].contains(role);
  }

  // Firestore References
  CollectionReference<Map<String, dynamic>> get _companyCustomersRef =>
      TenantFirestore(tenantId: _tenantId).collection('customers');

  CollectionReference<Map<String, dynamic>> get _companyUsersRef =>
      TenantFirestore(tenantId: _tenantId).collection('users');

  CollectionReference<Map<String, dynamic>> get _companyInquiriesRef =>
      TenantFirestore(tenantId: _tenantId).collection('inquiries');

  CollectionReference<Map<String, dynamic>> get _companyCountersRef =>
      TenantFirestore(tenantId: _tenantId).collection('counters');

  CollectionReference<Map<String, dynamic>> _companyContactsRef(
    String customerId,
  ) {
    return _companyCustomersRef.doc(customerId).collection('contacts');
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!_isEditing && !_isAdminOrManager) {
      _assignedToUid = widget.currentUserUid;
    }
    _hydrateFromInquiry();
    await _loadExtraData();
    _calculateDealScore();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _controllers.subject.dispose();
    _controllers.sourceRef.dispose();
    _controllers.expectedValue.dispose();
    _controllers.budget.dispose();
    _controllers.deliveryTimeline.dispose();
    _controllers.projectSiteLocation.dispose();
    _controllers.competitor.dispose();
    _controllers.decisionMaker.dispose();
    _controllers.notes.dispose();
    _controllers.internalNotes.dispose();
    _controllers.lastFollowUpNote.dispose();
    _controllers.linkedQuotationId.dispose();
    _controllers.lossReason.dispose();
    _controllers.tag.dispose();
    _controllers.customerSearch.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // STRUCTURED ERROR HANDLING
  // ---------------------------------------------------------
  void _handleError(String contextMessage, Object error, [StackTrace? st]) {
    developer.log(
      'Error: $contextMessage',
      error: error,
      stackTrace: st,
      name: 'InquiryModule',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$contextMessage: ${error.toString().replaceAll("Exception: ", "")}',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _setFormMessage(String? message) {
    if (!mounted) return;
    setState(() {
      _formMessage = message;
    });
  }

  void _showValidationMessage(String message) {
    _setFormMessage(message);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  String _statusForStage(String stage) {
    switch (stage) {
      case 'Won':
        return 'Won';
      case 'Lost':
        return 'Lost';
      default:
        return 'Open';
    }
  }

  String _normalizeText(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  }

  Map<String, double?> _parseBudgetRange(String text) {
    final matches = RegExp(r'\d+(?:\.\d+)?').allMatches(text);
    final values = matches
        .map((m) => double.tryParse(m.group(0) ?? ''))
        .whereType<double>()
        .toList();

    if (values.isEmpty) {
      return {'min': null, 'max': null};
    }
    if (values.length == 1) {
      return {'min': values.first, 'max': values.first};
    }
    values.sort();
    return {'min': values.first, 'max': values.last};
  }

  String _buildProductFingerprint() {
    final tokens =
        _structuredProducts
            .map((item) {
              final productId = (item['productId'] ?? '').toString().trim();
              final name = _normalizeText((item['name'] ?? '').toString());
              final sku = _normalizeText((item['sku'] ?? '').toString());
              return [
                productId,
                sku,
                name,
              ].where((e) => e.isNotEmpty).join(':');
            })
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();

    return tokens.join('|');
  }

  String _buildRequirementFingerprint(String subjectSearch) {
    final location = _normalizeText(_controllers.projectSiteLocation.text);
    final deliveryTimeline = _normalizeText(_controllers.deliveryTimeline.text);
    return [
      subjectSearch,
      _buildProductFingerprint(),
      location,
      deliveryTimeline,
    ].where((e) => e.isNotEmpty).join('|');
  }

  String? _getStageTransitionError(String fromStage, String toStage) {
    if (fromStage == toStage) return null;

    final fromIndex = _pipelineStages.indexOf(fromStage);
    final toIndex = _pipelineStages.indexOf(toStage);
    if (fromIndex == -1 || toIndex == -1) return 'Invalid stage selection.';

    if (fromStage == 'Won' || fromStage == 'Lost') {
      return 'Closed inquiries cannot be moved back into the pipeline from this screen.';
    }

    if (toStage == 'Lost') {
      return null;
    }

    if (toStage == 'Won') {
      if (!(fromStage == 'Negotiation' || fromStage == 'Proposal')) {
        return 'You can mark an inquiry as Won only from Proposal or Negotiation.';
      }
      return null;
    }

    if (toIndex > fromIndex + 1) {
      return 'Move the inquiry one stage at a time to keep the pipeline accurate.';
    }

    return null;
  }

  void _applyStageSelection(String stage) {
    final currentStage = _selectedStage;
    final transitionError = _getStageTransitionError(currentStage, stage);
    if (transitionError != null) {
      _showValidationMessage(transitionError);
      return;
    }

    setState(() {
      _selectedStage = stage;
      _selectedStatus = _statusForStage(stage);
      if (stage == 'Won' || stage == 'Lost') {
        _nextFollowUpDate = null;
      }
      if (stage != 'Lost') {
        _controllers.lossReason.clear();
      }
      _formMessage = null;
    });
    _calculateDealScore();
  }

  void _hydrateFromInquiry() {
    final iq = widget.existingInquiry;
    if (iq == null) return;

    _controllers.subject.text = iq.subject;
    _controllers.sourceRef.text = iq.sourceReference;

    final expValStr = iq.expectedValue.toString();
    final expVal = double.tryParse(expValStr) ?? 0.0;
    _controllers.expectedValue.text = expVal > 0 ? expValStr : '';

    _controllers.deliveryTimeline.text = iq.deliveryTimeline;
    _controllers.projectSiteLocation.text = iq.location;
    _controllers.notes.text = iq.notes;
    _controllers.internalNotes.text = iq.internalNotes;
    _controllers.lastFollowUpNote.text = iq.lastFollowUpNote;
    _controllers.linkedQuotationId.text = iq.linkedQuotationId;

    _selectedPriority = iq.priority.isNotEmpty ? iq.priority : 'Warm';
    _selectedSource = iq.source.isNotEmpty ? iq.source : null;
    _selectedType = iq.inquiryType.isNotEmpty ? iq.inquiryType : null;
    _selectedStatus = iq.status.isNotEmpty
        ? iq.status
        : _statusForStage(_selectedStage);

    _assignedToUid = iq.assignedToUid.isNotEmpty ? iq.assignedToUid : null;
    _nextFollowUpDate = iq.nextFollowUpDate;
    _expectedClosureDate = iq.expectedClosureDate;
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  Future<void> _loadExtraData() async {
    if (widget.existingDoc == null) return;
    try {
      final existingSnap = await widget.existingDoc!.get();
      final data = existingSnap.data() ?? {};
      _existingRawData = data;

      if (!mounted) return;
      setState(() {
        _selectedCustomerId = _firstNonEmptyString([
          data['customerId'],
          _selectedCustomerId,
        ]);
        _selectedContactId = _firstNonEmptyString([
          data['contactId'],
          _selectedContactId,
        ]);
        if (data['additionalContactIds'] != null) {
          _additionalContactIds = List<String>.from(
            data['additionalContactIds'],
          );
        }

        _customerNameSnapshot = (data['customerName'] ?? '').toString();
        _customerIndustrySnapshot = (data['customerIndustry'] ?? '').toString();
        _customerCitySnapshot = (data['customerCity'] ?? '').toString();

        _controllers.subject.text =
            _firstNonEmptyString([
              data['subject'],
              _controllers.subject.text,
            ]) ??
            '';
        _controllers.sourceRef.text =
            _firstNonEmptyString([
              data['sourceReference'],
              _controllers.sourceRef.text,
            ]) ??
            '';

        if (data['expectedValue'] != null &&
            (double.tryParse(data['expectedValue'].toString()) ?? 0) > 0) {
          _controllers.expectedValue.text = data['expectedValue'].toString();
        }

        _controllers.budget.text =
            _firstNonEmptyString([data['budget'], _controllers.budget.text]) ??
            '';
        _controllers.competitor.text =
            _firstNonEmptyString([
              data['competitor'],
              _controllers.competitor.text,
            ]) ??
            '';
        _controllers.decisionMaker.text =
            _firstNonEmptyString([
              data['decisionMaker'],
              _controllers.decisionMaker.text,
            ]) ??
            '';

        _controllers.deliveryTimeline.text =
            _firstNonEmptyString([
              data['deliveryTimeline'],
              _controllers.deliveryTimeline.text,
            ]) ??
            '';
        _controllers.projectSiteLocation.text =
            _firstNonEmptyString([
              data['projectSiteLocation'],
              data['location'],
              _controllers.projectSiteLocation.text,
            ]) ??
            '';
        _controllers.notes.text =
            _firstNonEmptyString([data['notes'], _controllers.notes.text]) ??
            '';
        _controllers.internalNotes.text =
            _firstNonEmptyString([
              data['internalNotes'],
              _controllers.internalNotes.text,
            ]) ??
            '';
        _controllers.lastFollowUpNote.text =
            _firstNonEmptyString([
              data['lastFollowUpNote'],
              _controllers.lastFollowUpNote.text,
            ]) ??
            '';
        _controllers.linkedQuotationId.text =
            _firstNonEmptyString([
              data['linkedQuotationId'],
              _controllers.linkedQuotationId.text,
            ]) ??
            '';
        _controllers.lossReason.text =
            _firstNonEmptyString([
              data['lossReason'],
              _controllers.lossReason.text,
            ]) ??
            '';

        _selectedSource = _firstNonEmptyString([
          data['source'],
          _selectedSource,
        ]);
        _selectedType = _firstNonEmptyString([
          data['inquiryType'],
          _selectedType,
        ]);
        _selectedPriority =
            _firstNonEmptyString([data['priority'], _selectedPriority]) ??
            'Warm';
        _selectedStage =
            _firstNonEmptyString([data['stage'], 'Lead']) ?? 'Lead';
        _selectedStatus = _statusForStage(_selectedStage);
        _previousStage = _selectedStage;
        _followUpType =
            _firstNonEmptyString([data['followUpType'], 'Call']) ?? 'Call';
        _assignedToUid = _firstNonEmptyString([
          data['assignedToUid'],
          _assignedToUid,
        ]);

        _probability = (data['probability'] ?? 50.0).toDouble();
        _tags = List<String>.from(data['tags'] ?? []);

        if (data['products'] != null && (data['products'] as List).isNotEmpty) {
          _structuredProducts = List<Map<String, dynamic>>.from(
            data['products'],
          );
        } else if (data['requiredProducts'] != null &&
            data['requiredProducts'].toString().isNotEmpty) {
          _structuredProducts = [
            {
              'productId': 'legacy',
              'name': data['requiredProducts'],
              'quantity': data['quantityScope'] ?? '1',
              'price': 0.0,
              'unit': 'Nos',
              'sku': '',
            },
          ];
        }

        if (data['nextFollowUpDate'] != null &&
            data['nextFollowUpDate'] is Timestamp) {
          _nextFollowUpDate = (data['nextFollowUpDate'] as Timestamp).toDate();
        }
        if (data['expectedClosureDate'] != null &&
            data['expectedClosureDate'] is Timestamp) {
          _expectedClosureDate = (data['expectedClosureDate'] as Timestamp)
              .toDate();
        }
      });

      if (_selectedCustomerId != null) {
        await _loadCustomerData(_selectedCustomerId!);
        _controllers.customerSearch.text = _customerNameSnapshot;
        if (_selectedContactId != null) {
          await _loadContactData(_selectedCustomerId!, _selectedContactId!);
        }
      }
      if (_assignedToUid != null) {
        await _loadAssignedUserData(_assignedToUid!);
      }
      _calculateDealScore();
      if (mounted) setState(() {});
    } catch (e, st) {
      _handleError('Failed to load existing data', e, st);
    }
  }

  void _calculateDealScore() {
    int score = 0;
    double expectedVal =
        double.tryParse(_controllers.expectedValue.text.trim()) ?? 0;

    if (expectedVal > 500000) {
      score += 25;
    } else if (expectedVal > 50000) {
      score += 15;
    } else if (expectedVal > 0) {
      score += 5;
    }

    if (_expectedClosureDate != null) {
      score += 15;
    }
    if (_controllers.decisionMaker.text.trim().isNotEmpty) {
      score += 15;
    }

    if (_probability >= 75) {
      score += 20;
    } else if (_probability >= 40) {
      score += 10;
    }

    if (_nextFollowUpDate != null) {
      final daysDiff = _nextFollowUpDate!.difference(DateTime.now()).inDays;
      if (daysDiff >= 0 && daysDiff <= 7) {
        score += 15;
      } else if (daysDiff > 7) {
        score += 5;
      }
    }

    if (_structuredProducts.isNotEmpty) {
      score += 10;
    }

    int newScore = score.clamp(0, 100);

    String suggested = 'Cold';
    if (newScore >= 70) {
      suggested = 'Hot';
    } else if (newScore >= 40) {
      suggested = 'Warm';
    }

    if (_dealScore != newScore || _suggestedPriority != suggested) {
      if (mounted) {
        setState(() {
          _dealScore = newScore;
          _suggestedPriority = suggested;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // ENTERPRISE DEBOUNCED SEARCH + SYNCHRONOUS AUTOCOMPLETE
  // ---------------------------------------------------------
  void _triggerAsyncCustomerSearch(String query) {
    final q = query.toLowerCase().trim();
    if (_customerSearchCache.containsKey(q)) return;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        Query<Map<String, dynamic>> baseQuery = _companyCustomersRef.where(
          'isActive',
          isEqualTo: true,
        );
        QuerySnapshot<Map<String, dynamic>> snap;

        if (q.isEmpty) {
          snap = await baseQuery.limit(30).get();
        } else {
          snap = await baseQuery.limit(30).get();

          if (snap.docs.isEmpty) {
            final fallbackSnap = await baseQuery.limit(50).get();
            final list = fallbackSnap.docs.where((doc) {
              final data = doc.data();
              final name = (data['companyName'] ?? data['name'] ?? '')
                  .toString()
                  .toLowerCase();
              final phone = (data['phone'] ?? '').toString();
              return name.contains(q) || phone.contains(q);
            }).toList();

            _customerSearchCache[q] = list;
            if (mounted) {
              setState(() {
                _customerSuggestions = _filterCustomersByRole(list).toList();
              });
            }
            return;
          }
        }

        _customerSearchCache[q] = snap.docs;
        if (mounted) {
          setState(() {
            _customerSuggestions = _filterCustomersByRole(snap.docs).toList();
          });
        }
      } catch (e, st) {
        _handleError('Customer Search Failed', e, st);
      }
    });
  }

  Iterable<DocumentSnapshot<Map<String, dynamic>>> _getSyncCustomerOptions(
    String query,
  ) {
    final q = query.toLowerCase().trim();
    _triggerAsyncCustomerSearch(q);

    if (_customerSearchCache.containsKey(q)) {
      return _filterCustomersByRole(_customerSearchCache[q]!);
    }

    return _customerSuggestions;
  }

  Iterable<DocumentSnapshot<Map<String, dynamic>>> _filterCustomersByRole(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (_isAdminOrManager) return docs;
    return docs.where((d) {
      final data = d.data();
      return data['assignedToUid'] == widget.currentUserUid ||
          data['createdByUid'] == widget.currentUserUid ||
          data['createdBy'] == widget.currentUserUid;
    }).toList();
  }

  Future<void> _loadCustomerData(String? customerId) async {
    if (customerId == null || customerId.trim().isEmpty) return;
    try {
      final doc = await _companyCustomersRef.doc(customerId).get();
      if (doc.exists) {
        _selectedCustomerData = doc.data();
        if (mounted) {
          setState(() {
            _customerNameSnapshot =
                (_selectedCustomerData?['companyName'] ??
                        _selectedCustomerData?['name'] ??
                        '')
                    .toString();
            _customerIndustrySnapshot =
                (_selectedCustomerData?['industry'] ?? '').toString();
            _customerCitySnapshot = (_selectedCustomerData?['city'] ?? '')
                .toString();
          });
        }
      }
    } catch (e, st) {
      _handleError('Failed to load customer data', e, st);
    }
  }

  Future<void> _loadContactData(String customerId, String contactId) async {
    final doc = await _companyContactsRef(customerId).doc(contactId).get();
    _selectedContactData = doc.data();
  }

  Future<void> _loadAssignedUserData(String userId) async {
    final doc = await _companyUsersRef.doc(userId).get();
    _assignedUserData = doc.data();
  }

  bool _validateForm() {
    _setFormMessage(null);

    if (!_formKey.currentState!.validate()) {
      _showValidationMessage(
        'Please fill in all required fields marked with *.',
      );
      return false;
    }

    if (_selectedCustomerId == null || _selectedCustomerId!.trim().isEmpty) {
      _showValidationMessage(
        'Please select a valid customer from the search results.',
      );
      return false;
    }

    if (_structuredProducts.isEmpty) {
      _showValidationMessage(
        'Add at least one inquiry item or engineering requirement before saving.',
      );
      return false;
    }

    for (var item in _structuredProducts) {
      double qty = double.tryParse(item['quantity'].toString()) ?? 0.0;
      if (qty <= 0) {
        _showValidationMessage(
          'Inquiry item "${item['name']}" must have a quantity greater than zero.',
        );
        return false;
      }
    }

    final expVal =
        double.tryParse(_controllers.expectedValue.text.trim()) ?? 0.0;
    if (_controllers.expectedValue.text.trim().isNotEmpty && expVal <= 0) {
      _showValidationMessage('Expected value must be greater than zero.');
      return false;
    }

    if (_nextFollowUpDate != null) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final followupDate = DateTime(
        _nextFollowUpDate!.year,
        _nextFollowUpDate!.month,
        _nextFollowUpDate!.day,
      );
      if (followupDate.isBefore(todayDate)) {
        _showValidationMessage('Next follow-up date cannot be in the past.');
        return false;
      }
    }

    if (_selectedStage != 'Won' &&
        _selectedStage != 'Lost' &&
        _nextFollowUpDate == null) {
      _showValidationMessage(
        'Open pipeline stages require a next follow-up date.',
      );
      return false;
    }

    final transitionError = _getStageTransitionError(
      _previousStage ?? _selectedStage,
      _selectedStage,
    );
    if (transitionError != null) {
      _showValidationMessage(transitionError);
      return false;
    }

    if (_selectedStage == 'Won') {
      if (_controllers.linkedQuotationId.text.trim().isEmpty) {
        _showValidationMessage('Won inquiries must be linked to a quotation.');
        return false;
      }
      if (expVal <= 0) {
        _showValidationMessage(
          'Won inquiries must have a positive expected value.',
        );
        return false;
      }
    }

    if (_selectedStage == 'Lost' &&
        _controllers.lossReason.text.trim().isEmpty) {
      _showValidationMessage(
        'Please capture a loss reason before closing the inquiry as Lost.',
      );
      return false;
    }

    if (_selectedPriority == 'Hot' &&
        _nextFollowUpDate == null &&
        _selectedStage != 'Won' &&
        _selectedStage != 'Lost') {
      _showValidationMessage('Hot inquiries require a next follow-up date.');
      return false;
    }

    return true;
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    final assignedTo = _isAdminOrManager
        ? (_assignedToUid ?? widget.currentUserUid).trim()
        : widget.currentUserUid;
    await _loadAssignedUserData(assignedTo);

    final contactData = _selectedContactData ?? {};
    final assignedUserData = _assignedUserData ?? {};

    final contactName =
        (contactData['name'] ?? contactData['contactName'] ?? '')
            .toString()
            .trim();
    final assignedToName =
        (assignedUserData['name'] ?? assignedUserData['fullName'] ?? '')
            .toString()
            .trim();
    final assignedToRole = (assignedUserData['role'] ?? '').toString().trim();

    final expText = _controllers.expectedValue.text.trim();
    final double? expectedValue = expText.isEmpty
        ? null
        : double.tryParse(expText);
    final budgetRange = _parseBudgetRange(_controllers.budget.text.trim());

    final now = DateTime.now();
    bool isOverdue = false;
    if (_nextFollowUpDate != null) {
      final today = DateTime(now.year, now.month, now.day);
      final compareDate = DateTime(
        _nextFollowUpDate!.year,
        _nextFollowUpDate!.month,
        _nextFollowUpDate!.day,
      );
      isOverdue = compareDate.isBefore(today);
    }

    Timestamp? createdAtTs = (_isEditing && _existingRawData != null)
        ? (_existingRawData!['createdAt'] as Timestamp?)
        : null;
    DateTime createdAtDate = createdAtTs?.toDate() ?? now;

    int? conversionTimeDays;
    if (_selectedStage == 'Won' && _previousStage != 'Won') {
      conversionTimeDays = now.difference(createdAtDate).inDays;
    } else if (_isEditing) {
      conversionTimeDays = _existingRawData?['conversionTimeDays'] as int?;
    }

    int? lastFollowUpGap;
    Timestamp? lastActivityTs =
        _existingRawData?['lastActivityDate'] as Timestamp?;
    if (lastActivityTs != null) {
      lastFollowUpGap = now.difference(lastActivityTs.toDate()).inDays;
    }

    int dealVelocityDays = now.difference(createdAtDate).inDays;

    final subjectStr = _controllers.subject.text.trim();
    final subjectSearch = subjectStr.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final requirementFingerprint = _buildRequirementFingerprint(subjectSearch);
    final uniqueKey =
        '${_selectedCustomerId}_${requirementFingerprint.replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

    final searchCache =
        '${_customerNameSnapshot.toLowerCase()} ${_customerIndustrySnapshot.toLowerCase()} ${_customerCitySnapshot.toLowerCase()} $subjectSearch'
            .trim();

    double totalQuantity = _structuredProducts.fold<double>(
      0.0,
      (runningTotal, item) =>
          runningTotal + (double.tryParse(item['quantity'].toString()) ?? 0.0),
    );
    _selectedStatus = _statusForStage(_selectedStage);

    return <String, dynamic>{
      'companyId': _tenantId,
      'tenantId': _tenantId,
      'subject': subjectStr,
      'subjectSearch': subjectSearch,
      'customerSearchCache': searchCache,
      'uniqueKey': uniqueKey,
      'requirementFingerprint': requirementFingerprint,
      'productFingerprint': _buildProductFingerprint(),

      'customerId': _selectedCustomerId,
      'customerName': _customerNameSnapshot,
      'customerIndustry': _customerIndustrySnapshot,
      'customerCity': _customerCitySnapshot,

      'contactId': _selectedContactId ?? '',
      'contactName': contactName,
      'additionalContactIds': _additionalContactIds,

      'source': (_selectedSource ?? '').trim(),
      'sourceReference': _controllers.sourceRef.text.trim(),
      'inquiryType': (_selectedType ?? '').trim(),

      'products': _structuredProducts,
      'quantityScope': totalQuantity.toString(),
      'totalQuantity': totalQuantity,

      'expectedValue': expectedValue ?? 0.0,
      'budget': _controllers.budget.text.trim(),
      'budgetMin': budgetRange['min'],
      'budgetMax': budgetRange['max'],
      'competitor': _controllers.competitor.text.trim(),
      'decisionMaker': _controllers.decisionMaker.text.trim(),
      'deliveryTimeline': _controllers.deliveryTimeline.text.trim(),
      'projectSiteLocation': _controllers.projectSiteLocation.text.trim(),

      'priority': _selectedPriority.trim(),
      'stage': _selectedStage.trim(),
      'status': _selectedStatus,
      'probability': _probability,
      'dealScore': _dealScore,
      'qualificationGuidance': _suggestedPriority,
      'leadQuality': _selectedPriority,
      'leadSourceType': _selectedSource,
      'isConverted': _selectedStage == 'Won',

      'conversionTimeDays': conversionTimeDays,
      'lastFollowUpGap': lastFollowUpGap,
      'dealVelocityDays': dealVelocityDays,

      'followUpType': _followUpType,
      'nextFollowUpDate': _nextFollowUpDate == null
          ? null
          : Timestamp.fromDate(_nextFollowUpDate!),
      'expectedClosureDate': _expectedClosureDate == null
          ? null
          : Timestamp.fromDate(_expectedClosureDate!),
      'isOverdue': isOverdue,
      'lastFollowUpNote': _controllers.lastFollowUpNote.text.trim(),
      'notes': _controllers.notes.text.trim(),
      'internalNotes': _controllers.internalNotes.text.trim(),
      'lossReason': _controllers.lossReason.text.trim(),
      'tags': _tags,

      'linkedQuotationId': _controllers.linkedQuotationId.text.trim(),
      'convertedToQuotationId': _selectedStage == 'Won'
          ? _controllers.linkedQuotationId.text.trim()
          : '',

      'assignedToUid': assignedTo,
      'assignedToName': assignedToName,
      'assignedToRole': assignedToRole,
      'recordOwnerUid': assignedTo,
      'updatedBy': widget.currentUserUid,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActivityDate': FieldValue.serverTimestamp(),
      'lastActivityBy': widget.currentUserUid,
    };
  }

  Future<void> _executeSave(Map<String, dynamic> payload) async {
    int attempts = 0;
    bool success = false;

    while (attempts < 2 && !success) {
      attempts++;
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          if (_isEditing) {
            final docRef = widget.existingDoc!;
            final snapshot = await transaction.get(docRef);

            if (!snapshot.exists) {
              throw Exception("Inquiry document no longer exists.");
            }
            if (snapshot.data()?['isActive'] == false) {
              throw Exception("Cannot edit inactive inquiry.");
            }

            final existingLog = List<dynamic>.from(
              snapshot.data()?['activityLog'] ?? [],
            );

            String actionDesc = 'Updated deal details.';
            if (_previousStage != _selectedStage) {
              actionDesc =
                  'Stage moved from $_previousStage to $_selectedStage.';
            } else if (_controllers.lastFollowUpNote.text.isNotEmpty &&
                _controllers.lastFollowUpNote.text !=
                    _existingRawData?['lastFollowUpNote']) {
              actionDesc =
                  'Added follow-up: ${_controllers.lastFollowUpNote.text}';
            }

            existingLog.add({
              'action': 'Updated',
              'description': actionDesc,
              'by': widget.currentUserUid,
              'timestamp': Timestamp.now(),
            });

            payload['activityLog'] = existingLog;
            payload['lastActivityType'] = 'Updated';

            transaction.update(docRef, payload);
          } else {
            final docRef = _companyInquiriesRef.doc();

            final now = DateTime.now();
            final year = now.year % 100;
            final nextYear = year + 1;
            final fy = now.month >= 4 ? '$year-$nextYear' : '${year - 1}-$year';

            final counterRef = _companyCountersRef.doc('inquiry_counter_$fy');
            final counterSnap = await transaction.get(counterRef);

            int currentSeq = 1;
            if (counterSnap.exists) {
              currentSeq = (counterSnap.data()?['sequence'] ?? 0) + 1;
            }

            String formattedSequence = currentSeq.toString().padLeft(4, '0');
            String generatedNumber = 'INQ-$fy-$formattedSequence';

            transaction.set(counterRef, {
              'sequence': currentSeq,
            }, SetOptions(merge: true));

            payload['inquiryNumber'] = generatedNumber;
            payload['lastActivityType'] = 'Created';
            payload['activityLog'] = [
              {
                'action': 'Created',
                'description': 'Deal pipeline initiated.',
                'by': widget.currentUserUid,
                'timestamp': Timestamp.now(),
              },
            ];

            payload.addAll({
              'companyId': _tenantId,
              'tenantId': _tenantId,
              'createdBy': widget.currentUserUid,
              'createdAt': FieldValue.serverTimestamp(),
              'isActive': true,
            });

            transaction.set(docRef, payload);
          }
        });
        success = true;
      } catch (e, st) {
        if (e.toString().contains('Duplicate') ||
            e.toString().contains('inactive')) {
          rethrow;
        }
        if (attempts >= 2) {
          _handleError('Transaction Save Failed', e, st);
          rethrow;
        }
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  Future<void> _ensureNotDuplicate(Map<String, dynamic> payload) async {
    final fingerprint = (payload['requirementFingerprint'] ?? '')
        .toString()
        .trim();
    final customerId = (payload['customerId'] ?? '').toString().trim();
    if (fingerprint.isEmpty || customerId.isEmpty) return;

    final duplicateSnap = await _companyInquiriesRef
        .where('customerId', isEqualTo: customerId)
        .where('requirementFingerprint', isEqualTo: fingerprint)
        .limit(5)
        .get();

    final duplicateExists = duplicateSnap.docs.any((doc) {
      if (_isEditing && doc.id == widget.existingDoc?.id) {
        return false;
      }
      final data = doc.data();
      return data['isActive'] != false && (data['stage'] ?? '') != 'Lost';
    });

    if (duplicateExists) {
      throw Exception(
        'A similar inquiry already exists for this customer. Reuse the existing inquiry instead of creating a duplicate.',
      );
    }
  }

  Future<void> _saveInquiry({bool createQuote = false}) async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();

    if (_tenantId.isEmpty) {
      _showValidationMessage(
        'Missing company workspace. Inquiry was not saved.',
      );
      return;
    }

    if (!_validateForm()) return;

    setState(() => _isSaving = true);

    try {
      final payload = await _buildPayload();
      await _ensureNotDuplicate(payload);
      await _executeSave(payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Deal successfully updated.'
                : 'Deal successfully created.',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _previousStage = _selectedStage;
      _setFormMessage(null);

      if (createQuote) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuotationScreenLocal(
              currentUserUid: widget.currentUserUid,
              companyId: _tenantId,
              inquirySeed: payload,
            ),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      _showValidationMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==========================================
  // UI BUILDER METHODS
  // ==========================================

  InputDecoration _dec(
    String label, {
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildResponsiveFields(
    List<Widget> children, {
    double breakpoint = 720,
    double spacing = 16,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: EdgeInsets.only(bottom: spacing),
                    child: child,
                  ),
                )
                .toList(),
          );
        }

        final rowChildren = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          rowChildren.add(Expanded(child: children[i]));
          if (i != children.length - 1) {
            rowChildren.add(SizedBox(width: spacing));
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        );
      },
    );
  }

  Widget _buildFormMessageBanner() {
    if (_formMessage == null || _formMessage!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, color: Color(0xFF9A3412)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _formMessage!,
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            onPressed: () => _setFormMessage(null),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9A3412)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isExpanded = _sectionExpanded[title] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _sectionExpanded[title] = !isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: Radius.circular(isExpanded ? 0 : 16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: const Color(0xFF334155), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(padding: const EdgeInsets.all(24), child: child),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;
            final customerField =
                Autocomplete<DocumentSnapshot<Map<String, dynamic>>>(
                  initialValue: TextEditingValue(text: _customerNameSnapshot),
                  displayStringForOption: (doc) {
                    final data = doc.data() ?? {};
                    return (data['companyName'] ?? data['name'] ?? 'Unknown')
                        .toString();
                  },
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    return _getSyncCustomerOptions(textEditingValue.text);
                  },
                  onSelected: (doc) async {
                    setState(() {
                      _selectedCustomerId = doc.id;
                      _selectedContactId = null;
                      _additionalContactIds.clear();
                      _formMessage = null;
                    });
                    _controllers.customerSearch.text =
                        (doc.data()?['companyName'] ??
                                doc.data()?['name'] ??
                                '')
                            .toString();
                    await _loadCustomerData(doc.id);
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          if (_controllers.customerSearch.text.isNotEmpty &&
                              controller.text.isEmpty) {
                            controller.text = _controllers.customerSearch.text;
                          }
                        });
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: _dec(
                            'Search Customer Database *',
                            hint: 'Type name or phone...',
                            prefixIcon: const Icon(Icons.business_outlined),
                          ),
                          validator: (v) =>
                              _selectedCustomerId == null ? 'Required' : null,
                          onChanged: (value) {
                            _controllers.customerSearch.text = value;
                            final normalizedInput = _normalizeText(value);
                            final normalizedSelected = _normalizeText(
                              _customerNameSnapshot,
                            );
                            if (_selectedCustomerId != null &&
                                normalizedInput != normalizedSelected) {
                              setState(() {
                                _selectedCustomerId = null;
                                _selectedContactId = null;
                                _additionalContactIds.clear();
                              });
                            }
                          },
                        );
                      },
                );

            final newButton = SizedBox(
              height: 56,
              width: isCompact ? double.infinity : null,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScreensAddCustomer(
                        companyId: widget.companyId,
                        currentUserUid: widget.currentUserUid,
                        currentUserRole: widget.currentUserRole,
                      ),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      _selectedCustomerId = null;
                      _controllers.customerSearch.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Customer added. Please search and select it.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('New'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );

            if (isCompact) {
              return Column(
                children: [
                  customerField,
                  const SizedBox(height: 12),
                  newButton,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: customerField),
                const SizedBox(width: 12),
                newButton,
              ],
            );
          },
        ),
        if (_selectedCustomerId != null &&
            _customerNameSnapshot.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildContactDropdown(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 20,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customerNameSnapshot,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Industry: ${_customerIndustrySnapshot.isEmpty ? 'N/A' : _customerIndustrySnapshot} • City: ${_customerCitySnapshot.isEmpty ? 'N/A' : _customerCitySnapshot}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactDropdown() {
    if (_selectedCustomerId == null || _selectedCustomerId!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _companyContactsRef(
        _selectedCustomerId!,
      ).where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final contacts = snap.data!.docs;
        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: contacts.any((d) => d.id == _selectedContactId)
                    ? _selectedContactId
                    : null,
                decoration: _dec(
                  'Primary Contact Person',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                items: contacts.map((doc) {
                  final data = doc.data();
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(
                      (data['name'] ?? data['contactName'] ?? '').toString(),
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedContactId = v),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _selectedContactId == null
                  ? null
                  : () {
                      _showMultiContactPicker(contacts);
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('+ ${_additionalContactIds.length} More'),
            ),
          ],
        );
      },
    );
  }

  void _showMultiContactPicker(
    List<DocumentSnapshot<Map<String, dynamic>>> contacts,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Additional Contacts'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: contacts
                      .where((c) => c.id != _selectedContactId)
                      .map((doc) {
                        final isSelected = _additionalContactIds.contains(
                          doc.id,
                        );
                        return CheckboxListTile(
                          title: Text(
                            (doc.data()?['name'] ??
                                    doc.data()?['contactName'] ??
                                    '')
                                .toString(),
                          ),
                          value: isSelected,
                          onChanged: (bool? val) {
                            setDialogState(() {
                              if (val == true) {
                                _additionalContactIds.add(doc.id);
                              } else {
                                _additionalContactIds.remove(doc.id);
                              }
                            });
                            setState(() {});
                          },
                        );
                      })
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInquiryBasicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controllers.subject,
          decoration: _dec(
            'Deal / Inquiry Subject *',
            hint: 'E.g. Requirement for 50 Laptops',
            prefixIcon: const Icon(Icons.title),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          onChanged: (v) => _calculateDealScore(),
        ),
        const SizedBox(height: 16),
        _buildResponsiveFields([
          Builder(
            builder: (context) {
              final sourceOptions = <String>{
                'Phone Call',
                'Whatsapp',
                'WhatsApp',
                'E-mail',
                'Email',
                'Website',
                'Referral',
                'Cold Call',
                'Exhibition',
                'IndiaMART',
                'Other',
                if ((_selectedSource ?? '').trim().isNotEmpty)
                  (_selectedSource ?? '').trim(),
              }.toList();

              final safeInitialValue =
                  sourceOptions.contains((_selectedSource ?? '').trim())
                  ? (_selectedSource ?? '').trim()
                  : null;

              return DropdownButtonFormField<String>(
                initialValue: safeInitialValue,
                decoration: _dec(
                  'Source',
                  prefixIcon: const Icon(Icons.campaign_outlined),
                ),
                items: sourceOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSource = v),
              );
            },
          ),
          TextFormField(
            controller: _controllers.sourceRef,
            decoration: _dec(
              'Source Reference',
              hint: 'E.g. Referral Name',
              prefixIcon: const Icon(Icons.link),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _buildAssignUserDropdown(),
        const SizedBox(height: 16),
        _buildTagsInput(),
      ],
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controllers.tag,
          decoration: _dec(
            'Tags',
            hint: 'Type tag and press Enter',
            prefixIcon: const Icon(Icons.label_outline),
          ),
          onFieldSubmitted: (val) {
            if (val.trim().isNotEmpty && !_tags.contains(val.trim())) {
              setState(() => _tags.add(val.trim()));
              _controllers.tag.clear();
            }
          },
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map(
                  (tag) => Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF64748B),
                    deleteIconColor: Colors.white70,
                    onDeleted: () => setState(() => _tags.remove(tag)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPipelineIndicator() {
    int currentIndex = _pipelineStages.indexOf(_selectedStage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 8,
        children: _pipelineStages.asMap().entries.map((entry) {
          int idx = entry.key;
          String stage = entry.value;
          bool isSelected = idx == currentIndex;
          bool isCompleted = idx < currentIndex;

          Color bgColor = isSelected
              ? const Color(0xFF2563EB)
              : (isCompleted ? const Color(0xFFDBEAFE) : Colors.white);
          Color textColor = isSelected
              ? Colors.white
              : (isCompleted
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF64748B));
          Color borderColor = isSelected
              ? const Color(0xFF2563EB)
              : (isCompleted
                    ? const Color(0xFFBFDBFE)
                    : const Color(0xFFCBD5E1));

          return GestureDetector(
            onTap: () => _applyStageSelection(stage),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCompleted)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  Text(
                    stage,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: _dec(
          label,
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onClear,
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value == null
              ? 'Select Date'
              : DateFormat('dd/MM/yyyy').format(value),
          style: TextStyle(
            color: value == null ? Colors.grey.shade500 : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAssignUserDropdown() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _companyUsersRef.where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();
        final docs = snap.data!.docs;
        return DropdownButtonFormField<String>(
          initialValue: docs.any((d) => d.id == _assignedToUid)
              ? _assignedToUid
              : null,
          decoration: _dec(
            'Assigned Record Owner *',
            prefixIcon: const Icon(Icons.assignment_ind_outlined),
          ),
          items: docs
              .map(
                (doc) => DropdownMenuItem(
                  value: doc.id,
                  child: Text(
                    doc.data()['name'] ?? doc.data()['fullName'] ?? 'Unknown',
                  ),
                ),
              )
              .toList(),
          onChanged: _isAdminOrManager
              ? (v) => setState(() => _assignedToUid = v)
              : null,
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }

  Future<void> _pickDate({
    required DateTime? initialValue,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 2);
    final lastDate = DateTime(now.year + 5);
    var initialDate = initialValue ?? now;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onPicked(picked);
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controllers.linkedQuotationId,
          decoration: _dec(
            'Linked Quotation ID',
            hint: 'E.g. QT-2425-001 (Required for Won deals)',
            prefixIcon: const Icon(Icons.receipt_long_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _controllers.notes,
          maxLines: 3,
          decoration: _dec(
            'External Notes (Customer visible)',
            hint: 'Special delivery instructions...',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _controllers.internalNotes,
          maxLines: 2,
          decoration: _dec(
            'Internal Private Notes',
            hint: 'Pricing constraints...',
          ),
        ),
      ],
    );
  }

  Widget _buildStickyActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final buttonWidth = compact ? constraints.maxWidth : null;
            return Wrap(
              alignment: WrapAlignment.end,
              runSpacing: 12,
              spacing: 12,
              children: [
                SizedBox(
                  width: buttonWidth,
                  child: TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: buttonWidth,
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => _saveInquiry(createQuote: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save & Quote',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: buttonWidth,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : () => _saveInquiry(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isEditing ? 'Update Deal' : 'Save Deal',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Deal / Inquiry' : 'Create Deal / Inquiry',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  _buildFormMessageBanner(),
                  _buildSmartInsightsPanel(),
                  _buildSection(
                    title: 'Customer & Contacts',
                    icon: Icons.domain,
                    child: _buildCustomerSection(),
                  ),
                  _buildSection(
                    title: 'Inquiry Basics',
                    icon: Icons.info_outline,
                    child: _buildInquiryBasicsSection(),
                  ),
                  _buildSection(
                    title: 'Inquiry Items & Engineering Scope',
                    icon: Icons.precision_manufacturing_outlined,
                    child: _buildProductsSection(),
                  ),
                  _buildSection(
                    title: 'Commercial & Intelligence',
                    icon: Icons.insights,
                    child: _buildCommercialSection(),
                  ),
                  _buildSection(
                    title: 'Follow-up & Activity',
                    icon: Icons.event_available,
                    child: _buildFollowUpSection(),
                  ),
                  _buildSection(
                    title: 'Notes & Attachments',
                    icon: Icons.note_alt_outlined,
                    child: _buildNotesSection(),
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildStickyActionBar(),
    );
  }
}

// ---------------------------------------------------------
// ENTERPRISE PAGINATED SEARCH DIALOG FOR INVENTORY
// ---------------------------------------------------------
