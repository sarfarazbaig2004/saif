import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/providers/customer_po_provider.dart';
import 'package:QUIK/modules/customer_po/widgets/customer_po_item_row.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_project_split_tab.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_attachments_tab.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_terms_tab.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_commercial_tab.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_form_section_card.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_pdf_upload_card.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_customer_picker_dialog.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_overview_tab.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_engineering_tab.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/keep_alive_page.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_form_field.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_summary_row.dart';
import 'package:QUIK/modules/customer_po/screens/form_widgets/po_form_shell.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_loader.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_form_builder.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_pdf_upload_service.dart';
import 'package:QUIK/modules/customer_po/screens/form_services/customer_po_save_service.dart';

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

  final _poNumber = TextEditingController();
  final _gstPercent = TextEditingController(text: '18');
  final _projectName = TextEditingController();
  final _siteLocation = TextEditingController();
  final _subject = TextEditingController();
  final _paymentTerms = TextEditingController();
  final _deliveryTerms = TextEditingController();
  final _inspectionRequirement = TextEditingController();
  final _warranty = TextEditingController();
  final _ldClause = TextEditingController();

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
      _basicValue * (double.tryParse(_gstPercent.text.trim()) ?? 0) / 100;

  double get _totalValue => _basicValue + _gstAmount;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _gstPercent.addListener(() => setState(() {}));
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
        _poNumber.text = data.poNumber;
        _customerId = data.customerId;
        _customerName = data.customerName;
        _customerEmail = data.customerEmail;
        _customerMobile = data.customerMobile;
        _customerAddress = data.customerAddress;
        _customerGstNumber = data.customerGstNumber;
        _projectName.text = data.projectName;
        _siteLocation.text = data.siteLocation;
        _subject.text = data.subject;
        _gstPercent.text = data.gstPercent;
        _paymentTerms.text = data.paymentTerms;
        _deliveryTerms.text = data.deliveryTerms;
        _inspectionRequirement.text = data.inspectionRequirement;
        _warranty.text = data.warranty;
        _ldClause.text = data.ldClause;
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
    if (_customerId.isEmpty) {
      setState(() => _customerErrorVisible = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final id = _isEditMode
        ? _existingId
        : DateTime.now().millisecondsSinceEpoch.toString();

    final po = CustomerPoFormBuilder.build(
      id: id,
      companyId: widget.companyId,
      poNumber: _poNumber.text.trim(),
      poDate: _poDate,
      customerId: _customerId,
      customerName: _customerName,
      customerEmail: _customerEmail,
      customerMobile: _customerMobile,
      customerAddress: _customerAddress,
      customerGstNumber: _customerGstNumber,
      projectName: _projectName.text.trim(),
      siteLocation: _siteLocation.text.trim(),
      subject: _subject.text.trim(),
      basicValue: _basicValue,
      gstPercent: double.tryParse(_gstPercent.text.trim()) ?? 0,
      gstAmount: _gstAmount,
      totalValue: _totalValue,
      paymentTerms: _paymentTerms.text.trim(),
      deliveryTerms: _deliveryTerms.text.trim(),
      inspectionRequirement: _inspectionRequirement.text.trim(),
      warranty: _warranty.text.trim(),
      ldClause: _ldClause.text.trim(),
      status: _isEditMode ? _existingStatus : 'Draft',
      items: _items,
      poDocumentUrl: _poDocumentUrl,
      poFileName: _poFileName,
      uploadedAt: _uploadedAt,
    );

    try {
      await CustomerPoSaveService.save(
        provider: _provider,
        isEditMode: _isEditMode,
        po: po,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Customer PO ${_isEditMode ? 'updated' : 'saved'} successfully',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${_isEditMode ? 'update' : 'save'} Customer PO: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _poNumber.dispose();
    _gstPercent.dispose();
    _projectName.dispose();
    _siteLocation.dispose();
    _subject.dispose();
    _paymentTerms.dispose();
    _deliveryTerms.dispose();
    _inspectionRequirement.dispose();
    _warranty.dispose();
    _ldClause.dispose();
    super.dispose();
  }

  // ── Field helpers ─────────────────────────────────────────────────────────────

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return PoFormField(
      label: label,
      controller: controller,
      requiredField: required,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return PoSummaryRow(label: label, value: value, bold: bold);
  }

  void _showCustomerPicker() {
    showDialog<void>(
      context: context,
      builder: (_) => PoCustomerPickerDialog(
        customers: _customers,
        onSelected: (c) {
          setState(() {
            _customerId = c['id'] as String;
            _customerName = c['name'] as String;
            _customerEmail = c['email'] as String;
            _customerMobile = c['mobile'] as String;
            _customerAddress = c['address'] as String;
            _customerGstNumber = c['gst'] as String;
            _customerErrorVisible = false;
          });
        },
      ),
    );
  }

  // ── Tab content builders ──────────────────────────────────────────────────────

  // ── Build ─────────────────────────────────────────────────────────────────────

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
      tabs: [
        KeepAlivePage(
          child: PoOverviewTab(
            poNumber: _poNumber,
            isEditMode: _isEditMode,
            customerErrorVisible: _customerErrorVisible,
            customerId: _customerId,
            isLoadingCustomers: _isLoadingCustomers,
            customerName: _customerName,
            customerEmail: _customerEmail,
            customerMobile: _customerMobile,
            customerGstNumber: _customerGstNumber,
            customerAddress: _customerAddress,
            showCustomerPicker: _showCustomerPicker,
            fieldBuilder: _field,
          ),
        ),
        KeepAlivePage(
          child: PoCommercialTab(
            gstPercent: _gstPercent,
            basicValue: _basicValue,
            gstAmount: _gstAmount,
            totalValue: _totalValue,
            fieldBuilder: _field,
            summaryRow: _summaryRow,
            sectionCard: ({required title, required child}) =>
                PoFormSectionCard(title: title, child: child),
          ),
        ),
        KeepAlivePage(
          child: PoProjectSplitTab(
            projectName: _projectName,
            siteLocation: _siteLocation,
            subject: _subject,
            fieldBuilder: _field,
          ),
        ),
        KeepAlivePage(
          child: PoEngineeringTab(
            items: _items,
            onChanged: (items) => setState(() => _items = items),
          ),
        ),
        KeepAlivePage(
          child: PoTermsTab(
            paymentTerms: _paymentTerms,
            deliveryTerms: _deliveryTerms,
            inspectionRequirement: _inspectionRequirement,
            warranty: _warranty,
            ldClause: _ldClause,
            fieldBuilder: _field,
          ),
        ),
        KeepAlivePage(
          child: PoAttachmentsTab(
            pdfUploadWidget: PoPdfUploadCard(
              fileName: _poFileName,
              isUploading: _isUploading,
              onPickPdf: _pickAndUploadPdf,
              onRemovePdf: () => setState(() {
                _poDocumentUrl = null;
                _poFileName = null;
                _uploadedAt = null;
              }),
            ),
          ),
        ),
      ],
    );
  }
}
