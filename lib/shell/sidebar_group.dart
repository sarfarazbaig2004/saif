import 'package:flutter/material.dart';

class SidebarGroup {
  final String key;
  final String title;
  final IconData icon;
  final List<dynamic> children;

  const SidebarGroup({
    required this.key,
    required this.title,
    required this.icon,
    required this.children,
  });
}
