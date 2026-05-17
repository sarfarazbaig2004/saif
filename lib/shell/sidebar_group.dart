import 'package:flutter/material.dart';

class SidebarGroup<T> {
  final String key;
  final String title;
  final IconData icon;
  final List<T> children;

  const SidebarGroup({
    required this.key,
    required this.title,
    required this.icon,
    required this.children,
  });
}
