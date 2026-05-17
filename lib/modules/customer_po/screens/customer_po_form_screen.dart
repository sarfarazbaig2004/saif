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
  final _customerName = TextEditingController();
  final _projectName = TextEditingController();
  final _siteLocation = TextEditingController();
  final _subject = TextEditingController();
  final _gstPercent = TextEditingController(text: '18');
  final _paymentTerms = TextEditingController();
  final _deliveryTerms = TextEditingController();
  final _inspectionRequirement = TextEditingController();
  final _warranty = TextEditingController();
  final _ldClause = TextEditingController();

  final DateTime _poDate = DateTime.now();
  List<CustomerPoItemRow> _items = [];

  double get _basicValue =>
      _items.fold<double>(0, (sum, item) => sum + item.amount);

  double get _gstAmount =>
      _basicValue * (double.tryParse(_gstPercent.text.trim()) ?? 0) / 100;

  double get _totalValue => _basicValue + _gstAmount;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final po = CustomerPoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      companyId: widget.companyId,
      poNumber: _poNumber.text.trim(),
      poDate: _poDate,
      customerName: _customerName.text.trim(),
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
      status: 'draft',
      items: _items,
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
    _customerName.dispose();
    _projectName.dispose();
    _siteLocation.dispose();
    _subject.dispose();
    _gstPercent.dispose();
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
            _field('Customer Name', _customerName, required: true),
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
