import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../factory_master/factory_model.dart';
import '../factory_master/factory_repository.dart';
import 'vertical_model.dart';
import 'vertical_repository.dart';

class VerticalListScreen extends StatefulWidget {
  final String companyId;
  final bool canAdd;

  const VerticalListScreen({
    super.key,
    required this.companyId,
    required this.canAdd,
  });

  @override
  State<VerticalListScreen> createState() => _VerticalListScreenState();
}

class _VerticalListScreenState extends State<VerticalListScreen> {
  late final VerticalRepository _repository;
  late final Stream<List<VerticalModel>> _verticalStream;
  late final Stream<List<FactoryModel>> _factoryStream;

  @override
  void initState() {
    super.initState();
    _repository = VerticalRepository(companyId: widget.companyId);
    _verticalStream = _repository.watchVerticals();
    _factoryStream = FactoryRepository(
      companyId: widget.companyId,
    ).watchFactories();
  }

  Future<void> _openAddDialog(List<FactoryModel> factories) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddVerticalDialog(
        repository: _repository,
        factories: factories,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vertical added successfully.')),
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
          'Verticals',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<FactoryModel>>(
          stream: _factoryStream,
          builder: (context, factorySnapshot) {
            final factories = (factorySnapshot.data ?? const <FactoryModel>[])
                .where((factory) => factory.isActive && !factory.isDeleted)
                .toList(growable: false);
            final factoriesLoading =
                factorySnapshot.connectionState == ConnectionState.waiting &&
                !factorySnapshot.hasData;
            final canOpenAdd =
                widget.canAdd &&
                !factoriesLoading &&
                !factorySnapshot.hasError &&
                factories.isNotEmpty;

            return Padding(
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
                            'Vertical Master',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: zText,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create verticals and link them to one or more factories.',
                            style: TextStyle(
                              color: zMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                      final button = FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEA6A00),
                        ),
                        onPressed: canOpenAdd
                            ? () => _openAddDialog(factories)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Vertical'),
                      );
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            heading,
                            if (widget.canAdd) ...[
                              const SizedBox(height: 14),
                              button,
                            ],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: heading),
                          if (widget.canAdd) button,
                        ],
                      );
                    },
                  ),
                  if (widget.canAdd && !factoriesLoading && factories.isEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Add at least one active factory before creating a vertical.',
                      style: TextStyle(color: zMuted),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<VerticalModel>>(
                      stream: _verticalStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Verticals could not be loaded.'),
                          );
                        }
                        final verticals =
                            snapshot.data ?? const <VerticalModel>[];
                        if (verticals.isEmpty) {
                          return const _VerticalEmptyState();
                        }
                        return ListView.separated(
                          itemCount: verticals.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) =>
                              _VerticalCard(vertical: verticals[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VerticalCard extends StatelessWidget {
  final VerticalModel vertical;

  const _VerticalCard({required this.vertical});

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
            child: const Icon(
              Icons.view_agenda_outlined,
              color: Color(0xFFEA6A00),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vertical.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: zText,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  vertical.factoryNames.isEmpty
                      ? 'No factories linked'
                      : vertical.factoryNames.join(', '),
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

class _VerticalEmptyState extends StatelessWidget {
  const _VerticalEmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.view_agenda_outlined, size: 52, color: zMuted),
        SizedBox(height: 12),
        Text(
          'No verticals added yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: zText,
          ),
        ),
      ],
    ),
  );
}

class _AddVerticalDialog extends StatefulWidget {
  final VerticalRepository repository;
  final List<FactoryModel> factories;

  const _AddVerticalDialog({
    required this.repository,
    required this.factories,
  });

  @override
  State<_AddVerticalDialog> createState() => _AddVerticalDialogState();
}

class _AddVerticalDialogState extends State<_AddVerticalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final Set<String> _selectedFactoryIds = <String>{};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _selectFactories() async {
    final draftIds = Set<String>.from(_selectedFactoryIds);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Select Factories',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 420),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final factory in widget.factories)
                  CheckboxListTile(
                    value: draftIds.contains(factory.id),
                    title: Text(
                      factory.plantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (selected) {
                      setDialogState(() {
                        if (selected == true) {
                          draftIds.add(factory.id);
                        } else {
                          draftIds.remove(factory.id);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                Set<String>.from(draftIds),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedFactoryIds
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_selectedFactoryIds.isEmpty) {
      setState(() => _error = 'Select at least one factory.');
      return;
    }
    final userId = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (userId.isEmpty) {
      setState(() => _error = 'Your session is unavailable. Sign in again.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final selectedFactories = widget.factories
          .where((factory) => _selectedFactoryIds.contains(factory.id))
          .toList(growable: false);
      await widget.repository.addVertical(
        name: _name.text,
        factoryIds: selectedFactories.map((factory) => factory.id).toList(),
        factoryNames: selectedFactories
            .map((factory) => factory.plantName)
            .toList(),
        userId: userId,
      );
      if (mounted) Navigator.pop(context, true);
    } on DuplicateVerticalException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.code == 'permission-denied'
            ? 'You do not have permission to add verticals.'
            : 'The vertical could not be saved. Please try again.';
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'The vertical could not be saved. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedNames = widget.factories
        .where((factory) => _selectedFactoryIds.contains(factory.id))
        .map((factory) => factory.plantName)
        .toList(growable: false);
    return AlertDialog(
      title: const Text(
        'Add Vertical',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Vertical Name *',
                  prefixIcon: Icon(Icons.view_agenda_outlined),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Vertical name is required.'
                    : null,
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _saving ? null : _selectFactories,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Belongs to which Factory *',
                    prefixIcon: Icon(Icons.factory_outlined),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedNames.isEmpty
                              ? 'Select factories'
                              : selectedNames.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selectedNames.isEmpty ? zMuted : zText,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEA6A00),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Vertical'),
        ),
      ],
    );
  }
}
