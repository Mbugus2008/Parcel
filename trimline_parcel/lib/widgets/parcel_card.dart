import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/parcel_controller.dart';
import '../models/parcel_model.dart';
import '../pages/addeditparcel.dart';
import '../utilities/status_color.dart';

class ParcelCard extends StatelessWidget {
  const ParcelCard({super.key, required this.parcel});

  final Parcel parcel;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ParcelController>();
    final theme = Theme.of(context);
    final status = parcel.Status ?? ParcelStatus.pending;
    final statusColor = getStatusColor(status);
    final isPending = status == ParcelStatus.pending;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color banner on the left
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: statusColor,
              ),
            ),
            // Main content
            Expanded(
              child: InkWell(
                onTap: () {
                  if (isPending) {
                    Get.to(() => AddEditParcelPage(parcel: parcel));
                  } else {
                    Get.snackbar(
                      'Locked',
                      'Only parcels that are still pending can be edited.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: Document No, Date, Status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  parcel.Document_No ?? 'Unknown',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy').format(
                                    parcel.Date_sent ?? DateTime.now(),
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              controller.statusLabel(status),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Route visualization
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: Colors.green.shade400,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                parcel.From ?? '-',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                parcel.To ?? '-',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: Colors.red.shade400,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Sender & Receiver info
                      Row(
                        children: [
                          Expanded(
                            child: _buildContactInfo(
                              context,
                              icon: Icons.person_outline,
                              label: 'Sender',
                              name: parcel.Sender_Name,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildContactInfo(
                              context,
                              icon: Icons.person_pin_outlined,
                              label: 'Receiver',
                              name: parcel.Receiver_Name,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Divider
                      Divider(height: 1, color: Colors.grey.shade200),
                      const SizedBox(height: 10),
                      // Action buttons row
                      Row(
                        children: [
                          // Amount display
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'KES ${(parcel.Amount_Paid ?? 0).toStringAsFixed(0)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Edit button (only for pending)
                          if (isPending)
                            _buildActionButton(
                              context,
                              icon: Icons.edit_outlined,
                              label: 'Edit',
                              color: Colors.blue,
                              onTap: () {
                                Get.to(() => AddEditParcelPage(parcel: parcel));
                              },
                            ),
                          if (isPending) const SizedBox(width: 8),
                          // Dispatch/Status change button
                          _buildStatusActionButton(
                            context,
                            status: status,
                            onTap: () {
                              _showStatusChangeSheet(
                                  context, controller, status);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? name,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
              Text(
                name?.isNotEmpty == true ? name! : '-',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusActionButton(
    BuildContext context, {
    required ParcelStatus status,
    required VoidCallback onTap,
  }) {
    String label;
    IconData icon;
    Color color;

    switch (status) {
      case ParcelStatus.pending:
        label = 'Dispatch';
        icon = Icons.local_shipping_outlined;
        color = Colors.orange;
        break;
      case ParcelStatus.inTransit:
        label = 'Mark Received';
        icon = Icons.home_outlined;
        color = Colors.blue;
        break;
      case ParcelStatus.received:
        label = 'Mark Collected';
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case ParcelStatus.collected:
        label = 'Completed';
        icon = Icons.verified_outlined;
        color = Colors.grey;
        break;
    }

    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: status != ParcelStatus.collected ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusChangeSheet(
    BuildContext context,
    ParcelController controller,
    ParcelStatus currentStatus,
  ) {
    final statusColor = getStatusColor(currentStatus);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_shipping_rounded,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update Status',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            parcel.Document_No ?? 'Unknown',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...controller.supportedStatuses.map((status) {
                  final isCurrentStatus = status == currentStatus;
                  final color = getStatusColor(status);
                  return ListTile(
                    onTap: isCurrentStatus
                        ? null
                        : () {
                            controller.updateParcelStatus(parcel, status);
                            Navigator.pop(context);
                          },
                    leading: Icon(
                      _getStatusIcon(status),
                      color: isCurrentStatus ? Colors.grey : color,
                    ),
                    title: Text(
                      controller.statusLabel(status),
                      style: TextStyle(
                        color: isCurrentStatus ? Colors.grey : Colors.black87,
                        fontWeight: isCurrentStatus
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isCurrentStatus
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isCurrentStatus ? Colors.grey.shade100 : null,
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.pending:
        return Icons.pending_actions_rounded;
      case ParcelStatus.inTransit:
        return Icons.local_shipping_rounded;
      case ParcelStatus.received:
        return Icons.home_work_rounded;
      case ParcelStatus.collected:
        return Icons.verified_rounded;
    }
  }
}
