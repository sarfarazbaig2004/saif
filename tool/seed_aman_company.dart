// ignore_for_file: avoid_print

import 'dart:io';
import 'package:args/args.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:QUIK/config/firebase_options.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('uid', abbr: 'u', help: 'Firebase UID of the admin user')
    ..addOption('email', abbr: 'e', help: 'Email of the admin user');

  final argResults = parser.parse(arguments);

  final uid = argResults['uid'] as String?;
  final email = argResults['email'] as String?;

  if (uid == null || uid.isEmpty) {
    print('Error: --uid is required');
    print(parser.usage);
    exit(1);
  }

  if (email == null || email.isEmpty) {
    print('Error: --email is required');
    print(parser.usage);
    exit(1);
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  const companyId = 'aman-infra';
  const companyName = 'Aman Infra';

  try {
    // Create/update company document
    await firestore.collection('companies').doc(companyId).set({
      'companyId': companyId,
      'companyName': companyName,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ Company document created/updated: companies/$companyId');

    // Create/update admin user profile
    await firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .doc(uid)
        .set({
      'uid': uid,
      'email': email,
      'role': 'admin',
      'companyId': companyId,
      'companyName': companyName,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ Admin user profile created/updated: companies/$companyId/users/$uid');

    print('\n🎉 Aman ERP seed completed successfully!');
    print('Admin user can now log in and access the company data.');

  } catch (e) {
    print('❌ Error during seeding: $e');
    exit(1);
  }
}