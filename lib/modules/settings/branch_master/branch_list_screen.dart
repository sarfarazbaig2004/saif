import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import 'branch_model.dart';
import 'branch_repository.dart';

class BranchListScreen extends StatefulWidget {
  final String companyId;
  final bool canAdd;

  const BranchListScreen({
    super.key,
    required this.companyId,
    required this.canAdd,
  });

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  late final BranchRepository _repository;
  int _streamRevision = 0;

  @override
  void initState() {
    super.initState();
    _repository = BranchRepository(companyId: widget.companyId);
  }

  void _retry() => setState(() => _streamRevision++);

  Future<void> _openAddDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddBranchDialog(repository: _repository),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branch added successfully.')),
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
        title: const Text('Branches', style: TextStyle(fontWeight: FontWeight.w900)),
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
                        'Branch Master',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: zText),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create and manage company branches.',
                        style: TextStyle(color: zMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  );
                  final button = FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEA6A00)),
                    onPressed: widget.canAdd ? _openAddDialog : null,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Branch'),
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
                child: StreamBuilder<List<BranchModel>>(
                  key: ValueKey(_streamRevision),
                  stream: _repository.watchBranches(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) return _ErrorState(onRetry: _retry);
                    final branches = snapshot.data ?? const <BranchModel>[];
                    if (branches.isEmpty) {
                      return _EmptyState(canAdd: widget.canAdd, onAdd: _openAddDialog);
                    }
                    return RefreshIndicator(
                      onRefresh: () async => _retry(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: branches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _BranchCard(branch: branches[index]),
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

class _BranchCard extends StatelessWidget {
  final BranchModel branch;

  const _BranchCard({required this.branch});

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
            child: const Icon(Icons.account_tree_outlined, color: Color(0xFFEA6A00)),
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
                    Text(branch.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: zText)),
                    _Badge(label: branch.code, color: const Color(0xFFEA6A00)),
                    _Badge(
                      label: branch.isActive ? 'Active' : 'Inactive',
                      color: branch.isActive ? const Color(0xFF15803D) : zMuted,
                    ),
                  ],
                ),
                if (branch.description.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(branch.description, style: const TextStyle(color: zMuted, height: 1.4)),
                ],
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
        const Icon(Icons.account_tree_outlined, size: 52, color: zMuted),
        const SizedBox(height: 12),
        const Text('No branches yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: zText)),
        const SizedBox(height: 6),
        Text(
          canAdd ? 'Add your first company branch to get started.' : 'No company branches have been configured.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: zMuted),
        ),
        if (canAdd) ...[
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add Branch')),
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
        const Text('Branches could not be loaded.', style: TextStyle(fontWeight: FontWeight.w900, color: zText)),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ],
    ),
  );
}

class _AddBranchDialog extends StatefulWidget {
  final BranchRepository repository;

  const _AddBranchDialog({required this.repository});

  @override
  State<_AddBranchDialog> createState() => _AddBranchDialogState();
}

class _AddBranchDialogState extends State<_AddBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _description = TextEditingController();
  bool _isActive = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _description.dispose();
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
      await widget.repository.addBranch(
        name: _name.text,
        code: _code.text,
        description: _description.text,
        isActive: _isActive,
        userId: userId,
      );
      if (mounted) Navigator.pop(context, true);
    } on DuplicateBranchException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.code == 'permission-denied'
          ? 'You do not have permission to add branches.'
          : 'The branch could not be saved. Please try again.');
    } catch (_) {
      if (mounted) setState(() => _error = 'The branch could not be saved. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Branch', style: TextStyle(fontWeight: FontWeight.w900)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Branch Name *'),
                  validator: (value) => (value ?? '').trim().isEmpty ? 'Branch name is required.' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _code,
                  maxLength: 24,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]'))],
                  decoration: const InputDecoration(labelText: 'Branch Code *', hintText: 'e.g. INFRA-MH'),
                  validator: (value) {
                    final code = (value ?? '').trim();
                    if (code.isEmpty) return 'Branch code is required.';
                    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(code)) return 'Use only letters, numbers, hyphen, and underscore.';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _description,
                  maxLength: 240,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
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
              : const Text('Save Branch'),
        ),
      ],
    );
  }
}
