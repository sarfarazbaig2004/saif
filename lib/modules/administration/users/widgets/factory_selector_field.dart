import 'package:flutter/material.dart';

import 'package:QUIK/modules/settings/factory_master/factory_model.dart';

class FactorySelectorField extends StatelessWidget {
  final Stream<List<FactoryModel>> factoryStream;
  final bool allFactoriesSelected;
  final Set<String> selectedFactoryIds;
  final ValueChanged<String?> onSelected;
  final InputDecoration decoration;

  const FactorySelectorField({
    super.key,
    required this.factoryStream,
    required this.allFactoriesSelected,
    required this.selectedFactoryIds,
    required this.onSelected,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FactoryModel>>(
      stream: factoryStream,
      builder: (context, snapshot) {
        final factories = (snapshot.data ?? const <FactoryModel>[])
            .where((factory) => factory.isActive && !factory.isDeleted)
            .toList(growable: false);
        final loading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final names = factories
            .where((factory) => selectedFactoryIds.contains(factory.id))
            .map((factory) => factory.plantName)
            .toList(growable: false);
        final value = loading
            ? 'Loading factories...'
            : allFactoriesSelected || names.isEmpty
            ? 'All Factories'
            : names.join(', ');

        return PopupMenuButton<String>(
          enabled: !loading,
          tooltip: 'Select factory',
          onSelected: (value) => onSelected(value == '__all__' ? null : value),
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 420),
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: '__all__',
              child: Text('All Factories'),
            ),
            if (factories.isEmpty)
              const PopupMenuItem<String>(
                enabled: false,
                value: '__none__',
                child: Text('No active factories available'),
              ),
            for (final factory in factories)
              PopupMenuItem<String>(
                value: factory.id,
                child: Text(
                  factory.plantName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          child: InputDecorator(
            isEmpty: false,
            decoration: decoration,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
    );
  }
}
