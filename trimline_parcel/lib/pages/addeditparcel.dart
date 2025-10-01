import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/parcel_controller.dart';
import '../models/Parcel_Details.dart';
import '../models/parcel_model.dart';
import '../utilities/status_color.dart';

typedef PaymentResponsibility = WhoToPay;

class AddEditParcelPage extends StatefulWidget {
  final Parcel? parcel;

  const AddEditParcelPage({super.key, this.parcel});

  @override
  State<AddEditParcelPage> createState() => _AddEditParcelPageState();
}

class _AddEditParcelPageState extends State<AddEditParcelPage> {
  late final ParcelController controller = Get.find<ParcelController>();
  int _currentStep = 0;

  late final VoidCallback _fieldsListener;

  @override
  void initState() {
    super.initState();
    controller.parcel = widget.parcel;
    if (widget.parcel != null) {
      controller.PopulateFormWithParcel(widget.parcel!);
    }

    // Live-update step errors when relevant fields change
    _fieldsListener = () {
      _updateStepErrors();
      if (mounted) setState(() {});
    };

    controller.documentNoController.addListener(_fieldsListener);
    controller.amountPaidController.addListener(_fieldsListener);
    controller.fromController.addListener(_fieldsListener);
    controller.toController.addListener(_fieldsListener);
    controller.senderNameController.addListener(_fieldsListener);
    controller.receiverNameController.addListener(_fieldsListener);
    controller.receiverPhoneController.addListener(_fieldsListener);
    controller.vehicleController.addListener(_fieldsListener);
    controller.driverController.addListener(_fieldsListener);
    controller.senderPhoneController.addListener(_fieldsListener);

    // initialize error states
    _updateStepErrors();
  }

  @override
  void dispose() {
    try {
      controller.documentNoController.removeListener(_fieldsListener);
      controller.amountPaidController.removeListener(_fieldsListener);
      controller.fromController.removeListener(_fieldsListener);
      controller.toController.removeListener(_fieldsListener);
      controller.senderNameController.removeListener(_fieldsListener);
      controller.receiverNameController.removeListener(_fieldsListener);
      controller.receiverPhoneController.removeListener(_fieldsListener);
      controller.vehicleController.removeListener(_fieldsListener);
      controller.driverController.removeListener(_fieldsListener);
      controller.senderPhoneController.removeListener(_fieldsListener);
    } catch (_) {}
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 1,
        toolbarHeight: 50,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
          child: _buildSummaryBar(theme),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Paid', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: controller.paid,
                  activeColor: Colors.greenAccent,
                  onChanged: (value) => setState(() => controller.paid = value),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
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
                      setState(() => _currentStep = firstErrorIndex);
                      Get.snackbar(
                        'Validation',
                        'Please fix the highlighted field.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.redAccent.withOpacity(0.9),
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
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: _backgroundGradient()),
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
                                      backgroundColor: Colors.redAccent
                                          .withOpacity(0.9),
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
                                      backgroundColor: Colors.redAccent
                                          .withOpacity(0.9),
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
                              onStepTapped:
                                  (index) =>
                                      setState(() => _currentStep = index),
                              controlsBuilder: (context, details) {
                                final isLastStep =
                                    _currentStep == steps.length - 1;
                                return Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: details.onStepContinue,
                                      child: Text(
                                        isLastStep
                                            ? (isEditing
                                                ? 'Update Parcel'
                                                : 'Save Parcel')
                                            : 'Next',
                                      ),
                                    ),
                                    if (_currentStep > 0)
                                      TextButton(
                                        onPressed: details.onStepCancel,
                                        child: const Text('Back'),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Step> _buildSteps(BuildContext context) {
    final contents = [
      _buildTabContent(context, [_buildParcelSection(context)]),
      _buildTabContent(context, [_buildSenderSection(context)]),
      _buildTabContent(context, [_buildReceiverSection(context)]),
      _buildTabContent(context, [_buildDeliverySection(context)]),
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

    final vehicle = controller.vehicleController.text.trim();
    final driver = controller.driverController.text.trim();
    final logisticsSubtitle =
        vehicle.isNotEmpty
            ? vehicle
            : (driver.isNotEmpty ? driver : 'Logistics');

    final details = controller.parcel?.parcelDetails ?? <Parcel_Details>[];
    final total = details.fold<double>(
      0,
      (sum, item) => sum + (item.Amount ?? 0.0),
    );
    final itemsSubtitle =
        details.isEmpty
            ? 'No items'
            : '${details.length} items • KES ${total.toStringAsFixed(2)}';

    final titles = ['Parcel', 'Sender', 'Receiver', 'Logistics', 'Items'];
    final subTitles = [
      parcelSubtitle,
      senderSubtitle,
      receiverSubtitle,
      logisticsSubtitle,
      itemsSubtitle,
    ];

    // Use a non-nullable list of RxString so every subtitle Obx observes a real reactive
    final List<RxString> stepErrors = [
      controller.parcelinformationError,
      controller.senderinformationError,
      controller.receiverinformationError,
      controller.deliveryinformationError,
      ''.obs, // Items step has no controller error; observe an empty RxString
    ];

    return List.generate(titles.length, (index) {
      Widget subtitleWidget;

      // Always use Obx but show subtitle or error based on the RxString value
      final subtitleObs = stepErrors[index];

      if (index == 4) {
        subtitleWidget = Row(
          children: [
            Expanded(
              child: Obx(() {
                final value = subtitleObs.value;
                final hasError = value.isNotEmpty;
                return Text(
                  hasError ? value : subTitles[index],
                  style: TextStyle(
                    color: hasError ? Colors.redAccent : Colors.white70,
                    fontSize: 14,
                  ),
                );
              }),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
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
              color: hasError ? Colors.redAccent : Colors.white70,
              fontSize: 14,
            ),
          );
        });
      }
      return Step(
        title: Text(
          titles[index],
          style: const TextStyle(color: Colors.white, fontSize: 20),
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

  // Provide a background gradient that changes when the parcel is marked as paid
  LinearGradient _backgroundGradient() {
    return controller.paid
        ? const LinearGradient(
          colors: [Color(0xFF083E1F), Color(0xFF196F3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
        : const LinearGradient(
          colors: [Color(0xFF101728), Color(0xFF1C2B4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
  }

  Widget _buildSummaryBar(ThemeData theme) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.documentNoController,
      builder:
          (context, docValue, _) => ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller.amountPaidController,
            builder: (context, amountValue, __) {
              final status = controller.selectedStatus;
              final statusColor = getStatusColor(status);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient:
                      controller.paid
                          ? const LinearGradient(
                            colors: [Color(0xFF154C2E), Color(0xFF2EA86A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : const LinearGradient(
                            colors: [Color(0xFF1F2D4D), Color(0xFF2E3E63)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            docValue.text,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(controller.selectedDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildTabContent(BuildContext context, List<Widget> children) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        2,
        4,
        2,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (children.isNotEmpty) ...[const SizedBox(height: 24), ...children],
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
            error: controller.fromError,
          ),
          _buildTextField(
            controller: controller.toController,
            label: 'To (Destination)',
            prefixIcon: Icons.location_on,
            isRequired: true,
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
          error: controller.senderNameFieldError,
        ),
        const SizedBox(height: 16),
        _buildInlineFields(context, [
          _buildTextField(
            controller: controller.senderPhoneController,
            label: 'Sender Phone',
            prefixIcon: Icons.phone,
            isRequired: true,
          ),
          _buildTextField(
            controller: controller.senderIdController,
            label: 'Sender ID / Passport',
            prefixIcon: Icons.credit_card,
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
          error: controller.receiverNameFieldError,
        ),
        const SizedBox(height: 16),
        _buildInlineFields(context, [
          _buildTextField(
            controller: controller.receiverPhoneController,
            label: 'Receiver Phone',
            prefixIcon: Icons.phone_outlined,
            isRequired: true,
            keyboardType: TextInputType.phone,
            error: controller.receiverPhoneFieldError,
          ),
          _buildTextField(
            controller: controller.receiverIdController,
            label: 'Receiver ID / Passport',
            prefixIcon: Icons.perm_identity,
          ),
        ]),
      ],
    );
  }

  Widget _buildDeliverySection(BuildContext context) {
    return _buildSectionCard(
      context,
      icon: Icons.local_shipping_outlined,
      title: 'Logistics',
      subtitle: 'Driver and vehicle details',
      children: [
        _buildTextField(
          controller: controller.vehicleController,
          label: 'Vehicle Registration',
          prefixIcon: Icons.directions_car,
          isRequired: true,
          error: controller.vehicleFieldError,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.driverController,
          label: 'Driver Name',
          prefixIcon: Icons.person,
          isRequired: true,
          error: controller.driverFieldError,
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final details = controller.parcel?.parcelDetails ?? <Parcel_Details>[];
    final total = details.fold<double>(
      0,
      (sum, item) => sum + (item.Amount ?? 0.0),
    );

    return _buildSectionCard(
      context,
      icon: Icons.list_alt_outlined,
      title: 'Parcel Items',
      subtitle: 'Breakdown of contents and values',
      trailing: IconButton(
        onPressed: () {
          controller.addParcelDetail();
          setState(() {});
        },
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
      ),
      children: [
        if (details.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: const Text(
              'No parcel items yet. Tap the + button to add.',
              style: TextStyle(color: Colors.white70),
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

  Widget _buildPaidSwitch(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(
            controller.paid ? Icons.verified_outlined : Icons.pending_outlined,
            color: controller.paid ? Colors.greenAccent : Colors.orangeAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment status',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  controller.paid
                      ? 'Customer has settled payment'
                      : 'Awaiting payment confirmation',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: controller.paid,
            activeTrackColor: Colors.greenAccent.withValues(alpha: 0.4),
            activeThumbColor: Colors.greenAccent,
            onChanged: (value) {
              setState(() {
                controller.paid = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (detail.Remarks?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      detail.Remarks!,
                      style: const TextStyle(
                        color: Colors.white60,
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
                    color: Colors.white,
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
  }) {
    final bool showError = (error?.value.isNotEmpty ?? false);
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      cursorColor: Colors.white,
      decoration: (decoration ?? const InputDecoration()).copyWith(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        labelText: label,
        labelStyle: TextStyle(
          // Only show red when the field-specific error is set; otherwise use neutral color
          color: showError ? Colors.redAccent : Colors.white70,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, color: Colors.white70)
                : decoration?.prefixIcon,
        suffixIcon:
            isRequired
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
      validator:
          isRequired
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
    final descCtrl = TextEditingController(text: parcelDetail.Description);
    final amountCtrl = TextEditingController(
      text: parcelDetail.Amount?.toString(),
    );
    final remarksCtrl = TextEditingController(text: parcelDetail.Remarks);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'Edit Parcel Detail',
                  style: TextStyle(color: Colors.white),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF101728), Color(0xFF1C2B4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: descCtrl,
                          maxLines: null,
                          minLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.07),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFF4FB5FF),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: amountCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.07),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFF4FB5FF),
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: remarksCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Remarks',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.07),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFF4FB5FF),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF101728), Color(0xFF1C2B4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        controller.updateParcelDetail(
                          index,
                          descCtrl.text,
                          double.tryParse(amountCtrl.text) ?? 0.0,
                          remarksCtrl.text,
                        );
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FB5FF),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _submitForm() async {
    try {
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
  }
}
