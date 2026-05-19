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

  DateTime _poDate = DateTime.now();
  List<CustomerPoItemRow> _items = [];

  bool get _isEditMode => widget.existingDocId != null;
  bool _isLoadingExisting = false;
  String _existingStatus = 'Draft';
  String _existingId = '';

  // Customer selector state
  bool _isLoadingCustomers = false;
  List<Map<String, dynamic>> _customers = [];
  String _customerId = '';
  String _customerName = '';
  String _customerEmail = '';
  String _customerMobile = '';
  String _customerAddress = '';
  String _customerGstNumber = '';
  bool _customerErrorVisible = false;

  // PDF upload state
  bool _isUploading = false;
  String? _poDocumentUrl;
  String? _poFileName;
  DateTime? _uploadedAt;

  double get _basicValue =>
      _items.fold<double>(0, (acc, item) => acc + item.amount);

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
          'name': (d['companyName'] ?? d['name'] ?? '').toString(),
          'email': (d['businessEmail'] ?? d['email'] ?? '').toString(),
          'mobile': (d['phone'] ?? d['companyPhone'] ?? '').toString(),
          'address': (d['address'] ?? '').toString(),
          'gst': (d['gst'] ?? '').toString(),
        };
      }).toList();
      list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      setState(() => _customers = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load customers: $e'),
            action: SnackBarAction(label: 'Retry', onPressed: _loadCustomers),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingCustomers = false);
    }
  }

  Future<void> _loadExistingData() async {
    try {
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
        _controllers.paymentTerms.text = data.paymentTerms;
        _controllers.deliveryTerms.text = data.deliveryTerms;
        _controllers.inspectionRequirement.text = data.inspectionRequirement;
        _controllers.warranty.text = data.warranty;
        _controllers.ldClause.text = data.ldClause;
        _poDocumentUrl = data.poDocumentUrl;
        _poFileName = data.poFileName;
        _uploadedAt = data.uploadedAt;
        _items = data.items;
        _isLoadingExisting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingExisting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load PO: $e')));
    }
  }

  Future<void> _pickAndUploadPdf() async {
    setState(() => _isUploading = true);

    try {
      final uploaded = await CustomerPoPdfUploadService.pickAndUpload(
        companyId: widget.companyId,
      );

      if (uploaded == null) return;

      setState(() {
        _poDocumentUrl = uploaded.url;
        _poFileName = uploaded.fileName;
        _uploadedAt = uploaded.uploadedAt;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
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
      showCustomerError: () => setState(() => _customerErrorVisible = true),
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
    if (_isLoadingExisting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Customer PO')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
        showCustomerPicker: () => showDialog<void>(
          context: context,
          builder: (_) => PoCustomerPickerDialog(
            customers: _customers,
            onSelected: (c) => setState(() {
              _customerId = c['id'] as String;
              _customerName = c['name'] as String;
              _customerEmail = c['email'] as String;
              _customerMobile = c['mobile'] as String;
              _customerAddress = c['address'] as String;
              _customerGstNumber = c['gst'] as String;
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
        isUploading: _isUploading,
        pickAndUploadPdf: _pickAndUploadPdf,
        removePdf: () => setState(() {
          _poDocumentUrl = null;
          _poFileName = null;
          _uploadedAt = null;
        }),
      ),
    );
  }
}
