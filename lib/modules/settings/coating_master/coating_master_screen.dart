import 'package:flutter/material.dart';

import 'coating_master_model.dart';
import 'coating_master_repository.dart';

class CoatingMasterScreen extends StatefulWidget {
  final String tenantId;

  const CoatingMasterScreen({super.key, required this.tenantId});

  @override
  State<CoatingMasterScreen> createState() => _CoatingMasterScreenState();
}

class _CoatingMasterScreenState extends State<CoatingMasterScreen> {
  CoatingMasterRepository get _repo =>
      CoatingMasterRepository(tenantId: widget.tenantId);

  static const _defaults = [
    CoatingMasterModel(
      id: 'hdg_80_micron',
      status: 'HDG',
      spec: '80 Micron',
      percent: 6,
    ),
    CoatingMasterModel(
      id: 'hdg_100_micron',
      status: 'HDG',
      spec: '100 Micron',
      percent: 7,
    ),
    CoatingMasterModel(
      id: 'galvalume_az150',
      status: 'Galvalume',
      spec: 'AZ150',
      percent: 0,
    ),
    CoatingMasterModel(
      id: 'galvalume_az350',
      status: 'Galvalume',
      spec: 'AZ350',
      percent: 0,
    ),
    CoatingMasterModel(id: 'zm350', status: 'ZM', spec: 'ZM350', percent: 0),
    CoatingMasterModel(
      id: 'posmac',
      status: 'PosMAC',
      spec: 'PosMAC',
      percent: 0,
    ),
    CoatingMasterModel(id: 'black', status: 'Black', spec: 'None', percent: 0),
  ];

  Future<void> _seedDefaults() async {
    for (final item in _defaults) {
      await _repo.save(item);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default coating master saved')),
    );
  }

  Future<void> _edit(CoatingMasterModel item) async {
    final percent = TextEditingController(text: item.percent.toString());

    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${item.status} - ${item.spec}'),
        content: TextField(
          controller: percent,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Percentage'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(percent.text) ?? 0),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    await _repo.save(
      CoatingMasterModel(
        id: item.id,
        status: item.status,
        spec: item.spec,
        percent: result,
        isActive: item.isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coating Master'),
        actions: [
          TextButton.icon(
            onPressed: _seedDefaults,
            icon: const Icon(Icons.playlist_add),
            label: const Text('Seed Defaults'),
          ),
        ],
      ),
      body: StreamBuilder<List<CoatingMasterModel>>(
        stream: _repo.watch(),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <CoatingMasterModel>[];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (rows.isEmpty) {
            return const Center(
              child: Text('No coating records. Click Seed Defaults.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final item = rows[index];
              return ListTile(
                leading: const Icon(Icons.layers_outlined),
                title: Text('${item.status} - ${item.spec}'),
                subtitle: Text(item.isActive ? 'Active' : 'Inactive'),
                trailing: Text(
                  '${item.percent.toStringAsFixed(2)}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onTap: () => _edit(item),
              );
            },
          );
        },
      ),
    );
  }
}
