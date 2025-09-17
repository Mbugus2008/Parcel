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

  @override
  void initState() {
    super.initState();
    controller.parcel = widget.parcel;
    if (widget.parcel != null) {
      controller.PopulateFormWithParcel(widget.parcel!);
    }
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

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          title: Text(
            isEditing ? 'Update Parcel' : 'Create Parcel',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(156),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildSummaryBar(theme),
                ),
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Parcel'),
                    Tab(text: 'Sender'),
                    Tab(text: 'Receiver'),
                    Tab(text: 'Logistics'),
                    Tab(text: 'Items'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF101728), Color(0xFF1C2B4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Form(
              key: controller.formKey,
              child: TabBarView(
                physics: const ClampingScrollPhysics(),
                children: [
                  _buildTabContent(context, [
                    _buildParcelSection(context),
                  ]),
                  _buildTabContent(context, [
                    _buildSenderSection(context),
                  ]),
                  _buildTabContent(context, [
                    _buildReceiverSection(context),
                  ]),
                  _buildTabContent(context, [
                    _buildDeliverySection(context),
                  ]),
                  _buildTabContent(context, [
                    _buildDetailsSection(context),
                  ]),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                if (controller.formKey.currentState!.validate()) {
                  _submitForm();
                }
              },
              icon: Icon(isEditing ? Icons.save_rounded : Icons.check_circle_outline),
              label: Text(isEditing ? 'Update Parcel' : 'Save Parcel'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(ThemeData theme) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.documentNoController,
      builder: (context, docValue, _) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller.amountPaidController,
        builder: (context, amountValue, __) {
          final status = controller.selectedStatus;
          final statusColor = getStatusColor(status);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
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
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd MMM yyyy').format(controller.selectedDate),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.statusLabel(status),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'KES ',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, List<Widget> children) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        MediaQuery.of(context).viewInsets.bottom + 120,
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF3A6FF5), Color(0xFF4FB5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...children,
          ],
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
          error: controller.parcelinformationError,
        ),
        const SizedBox(height: 16),
        _buildPaidSwitch(context),
        const SizedBox(height: 16),
        Text(
          'Parcel status',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: controller.supportedStatuses.map((option) {
            final isSelected = controller.selectedStatus == option;
            return ChoiceChip(
              label: Text(controller.statusLabel(option)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    controller.selectedStatus = option;
                  });
                }
              },
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              selectedColor: getStatusColor(option).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? Colors.white : Colors.white24,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildInlineFields(
          context,
          [
            _buildTextField(
              controller: controller.fromController,
              label: 'From (Location)',
              prefixIcon: Icons.location_on,
              isRequired: true,
              error: controller.parcelinformationError,
            ),
            _buildTextField(
              controller: controller.toController,
              label: 'To (Destination)',
              prefixIcon: Icons.location_on,
              isRequired: true,
              error: controller.parcelinformationError,
            ),
          ],
        ),
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
          error: controller.senderinformationError,
        ),
        const SizedBox(height: 16),
        _buildInlineFields(
          context,
          [
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
          ],
        ),
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
          error: controller.receiverinformationError,
        ),
        const SizedBox(height: 16),
        _buildInlineFields(
          context,
          [
            _buildTextField(
              controller: controller.receiverPhoneController,
              label: 'Receiver Phone',
              prefixIcon: Icons.phone_outlined,
              isRequired: true,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: controller.receiverIdController,
              label: 'Receiver ID / Passport',
              prefixIcon: Icons.perm_identity,
            ),
          ],
        ),
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
          error: controller.deliveryinformationError,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.driverController,
          label: 'Driver Name',
          prefixIcon: Icons.person,
          isRequired: true,
          error: controller.deliveryinformationError,
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final details = controller.parcel?.parcelDetails ?? <Parcel_Details>[];
    final total = details.fold<double>(0, (sum, item) => sum + (item.Amount ?? 0.0));

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
        Row(
          children: [
            _buildSummaryPill(label: 'Items', value: ''),
            const SizedBox(width: 12),
            _buildSummaryPill(label: 'Total', value: 'KES '),
          ],
        ),
        const SizedBox(height: 16),
        if (details.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
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
                  padding: EdgeInsets.only(bottom: i == details.length - 1 ? 0 : 12),
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
                  padding: EdgeInsets.only(bottom: i == fields.length - 1 ? 0 : 16),
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
                  padding: EdgeInsets.only(right: i == fields.length - 1 ? 0 : 16),
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
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
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

  Widget _buildParcelDetailTile(BuildContext context, Parcel_Details detail, int index) {
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
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'KES ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    // controller.removeParcelDetail(index);
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
    final fieldKey = GlobalKey<FormFieldState>();
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final bool isEmpty = value.text.isEmpty;
        final bool showError = (error?.value.isNotEmpty ?? false);
        final baseBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        );

        return TextFormField(
          key: fieldKey,
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
              color: showError
                  ? Colors.redAccent
                  : (isEmpty && isRequired ? Colors.orangeAccent : Colors.white70),
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.white70)
                : decoration?.prefixIcon,
            suffixIcon: isRequired
                ? const Icon(Icons.star_rounded, size: 16, color: Colors.redAccent)
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
          validator: isRequired
              ? (value) {
                  error?.value = '';
                  if (value == null || value.isEmpty) {
                    error?.value = ' field is required';
                    return error?.value;
                  }
                  return null;
                }
              : null,
        );
      },
    );
  }

  Future<void> _showEditParcelDetailDialog(
      BuildContext context, Parcel_Details parcelDetail, int index) async {
    final descCtrl = TextEditingController(text: parcelDetail.Description);
    final amountCtrl = TextEditingController(text: parcelDetail.Amount?.toString());
    final remarksCtrl = TextEditingController(text: parcelDetail.Remarks);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Scaffold(
            appBar: AppBar(title: const Text('Edit Parcel Detail')),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: descCtrl,
                      maxLines: null,
                      minLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: remarksCtrl,
                      decoration: const InputDecoration(labelText: 'Remarks'),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // controller.updateParcelDetail(
                      //   index,
                      //   descCtrl.text,
                      //   double.tryParse(amountCtrl.text) ?? 0.0,
                      //   remarksCtrl.text,
                      // );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
        Amount_Paid: double.tryParse(controller.amountPaidController.text) ?? 0.0,
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
        'Failed to save parcel: ',
        backgroundColor: Colors.red,
      );
    }
  }
}






