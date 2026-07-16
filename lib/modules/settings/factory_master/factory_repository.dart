import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'factory_model.dart';

class DuplicateFactoryException implements Exception {
  final String message;

  const DuplicateFactoryException(this.message);
}

class FactoryRepository {
  final String companyId;
  final FirebaseFirestore _firestore;

  FactoryRepository({required this.companyId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _factories => _firestore
      .collection('companies')
      .doc(companyId)
      .collection('factories');

  Stream<List<FactoryModel>> watchFactories() {
    return _factories.snapshots().map((snapshot) {
      final factories = snapshot.docs
          .map(FactoryModel.fromFirestore)
          .where((factory) => !factory.isDeleted)
          .toList();
      factories.sort(
        (a, b) => a.plantName.toLowerCase().compareTo(
          b.plantName.toLowerCase(),
        ),
      );
      return factories;
    });
  }

  Future<void> addFactory({
    required String plantName,
    required String streetAddress,
    required String country,
    required String state,
    required String city,
    required String pincode,
    required String gstNo,
    required String panNo,
    required bool isActive,
    required String userId,
  }) async {
    final normalizedName = plantName.trim().toLowerCase();
    final normalizedQuery = await _factories
        .where('plantNameNormalized', isEqualTo: normalizedName)
        .limit(1)
        .get();
    final allFactories = await _factories.get();
    final duplicateExists =
        normalizedQuery.docs.any((doc) => doc.data()['isDeleted'] != true) ||
        allFactories.docs.any((doc) {
          final data = doc.data();
          return data['isDeleted'] != true &&
              (data['plantName'] ?? '').toString().trim().toLowerCase() ==
                  normalizedName;
        });
    if (duplicateExists) {
      throw const DuplicateFactoryException(
        'A factory with this plant name already exists.',
      );
    }

    final documentId = base64Url
        .encode(utf8.encode(normalizedName))
        .replaceAll('=', '');
    final document = _factories.doc(documentId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(document);
      if (existing.exists) {
        throw const DuplicateFactoryException(
          'A factory with this plant name already exists.',
        );
      }
      transaction.set(
        document,
        FactoryModel(
          id: document.id,
          plantName: plantName.trim(),
          address: [
            streetAddress.trim(),
            city.trim(),
            state.trim(),
            pincode.trim(),
            country.trim(),
          ].where((part) => part.isNotEmpty).join(', '),
          streetAddress: streetAddress.trim(),
          country: country.trim(),
          state: state.trim(),
          city: city.trim(),
          pincode: pincode.trim(),
          gstNo: gstNo.trim().toUpperCase(),
          panNo: panNo.trim().toUpperCase(),
          isActive: isActive,
          createdBy: userId,
          updatedBy: userId,
        ).toMap(),
      );
    });
  }
}
