import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';

class CompanyProfileBankScreen extends StatefulWidget {
  final String companyId;
  final bool canEdit;

  const CompanyProfileBankScreen({
    super.key,
    required this.companyId,
    required this.canEdit,
  });

  @override
  State<CompanyProfileBankScreen> createState() => _CompanyProfileBankScreenState();
}

class _CompanyProfileBankScreenState extends State<CompanyProfileBankScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {
    for (final key in const [
      'companyName', 'legalName', 'gstin', 'pan', 'cin', 'iecCode', 'email',
      'phone', 'website', 'state', 'city', 'pincode', 'country', 'address',
      'lutNumber', 'adCode',
    ]) key: TextEditingController(),
  };
  final List<_BankDraft> _banks = [];
  Map<String, dynamic> _original = {};
  bool _loading = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>> get _companyRef =>
      FirebaseFirestore.instance.collection('companies').doc(widget.companyId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    for (final bank in _banks) {
      bank.dispose();
    }
    super.dispose();
  }

  String _first(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = (data[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Future<void> _load() async {
    try {
      final snapshot = await _companyRef.get();
      final data = snapshot.data() ?? <String, dynamic>{};
      _original = Map<String, dynamic>.from(data);
      final aliases = <String, List<String>>{
        'companyName': ['companyName', 'name'],
        'legalName': ['legalName', 'entityName'],
        'gstin': ['gstin', 'gstNo', 'gst'],
        'pan': ['pan', 'panNo'],
        'cin': ['cin'], 'iecCode': ['iecCode', 'iec'],
        'email': ['email'], 'phone': ['phone', 'mobile'],
        'website': ['website'], 'state': ['state'],
        'city': ['city', 'district'],
        'pincode': ['pincode', 'postalCode', 'zip'],
        'country': ['country'],
        'address': ['address', 'streetAddress', 'registeredAddress'],
        'lutNumber': ['lutNumber'], 'adCode': ['adCode'],
      };
      for (final entry in aliases.entries) {
        _fields[entry.key]!.text = _first(data, entry.value);
      }
      if (_fields['country']!.text.isEmpty) _fields['country']!.text = 'India';
      final rawBanks = data['bankAccounts'];
      if (rawBanks is List) {
        for (final item in rawBanks) {
          if (item is Map) _banks.add(_BankDraft.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      if (_banks.isEmpty) {
        final legacy = data['bankDetails'] is Map
            ? Map<String, dynamic>.from(data['bankDetails'] as Map)
            : data;
        final bank = _BankDraft.fromMap(legacy)..isDefault = true;
        if (bank.hasData) {
          _banks.add(bank);
        } else {
          bank.dispose();
        }
      }
      if (_banks.isNotEmpty && !_banks.any((bank) => bank.isDefault)) {
        _banks.first.isDefault = true;
      }
    } catch (_) {
      _message('Company profile could not be loaded.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validate(String key, String? raw) {
    final value = (raw ?? '').trim();
    if (key == 'companyName' && value.isEmpty) return 'Company Name is required';
    if (value.isEmpty) return null;
    if ((key == 'companyName' || key == 'legalName') && value.length > 150) return 'Maximum 150 characters';
    if (key == 'gstin' && !RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$').hasMatch(value.toUpperCase())) return 'Enter a valid 15-character GSTIN';
    if (key == 'pan' && !RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(value.toUpperCase())) return 'Enter a valid 10-character PAN';
    if (key == 'cin' && !RegExp(r'^[A-Z]\d{5}[A-Z]{2}\d{4}[A-Z]{3}\d{6}$').hasMatch(value.toUpperCase())) return 'Enter a valid CIN';
    if (key == 'iecCode' && !RegExp(r'^[A-Z0-9]{10}$').hasMatch(value.toUpperCase())) return 'IEC Code must be 10 letters/numbers';
    if (key == 'email' && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Enter a valid email';
    if (key == 'phone' && !RegExp(r'^[+0-9][0-9 ()-]{6,19}$').hasMatch(value)) return 'Enter a valid phone number';
    if (key == 'website' && Uri.tryParse(value.contains('://') ? value : 'https://$value')?.host.isEmpty != false) return 'Enter a valid website';
    if (key == 'pincode' && !RegExp(r'^\d{6}$').hasMatch(value)) return 'Enter a valid 6-digit pincode';
    return null;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final populatedBanks = _banks.where((bank) => bank.hasData).toList();
    for (final bank in populatedBanks) {
      final error = bank.validationError;
      if (error != null) { _message(error, error: true); return; }
    }
    if (populatedBanks.isNotEmpty && !populatedBanks.any((bank) => bank.isDefault)) {
      populatedBanks.first.isDefault = true;
    }
    setState(() => _saving = true);
    try {
      final updates = <String, dynamic>{};
      for (final entry in _fields.entries) {
        var value = entry.value.text.trim();
        if (['gstin', 'pan', 'cin', 'iecCode', 'adCode'].contains(entry.key)) value = value.toUpperCase();
        if (value.isNotEmpty && value != (_original[entry.key] ?? '').toString().trim()) updates[entry.key] = value;
      }
      final bankMaps = populatedBanks.map((bank) => bank.toMap()).toList();
      if (bankMaps.isNotEmpty) {
        final defaultBank = populatedBanks.firstWhere((bank) => bank.isDefault);
        updates.addAll({
          'bankAccounts': bankMaps,
          'defaultBankAccountId': defaultBank.id,
          'bankDetails': defaultBank.toMap(),
          'bankName': defaultBank.bankName.text.trim(),
          'accountHolderName': defaultBank.accountHolder.text.trim(),
          'accountNumber': defaultBank.accountNumber.text.trim(),
          'ifsc': defaultBank.ifsc.text.trim().toUpperCase(),
          'ifscCode': defaultBank.ifsc.text.trim().toUpperCase(),
          'branch': defaultBank.branch.text.trim(),
          'swiftCode': defaultBank.swift.text.trim().toUpperCase(),
          'bankAddress': defaultBank.address.text.trim(),
        });
      }
      if (updates.isEmpty) { _message('No changes to save.'); return; }
      updates['updatedAt'] = FieldValue.serverTimestamp();
      updates['updatedBy'] = FirebaseAuth.instance.currentUser?.uid;
      await _companyRef.set(updates, SetOptions(merge: true));
      _original.addAll(updates);
      _message('Company profile and banking saved.');
    } on FirebaseException catch (e) {
      _message(e.message ?? 'Company profile could not be saved.', error: true);
    } catch (_) {
      _message('Company profile could not be saved.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Colors.red.shade700 : null));
  }

  void _addBank() => setState(() => _banks.add(_BankDraft()..isDefault = _banks.isEmpty));
  void _removeBank(int index) => setState(() {
    final removed = _banks.removeAt(index);
    final wasDefault = removed.isDefault;
    removed.dispose();
    if (wasDefault && _banks.isNotEmpty) _banks.first.isDefault = true;
  });

  Widget _field(String key, String label, IconData icon, {int lines = 1}) => TextFormField(
    controller: _fields[key], enabled: widget.canEdit, maxLines: lines,
    textCapitalization: ['gstin', 'pan', 'cin', 'iecCode', 'adCode'].contains(key) ? TextCapitalization.characters : TextCapitalization.none,
    validator: (value) => _validate(key, value),
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white),
  );

  Widget _grid(List<Widget> children) => LayoutBuilder(builder: (_, constraints) {
    final columns = constraints.maxWidth >= 960 ? 3 : constraints.maxWidth >= 600 ? 2 : 1;
    final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
    return Wrap(spacing: 12, runSpacing: 12, children: children.map((child) => SizedBox(width: width, child: child)).toList());
  });

  Widget _section(String title, String subtitle, Widget child) => Container(
    padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: zBorder), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: zMuted)), const SizedBox(height: 16), child]),
  );

  Widget _bankCard(int index, _BankDraft bank) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: zAppBg, border: Border.all(color: bank.isDefault ? zOrange : zBorder), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Row(children: [const Icon(Icons.account_balance_outlined), const SizedBox(width: 8), Expanded(child: Text(bank.isDefault ? 'Default Bank Account' : 'Bank Account ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900))), TextButton.icon(onPressed: widget.canEdit ? () => setState(() { for (final item in _banks) { item.isDefault = identical(item, bank); } }) : null, icon: Icon(bank.isDefault ? Icons.star : Icons.star_border), label: Text(bank.isDefault ? 'Default' : 'Set Default')), IconButton(onPressed: widget.canEdit ? () => _removeBank(index) : null, icon: const Icon(Icons.remove_circle_outline, color: Colors.red))]),
      const SizedBox(height: 10),
      _grid([bank.field(bank.label, 'Account Label', enabled: widget.canEdit), bank.field(bank.bankName, 'Bank Name', enabled: widget.canEdit), bank.field(bank.accountHolder, 'Account Holder', enabled: widget.canEdit), bank.field(bank.accountNumber, 'Account Number', enabled: widget.canEdit), bank.field(bank.ifsc, 'IFSC / RTGS Code', enabled: widget.canEdit), bank.field(bank.branch, 'Branch', enabled: widget.canEdit), bank.field(bank.swift, 'SWIFT Code', enabled: widget.canEdit)]),
      const SizedBox(height: 12), bank.field(bank.address, 'Bank Address', lines: 2, enabled: widget.canEdit),
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: zAppBg,
    appBar: AppBar(title: const Text('Company Profile & Banking'), actions: [if (widget.canEdit) Padding(padding: const EdgeInsets.only(right: 12), child: FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save')))]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(18), children: [
      if (!widget.canEdit) const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('You have read-only access to these settings.'))),
      _section('Company Identity', 'Details used across quotations, invoices, and ERP documents.', _grid([_field('companyName', 'Company Name', Icons.business_outlined), _field('legalName', 'Legal Name', Icons.verified_outlined), _field('gstin', 'GSTIN', Icons.receipt_long_outlined), _field('pan', 'PAN', Icons.badge_outlined), _field('cin', 'CIN', Icons.confirmation_number_outlined), _field('iecCode', 'IEC Code', Icons.import_export_outlined)])),
      const SizedBox(height: 16),
      _section('Contact & Address', 'Registered address and company contact details.', Column(children: [_grid([_field('email', 'Email', Icons.email_outlined), _field('phone', 'Phone', Icons.phone_outlined), _field('website', 'Website', Icons.language_outlined), _field('state', 'State', Icons.map_outlined), _field('city', 'City', Icons.location_city_outlined), _field('pincode', 'Pincode', Icons.pin_drop_outlined), _field('country', 'Country', Icons.public_outlined)]), const SizedBox(height: 12), _field('address', 'Registered Address', Icons.place_outlined, lines: 3)])),
      const SizedBox(height: 16),
      _section('Export / Tax References', 'Optional references for export and tax documents.', _grid([_field('lutNumber', 'LUT Number', Icons.description_outlined), _field('adCode', 'AD Code', Icons.account_balance_outlined)])),
      const SizedBox(height: 16),
      _section('Bank Accounts', 'Maintain multiple accounts and select one default account.', Column(children: [for (var i = 0; i < _banks.length; i++) _bankCard(i, _banks[i]), if (widget.canEdit) Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: _addBank, icon: const Icon(Icons.add), label: const Text('Add Bank Account')))])),
    ])),
  );
}

class _BankDraft {
  String id = DateTime.now().microsecondsSinceEpoch.toString();
  bool isDefault = false;
  final label = TextEditingController(); final bankName = TextEditingController();
  final accountHolder = TextEditingController(); final accountNumber = TextEditingController();
  final ifsc = TextEditingController(); final branch = TextEditingController();
  final swift = TextEditingController(); final address = TextEditingController();

  factory _BankDraft.fromMap(Map<String, dynamic> map) {
    final bank = _BankDraft();
    bank.id = (map['id'] ?? bank.id).toString(); bank.isDefault = map['isDefault'] == true;
    bank.label.text = (map['accountLabel'] ?? map['label'] ?? '').toString();
    bank.bankName.text = (map['bankName'] ?? '').toString(); bank.accountHolder.text = (map['accountHolder'] ?? map['accountHolderName'] ?? '').toString();
    bank.accountNumber.text = (map['accountNumber'] ?? '').toString(); bank.ifsc.text = (map['ifsc'] ?? map['ifscCode'] ?? '').toString();
    bank.branch.text = (map['branch'] ?? '').toString(); bank.swift.text = (map['swiftCode'] ?? '').toString(); bank.address.text = (map['bankAddress'] ?? '').toString();
    return bank;
  }
  _BankDraft();
  bool get hasData => [bankName, accountHolder, accountNumber, ifsc, branch, swift, address].any((c) => c.text.trim().isNotEmpty);
  String? get validationError {
    if (bankName.text.trim().isEmpty || accountNumber.text.trim().isEmpty || ifsc.text.trim().isEmpty) return 'Bank name, account number, and IFSC are required for every saved bank account.';
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc.text.trim().toUpperCase())) return 'Enter a valid IFSC code.';
    return null;
  }
  Widget field(TextEditingController controller, String label, {int lines = 1, bool enabled = true}) => TextFormField(controller: controller, enabled: enabled, maxLines: lines, decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white));
  Map<String, dynamic> toMap() => {'id': id, 'accountLabel': label.text.trim(), 'bankName': bankName.text.trim(), 'accountHolder': accountHolder.text.trim(), 'accountHolderName': accountHolder.text.trim(), 'accountNumber': accountNumber.text.trim(), 'ifsc': ifsc.text.trim().toUpperCase(), 'ifscCode': ifsc.text.trim().toUpperCase(), 'branch': branch.text.trim(), 'swiftCode': swift.text.trim().toUpperCase(), 'bankAddress': address.text.trim(), 'isDefault': isDefault, 'isActive': true};
  void dispose() { for (final c in [label, bankName, accountHolder, accountNumber, ifsc, branch, swift, address]) { c.dispose(); } }
}
