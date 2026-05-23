import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/providers/customer_po_provider.dart';
import 'package:QUIK/modules/customer_po/widgets/customer_po_item_row.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_customer_picker_dialog.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_form_shell.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_loader.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_pdf_upload_service.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_controllers.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_form_tabs.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_draft_factory.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_form_helpers.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_orchestrator.dart';
import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_amendment_handler.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_loading_screen.dart';
import 'package:QUIK/modules/customer_po/screens/form_core/customer_po_form_state.dart';

class CustomerPoFormScreen extends StatefulWidget {
  final String companyId;
  final String? existingDocId;

  const CustomerPoFormScreen({
    super.key,
    required this.companyId,
    this.existingDocId,
  });

  @override
  State<CustomerPoFormScreen> createState() => _CustomerPoFormScreenState();
}

class _CustomerPoFormScreenState extends State<CustomerPoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _provider = CustomerPoProvider();
  final _controllers = CustomerPoFormControllers();

  // ✅ NEW STATE LAYER

  DateTime _poDate = DateTime.now();
  List<CustomerPoItemRow> _items = [];

  bool get _isEditMode => widget.existingDocId != null;
  bool _isLoadingExisting = false;
  String _existingStatus = 'Draft';
  String _existingId = '';

  bool _isLoadingCustomers = false;
  List<Map<String, dynamic>> _customers = [];

  String _customerId = '';
  String _customerName = '';
  String _customerEmail = '';
  String _customerMobile = '';
  String _customerAddress = '';
  String _customerGstNumber = '';
  bool _customerErrorVisible = false;

  bool _isUploading = false;
  String? _poDocumentUrl;
  String? _poFileName;
  DateTime? _uploadedAt;

  double get _basicValue =>
      _items.fold<double>(0, (a, b) => a + b.amount);

  double get _gstAmount =>
      _basicValue *
      (double.tryParse(_controllers.gstPercent.text.trim()) ?? 0) /
      100;

  double get _totalValue => _basicValue + _gstAmount;

  @override
  void initState() {
    super.initState();
    _loadCustomers();

    _controllers.gstPercent.addListener(() => setState(() {}));

    if (_isEditMode) {
      _isLoadingExisting = true;
      _loadExistingData();
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('customers')
          .get();

      final list = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'name': (d['name'] ?? '').toString(),
          'email': (d['email'] ?? '').toString(),
          'mobile': (d['phone'] ?? '').toString(),
          'address': (d['address'] ?? '').toString(),
          'gst': (d['gst'] ?? '').toString(),
        };
      }).toList();

      setState(() => _customers = list);
    } finally {
      setState(() => _isLoadingCustomers = false);
    }
  }

  Future<void> _loadExistingData() async {
    final data = await CustomerPoFormLoader.load(
      companyId: widget.companyId,
      existingDocId: widget.existingDocId,
    );

    if (data == null || !mounted) return;

    setState(() {
      _existingId = data.id;
      _existingStatus = data.status;

      _poDate = data.poDate;

      _controllers.poNumber.text = data.poNumber;

      _customerId = data.customerId;
      _customerName = data.customerName;
      _customerEmail = data.customerEmail;
      _customerMobile = data.customerMobile;
      _customerAddress = data.customerAddress;
      _customerGstNumber = data.customerGstNumber;

      _controllers.projectName.text = data.projectName;
      _controllers.siteLocation.text = data.siteLocation;
      _controllers.subject.text = data.subject;
      _controllers.gstPercent.text = data.gstPercent;

      _items = data.items;

      _poDocumentUrl = data.poDocumentUrl;
      _poFileName = data.poFileName;
      _uploadedAt = data.uploadedAt;

      _isLoadingExisting = false;
    });
  }

  Future<void> _save() async {
    await CustomerPoFormOrchestrator.save(
      context: context,
      formKey: _formKey,
      mounted: mounted,
      isEditMode: _isEditMode,
      provider: _provider,
      companyId: widget.companyId,
      customerId: _customerId,
      poNumber: _controllers.poNumber.text.trim(),
      currentDocId: _isEditMode ? _existingId : null,
      showCustomerError: () =>
          setState(() => _customerErrorVisible = true),
      buildPo: _buildCustomerPo,
    );
  }

  CustomerPoModel _buildCustomerPo() {
    return CustomerPoFormDraftFactory.build(
      isEditMode: _isEditMode,
      existingId: _existingId,
      companyId: widget.companyId,
      controllers: _controllers,
      poDate: _poDate,
      customerId: _customerId,
      customerName: _customerName,
      customerEmail: _customerEmail,
      customerMobile: _customerMobile,
      customerAddress: _customerAddress,
      customerGstNumber: _customerGstNumber,
      basicValue: _basicValue,
      gstAmount: _gstAmount,
      totalValue: _totalValue,
      existingStatus: _existingStatus,
      items: _items,
      poDocumentUrl: _poDocumentUrl,
      poFileName: _poFileName,
      uploadedAt: _uploadedAt,
    );
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingExisting) return const PoLoadingScreen();

    return PoFormShell(
      isEditMode: _isEditMode,
      isSaving: _provider.loading,
      onSave: _save,
      formKey: _formKey,
      body: PoFormTabs(
        controllers: _controllers,
        isEditMode: _isEditMode,
        customerErrorVisible: _customerErrorVisible,
        customerId: _customerId,
        isLoadingCustomers: _isLoadingCustomers,
        customerName: _customerName,
        customerEmail: _customerEmail,
        customerMobile: _customerMobile,
        customerGstNumber: _customerGstNumber,
        customerAddress: _customerAddress,

        // NEW STATE PASSED

        showCustomerPicker: () => showDialog(
          context: context,
          builder: (_) => PoCustomerPickerDialog(
            customers: _customers,
            onSelected: (c) => setState(() {
              _customerId = c['id'];
              _customerName = c['name'];
              _customerEmail = c['email'];
              _customerMobile = c['mobile'];
              _customerAddress = c['address'];
              _customerGstNumber = c['gst'];
              _customerErrorVisible = false;
            }),
          ),
        ),

        fieldBuilder: PoFormHelpers.field,
        summaryRow: PoFormHelpers.summaryRow,
        basicValue: _basicValue,
        gstAmount: _gstAmount,
        totalValue: _totalValue,
        items: _items,
        onItemsChanged: (items) => setState(() => _items = items),

        poFileName: _poFileName,
        poDocumentUrl: _poDocumentUrl,
        isUploading: _isUploading,

        pickAndUploadPdf: _pickAndUploadPdf,
        removePdf: () => setState(() {
          _poDocumentUrl = null;
          _poFileName = null;
          _uploadedAt = null;
        }),

        uploadAmendedPdf: !_isEditMode
            ? null
            : () => CustomerPoAmendmentHandler.uploadAmendedPo(
                  context: context,
                  companyId: widget.companyId,
                  docId: _existingId,
                  currentRevisionNo: 0,
                  currentPoDocumentUrl: _poDocumentUrl,
                ),
      ),
    );
  }

  Future<void> _pickAndUploadPdf() async {
    setState(() => _isUploading = true);

    try {
      final uploaded =
          await CustomerPoPdfUploadService.pickAndUpload(
        companyId: widget.companyId,
      );

      if (uploaded == null) return;

      setState(() {
        _poDocumentUrl = uploaded.url;
        _poFileName = uploaded.fileName;
        _uploadedAt = uploaded.uploadedAt;
      });
    } finally {
      setState(() => _isUploading = false);
    }
  }
}