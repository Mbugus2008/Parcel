import '../controllers/parcel_controller.dart';

/// Service to centralize parcel validation logic
class ParcelValidationService {
  ParcelValidationService._();

  /// Validates parcel information step
  static ParcelStepValidation validateParcelInfo(ParcelController controller) {
    if (controller.amountPaidController.text.trim().isEmpty) {
      return ParcelStepValidation(
        isValid: false,
        errorMessage: 'Amount Paid is required',
        fieldError: ParcelFieldError.amountPaid,
      );
    }

    final amount = double.tryParse(controller.amountPaidController.text.trim());
    if (amount == null || amount <= 0) {
      return ParcelStepValidation(
        isValid: false,
        errorMessage: 'Enter a valid amount',
        fieldError: ParcelFieldError.amountPaid,
      );
    }

    if (controller.fromController.text.trim().isEmpty) {
      return ParcelStepValidation(
        isValid: false,
        errorMessage: 'From location is required',
        fieldError: ParcelFieldError.from,
      );
    }

    if (controller.toController.text.trim().isEmpty) {
      return ParcelStepValidation(
        isValid: false,
        errorMessage: 'Destination is required',
        fieldError: ParcelFieldError.to,
      );
    }

    return ParcelStepValidation(isValid: true);
  }

  /// Validates sender information step
  static ParcelStepValidation validateSenderInfo(ParcelController controller) {
    if (controller.senderNameController.text.trim().isEmpty) {
      return ParcelStepValidation(
        isValid: false,
        errorMessage: 'Sender name is required',
        fieldError: ParcelFieldError.senderName,
      );
    }

    if (controller.senderPhoneController.text.trim().isEmpty) {
      return ParcelStepValidation(
        isValid: false,
        errorMessage: 'Sender phone is required',
        fieldError: ParcelFieldError.senderPhone,
      );
    }

    return ParcelStepValidation(isValid: true);
  }

  /// Validates receiver information step
  static ParcelStepValidation validateReceiverInfo(
      ParcelController controller) {
    if (controller.receiverNameController.text.trim().isEmpty) {
      return ParcelStepValidation(
        isValid: false,
        errorMessage: 'Receiver name is required',
        fieldError: ParcelFieldError.receiverName,
      );
    }

    if (controller.receiverPhoneController.text.trim().isEmpty) {
      return ParcelStepValidation(
        isValid: false,
        errorMessage: 'Receiver phone is required',
        fieldError: ParcelFieldError.receiverPhone,
      );
    }

    return ParcelStepValidation(isValid: true);
  }

  /// Validates items step
  static ParcelStepValidation validateItems(ParcelController controller) {
    final items = controller.parcel?.parcelDetails ?? [];
    if (items.isEmpty) {
      return ParcelStepValidation(
        isValid: false,
        errorMessage: 'At least one item is required',
        fieldError: ParcelFieldError.items,
      );
    }

    return ParcelStepValidation(isValid: true);
  }

  /// Validates all steps and returns list of validation results
  static List<ParcelStepValidation> validateAllSteps(
      ParcelController controller) {
    return [
      validateParcelInfo(controller),
      validateSenderInfo(controller),
      validateReceiverInfo(controller),
      validateItems(controller),
    ];
  }

  /// Updates controller error fields based on validation
  static void updateControllerErrors(
      ParcelController controller, ParcelStepValidation validation) {
    // Clear all errors first
    controller.amountPaidError.value = '';
    controller.fromError.value = '';
    controller.toError.value = '';
    controller.senderNameFieldError.value = '';
    controller.receiverNameFieldError.value = '';
    controller.receiverPhoneFieldError.value = '';

    // Set specific error if validation failed
    if (!validation.isValid && validation.fieldError != null) {
      switch (validation.fieldError!) {
        case ParcelFieldError.amountPaid:
          controller.amountPaidError.value = validation.errorMessage;
          controller.parcelinformationError.value = validation.errorMessage;
          break;
        case ParcelFieldError.from:
          controller.fromError.value = validation.errorMessage;
          controller.parcelinformationError.value = validation.errorMessage;
          break;
        case ParcelFieldError.to:
          controller.toError.value = validation.errorMessage;
          controller.parcelinformationError.value = validation.errorMessage;
          break;
        case ParcelFieldError.senderName:
          controller.senderNameFieldError.value = validation.errorMessage;
          controller.senderinformationError.value = validation.errorMessage;
          break;
        case ParcelFieldError.senderPhone:
          controller.senderinformationError.value = validation.errorMessage;
          break;
        case ParcelFieldError.receiverName:
          controller.receiverNameFieldError.value = validation.errorMessage;
          controller.receiverinformationError.value = validation.errorMessage;
          break;
        case ParcelFieldError.receiverPhone:
          controller.receiverPhoneFieldError.value = validation.errorMessage;
          controller.receiverinformationError.value = validation.errorMessage;
          break;
        case ParcelFieldError.items:
          controller.itemsError.value = validation.errorMessage;
          break;
      }
    }
  }
}

/// Represents validation result for a step
class ParcelStepValidation {
  final bool isValid;
  final String errorMessage;
  final ParcelFieldError? fieldError;

  ParcelStepValidation({
    required this.isValid,
    this.errorMessage = '',
    this.fieldError,
  });
}

/// Enum for parcel field errors
enum ParcelFieldError {
  amountPaid,
  from,
  to,
  senderName,
  senderPhone,
  receiverName,
  receiverPhone,
  items,
}
