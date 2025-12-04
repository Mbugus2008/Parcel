/// Constants used in the parcel form UI and validation
class ParcelFormConstants {
  // Timing constants
  static const int debounceMilliseconds = 300;
  static const int autoSaveIntervalSeconds = 5;

  // UI spacing and sizing
  static const double stepContentPadding = 16.0;
  static const double buttonSpacing = 50.0;
  static const double formFieldSpacing = 10.0;
  static const double sectionSpacing = 20.0;
  static const double borderRadius = 12.0;
  static const double buttonVerticalPadding = 12.0;
  static const double buttonHorizontalPadding = 12.0;
  static const double loadingIndicatorSize = 20.0;
  static const double loadingIndicatorStrokeWidth = 2.0;

  // Validation limits
  static const int maxItemNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const double maxAmountValue = 1000000.0;
  static const double minAmountValue = 0.0;
  static const int maxItemQuantity = 10000;

  // Phone number formats
  static const String phoneHintText = 'Format: +254712345678 or 0712345678';
  static const String idHintText = 'National ID or Passport number';
  static const String amountHintText = 'Enter amount (max: 1,000,000)';

  // Error messages
  static const String genericSaveError =
      'Failed to save parcel. Please try again.';
  static const String genericUpdateError =
      'Failed to update parcel. Please try again.';
  static const String validationErrorTitle = 'Validation';
  static const String unsavedChangesTitle = 'Unsaved Changes';
  static const String unsavedChangesMessage =
      'You have unsaved changes. Are you sure you want to leave?';

  // Success messages
  static const String parcelSavedSuccess = 'Parcel saved successfully.';
  static const String parcelUpdatedSuccess = 'Parcel updated successfully.';

  // Button labels
  static const String saveButtonLabel = 'Save Parcel';
  static const String updateButtonLabel = 'Update Parcel';
  static const String cancelButtonLabel = 'Cancel';
  static const String continueButtonLabel = 'Continue';
  static const String addItemButtonLabel = 'Add Item';

  // Step titles
  static const String parcelInfoStepTitle = 'Parcel Information';
  static const String senderInfoStepTitle = 'Sender Information';
  static const String receiverInfoStepTitle = 'Receiver Information';
  static const String itemsStepTitle = 'Items';

  // Colors (hex values)
  static const int primaryColorValue = 0xFF4FB5FF;
  static const int errorColorValue = 0xFFFF5252;
  static const int successColorValue = 0xFF4CAF50;

  // Draft storage keys
  static const String draftStorageKey = 'parcel_draft';
  static const String draftTimestampKey = 'parcel_draft_timestamp';

  // Accessibility
  static const String savingAccessibilityHint = 'Saving parcel, please wait';
  static const String formAccessibilityLabel =
      'Parcel entry form with multiple steps';

  // Private constructor to prevent instantiation
  ParcelFormConstants._();
}
