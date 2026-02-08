import 'package:flutter/material.dart';

import '../../constants/parcel_form_constants.dart';
import '../../controllers/parcel_controller.dart';
import '../../utils/validation_utils.dart';
import '../form_builders.dart';
import '../parcel_text_field.dart';

/// Step 2: Receiver Information
/// Handles receiver name, phone, and ID
class ReceiverInfoStep extends StatelessWidget {
  final ParcelController controller;
  final bool isViewOnly;
  final FocusNode receiverNameFocusNode;
  final FocusNode receiverPhoneFocusNode;
  final FocusNode receiverIdFocusNode;
  final FocusNode? vehicleFocusNode;
  final int currentStep;
  final Function(int) onStepChanged;

  const ReceiverInfoStep({
    super.key,
    required this.controller,
    required this.isViewOnly,
    required this.receiverNameFocusNode,
    required this.receiverPhoneFocusNode,
    required this.receiverIdFocusNode,
    this.vehicleFocusNode,
    required this.currentStep,
    required this.onStepChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilders.buildSectionCard(
      context,
      icon: Icons.person_outline,
      title: 'Receiver',
      subtitle: 'Who is expecting the parcel?',
      children: [
        ParcelTextField(
          controller: controller.receiverNameController,
          label: 'Receiver Name',
          prefixIcon: Icons.person_outline,
          isRequired: true,
          readOnly: isViewOnly,
          focusNode: receiverNameFocusNode,
          nextFocus: receiverPhoneFocusNode,
          error: controller.receiverNameFieldError,
        ),
        const SizedBox(height: 16),
        FormBuilders.buildInlineFields(context, [
          ParcelTextField(
            controller: controller.receiverPhoneController,
            label: 'Receiver Phone',
            prefixIcon: Icons.phone_outlined,
            isRequired: true,
            readOnly: isViewOnly,
            focusNode: receiverPhoneFocusNode,
            nextFocus: receiverIdFocusNode,
            keyboardType: TextInputType.phone,
            customValidator: ValidationUtils.validateKenyanPhone,
            helperText: ParcelFormConstants.phoneHintText,
            onNextStep: () {
              // After receiver phone, advance to Delivery step
              if (currentStep == 2) onStepChanged(3);
            },
            error: controller.receiverPhoneFieldError,
          ),
          ParcelTextField(
            controller: controller.receiverIdController,
            label: 'Receiver ID / Passport',
            prefixIcon: Icons.perm_identity,
            readOnly: isViewOnly,
            focusNode: receiverIdFocusNode,
            nextFocus: vehicleFocusNode,
            helperText: ParcelFormConstants.idHintText,
          ),
        ]),
      ],
    );
  }
}
