import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/parcel_controller.dart';
import '../models/Parcel_Details.dart';
import '../models/parcel_model.dart';
import '../widgets/payment_dialog.dart';

class AddEditParcelPage extends StatefulWidget {
  final Parcel? parcel;
  const AddEditParcelPage({super.key, this.parcel});

  @override
  State<AddEditParcelPage> createState() => _AddEditParcelPageState();
}

class _AddEditParcelPageState extends State<AddEditParcelPage> {
  late final ParcelController controller;
  int _currentStep = 0;

  // When a parcel is already dispatched/received/collected we should show the
  // form in view-only mode (no edits allowed).
  bool get _isViewOnly {
    final status = controller.parcel?.Status ?? widget.parcel?.Status;
    return status == ParcelStatus.inTransit ||
        status == ParcelStatus.received ||
        status == ParcelStatus.collected;
  }

  late final VoidCallback _fieldsListener;

  Timer? _debounceTimer; // debounce rapid listener updates
  // Focus nodes to control explicit next-focus order across the form
  late final FocusNode amountPaidFocusNode;
  late final FocusNode fromFocusNode;
  late final FocusNode toFocusNode;
  late final FocusNode senderNameFocusNode;
  late final FocusNode senderPhoneFocusNode;
  late final FocusNode senderIdFocusNode;
  late final FocusNode receiverNameFocusNode;
  late final FocusNode receiverPhoneFocusNode;
  late final FocusNode receiverIdFocusNode;
  late final FocusNode vehicleFocusNode;
  late final FocusNode driverFocusNode;

  @override
  void initState() {
    super.initState();

    // Use the app-level controller instance (created in main)
    controller = Get.find<ParcelController>();
    controller.parcel = widget.parcel;

    // Defer heavy population work to after the first frame to avoid blocking navigation
    if (widget.parcel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          controller.PopulateFormWithParcel(widget.parcel!);
        }
      });
    }

    // Live-update step errors when relevant fields change
    // Reduced listeners to only essential fields to prevent excessive rebuilds
    _fieldsListener = () {
      if (mounted) {
        _updateStepErrors();
        // Debounce rapid state updates (typing) to avoid excessive rebuild work on main thread
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          // Increased debounce time
          if (mounted) setState(() {});
        });
      }
    };

    // Only listen to key validation fields, not all fields
    controller.amountPaidController.addListener(_fieldsListener);
    controller.fromController.addListener(_fieldsListener);
    controller.toController.addListener(_fieldsListener);
    controller.senderNameController.addListener(_fieldsListener);
    controller.receiverNameController.addListener(_fieldsListener);
    controller.receiverPhoneController.addListener(_fieldsListener);
    controller.vehicleController.addListener(_fieldsListener);
    controller.driverController.addListener(_fieldsListener);

    // initialize focus nodes
    amountPaidFocusNode = FocusNode();
    fromFocusNode = FocusNode();
    toFocusNode = FocusNode();
    senderNameFocusNode = FocusNode();
    senderPhoneFocusNode = FocusNode();
    senderIdFocusNode = FocusNode();
    receiverNameFocusNode = FocusNode();
    receiverPhoneFocusNode = FocusNode();
    receiverIdFocusNode = FocusNode();
    vehicleFocusNode = FocusNode();
    driverFocusNode = FocusNode();

    // initialize error states after first frame to avoid blocking navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateStepErrors();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Cancel timer
    _debounceTimer?.cancel();

    // Remove listeners
    try {
      controller.amountPaidController.removeListener(_fieldsListener);
      controller.fromController.removeListener(_fieldsListener);
      controller.toController.removeListener(_fieldsListener);
      controller.senderNameController.removeListener(_fieldsListener);
      controller.receiverNameController.removeListener(_fieldsListener);
      controller.receiverPhoneController.removeListener(_fieldsListener);
      controller.vehicleController.removeListener(_fieldsListener);
      controller.driverController.removeListener(_fieldsListener);
      // Note: documentNoController and senderPhoneController were not
      // subscribed to _fieldsListener in initState; avoid removing them.
    } catch (_) {}

    // dispose focus nodes
    try {
      amountPaidFocusNode.dispose();
      fromFocusNode.dispose();
      toFocusNode.dispose();
      senderNameFocusNode.dispose();
      senderPhoneFocusNode.dispose();
      senderIdFocusNode.dispose();
      receiverNameFocusNode.dispose();
      receiverPhoneFocusNode.dispose();
      receiverIdFocusNode.dispose();
      vehicleFocusNode.dispose();
      driverFocusNode.dispose();
    } catch (_) {}

    // Do not delete the shared controller here; it's app-scoped.

    super.dispose();
  }

  void _showSnackBar(
    String title,
    String message, {
    Color backgroundColor = Colors.green,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.parcel != null;
    final steps = _buildSteps(context);
    return Scaffold(
      // Prevent the scaffold from resizing when the keyboard appears. This
      // disables the default keyboard-driven animation/resize behavior so the
      // page layout remains stable while the onscreen keyboard is shown.
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
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
        actions: [],
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      height: constraints.maxHeight,
                      child: Form(
                        key: controller.formKey,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                // 💙 blueish border
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.6),
                                  width: 1.5,
                                ),
                                // soft shadow for "floating" effect
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.15),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stepper(
                                type: StepperType.vertical,
                                currentStep: _currentStep,
                                steps: steps,
                                onStepContinue: () {
                                  final isLastStep =
                                      _currentStep == steps.length - 1;
                                  if (isLastStep) {
                                    // Validate all steps using the step error aggregator
                                    _updateStepErrors();
                                    setState(() {});
                                    final errors = [
                                      controller.parcelinformationError.value,
                                      controller.senderinformationError.value,
                                      controller.receiverinformationError.value,
                                      controller.deliveryinformationError.value,
                                    ];
                                    final firstError = errors.indexWhere(
                                      (e) => e.isNotEmpty,
                                    );
                                    if (firstError != -1) {
                                      setState(() => _currentStep = firstError);
                                      Get.snackbar(
                                        'Validation',
                                        errors[firstError],
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor:
                                            Colors.redAccent.withOpacity(0.9),
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    _submitForm();
                                  } else {
                                    // Update step errors and prevent advancing if the current step has an error
                                    _updateStepErrors();
                                    setState(() {});
                                    final stepErrors = [
                                      controller.parcelinformationError.value,
                                      controller.senderinformationError.value,
                                      controller.receiverinformationError.value,
                                      controller.deliveryinformationError.value,
                                      '',
                                    ];
                                    if (stepErrors[_currentStep].isNotEmpty) {
                                      Get.snackbar(
                                        'Validation',
                                        stepErrors[_currentStep],
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor:
                                            Colors.redAccent.withOpacity(0.9),
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }
                                    setState(() => _currentStep += 1);
                                  }
                                },
                                onStepCancel: () {
                                  if (_currentStep > 0)
                                    setState(() => _currentStep -= 1);
                                },
                                onStepTapped: (index) =>
                                    setState(() => _currentStep = index),
                                controlsBuilder: (context, details) {
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                // Keep footer visible above the keyboard by adding viewInsets.bottom
                // We limit this to the footer only to avoid large-scale layout animations
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isViewOnly
                            ? null
                            : () {
                                // Update step errors so subtitles reflect validation state
                                _updateStepErrors();
                                setState(() {});

                                // Check aggregated step errors instead of running full form validation
                                final errors = [
                                  controller.parcelinformationError.value,
                                  controller.senderinformationError.value,
                                  controller.receiverinformationError.value,
                                  controller.deliveryinformationError.value,
                                ];
                                final firstErrorIndex = errors.indexWhere(
                                  (e) => e.isNotEmpty,
                                );
                                if (firstErrorIndex != -1) {
                                  setState(
                                      () => _currentStep = firstErrorIndex);
                                  Get.snackbar(
                                    'Validation',
                                    'Please fix the highlighted field.',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor:
                                        Colors.redAccent.withOpacity(0.9),
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                // No step errors — proceed to submit
                                _submitForm();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FB5FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            Text(isEditing ? 'Update Parcel' : 'Save Parcel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isViewOnly
                            ? null
                            : () async {
                                if (widget.parcel != null) {
                                  // Open the reusable payment dialog
                                  await showPaymentDialog(
                                      context, widget.parcel!);
                                } else {
                                  Get.snackbar(
                                    'Save First',
                                    'Please save the parcel first before making a payment.',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor:
                                        Colors.orangeAccent.withOpacity(0.9),
                                    colorText: Colors.white,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Pay'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Step> _buildSteps(BuildContext context) {
    // Steps: Parcel, Sender, Receiver, Items (Logistics removed)
    final contents = [
      _buildTabContent(context, [_buildParcelSection(context)]),
      _buildTabContent(context, [_buildSenderSection(context)]),
      _buildTabContent(context, [_buildReceiverSection(context)]),
      _buildTabContent(context, [_buildDetailsSection(context)]),
    ];

    // Dynamic subtitles sourced from the form/controller state
    final docNo = controller.documentNoController.text.trim();
    final parcelSubtitle = docNo.isNotEmpty ? docNo : 'Parcel Details';

    final senderName = controller.senderNameController.text.trim();
    final senderSubtitle =
        senderName.isNotEmpty ? senderName : 'Who is sending';

    final receiverName = controller.receiverNameController.text.trim();
    final receiverSubtitle =
        receiverName.isNotEmpty ? receiverName : 'Receiver';

    final details = controller.parcel?.parcelDetails ?? <Parcel_Details>[];
    final total = details.fold<double>(
      0,
      (sum, item) => sum + (item.Amount ?? 0.0),
    );
    final itemsSubtitle = details.isEmpty
        ? 'No items'
        : '${details.length} items • KES ${total.toStringAsFixed(2)}';

    final titles = ['Parcel', 'Sender', 'Receiver', 'Items'];
    final subTitles = [
      parcelSubtitle,
      senderSubtitle,
      receiverSubtitle,
      itemsSubtitle,
    ];

    // Use a non-nullable list of RxString so every subtitle Obx observes a real reactive
    // Map step index -> step-level error (items step uses itemsError)
    final List<RxString> stepErrors = [
      controller.parcelinformationError,
      controller.senderinformationError,
      controller.receiverinformationError,
      controller.itemsError,
    ];

    return List.generate(titles.length, (index) {
      Widget subtitleWidget;

      // Always use Obx but show subtitle or error based on the RxString value
      final subtitleObs = stepErrors[index];

      // Items step is index 3 (Parcel, Sender, Receiver, Items)
      if (index == 3) {
        subtitleWidget = Row(
          children: [
            Expanded(
              child: Obx(() {
                final value = subtitleObs.value;
                final hasError = value.isNotEmpty;
                return Text(
                  hasError ? value : subTitles[index],
                  style: TextStyle(
                    color: hasError ? Colors.redAccent : Colors.black54,
                    fontSize: 14,
                  ),
                );
              }),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
              tooltip: 'Add item',
              onPressed: () {
                controller.addParcelDetail();
                setState(() {});
              },
            ),
          ],
        );
      } else {
        subtitleWidget = Obx(() {
          final value = subtitleObs.value;
          final hasError = value.isNotEmpty;
          return Text(
            hasError ? value : subTitles[index],
            style: TextStyle(
              color: hasError ? Colors.redAccent : Colors.black54,
              fontSize: 14,
            ),
          );
        });
      }
      return Step(
        title: Text(
          titles[index],
          style: const TextStyle(color: Colors.black, fontSize: 20),
        ),
        subtitle: subtitleWidget,
        state: _stepStateFor(index),
        isActive: _currentStep >= index,
        content: contents[index],
      );
    });
  }

  StepState _stepStateFor(int index) {
    if (_currentStep > index) {
      return StepState.complete;
    }
    if (_currentStep == index) {
      return StepState.editing;
    }
    return StepState.indexed;
  }

  // Provide a background summary bar that updates when the document number changes
  Widget _buildSummaryBar(ThemeData theme) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.documentNoController,
      builder: (context, value, _) {
        final docNo = value.text;

        // Choose a readable text color based on overall theme brightness.
        final textColor =
            theme.brightness == Brightness.dark ? Colors.white : Colors.black;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      docNo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy').format(controller.selectedDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabContent(BuildContext context, List<Widget> children) {
    return Padding(
      // Fixed padding — avoid reacting to viewInsets to prevent keyboard show animation
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          // 💙 blueish border
          border: Border.all(
            color: Colors.blueAccent.withOpacity(0.6),
            width: 1.5,
          ),
          // soft shadow for "floating" effect
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSectionCard(
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

  Widget _buildParcelSection(BuildContext context) {
    return _buildSectionCard(
      context,
      icon: Icons.inventory_2_outlined,
      title: 'Parcel Details',
      subtitle: 'Payment and route information',
      children: [
        _buildTextField(
          controller: controller.amountPaidController,
          label: 'Amount Paid',
          isRequired: true,
          keyboardType: TextInputType.number,
          readOnly: _isViewOnly,
          focusNode: amountPaidFocusNode,
          nextFocus: fromFocusNode,
          decoration: const InputDecoration(prefixText: 'Ksh '),
          error: controller.amountPaidError,
        ),
        const SizedBox(height: 16),
        _buildInlineFields(context, [
          _buildTextField(
            controller: controller.fromController,
            label: 'From (Location)',
            prefixIcon: Icons.location_on,
            isRequired: true,
            readOnly: _isViewOnly,
            focusNode: fromFocusNode,
            nextFocus: toFocusNode,
            error: controller.fromError,
          ),
          _buildTextField(
            controller: controller.toController,
            label: 'To (Destination)',
            prefixIcon: Icons.location_on,
            isRequired: true,
            readOnly: _isViewOnly,
            focusNode: toFocusNode,
            nextFocus: senderNameFocusNode,
            onNextStep: () {
              // After destination, advance to Sender step
              if (_currentStep == 0) setState(() => _currentStep = 1);
            },
            error: controller.toError,
          ),
        ]),
      ],
    );
  }

  Widget _buildSenderSection(BuildContext context) {
    return _buildSectionCard(
      context,
      icon: Icons.person_pin_circle_outlined,
      title: 'Sender',
      subtitle: 'Who is shipping this parcel?',
      children: [
        _buildTextField(
          controller: controller.senderNameController,
          label: 'Sender Name',
          prefixIcon: Icons.person,
          isRequired: true,
          readOnly: _isViewOnly,
          focusNode: senderNameFocusNode,
          nextFocus: senderPhoneFocusNode,
          error: controller.senderNameFieldError,
        ),
        const SizedBox(height: 16),
        _buildInlineFields(context, [
          _buildTextField(
            controller: controller.senderPhoneController,
            label: 'Sender Phone',
            prefixIcon: Icons.phone,
            isRequired: true,
            readOnly: _isViewOnly,
            focusNode: senderPhoneFocusNode,
            nextFocus: senderIdFocusNode,
            onNextStep: () {
              // move to Sender ID
              if (_currentStep == 1)
                FocusScope.of(context).requestFocus(senderIdFocusNode);
            },
          ),
          _buildTextField(
            controller: controller.senderIdController,
            label: 'Sender ID / Passport',
            prefixIcon: Icons.credit_card,
            readOnly: _isViewOnly,
            focusNode: senderIdFocusNode,
            nextFocus: receiverNameFocusNode,
          ),
        ]),
      ],
    );
  }

  Widget _buildReceiverSection(BuildContext context) {
    return _buildSectionCard(
      context,
      icon: Icons.person_outline,
      title: 'Receiver',
      subtitle: 'Who is expecting the parcel?',
      children: [
        _buildTextField(
          controller: controller.receiverNameController,
          label: 'Receiver Name',
          prefixIcon: Icons.person_outline,
          isRequired: true,
          readOnly: _isViewOnly,
          focusNode: receiverNameFocusNode,
          nextFocus: receiverPhoneFocusNode,
          error: controller.receiverNameFieldError,
        ),
        const SizedBox(height: 16),
        _buildInlineFields(context, [
          _buildTextField(
            controller: controller.receiverPhoneController,
            label: 'Receiver Phone',
            prefixIcon: Icons.phone_outlined,
            isRequired: true,
            readOnly: _isViewOnly,
            focusNode: receiverPhoneFocusNode,
            nextFocus: receiverIdFocusNode,
            onNextStep: () {
              // After receiver phone, advance to Delivery step
              if (_currentStep == 2) setState(() => _currentStep = 3);
            },
            keyboardType: TextInputType.phone,
            error: controller.receiverPhoneFieldError,
          ),
          _buildTextField(
            controller: controller.receiverIdController,
            label: 'Receiver ID / Passport',
            prefixIcon: Icons.perm_identity,
            readOnly: _isViewOnly,
            focusNode: receiverIdFocusNode,
            nextFocus: vehicleFocusNode,
          ),
        ]),
      ],
    );
  }

  // Logistics step removed from the Stepper. Keep vehicle/driver fields in the model
  // if needed elsewhere — UI for logistics is no longer part of the Add/Edit flow.

  Widget _buildDetailsSection(BuildContext context) {
    final details = controller.parcel?.parcelDetails ?? <Parcel_Details>[];

    return _buildSectionCard(
      context,
      icon: Icons.list_alt_outlined,
      title: 'Parcel Items',
      subtitle: 'Breakdown of contents and values',
      trailing: IconButton(
        onPressed: _isViewOnly
            ? null
            : () {
                controller.addParcelDetail();
                setState(() {});
              },
        icon: const Icon(Icons.add_circle_outline, color: Colors.black),
      ),
      children: [
        if (details.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: const Text(
              'No parcel items yet. Tap the + button to add.',
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < details.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == details.length - 1 ? 0 : 12,
                  ),
                  child: _buildParcelDetailTile(context, details[i], i),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildInlineFields(BuildContext context, List<Widget> fields) {
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

  Widget _buildParcelDetailTile(
    BuildContext context,
    Parcel_Details detail,
    int index,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showEditParcelDetailDialog(context, detail, index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.Description?.isNotEmpty == true
                        ? detail.Description!
                        : 'No description provided',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (detail.Remarks?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      detail.Remarks!,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'KES ${detail.Amount?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    controller.removeParcelDetail(index);
                    setState(() {});
                  },
                  tooltip: 'Remove item',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    InputDecoration? decoration,
    IconData? prefixIcon,
    RxString? error,
    FocusNode? focusNode,
    VoidCallback? onNextStep,
    FocusNode? nextFocus,
  }) {
    final bool showError = (error?.value.isNotEmpty ?? false);
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.black.withOpacity(0.18)),
    );

    // Choose an appropriate action for the keyboard. For multiline fields allow newline,
    // otherwise provide a 'next' action so Enter/Done moves focus to the next field.
    final textInputAction = keyboardType == TextInputType.multiline
        ? TextInputAction.newline
        : TextInputAction.next;

    return TextFormField(
      controller: controller,
      // Avoid automatic scroll padding/scroll animation when focusing the field.
      // This reduces the scroll/animate behavior when the keyboard opens.
      scrollPadding: EdgeInsets.zero,
      keyboardType: keyboardType,
      focusNode: focusNode,
      textInputAction: textInputAction,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      cursorColor: Colors.black,
      decoration: (decoration ?? const InputDecoration()).copyWith(
        filled: true,
        fillColor: Colors.black.withOpacity(0.07),
        labelText: label,
        labelStyle: TextStyle(
          // Only show red when the field-specific error is set; otherwise use neutral color
          color: showError ? Colors.redAccent : Colors.black54,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.black54)
            : decoration?.prefixIcon,
        suffixIcon: isRequired
            ? const Icon(
                Icons.star_rounded,
                size: 16,
                color: Colors.redAccent,
              )
            : decoration?.suffixIcon,
        enabledBorder: baseBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF4FB5FF)),
        ),
        errorBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorText: showError ? error?.value : null,
      ),
      onFieldSubmitted: (_) {
        if (readOnly) return;
        // If a specific next focus is provided, focus it; otherwise fall back to default traversal
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          FocusScope.of(context).nextFocus();
        }

        // If caller wants to advance to the next step (end of a step fields)
        if (onNextStep != null) onNextStep();
      },
      validator: isRequired
          ? (value) {
              // keep validator backing the field-specific RxString but avoid coloring other fields
              error?.value = '';
              if (value == null || value.isEmpty) {
                error?.value = ' field is required';
                return error?.value;
              }
              return null;
            }
          : null,
    );
  }

  Future<void> _showEditParcelDetailDialog(
    BuildContext context,
    Parcel_Details parcelDetail,
    int index,
  ) async {
    // Use a small StatefulWidget dialog that owns its controllers and disposes them
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EditParcelDetailDialog(
        parcelDetail: parcelDetail,
        index: index,
        parcelController: controller,
      ),
    );
  }

  void _submitForm() async {
    try {
      // Ensure there is at least one parcel item before saving
      final items = controller.parcel?.parcelDetails ?? <dynamic>[];
      if (items.isEmpty) {
        controller.itemsError.value = 'At least one item is required';
        _showSnackBar('Validation', 'Please add at least one parcel item.',
            backgroundColor: Colors.redAccent);
        return;
      }

      final parcel = Parcel(
        Document_No: controller.documentNoController.text,
        Date_sent: controller.selectedDate,
        Sender_Name: controller.senderNameController.text,
        Sender_ID: controller.senderIdController.text,
        Sender_Phone: controller.senderPhoneController.text,
        From: controller.fromController.text,
        To: controller.toController.text,
        Receiver_Name: controller.receiverNameController.text,
        Receiver_ID: controller.receiverIdController.text,
        Receiver_Phone: controller.receiverPhoneController.text,
        Status: controller.selectedStatus,
        Driver: controller.driverController.text,
        Vehicle: controller.vehicleController.text,
        Who_to_Pay: controller.paymentResponsibility,
        Amount_Paid:
            double.tryParse(controller.amountPaidController.text) ?? 0.0,
        Paid: controller.paid,
        Date_Collected: controller.parcel?.Date_Collected,
        Date_Delivered: controller.parcel?.Date_Delivered,
        parcelDetails: controller.parcel?.parcelDetails,
      );

      if (controller.parcel != null) {
        controller.updateParcel(parcel);
        _showSnackBar('Success', 'Parcel updated successfully!');
      } else {
        controller.addParcel(parcel);
        _showSnackBar('Success', 'Parcel added successfully!');
        controller.formKey.currentState?.reset();
      }

      await Future.delayed(const Duration(seconds: 1));
      Get.back();
    } catch (e) {
      _showSnackBar(
        'Error',
        'Failed to save parcel: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  void _updateStepErrors() {
    // Clear field-specific errors first
    controller.amountPaidError.value = '';
    controller.fromError.value = '';
    controller.toError.value = '';
    controller.senderNameFieldError.value = '';
    controller.receiverNameFieldError.value = '';
    controller.receiverPhoneFieldError.value = '';
    controller.vehicleFieldError.value = '';
    controller.driverFieldError.value = '';

    // Parcel step (both field errors and step-level summary)
    controller.parcelinformationError.value = '';
    if (controller.amountPaidController.text.trim().isEmpty) {
      controller.amountPaidError.value = 'Amount Paid is required';
      controller.parcelinformationError.value =
          controller.amountPaidError.value;
    } else if (controller.fromController.text.trim().isEmpty) {
      controller.fromError.value = 'From location is required';
      controller.parcelinformationError.value = controller.fromError.value;
    } else if (controller.toController.text.trim().isEmpty) {
      controller.toError.value = 'Destination is required';
      controller.parcelinformationError.value = controller.toError.value;
    } else {
      controller.parcelinformationError.value = '';
    }

    // Sender step
    controller.senderinformationError.value = '';
    if (controller.senderNameController.text.trim().isEmpty) {
      controller.senderNameFieldError.value = 'Sender name is required';
      controller.senderinformationError.value =
          controller.senderNameFieldError.value;
    }

    // Receiver step
    controller.receiverinformationError.value = '';
    if (controller.receiverNameController.text.trim().isEmpty) {
      controller.receiverNameFieldError.value = 'Receiver name is required';
      controller.receiverinformationError.value =
          controller.receiverNameFieldError.value;
    } else if (controller.receiverPhoneController.text.trim().isEmpty) {
      controller.receiverPhoneFieldError.value = 'Receiver phone is required';
      controller.receiverinformationError.value =
          controller.receiverPhoneFieldError.value;
    }

    // Delivery step
    controller.deliveryinformationError.value = '';
    if (controller.vehicleController.text.trim().isEmpty) {
      controller.vehicleFieldError.value = 'Vehicle registration is required';
      controller.deliveryinformationError.value =
          controller.vehicleFieldError.value;
    } else if (controller.driverController.text.trim().isEmpty) {
      controller.driverFieldError.value = 'Driver name is required';
      controller.deliveryinformationError.value =
          controller.driverFieldError.value;
    }

    // Items step: ensure at least one item exists
    controller.itemsError.value = '';
    final items = controller.parcel?.parcelDetails ?? <dynamic>[];
    if (items.isEmpty) {
      controller.itemsError.value = 'At least one item is required';
    }
  }
}

// Dialog widget that owns controllers for editing a Parcel_Details entry.
class _EditParcelDetailDialog extends StatefulWidget {
  final Parcel_Details parcelDetail;
  final int index;
  final ParcelController parcelController;

  const _EditParcelDetailDialog({
    Key? key,
    required this.parcelDetail,
    required this.index,
    required this.parcelController,
  }) : super(key: key);

  @override
  State<_EditParcelDetailDialog> createState() =>
      _EditParcelDetailDialogState();
}

class _EditParcelDetailDialogState extends State<_EditParcelDetailDialog> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _remarksCtrl;
  // Form key for validation inside the dialog
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Currency formatter for the live preview
  final NumberFormat _currencyFmt =
      NumberFormat.currency(locale: 'en_US', symbol: 'KES ');

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.parcelDetail.Description);
    _amountCtrl = TextEditingController(
        text: widget.parcelDetail.Amount?.toString() ?? '');
    _remarksCtrl = TextEditingController(text: widget.parcelDetail.Remarks);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide a pleasantly styled, centered dialog with form validation
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade600,
                    Colors.lightBlueAccent.shade100
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Item',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.parcelDetail.Description?.isNotEmpty == true
                              ? widget.parcelDetail.Description!
                              : 'Item ${widget.index + 1}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Description
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: null,
                          minLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Brief description of the item',
                            prefixIcon: const Icon(Icons.subject),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),

                        // Amount
                        TextFormField(
                          controller: _amountCtrl,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            hintText: '0.00',
                            prefixIcon: const Icon(Icons.monetization_on),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                          ],
                          validator: (v) {
                            final val = double.tryParse(v ?? '');
                            if (val == null || val <= 0)
                              return 'Enter a valid amount';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),

                        // Remarks
                        TextFormField(
                          controller: _remarksCtrl,
                          decoration: InputDecoration(
                            labelText: 'Remarks (optional)',
                            prefixIcon: const Icon(Icons.note),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 16),

                        // Live preview
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _descCtrl.text.isNotEmpty
                                            ? _descCtrl.text
                                            : 'No description',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _remarksCtrl.text.isNotEmpty
                                            ? _remarksCtrl.text
                                            : '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  // Format amount nicely; fall back to 0.00 when parsing fails
                                  _currencyFmt.format(
                                      double.tryParse(_amountCtrl.text) ?? 0.0),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Item'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        final desc = _descCtrl.text.trim();
                        final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
                        final remarks = _remarksCtrl.text.trim();
                        widget.parcelController.updateParcelDetail(
                          widget.index,
                          desc,
                          amount,
                          remarks,
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
