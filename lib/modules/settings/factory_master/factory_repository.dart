import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'factory_model.dart';

class DuplicateFactoryException implements Exception {
  const DuplicateFactoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FactoryRepository {
  FactoryRepository({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String companyId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _factories => _firestore
      .collection('companies')
      .doc(companyId)
      .collection('factories');

  Stream<List<FactoryModel>> watchFactories() {
    return _factories.snapshots().map((snapshot) {
      final factories = snapshot.docs
          .map(FactoryModel.fromFirestore)
          .where((factory) => !factory.isDeleted)
          .toList(growable: false);
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
    final normalizedName = _normalizeName(plantName);
    _validateRequired(
      plantName: plantName,
      streetAddress: streetAddress,
      country: country,
      state: state,
      city: city,
      pincode: pincode,
    );

    final duplicate = await _factories
        .where('plantNameNormalized', isEqualTo: normalizedName)
        .limit(1)
        .get();
    if (duplicate.docs.any((doc) => doc.data()['isDeleted'] != true)) {
      throw const DuplicateFactoryException(
        'A factory with this plant name already exists.',
      );
    }

    final documentId = _documentIdForName(normalizedName);
    final document = _factories.doc(documentId);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(document);
      if (existing.exists && existing.data()?['isDeleted'] != true) {
        throw const DuplicateFactoryException(
          'A factory with this plant name already exists.',
        );
      }

      final factory = FactoryModel(
        id: document.id,
        plantName: plantName.trim(),
        address: _buildAddress(
          streetAddress: streetAddress,
          city: city,
          state: state,
          pincode: pincode,
          country: country,
        ),
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
      );

      transaction.set(
        document,
        factory.toCreateMap(),
        SetOptions(merge: existing.exists),
      );
    });
  }

  Future<void> updateFactory({
    required String factoryId,
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
    final id = factoryId.trim();
    if (id.isEmpty) throw ArgumentError('Factory ID is required.');
    _validateRequired(
      plantName: plantName,
      streetAddress: streetAddress,
      country: country,
      state: state,
      city: city,
      pincode: pincode,
    );

    final normalizedName = _normalizeName(plantName);
    final duplicate = await _factories
        .where('plantNameNormalized', isEqualTo: normalizedName)
        .limit(2)
        .get();
    if (duplicate.docs.any(
          (doc) => doc.id != id && doc.data()['isDeleted'] != true,
    )) {
      throw const DuplicateFactoryException(
        'A factory with this plant name already exists.',
      );
    }

    final current = await _factories.doc(id).get();
    if (!current.exists) {
      throw StateError('The selected factory no longer exists.');
    }

    final existing = FactoryModel.fromFirestore(current);
    await _factories.doc(id).update(
      existing
          .copyWith(
        plantName: plantName.trim(),
        address: _buildAddress(
          streetAddress: streetAddress,
          city: city,
          state: state,
          pincode: pincode,
          country: country,
        ),
        streetAddress: streetAddress.trim(),
        country: country.trim(),
        state: state.trim(),
        city: city.trim(),
        pincode: pincode.trim(),
        gstNo: gstNo.trim().toUpperCase(),
        panNo: panNo.trim().toUpperCase(),
        isActive: isActive,
        updatedBy: userId,
      )
          .toUpdateMap(),
    );
  }

  Future<void> setFactoryActive({
    required String factoryId,
    required bool isActive,
    required String userId,
  }) {
    return _factories.doc(factoryId.trim()).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': userId.trim(),
    });
  }

  Future<void> softDeleteFactory({
    required String factoryId,
    required String userId,
  }) {
    return _factories.doc(factoryId.trim()).update({
      'isDeleted': true,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': userId.trim(),
    });
  }

  static String _normalizeName(String value) => value.trim().toLowerCase();

  static String _documentIdForName(String normalizedName) {
    return base64Url
        .encode(utf8.encode(normalizedName))
        .replaceAll('=', '');
  }

  static String _buildAddress({
    required String streetAddress,
    required String city,
    required String state,
    required String pincode,
    required String country,
  }) {
    return [
      streetAddress.trim(),
      city.trim(),
      state.trim(),
      pincode.trim(),
      country.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
  }

  static void _validateRequired({
    required String plantName,
    required String streetAddress,
    required String country,
    required String state,
    required String city,
    required String pincode,
  }) {
    if (plantName.trim().isEmpty) {
      throw ArgumentError('Plant name is required.');
    }
    if (streetAddress.trim().isEmpty ||
        country.trim().isEmpty ||
        state.trim().isEmpty ||
        city.trim().isEmpty ||
        pincode.trim().isEmpty) {
      throw ArgumentError('Complete factory address is required.');
    }
  }
}
