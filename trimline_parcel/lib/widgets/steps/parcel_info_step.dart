import 'package:flutter/material.dart';

import '../../constants/parcel_form_constants.dart';
import '../../controllers/parcel_controller.dart';
import '../form_builders.dart';
import '../parcel_text_field.dart';

/// Step 0: Parcel Information
/// Handles amount paid, from/to locations
class ParcelInfoStep extends StatelessWidget {
  final ParcelController controller;
  final bool isViewOnly;
  final FocusNode amountPaidFocusNode;
  final FocusNode fromFocusNode;
  final FocusNode toFocusNode;
  final FocusNode? senderNameFocusNode;
  final int currentStep;
  final Function(int) onStepChanged;

  const ParcelInfoStep({
    super.key,
    required this.controller,
    required this.isViewOnly,
    required this.amountPaidFocusNode,
    required this.fromFocusNode,
    required this.toFocusNode,
    this.senderNameFocusNode,
    required this.currentStep,
    required this.onStepChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilders.buildSectionCard(
      context,
      icon: Icons.inventory_2_outlined,
      title: 'Parcel Details',
      subtitle: 'Payment and route information',
      children: [
        ParcelTextField(
          controller: controller.amountPaidController,
          label: 'Amount Paid',
          isRequired: true,
          keyboardType: TextInputType.number,
          readOnly: isViewOnly,
          focusNode: amountPaidFocusNode,
          nextFocus: fromFocusNode,
          decoration: const InputDecoration(prefixText: 'Ksh '),
          helperText: ParcelFormConstants.amountHintText,
          error: controller.amountPaidError,
        ),
        const SizedBox(height: 16),
        FormBuilders.buildInlineFields(context, [
          ParcelTextField(
            controller: controller.fromController,
            label: 'From (Location)',
            prefixIcon: Icons.location_on,
            isRequired: true,
            readOnly: isViewOnly,
            focusNode: fromFocusNode,
            nextFocus: toFocusNode,
            error: controller.fromError,
          ),
          ParcelTextField(
            controller: controller.toController,
            label: 'To (Destination)',
            prefixIcon: Icons.location_on,
            isRequired: true,
            readOnly: isViewOnly,
            focusNode: toFocusNode,
            nextFocus: senderNameFocusNode,
            onNextStep: () {
              // After destination, advance to Sender step
              if (currentStep == 0) onStepChanged(1);
            },
            error: controller.toError,
          ),
        ]),
      ],
    );
  }
}
