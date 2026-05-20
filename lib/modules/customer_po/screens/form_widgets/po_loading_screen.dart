import 'package:flutter/material.dart';

class PoLoadingScreen extends StatelessWidget {
  const PoLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Customer PO')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
