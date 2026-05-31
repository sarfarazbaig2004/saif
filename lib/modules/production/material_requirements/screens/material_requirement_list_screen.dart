import 'package:flutter/material.dart';

import 'package:QUIK/core/theme/app_theme.dart';
import 'package:QUIK/modules/production/material_requirements/models/material_requirement_model.dart';
import 'package:QUIK/modules/production/material_requirements/repositories/material_requirement_repository.dart';
import 'package:QUIK/modules/production/material_requirements/screens/material_requirement_detail_screen.dart';

class MaterialRequirementListScreen extends StatelessWidget {
  final String tenantId;

  const MaterialRequirementListScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    final activeTenantId = tenantId.trim();

    if (activeTenantId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Select a company workspace first.')),
      );
    }

    final repository = MaterialRequirementRepository(tenantId: activeTenantId);

    return Scaffold(
      backgroundColor: zCanvasBg,
      appBar: AppBar(title: const Text('Material Requirements')),
      body: StreamBuilder<List<MaterialRequirementModel>>(
        stream: repository.watchRequirements(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load material requirements: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requirements = snapshot.data ?? const [];

          if (requirements.isEmpty) {
            return const Center(child: Text('No material requirements found.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('MR No')),
                    DataColumn(label: Text('Customer PO')),
                    DataColumn(label: Text('Job Card')),
                    DataColumn(label: Text('BOM')),
                    DataColumn(label: Text('Required')),
                    DataColumn(label: Text('Available')),
                    DataColumn(label: Text('Shortage')),
                    DataColumn(label: Text('Purchase Qty')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: requirements
                      .map((requirement) {
                        return DataRow(
                          onSelectChanged: (_) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MaterialRequirementDetailScreen(
                                  tenantId: activeTenantId,
                                  requirement: requirement,
                                ),
                              ),
                            );
                          },
                          cells: [
                            DataCell(Text(_dash(requirement.requirementNo))),
                            DataCell(Text(_dash(requirement.poNumber))),
                            DataCell(Text(_dash(requirement.jobCardNo))),
                            DataCell(Text(_dash(requirement.bomNumber))),
                            DataCell(Text(_qty(requirement.totalRequiredQty))),
                            DataCell(Text(_qty(requirement.totalAvailableQty))),
                            DataCell(Text(_qty(requirement.totalShortageQty))),
                            DataCell(
                              Text(_qty(requirement.totalPurchaseRequiredQty)),
                            ),
                            DataCell(Text(_dash(requirement.status))),
                          ],
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _dash(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  static String _qty(double value) {
    return value.toStringAsFixed(2);
  }
}
