import 'package:flutter/material.dart';

import '../../constants/parcel_form_constants.dart';
import '../../controllers/parcel_controller.dart';
import '../../utils/validation_utils.dart';
import '../form_builders.dart';
import '../parcel_text_field.dart';

/// Step 1: Sender Information
/// Handles sender name, phone, and ID
class SenderInfoStep extends StatelessWidget {
  final ParcelController controller;
  final bool isViewOnly;
  final FocusNode senderNameFocusNode;
  final FocusNode senderPhoneFocusNode;
  final FocusNode senderIdFocusNode;
  final FocusNode? receiverNameFocusNode;
  final int currentStep;
  final BuildContext parentContext;

  const SenderInfoStep({
    super.key,
    required this.controller,
    required this.isViewOnly,
    required this.senderNameFocusNode,
    required this.senderPhoneFocusNode,
    required this.senderIdFocusNode,
    this.receiverNameFocusNode,
    required this.currentStep,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilders.buildSectionCard(
      context,
      icon: Icons.person_pin_circle_outlined,
      title: 'Sender',
      subtitle: 'Who is shipping this parcel?',
      children: [
        ParcelTextField(
          controller: controller.senderNameController,
          label: 'Sender Name',
          prefixIcon: Icons.person,
          isRequired: true,
          readOnly: isViewOnly,
          focusNode: senderNameFocusNode,
          nextFocus: senderPhoneFocusNode,
          error: controller.senderNameFieldError,
        ),
        const SizedBox(height: 16),
        FormBuilders.buildInlineFields(context, [
          ParcelTextField(
            controller: controller.senderPhoneController,
            label: 'Sender Phone',
            prefixIcon: Icons.phone,
            isRequired: true,
            readOnly: isViewOnly,
            focusNode: senderPhoneFocusNode,
            nextFocus: senderIdFocusNode,
            keyboardType: TextInputType.phone,
            customValidator: ValidationUtils.validateKenyanPhone,
            helperText: ParcelFormConstants.phoneHintText,
            onNextStep: () {
              // move to Sender ID
              if (currentStep == 1) {
                FocusScope.of(parentContext).requestFocus(senderIdFocusNode);
              }
            },
          ),
          ParcelTextField(
            controller: controller.senderIdController,
            label: 'Sender ID / Passport',
            prefixIcon: Icons.credit_card,
            helperText: ParcelFormConstants.idHintText,
            readOnly: isViewOnly,
            focusNode: senderIdFocusNode,
            nextFocus: receiverNameFocusNode,
          ),
        ]),
      ],
    );
  }
}
