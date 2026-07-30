import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'vertical_model.dart';

class DuplicateVerticalException implements Exception {
  const DuplicateVerticalException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VerticalRepository {
  VerticalRepository({
    required this.companyId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String companyId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _verticals => _firestore
      .collection('companies')
      .doc(companyId)
      .collection('verticals');

  Stream<List<VerticalModel>> watchVerticals() {
    return _verticals.snapshots().map((snapshot) {
      final verticals = snapshot.docs
          .map(VerticalModel.fromFirestore)
          .where((vertical) => !vertical.isDeleted)
          .toList(growable: false);
      verticals.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return verticals;
    });
  }

  Future<void> addVertical({
    required String name,
    required List<String> factoryIds,
    required List<String> factoryNames,
    required String userId,
  }) async {
    final normalizedName = _normalizeName(name);
    _validateInput(
      name: name,
      factoryIds: factoryIds,
      factoryNames: factoryNames,
    );

    final duplicate = await _verticals
        .where('nameNormalized', isEqualTo: normalizedName)
        .limit(1)
        .get();
    if (duplicate.docs.any((doc) => doc.data()['isDeleted'] != true)) {
      throw const DuplicateVerticalException(
        'A vertical with this name already exists.',
      );
    }

    final documentId = _documentIdForName(normalizedName);
    final document = _verticals.doc(documentId);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(document);
      if (existing.exists && existing.data()?['isDeleted'] != true) {
        throw const DuplicateVerticalException(
          'A vertical with this name already exists.',
        );
      }

      final vertical = VerticalModel(
        id: document.id,
        name: name.trim(),
        factoryIds: List<String>.from(factoryIds),
        factoryNames: List<String>.from(factoryNames),
        createdBy: userId,
        updatedBy: userId,
      );

      transaction.set(
        document,
        vertical.toCreateMap(),
        SetOptions(merge: existing.exists),
      );
    });
  }

  Future<void> updateVertical({
    required String verticalId,
    required String name,
    required List<String> factoryIds,
    required List<String> factoryNames,
    required bool isActive,
    required String userId,
  }) async {
    final id = verticalId.trim();
    if (id.isEmpty) throw ArgumentError('Vertical ID is required.');
    _validateInput(
      name: name,
      factoryIds: factoryIds,
      factoryNames: factoryNames,
    );

    final normalizedName = _normalizeName(name);
    final duplicate = await _verticals
        .where('nameNormalized', isEqualTo: normalizedName)
        .limit(2)
        .get();
    if (duplicate.docs.any(
          (doc) => doc.id != id && doc.data()['isDeleted'] != true,
    )) {
      throw const DuplicateVerticalException(
        'A vertical with this name already exists.',
      );
    }

    final current = await _verticals.doc(id).get();
    if (!current.exists) {
      throw StateError('The selected vertical no longer exists.');
    }

    final existing = VerticalModel.fromFirestore(current);
    await _verticals.doc(id).update(
      existing
          .copyWith(
        name: name.trim(),
        factoryIds: List<String>.from(factoryIds),
        factoryNames: List<String>.from(factoryNames),
        isActive: isActive,
        updatedBy: userId,
      )
          .toUpdateMap(),
    );
  }

  Future<void> setVerticalActive({
    required String verticalId,
    required bool isActive,
    required String userId,
  }) {
    return _verticals.doc(verticalId.trim()).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': userId.trim(),
    });
  }

  Future<void> softDeleteVertical({
    required String verticalId,
    required String userId,
  }) {
    return _verticals.doc(verticalId.trim()).update({
      'isDeleted': true,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': userId.trim(),
    });
  }

  static void _validateInput({
    required String name,
    required List<String> factoryIds,
    required List<String> factoryNames,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Vertical name is required.');
    }
    if (factoryIds.isEmpty) {
      throw ArgumentError('Select at least one factory.');
    }
    if (factoryIds.length != factoryNames.length) {
      throw ArgumentError('Factory IDs and names are inconsistent.');
    }
  }

  static String _normalizeName(String value) => value.trim().toLowerCase();

  static String _documentIdForName(String normalizedName) {
    return base64Url
        .encode(utf8.encode(normalizedName))
        .replaceAll('=', '');
  }
}
