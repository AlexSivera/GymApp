import 'package:flutter/material.dart';

// Shared rounded, padded card used across dashboard-style sections.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}
