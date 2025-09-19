import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/parcel_controller.dart';
import '../models/Parcel_Details.dart';
import '../models/parcel_model.dart';
import '../pages/addeditparcel.dart';
import '../utilities/status_color.dart';

String _routeLabel(Parcel parcel) {
  final origin = parcel.From?.trim();
  final destination = parcel.To?.trim();

  if (origin != null && origin.isNotEmpty && destination != null && destination.isNotEmpty) {
    return '$origin -> $destination';
  }
  if (origin != null && origin.isNotEmpty) return origin;
  if (destination != null && destination.isNotEmpty) return destination;
  return 'Route not set';
}

class ParcelDashboardPage extends StatefulWidget {
  const ParcelDashboardPage({super.key});

  @override
  State<ParcelDashboardPage> createState() => _ParcelDashboardPageState();
}

class _ParcelDashboardPageState extends State<ParcelDashboardPage> {
  final ParcelController _controller = Get.find<ParcelController>();
  int _currentStep = 0;

  static const Color _headingColor = Color(0xFF102A59);
  static const Color _bodyColor = Color(0xFF24334E);
  static const Color _mutedColor = Color(0xFF6B7C93);
  static const Color _panelColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepperTheme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: const Color(0xFF4A6BFF),
        onSurface: _bodyColor,
      ),
      textTheme: theme.textTheme.apply(
        bodyColor: _bodyColor,
        displayColor: _bodyColor,
      ),
      iconTheme: theme.iconTheme.copyWith(color: const Color(0xFF4A6BFF)),
      dividerColor: Colors.black12,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const Text('Parcel Dashboard'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6FAFF), Color(0xFFDDEBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.parcels.isEmpty) {
              final hasAnyParcels = _controller.allParcels.isNotEmpty;
              final message = hasAnyParcels
                  ? 'No parcels match your search or filters'
                  : 'No parcels available yet';
              return Center(
                child: Text(
                  message,
                  style: const TextStyle(color: _mutedColor),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final steps = _buildSteps(context);
            final safeStep = steps.isEmpty ? 0 : _currentStep.clamp(0, steps.length - 1);

            return Theme(
              data: stepperTheme,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: safeStep,
                physics: const ClampingScrollPhysics(),
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                onStepTapped: (step) => setState(() => _currentStep = step),
                steps: steps,
              ),
            );
          }),
        ),
      ),
    );
  }

  List<Step> _buildSteps(BuildContext context) {
    final statuses = ParcelStatus.values;
    final groups = _controller.parcelsByStatus;

    return statuses.asMap().entries.map((entry) {
      final index = entry.key;
      final status = entry.value;
      final parcels = groups[status] ?? <Parcel>[];
      final statusColor = getStatusColor(status);

      return Step(
        state: _currentStep > index
            ? StepState.complete
            : (_currentStep == index ? StepState.editing : StepState.indexed),
        isActive: _currentStep >= index,
        title: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withValues(alpha: 0.18),
              ),
              child: Icon(_statusIcon(status), color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _controller.statusLabel(status),
                    style: const TextStyle(
                      color: _headingColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${parcels.length} parcel${parcels.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: _mutedColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: parcels.isEmpty
            ? _buildEmptyStatus(statusColor)
            : Column(
                children: [
                  for (final parcel in parcels)
                    _buildParcelCard(context, parcel, statusColor),
                ],
              ),
      );
    }).toList();
  }

  Widget _buildEmptyStatus(Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Text(
        'No parcels in this step yet',
        style: TextStyle(color: _mutedColor),
      ),
    );
  }

  Widget _buildParcelCard(
    BuildContext context,
    Parcel parcel,
    Color statusColor,
  ) {
    final routeLabel = _routeLabel(parcel);
    final dispatched = parcel.Date_sent != null
        ? DateFormat('dd MMM, yyyy').format(parcel.Date_sent!)
        : 'Pending dispatch';
    final isPaid = parcel.Paid == true;
    final amountPaid = (parcel.Amount_Paid ?? 0).toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _panelColor,
        border: Border.all(color: const Color(0xFFE1E7F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  parcel.Document_No ?? 'Unknown Document',
                  style: const TextStyle(
                    color: _headingColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFFE7F8EF)
                      : const Color(0xFFF1F3F8),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isPaid
                        ? const Color(0xFF2F8F47).withValues(alpha: 0.4)
                        : Colors.black12,
                  ),
                ),
                child: Text(
                  isPaid ? 'Paid' : 'Unpaid',
                  style: const TextStyle(
                    color: _bodyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.route_outlined, size: 18, color: _mutedColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  routeLabel,
                  style: const TextStyle(
                    color: _bodyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _infoChip(Icons.schedule_outlined, dispatched),
              _infoChip(
                Icons.person_outline,
                parcel.Sender_Name?.isNotEmpty == true
                    ? parcel.Sender_Name!
                    : 'Sender not set',
              ),
              _infoChip(
                Icons.phone_outlined,
                parcel.Sender_Phone?.isNotEmpty == true
                    ? parcel.Sender_Phone!
                    : 'Phone not set',
              ),
              _infoChip(
                Icons.monetization_on_outlined,
                'KES $amountPaid',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => Get.to(() => _ParcelCardPreview(parcel: parcel)),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('View details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _mutedColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _bodyColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.pending:
        return Icons.pending_actions;
      case ParcelStatus.inTransit:
        return Icons.local_shipping_outlined;
      case ParcelStatus.received:
        return Icons.inventory_2_outlined;
      case ParcelStatus.collected:
        return Icons.task_alt_outlined;
    }
  }
}

class _ParcelCardPreview extends StatelessWidget {
  const _ParcelCardPreview({required this.parcel});

  final Parcel parcel;

  static const Color _headingColor = Color(0xFF102A59);
  static const Color _bodyColor = Color(0xFF24334E);
  static const Color _mutedColor = Color(0xFF6B7C93);
  static const Color _panelColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final status = parcel.Status ?? ParcelStatus.pending;
    final statusColor = getStatusColor(status);
    final statusLabel = _statusLabel(status);
    final amountPaid = (parcel.Amount_Paid ?? 0).toStringAsFixed(2);
    final details = parcel.parcelDetails;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _headingColor,
        title: Text(
          parcel.Document_No?.isNotEmpty == true
              ? parcel.Document_No!
              : 'Parcel Details',
          style: const TextStyle(
            color: _headingColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit parcel',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Get.to(() => AddEditParcelPage(parcel: parcel)),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEAF2FF), Color(0xFFD5E8FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6FAFF), Color(0xFFDDEBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _summaryCard(statusColor, statusLabel, amountPaid),
              const SizedBox(height: 18),
              _sectionCard(
                title: 'Route & Schedule',
                children: [
                  _infoRow(
                    icon: Icons.location_on_outlined,
                    label: 'From',
                    value: parcel.From ?? 'Not provided',
                  ),
                  _infoRow(
                    icon: Icons.flag_outlined,
                    label: 'To',
                    value: parcel.To ?? 'Not provided',
                  ),
                  _infoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Dispatched',
                    value: parcel.Date_sent != null
                        ? DateFormat('dd MMM, yyyy').format(parcel.Date_sent!)
                        : 'Pending dispatch',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Contacts',
                children: [
                  _infoRow(
                    icon: Icons.person_outline,
                    label: 'Sender',
                    value: parcel.Sender_Name?.isNotEmpty == true
                        ? parcel.Sender_Name!
                        : 'Not provided',
                  ),
                  _infoRow(
                    icon: Icons.phone_outlined,
                    label: 'Sender Phone',
                    value: parcel.Sender_Phone?.isNotEmpty == true
                        ? parcel.Sender_Phone!
                        : 'Not set',
                  ),
                  _infoRow(
                    icon: Icons.person,
                    label: 'Receiver',
                    value: parcel.Receiver_Name?.isNotEmpty == true
                        ? parcel.Receiver_Name!
                        : 'Not provided',
                  ),
                  _infoRow(
                    icon: Icons.phone,
                    label: 'Receiver Phone',
                    value: parcel.Receiver_Phone?.isNotEmpty == true
                        ? parcel.Receiver_Phone!
                        : 'Not set',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Logistics & Payments',
                children: [
                  _infoRow(
                    icon: Icons.local_shipping_outlined,
                    label: 'Driver',
                    value: parcel.Driver?.isNotEmpty == true
                        ? parcel.Driver!
                        : 'Driver TBD',
                  ),
                  _infoRow(
                    icon: Icons.directions_car_filled_outlined,
                    label: 'Vehicle',
                    value: parcel.Vehicle?.isNotEmpty == true
                        ? parcel.Vehicle!
                        : 'Vehicle TBD',
                  ),
                  _infoRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Amount Paid',
                    value: 'KES $amountPaid',
                  ),
                  _infoRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Payment Status',
                    value: parcel.Paid == true ? 'Paid' : 'Unpaid',
                  ),
                ],
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Parcel Items',
                  children: [
                    for (final detail in details)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _itemTile(detail),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(Color statusColor, String statusLabel, String amountPaid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _panelColor,
        border: Border.all(color: const Color(0xFFE1E7F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Document No.',
                      style: TextStyle(color: _mutedColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      parcel.Document_No?.isNotEmpty == true
                          ? parcel.Document_No!
                          : 'Pending number',
                      style: const TextStyle(
                        color: _headingColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radio_button_checked, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: const TextStyle(
                        color: _bodyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount Paid',
                      style: TextStyle(color: _mutedColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KES $amountPaid',
                      style: const TextStyle(
                        color: _headingColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dispatched On',
                      style: TextStyle(color: _mutedColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      parcel.Date_sent != null
                          ? DateFormat('dd MMM, yyyy').format(parcel.Date_sent!)
                          : 'Pending dispatch',
                      style: const TextStyle(
                        color: _bodyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _panelColor,
        border: Border.all(color: const Color(0xFFE1E7F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _headingColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _mutedColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: _bodyColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(Parcel_Details detail) {
    final amount = (detail.Amount ?? 0).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _panelColor,
        border: Border.all(color: const Color(0xFFE1E7F5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.Description?.isNotEmpty == true
                      ? detail.Description!
                      : 'Item description not set',
                  style: const TextStyle(
                    color: _bodyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail.Remarks?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail.Remarks!,
                    style: const TextStyle(color: _mutedColor, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Text(
            'KES $amount',
            style: const TextStyle(
              color: _headingColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.pending:
        return 'Pending';
      case ParcelStatus.inTransit:
        return 'In Transit';
      case ParcelStatus.received:
        return 'Received';
      case ParcelStatus.collected:
        return 'Collected';
    }
    return 'Pending';
  }
}
