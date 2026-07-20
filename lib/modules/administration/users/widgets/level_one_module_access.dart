import 'package:flutter/material.dart';

import 'package:QUIK/core/modules/module_registry.dart';

class LevelOneModuleAccess extends StatelessWidget {
  final Set<String> selectedModuleIds;
  final void Function(String moduleId, bool value) onChanged;
  final bool readOnly;

  const LevelOneModuleAccess({
    super.key,
    required this.selectedModuleIds,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final modules = ModuleRegistry.activeModules;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 74,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final module = modules[index];
            final selected = selectedModuleIds.contains(module.id);
            return Container(
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: CheckboxListTile(
                value: selected,
                onChanged: readOnly
                    ? null
                    : (value) => onChanged(module.id, value ?? false),
                title: Text(
                  module.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  selected ? 'Access enabled' : 'Access disabled',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            );
          },
        );
      },
    );
  }
}
