import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:QUIK/modules/sales/costing/models/costing_sheet_model.dart';
import 'package:QUIK/modules/sales/costing/widgets/costing_input_field.dart';
import 'package:QUIK/modules/sales/quotations/quotation_screen_local.dart';

class CostingSheetScreen extends StatefulWidget {
  final String companyId;
  final String currentUserUid;
  final Map<String, dynamic> inquiryData;

  const CostingSheetScreen({
    super.key,
    required this.companyId,
    required this.currentUserUid,
    required this.inquiryData,
  });

  @override
  State<CostingSheetScreen> createState() => _CostingSheetScreenState();
}

class _CostingSheetScreenState extends State<CostingSheetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _item = TextEditingController();
  final _qty = TextEditingController();
  final _weight = TextEditingController();
  final _rm = TextEditingController();
  final _fab = TextEditingController();
  final _galv = TextEditingController();
  final _pack = TextEditingController();
  final _freight = TextEditingController();
  final _overhead = TextEditingController(text: '0');
  final _margin = TextEditingController(text: '30');
  bool _loading = true;
  bool _saving = false;
  String _costingId = '';

  String get _inquiryId => (widget.inquiryData['id'] ?? '').toString();
  String get _customerName =>
      (widget.inquiryData['customerName'] ??
              widget.inquiryData['companyName'] ??
              '')
          .toString();
  String get _inquiryNumber =>
      (widget.inquiryData['inquiryNumber'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _seedDefaults();
    _loadExisting();
  }

  @override
  void dispose() {
    for (final c in [
      _item,
      _qty,
      _weight,
      _rm,
      _fab,
      _galv,
      _pack,
      _freight,
      _overhead,
      _margin,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedDefaults() {
    final products =
        widget.inquiryData['products'] ?? widget.inquiryData['items'];
    final first =
        products is List && products.isNotEmpty && products.first is Map
        ? Map<String, dynamic>.from(products.first as Map)
        : const <String, dynamic>{};
    _item.text =
        (first['name'] ??
                first['description'] ??
                widget.inquiryData['subject'] ??
                '')
            .toString();
    _qty.text = _numText(
      first['quantity'] ?? widget.inquiryData['totalQuantity'],
    );
    _weight.text = _numText(first['estimatedWeight'] ?? first['bomWeight']);
  }

  Future<void> _loadExisting() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('costing_sheets')
          .where('inquiryId', isEqualTo: _inquiryId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        _apply(CostingSheetModel.fromDoc(snap.docs.first));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(CostingSheetModel c) {
    _costingId = c.id;
    _item.text = c.itemName;
    _qty.text = _numText(c.qty);
    _weight.text = _numText(c.totalWeightKg);
    _rm.text = _numText(c.rawMaterialRatePerKg);
    _fab.text = _numText(c.fabricationRatePerKg);
    _galv.text = _numText(c.galvanizingRatePerKg);
    _pack.text = _numText(c.packingRatePerKg);
    _freight.text = _numText(c.freightRatePerKg);
    _overhead.text = _numText(c.overheadPercent);
    _margin.text = _numText(c.marginPercent);
  }

  double _v(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
  String _numText(Object? v) {
    final n = CostingSheetModel.value(v);
    return n == 0
        ? ''
        : (n == n.roundToDouble() ? n.toInt().toString() : n.toString());
  }

  CostingSheetModel _model() {
    final kgCost = _v(_rm) + _v(_fab) + _v(_galv) + _v(_pack) + _v(_freight);
    final base = _v(_weight) * kgCost;
    final totalCost = base + (base * _v(_overhead) / 100);
    final selling = totalCost + (totalCost * _v(_margin) / 100);
    final qty = _v(_qty);
    return CostingSheetModel(
      id: _costingId,
      inquiryId: _inquiryId,
      inquiryNumber: _inquiryNumber,
      customerName: _customerName,
      itemName: _item.text.trim(),
      qty: qty,
      totalWeightKg: _v(_weight),
      rawMaterialRatePerKg: _v(_rm),
      fabricationRatePerKg: _v(_fab),
      galvanizingRatePerKg: _v(_galv),
      packingRatePerKg: _v(_pack),
      freightRatePerKg: _v(_freight),
      overheadPercent: _v(_overhead),
      marginPercent: _v(_margin),
      totalCost: totalCost,
      sellingPrice: selling,
      ratePerUnit: qty <= 0 ? 0 : selling / qty,
      bomId: (widget.inquiryData['bomId'] ?? '').toString(),
      bomRevision: (widget.inquiryData['bomRevision'] ?? '').toString(),
      bomRevisionId: (widget.inquiryData['bomRevisionId'] ?? '').toString(),
    );
  }

  Future<CostingSheetModel?> _save() async {
    if (!_formKey.currentState!.validate()) return null;
    setState(() => _saving = true);
    try {
      var model = _model();
      final collection = FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('costing_sheets');
      final ref = _costingId.isEmpty
          ? collection.doc()
          : collection.doc(_costingId);
      _costingId = ref.id;
      model = _model();
      await ref.set({
        ...model.toMap(),
        'companyId': widget.companyId,
        'createdBy': widget.currentUserUid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('inquiries')
          .doc(_inquiryId)
          .set({
            'costingSheetId': ref.id,
            'stage': 'Costing',
          }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Costing sheet saved')));
      }
      return model;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generateQuotation() async {
    final model = await _save();
    if (model == null || !mounted) return;
    final seed = Map<String, dynamic>.from(widget.inquiryData)
      ..addAll({
        'id': _inquiryId,
        'inquiryId': _inquiryId,
        'customerName': _customerName,
        'inquiryNumber': _inquiryNumber,
        'subject': widget.inquiryData['subject'] ?? model.itemName,
        'items': [model.quotationItemMap()],
        'costingSheetId': _costingId,
      });
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotationScreenLocal(
          currentUserUid: widget.currentUserUid,
          companyId: widget.companyId,
          inquirySeed: seed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ');
    final model = _model();
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Costing Sheet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_customerName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _field(_item, 'Item Name', required: true),
            Row(
              children: [
                Expanded(child: _field(_qty, 'Qty')),
                const SizedBox(width: 12),
                Expanded(child: _field(_weight, 'Total Weight Kg')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field(_rm, 'Raw Material / Kg')),
                const SizedBox(width: 12),
                Expanded(child: _field(_fab, 'Fabrication / Kg')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field(_galv, 'Galvanizing / Kg')),
                const SizedBox(width: 12),
                Expanded(child: _field(_pack, 'Packing / Kg')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field(_freight, 'Freight / Kg')),
                const SizedBox(width: 12),
                Expanded(child: _field(_overhead, 'Overhead %')),
              ],
            ),
            _field(_margin, 'Margin %'),
            const SizedBox(height: 8),
            Text('Total Cost: ${money.format(model.totalCost)}'),
            Text('Selling Price: ${money.format(model.sellingPrice)}'),
            Text('Rate / Unit: ${money.format(model.ratePerUnit)}'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _generateQuotation,
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Generate Quotation from Costing'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
  }) => CostingInputField(
    controller: c,
    label: label,
    requiredField: required,
    onChanged: (_) => setState(() {}),
  );
}
