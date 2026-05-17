import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/modules/customer_po/models/customer_po_model.dart';
import 'package:QUIK/modules/customer_po/providers/customer_po_provider.dart';
import 'package:QUIK/modules/customer_po/widgets/customer_po_item_row.dart';
import 'package:QUIK/modules/customer_po/widgets/customer_po_items_table.dart';

class CustomerPoFormScreen extends StatefulWidget {
  final String companyId;

  const CustomerPoFormScreen({super.key, required this.companyId});

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

  final DateTime _poDate = DateTime.now();
  List<CustomerPoItemRow> _items = [];

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

  Future<void> _pickAndUploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final fileName = file.name;
    final storagePath = 'companies/${widget.companyId}/customer_pos/$fileName';

    setState(() => _isUploading = true);
    try {
      final ref = FirebaseStorage.instance.ref(storagePath);
      await ref.putData(
        file.bytes!,
        SettableMetadata(contentType: 'application/pdf'),
      );
      final url = await ref.getDownloadURL();
      setState(() {
        _poDocumentUrl = url;
        _poFileName = fileName;
        _uploadedAt = DateTime.now();
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

  Widget _pdfUploadWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PO Document (PDF)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (_poFileName != null)
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _poFileName!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _poDocumentUrl = null;
                      _poFileName = null;
                      _uploadedAt = null;
                    }),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadPdf,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading ? 'Uploading…' : 'Select PDF'),
              ),
          ],
        ),
      ),
    );
  }

  void _showCustomerPicker() {
    String search = '';
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filtered = _customers.where((c) {
            final name = (c['name'] as String).toLowerCase();
            return search.isEmpty || name.contains(search.toLowerCase());
          }).toList();

          return AlertDialog(
            title: const Text('Select Customer'),
            content: SizedBox(
              width: 420,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search customer...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setDialogState(() => search = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No customers found'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final c = filtered[i];
                              return ListTile(
                                title: Text(c['name'] as String),
                                subtitle: (c['email'] as String).isNotEmpty
                                    ? Text(c['email'] as String)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _customerId = c['id'] as String;
                                    _customerName = c['name'] as String;
                                    _customerEmail = c['email'] as String;
                                    _customerMobile = c['mobile'] as String;
                                    _customerAddress = c['address'] as String;
                                    _customerGstNumber = c['gst'] as String;
                                    _customerErrorVisible = false;
                                  });
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
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

    final po = CustomerPoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      status: 'Draft',
      items: _items,
      poDocumentUrl: _poDocumentUrl,
      poFileName: _poFileName,
      uploadedAt: _uploadedAt,
    );

    try {
      await _provider.createCustomerPo(po);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer PO saved successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save Customer PO: $e')));
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

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _customerSelector() {
    final hasError = _customerErrorVisible && _customerId.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _isLoadingCustomers ? null : _showCustomerPicker,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Customer *',
              border: const OutlineInputBorder(),
              errorText: hasError ? 'Please select a customer' : null,
              suffixIcon: _isLoadingCustomers
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              _customerName.isEmpty ? 'Select Customer' : _customerName,
              style: TextStyle(
                color: _customerName.isEmpty ? Colors.grey.shade600 : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Customer details are managed in CRM',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Customer PO')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('Customer PO Number', _poNumber, required: true),
            const SizedBox(height: 12),
            _customerSelector(),
            const SizedBox(height: 12),
            _field('Project Name', _projectName),
            const SizedBox(height: 12),
            _field('Site Location', _siteLocation),
            const SizedBox(height: 12),
            _field('Subject / Scope', _subject),
            const SizedBox(height: 16),
            CustomerPoItemsTable(
              onChanged: (items) => setState(() => _items = items),
            ),
            const SizedBox(height: 12),
            _field('GST %', _gstPercent, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summaryRow(
                      'Basic Value',
                      '₹${_basicValue.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _summaryRow(
                      'GST (${_gstPercent.text.trim()}%)',
                      '₹${_gstAmount.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 20),
                    _summaryRow(
                      'Total Value',
                      '₹${_totalValue.toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _pdfUploadWidget(),
            const SizedBox(height: 12),
            _field('Payment Terms', _paymentTerms),
            const SizedBox(height: 12),
            _field('Delivery Terms', _deliveryTerms),
            const SizedBox(height: 12),
            _field('Inspection Requirement', _inspectionRequirement),
            const SizedBox(height: 12),
            _field('Warranty', _warranty),
            const SizedBox(height: 12),
            _field('LD Clause', _ldClause),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _provider.loading ? null : _save,
              child: const Text('Save Customer PO'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
