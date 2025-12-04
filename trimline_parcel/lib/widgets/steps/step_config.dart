import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Configuration for a single step in the parcel form stepper
class StepConfig {
  /// Step title displayed in the stepper header
  final String title;

  /// Default subtitle when no error or dynamic value
  final String defaultSubtitle;

  /// Function to get dynamic subtitle (e.g., sender name, item count)
  final String Function()? dynamicSubtitle;

  /// Reactive error observable for this step
  final RxString error;

  /// The widget content for this step
  final Widget content;

  /// Optional trailing widget (e.g., add button for items step)
  final Widget? trailing;

  /// Icon for the step (used in section card)
  final IconData icon;

  const StepConfig({
    required this.title,
    required this.defaultSubtitle,
    this.dynamicSubtitle,
    required this.error,
    required this.content,
    this.trailing,
    required this.icon,
  });

  /// Get the current subtitle (dynamic value or default)
  String get subtitle {
    if (dynamicSubtitle != null) {
      final dynamic = dynamicSubtitle!();
      if (dynamic.isNotEmpty) return dynamic;
    }
    return defaultSubtitle;
  }

  /// Check if step has an error
  bool get hasError => error.value.isNotEmpty;

  /// Get display text (error if present, otherwise subtitle)
  String get displayText => hasError ? error.value : subtitle;
}

/// Extension to build Flutter Steps from StepConfig list
extension StepConfigListExtension on List<StepConfig> {
  /// Convert configurations to Flutter Step widgets
  List<Step> toSteps({
    required int currentStep,
    VoidCallback? onAddItem,
  }) {
    return asMap().entries.map((entry) {
      final index = entry.key;
      final config = entry.value;

      // Build subtitle widget with reactive error handling
      Widget subtitleWidget;
      if (config.trailing != null) {
        // Items step with add button
        subtitleWidget = Row(
          children: [
            Expanded(
              child: Obx(() => Text(
                    config.displayText,
                    style: TextStyle(
                      color:
                          config.hasError ? Colors.redAccent : Colors.black54,
                      fontSize: 14,
                    ),
                  )),
            ),
            config.trailing!,
          ],
        );
      } else {
        subtitleWidget = Obx(() => Text(
              config.displayText,
              style: TextStyle(
                color: config.hasError ? Colors.redAccent : Colors.black54,
                fontSize: 14,
              ),
            ));
      }

      return Step(
        title: Text(
          config.title,
          style: const TextStyle(color: Colors.black, fontSize: 20),
        ),
        subtitle: subtitleWidget,
        state: _stepStateFor(index, currentStep),
        isActive: currentStep >= index,
        content: config.content,
      );
    }).toList();
  }

  static StepState _stepStateFor(int index, int currentStep) {
    if (currentStep > index) return StepState.complete;
    if (currentStep == index) return StepState.editing;
    return StepState.indexed;
  }
}
