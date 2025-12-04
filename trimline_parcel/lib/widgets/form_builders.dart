import 'package:flutter/material.dart';

/// Helper methods for building common form UI components
class FormBuilders {
  /// Builds a section card container with optional icon, title, and children
  static Widget buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    List<Widget> children = const [],
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (children.isNotEmpty) ...children,
        ],
      ),
    );
  }

  /// Builds inline fields that stack vertically on small screens and horizontally on large screens
  static Widget buildInlineFields(BuildContext context, List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          return Column(
            children: [
              for (var i = 0; i < fields.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == fields.length - 1 ? 0 : 16,
                  ),
                  child: fields[i],
                ),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < fields.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == fields.length - 1 ? 0 : 16,
                  ),
                  child: fields[i],
                ),
              ),
          ],
        );
      },
    );
  }

  // Private constructor to prevent instantiation
  FormBuilders._();
}
