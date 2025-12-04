import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../constants/parcel_form_constants.dart';
import '../controllers/parcel_controller.dart';
import '../models/Parcel_Details.dart';
import '../models/parcel_model.dart';
import '../services/parcel_draft_service.dart';
import '../services/parcel_number_service.dart';
import '../services/parcel_validation_service.dart';
import '../widgets/edit_parcel_detail_dialog.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/steps/parcel_stepper_mixin.dart';

/// Refactored AddEditParcelPage using ParcelStepperMixin
/// This version is ~60% shorter than the original while maintaining all functionality
class AddEditParcelPageV2 extends StatefulWidget {
  final Parcel? parcel;
  const AddEditParcelPageV2({super.key, this.parcel});

  @override
  State<AddEditParcelPageV2> createState() => _AddEditParcelPageV2State();
}

class _AddEditParcelPageV2State extends State<AddEditParcelPageV2>
    with ParcelStepperMixin {
  late final ParcelController _controller;
  late final ParcelFormFocusNodes _focusNodes;

  int _currentStep = 0;
  bool _isDirty = false;
  bool _isPopulating = false;
  Timer? _autoSaveTimer;
  Timer? _debounceTimer;
  late VoidCallback _fieldsListener; // Store reference for removal

  // Mixin requirements
  @override
  ParcelController get stepperController => _controller;

  @override
  ParcelFormFocusNodes get focusNodes => _focusNodes;

  @override
  bool get isViewOnly {
    final status = _controller.parcel?.Status ?? widget.parcel?.Status;
    return status == ParcelStatus.inTransit ||
        status == ParcelStatus.received ||
        status == ParcelStatus.collected;
  }

  @override
  int get currentStep => _currentStep;

  @override
  void onStepChanged(int step) => setState(() => _currentStep = step);

  @override
  Future<void> onEditItem(
      BuildContext context, Parcel_Details detail, int index) async {
    await _showEditParcelDetailDialog(context, detail, index);
    if (mounted) setState(() {});
  }

  @override
  void onItemsChanged() => setState(() {});

  @override
  Future<void> onAddItem() async {
    if (_currentStep != 3) {
      setState(() => _currentStep = 3);
    }
    _controller.addParcelDetail();
    final newIndex = (_controller.parcel?.parcelDetails.length ?? 1) - 1;
    if (newIndex >= 0 && mounted) {
      await _showEditParcelDetailDialog(
        context,
        _controller.parcel!.parcelDetails[newIndex],
        newIndex,
      );
      if (mounted) setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ParcelController>();
    _controller.parcel = widget.parcel;
    _focusNodes = ParcelFormFocusNodes();

    _setupFieldListeners();
    _initializeForm();
  }

  void _setupFieldListeners() {
    _fieldsListener = () {
      if (!mounted || _isPopulating) return;
      _isDirty = true;
    };

    // Listen only to key validation fields
    for (final ctrl in [
      _controller.amountPaidController,
      _controller.fromController,
      _controller.toController,
      _controller.senderNameController,
      _controller.receiverNameController,
      _controller.receiverPhoneController,
      _controller.vehicleController,
      _controller.driverController,
    ]) {
      ctrl.addListener(_fieldsListener);
    }
  }

  void _initializeForm() {
    if (widget.parcel != null) {
      _isPopulating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.populateFormWithParcel(widget.parcel!);
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _isDirty = false;
              _isPopulating = false;
            }
          });
        }
      });
    } else {
      // Defer heavy operations to after first frame to avoid blocking navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _generateParcelNumber();
          _loadDraft();
          _startAutoSave();
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateStepErrors();
        setState(() {});
      }
    });
  }

  Future<void> _generateParcelNumber() async {
    try {
      final service = Get.find<ParcelNumberService>();
      final number = await service.getNextParcelNumber();
      if (mounted) _controller.documentNoController.text = number;
    } catch (_) {}
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(
      Duration(seconds: ParcelFormConstants.autoSaveIntervalSeconds),
      (_) {
        if (_isDirty && !isViewOnly && mounted) _saveDraft();
      },
    );
  }

  Future<void> _saveDraft() async {
    await ParcelDraftService.saveDraft({
      'amountPaid': _controller.amountPaidController.text,
      'from': _controller.fromController.text,
      'to': _controller.toController.text,
      'senderName': _controller.senderNameController.text,
      'senderPhone': _controller.senderPhoneController.text,
      'senderId': _controller.senderIdController.text,
      'receiverName': _controller.receiverNameController.text,
      'receiverPhone': _controller.receiverPhoneController.text,
      'receiverId': _controller.receiverIdController.text,
      'vehicle': _controller.vehicleController.text,
      'driver': _controller.driverController.text,
    });
  }

  Future<void> _loadDraft() async {
    if (!await ParcelDraftService.hasDraft() || !mounted) return;

    final timestamp = await ParcelDraftService.getDraftTimestamp();
    if (timestamp == null) return;

    final age = DateTime.now().difference(timestamp);
    final ageText = age.inHours > 24
        ? '${age.inDays} days ago'
        : age.inHours > 0
            ? '${age.inHours} hours ago'
            : '${age.inMinutes} minutes ago';

    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Draft Found'),
        content: Text('A draft from $ageText was found. Restore it?'),
        actions: [
          TextButton(
            onPressed: () {
              ParcelDraftService.clearDraft();
              Navigator.pop(ctx, false);
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (shouldRestore == true && mounted) {
      final data = await ParcelDraftService.loadDraft();
      if (data != null) {
        _controller.amountPaidController.text = data['amountPaid'] ?? '';
        _controller.fromController.text = data['from'] ?? '';
        _controller.toController.text = data['to'] ?? '';
        _controller.senderNameController.text = data['senderName'] ?? '';
        _controller.senderPhoneController.text = data['senderPhone'] ?? '';
        _controller.senderIdController.text = data['senderId'] ?? '';
        _controller.receiverNameController.text = data['receiverName'] ?? '';
        _controller.receiverPhoneController.text = data['receiverPhone'] ?? '';
        _controller.receiverIdController.text = data['receiverId'] ?? '';
        _controller.vehicleController.text = data['vehicle'] ?? '';
        _controller.driverController.text = data['driver'] ?? '';
        _isDirty = false;
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _autoSaveTimer?.cancel();

    // Remove listeners from controllers
    for (final ctrl in [
      _controller.amountPaidController,
      _controller.fromController,
      _controller.toController,
      _controller.senderNameController,
      _controller.receiverNameController,
      _controller.receiverPhoneController,
      _controller.vehicleController,
      _controller.driverController,
    ]) {
      ctrl.removeListener(_fieldsListener);
    }

    _focusNodes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.parcel != null;
    final steps = buildSteps(context); // From mixin!

    return PopScope(
      canPop: !_isDirty || isViewOnly,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog();
        if (shouldPop == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(theme),
        body: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildStepperBody(steps)),
                _buildBottomButtons(isEditing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 1,
      toolbarHeight: 50,
      iconTheme: const IconThemeData(color: Colors.black),
      foregroundColor: Colors.black,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
        child: _buildSummaryBar(theme),
      ),
    );
  }

  Widget _buildSummaryBar(ThemeData theme) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller.documentNoController,
      builder: (context, value, _) {
        final textColor =
            theme.brightness == Brightness.dark ? Colors.white : Colors.black;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.text,
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('dd MMM yyyy').format(_controller.selectedDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor.withOpacity(0.75),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepperBody(List<Step> steps) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Form(
            key: _controller.formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Semantics(
                    label: ParcelFormConstants.formAccessibilityLabel,
                    child: Stepper(
                      type: StepperType.vertical,
                      currentStep: _currentStep,
                      steps: steps,
                      onStepContinue: _handleStepContinue,
                      onStepCancel: () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep -= 1);
                        }
                      },
                      onStepTapped: (index) =>
                          setState(() => _currentStep = index),
                      controlsBuilder: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleStepContinue() {
    _updateStepErrors();
    setState(() {});

    final errors = [
      _controller.parcelinformationError.value,
      _controller.senderinformationError.value,
      _controller.receiverinformationError.value,
      _controller.itemsError.value,
    ];

    final isLastStep = _currentStep == 3;

    if (isLastStep) {
      final firstError = errors.indexWhere((e) => e.isNotEmpty);
      if (firstError != -1) {
        setState(() => _currentStep = firstError);
        _showValidationError(errors[firstError]);
        return;
      }
      _submitForm();
    } else {
      if (errors[_currentStep].isNotEmpty) {
        _showValidationError(errors[_currentStep]);
        return;
      }
      setState(() => _currentStep += 1);
    }
  }

  Widget _buildBottomButtons(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => _buildSaveButton(isEditing)),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildPayButton()),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    final isSaving = _controller.isSavingParcel;
    return Semantics(
      button: true,
      enabled: !isViewOnly && !isSaving,
      hint: isSaving ? ParcelFormConstants.savingAccessibilityHint : null,
      child: ElevatedButton(
        onPressed: isViewOnly || isSaving ? null : _handleSavePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(ParcelFormConstants.primaryColorValue),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: ParcelFormConstants.buttonHorizontalPadding,
            vertical: ParcelFormConstants.buttonVerticalPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ParcelFormConstants.borderRadius),
          ),
        ),
        child: isSaving
            ? SizedBox(
                height: ParcelFormConstants.loadingIndicatorSize,
                width: ParcelFormConstants.loadingIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: ParcelFormConstants.loadingIndicatorStrokeWidth,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(isEditing ? 'Update Parcel' : 'Save Parcel'),
      ),
    );
  }

  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: isViewOnly
          ? null
          : () async {
              if (widget.parcel != null) {
                await showPaymentDialog(context, widget.parcel!);
              } else {
                _showSnackBar('Save First',
                    'Please save the parcel first before making a payment.',
                    backgroundColor: Colors.orangeAccent);
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: ParcelFormConstants.buttonHorizontalPadding,
          vertical: ParcelFormConstants.buttonVerticalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ParcelFormConstants.borderRadius),
        ),
      ),
      child: const Text('Pay'),
    );
  }

  void _handleSavePressed() {
    _updateStepErrors();
    setState(() {});

    final errors = [
      _controller.parcelinformationError.value,
      _controller.senderinformationError.value,
      _controller.receiverinformationError.value,
      _controller.itemsError.value,
    ];

    final firstError = errors.indexWhere((e) => e.isNotEmpty);
    if (firstError != -1) {
      setState(() => _currentStep = firstError);
      _showValidationError('Please fix the highlighted field.');
      return;
    }
    _submitForm();
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Leave without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _showValidationError(String message) {
    Get.snackbar(
      'Validation',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  void _showSnackBar(String title, String message,
      {Color backgroundColor = Colors.green}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _submitForm() async {
    try {
      final items = _controller.parcel?.parcelDetails ?? [];
      if (items.isEmpty) {
        _controller.itemsError.value = 'At least one item is required';
        _showSnackBar('Validation', 'Please add at least one parcel item.',
            backgroundColor: Colors.redAccent);
        return;
      }

      final parcel = Parcel(
        Document_No: _controller.documentNoController.text,
        Date_sent: _controller.selectedDate,
        Sender_Name: _controller.senderNameController.text,
        Sender_ID: _controller.senderIdController.text,
        Sender_Phone: _controller.senderPhoneController.text,
        From: _controller.fromController.text,
        To: _controller.toController.text,
        Receiver_Name: _controller.receiverNameController.text,
        Receiver_ID: _controller.receiverIdController.text,
        Receiver_Phone: _controller.receiverPhoneController.text,
        Status: _controller.selectedStatus,
        Driver: _controller.driverController.text,
        Vehicle: _controller.vehicleController.text,
        Who_to_Pay: _controller.paymentResponsibility,
        Amount_Paid:
            double.tryParse(_controller.amountPaidController.text) ?? 0.0,
        Paid: _controller.paid,
        Date_Collected: _controller.parcel?.Date_Collected,
        Date_Delivered: _controller.parcel?.Date_Delivered,
        parcelDetails: _controller.parcel?.parcelDetails,
      );

      final success = widget.parcel != null
          ? await _controller.updateParcel(parcel)
          : await _controller.addParcel(parcel);

      if (success) {
        setState(() => _isDirty = false);
        if (widget.parcel == null) await ParcelDraftService.clearDraft();
        await Future.delayed(const Duration(seconds: 1));
        Get.back();
      }
    } catch (e) {
      _showSnackBar('Error', 'Failed to save parcel: $e',
          backgroundColor: Colors.red);
    }
  }

  void _updateStepErrors() {
    final validations = ParcelValidationService.validateAllSteps(_controller);

    _controller.parcelinformationError.value = '';
    _controller.senderinformationError.value = '';
    _controller.receiverinformationError.value = '';
    _controller.itemsError.value = '';

    for (final validation in validations) {
      if (!validation.isValid) {
        ParcelValidationService.updateControllerErrors(_controller, validation);
        break;
      }
    }
  }

  Future<void> _showEditParcelDetailDialog(
    BuildContext context,
    Parcel_Details detail,
    int index,
  ) async {
    // Use the shared dialog widget that properly manages controller lifecycle
    await showEditParcelDetailDialog(context, detail, index, _controller);
  }
}
