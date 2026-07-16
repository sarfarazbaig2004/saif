import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import 'factory_model.dart';
import 'factory_repository.dart';

class FactoryListScreen extends StatefulWidget {
  final String companyId;
  final bool canAdd;

  const FactoryListScreen({
    super.key,
    required this.companyId,
    required this.canAdd,
  });

  @override
  State<FactoryListScreen> createState() => _FactoryListScreenState();
}

class _FactoryListScreenState extends State<FactoryListScreen> {
  late final FactoryRepository _repository;
  int _streamRevision = 0;

  @override
  void initState() {
    super.initState();
    _repository = FactoryRepository(companyId: widget.companyId);
  }

  void _retry() => setState(() => _streamRevision++);

  Future<void> _openAddDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddFactoryDialog(repository: _repository),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factory added successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Factories',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 520;
                  final heading = const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Factory Master',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: zText),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create and manage company factories and plants.',
                        style: TextStyle(color: zMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                  final button = FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEA6A00)),
                    onPressed: widget.canAdd ? _openAddDialog : null,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Factory'),
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [heading, if (widget.canAdd) ...[const SizedBox(height: 14), button]],
                    );
                  }
                  return Row(children: [Expanded(child: heading), if (widget.canAdd) button]);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<FactoryModel>>(
                  key: ValueKey(_streamRevision),
                  stream: _repository.watchFactories(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) return _ErrorState(onRetry: _retry);
                    final factories = snapshot.data ?? const <FactoryModel>[];
                    if (factories.isEmpty) {
                      return _EmptyState(canAdd: widget.canAdd, onAdd: _openAddDialog);
                    }
                    return RefreshIndicator(
                      onRefresh: () async => _retry(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: factories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _FactoryCard(factory: factories[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactoryCard extends StatelessWidget {
  final FactoryModel factory;

  const _FactoryCard({required this.factory});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E8),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.factory_outlined, color: Color(0xFFEA6A00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      factory.plantName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: zText,
                      ),
                    ),
                    if (factory.gstNo.isNotEmpty)
                      _Badge(
                        label: factory.gstNo,
                        color: const Color(0xFFEA6A00),
                      ),
                    _Badge(
                      label: factory.isActive ? 'Active' : 'Inactive',
                      color: factory.isActive ? const Color(0xFF15803D) : zMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  factory.address,
                  style: const TextStyle(color: zMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
  );
}

class _EmptyState extends StatelessWidget {
  final bool canAdd;
  final VoidCallback onAdd;

  const _EmptyState({required this.canAdd, required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.factory_outlined, size: 52, color: zMuted),
        const SizedBox(height: 12),
        const Text(
          'No factories added yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: zText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          canAdd ? 'Add your first company factory to get started.' : 'No company factories have been configured.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: zMuted),
        ),
        if (canAdd) ...[
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add Factory')),
        ],
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 48, color: zMuted),
        const SizedBox(height: 12),
        const Text('Factories could not be loaded.', style: TextStyle(fontWeight: FontWeight.w900, color: zText)),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ],
    ),
  );
}

class _AddFactoryDialog extends StatefulWidget {
  final FactoryRepository repository;

  const _AddFactoryDialog({required this.repository});

  @override
  State<_AddFactoryDialog> createState() => _AddFactoryDialogState();
}

class _AddFactoryDialogState extends State<_AddFactoryDialog> {
  static const _indianStates = <String>[
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  final _formKey = GlobalKey<FormState>();
  final _plantName = TextEditingController();
  final _streetAddress = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _gstNo = TextEditingController();
  final _panNo = TextEditingController();
  String? _state;
  bool _isActive = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _plantName.dispose();
    _streetAddress.dispose();
    _city.dispose();
    _pincode.dispose();
    _gstNo.dispose();
    _panNo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final companyId = widget.repository.companyId.trim();
    final userId = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (companyId.isEmpty || userId.isEmpty) {
      setState(() => _error = 'Your workspace session is unavailable. Please sign in again.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.addFactory(
        plantName: _plantName.text,
        streetAddress: _streetAddress.text,
        country: 'India',
        state: _state ?? '',
        city: _city.text,
        pincode: _pincode.text,
        gstNo: _gstNo.text,
        panNo: _panNo.text,
        isActive: _isActive,
        userId: userId,
      );
      if (mounted) Navigator.pop(context, true);
    } on DuplicateFactoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.code == 'permission-denied'
          ? 'You do not have permission to add factories.'
          : 'The factory could not be saved. Please try again.');
    } catch (_) {
      if (mounted) setState(() => _error = 'The factory could not be saved. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _formSection({
    required String title,
    required IconData icon,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: zBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E8),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: const Color(0xFFEA6A00)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: zText,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle, style: const TextStyle(color: zMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _responsivePair(Widget left, Widget right) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    if (compact) {
      return Column(children: [left, const SizedBox(height: 12), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Factory', style: TextStyle(fontWeight: FontWeight.w900)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _plantName,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Plant Name *',
                    prefixIcon: Icon(Icons.factory_outlined),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Plant name is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                _formSection(
                  title: 'Entity Address',
                  icon: Icons.location_on_outlined,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _streetAddress,
                        maxLength: 500,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Street Address *',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        validator: (value) {
                          final address = (value ?? '').trim();
                          if (address.isEmpty) return 'Street address is required.';
                          if (address.length < 5) {
                            return 'Enter at least 5 meaningful characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _responsivePair(
                        TextFormField(
                          initialValue: 'India',
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _state,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'State *',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                          items: _indianStates
                              .map(
                                (state) => DropdownMenuItem(
                                  value: state,
                                  child: Text(
                                    state,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _state = value),
                          validator: (value) => value == null
                              ? 'State is required.'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _responsivePair(
                        TextFormField(
                          controller: _city,
                          maxLength: 80,
                          decoration: const InputDecoration(
                            labelText: 'District / City *',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'District / City is required.'
                              : null,
                        ),
                        TextFormField(
                          controller: _pincode,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Pincode / Zip Code *',
                            prefixIcon: Icon(Icons.pin_drop_outlined),
                          ),
                          validator: (value) =>
                              RegExp(r'^[1-9][0-9]{5}$').hasMatch(
                                (value ?? '').trim(),
                              )
                              ? null
                              : 'Enter a valid 6-digit pincode.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _formSection(
                  title: 'Tax Information',
                  subtitle: 'Optional fields for GST and PAN details',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _gstNo,
                        maxLength: 15,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'GSTIN',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        ),
                        validator: (value) {
                          final gstNo = (value ?? '').trim().toUpperCase();
                          if (gstNo.isEmpty) return null;
                          if (!RegExp(
                            r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
                          ).hasMatch(gstNo)) {
                            return 'Enter a valid 15-character GSTIN.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _panNo,
                        maxLength: 10,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'PAN Number',
                          prefixIcon: Icon(Icons.credit_card_outlined),
                        ),
                        validator: (value) {
                          final panNo = (value ?? '').trim().toUpperCase();
                          if (panNo.isEmpty) return null;
                          return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$')
                                  .hasMatch(panNo)
                              ? null
                              : 'Enter a valid 10-character PAN.';
                        },
                      ),
                    ],
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active', style: TextStyle(fontWeight: FontWeight.w700)),
                  value: _isActive,
                  onChanged: _saving ? null : (value) => setState(() => _isActive = value),
                ),
                if (_error != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEA6A00)),
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Factory'),
        ),
      ],
    );
  }
}
