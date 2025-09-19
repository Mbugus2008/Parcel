import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/parcel_controller.dart';
import '../models/parcel_model.dart';
import '../utilities/status_color.dart';

class ParcelDashboardPage extends StatelessWidget {
  const ParcelDashboardPage({super.key});

  ParcelController get _controller => Get.find<ParcelController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcel Dashboard'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF101728), Color(0xFF1F2A44)],
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
              return const Center(
                child: Text(
                  'No parcels available yet',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final groups = _controller.parcelsByStatus;
            final statuses = ParcelStatus.values;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildStatusStepper(context, groups),
                const SizedBox(height: 24),
                ...statuses.map(
                  (status) => _buildStatusCard(
                    context,
                    status,
                    groups[status] ?? <Parcel>[],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatusStepper(
    BuildContext context,
    Map<ParcelStatus, List<Parcel>> groups,
  ) {
    final statuses = ParcelStatus.values;
    final theme = Theme.of(context);
    final totalParcels = groups.values.fold<int>(0, (sum, list) => sum + list.length);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF283349), Color(0xFF202736)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parcel journey',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor how many shipments sit at each milestone in real time.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(statuses.length, (index) {
            final status = statuses[index];
            final parcels = groups[status] ?? <Parcel>[];
            final statusColor = getStatusColor(status);
            final count = parcels.length;
            final hasParcels = count > 0;
            final progress = totalParcels == 0 ? 0.0 : count / totalParcels;
            final nextHasParcels = index + 1 < statuses.length
                ? (groups[statuses[index + 1]]?.isNotEmpty ?? false)
                : false;

            return Padding(
              padding: EdgeInsets.only(bottom: index == statuses.length - 1 ? 0 : 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      _buildStepIndicator(status, hasParcels, statusColor),
                      if (index != statuses.length - 1)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 2,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: hasParcels || nextHasParcels
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      statusColor.withOpacity(hasParcels ? 0.9 : 0.35),
                                      getStatusColor(statuses[index + 1])
                                          .withOpacity(nextHasParcels ? 0.9 : 0.35),
                                    ],
                                  )
                                : null,
                            color: hasParcels || nextHasParcels ? null : Colors.white12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(hasParcels ? 0.12 : 0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: hasParcels
                              ? Colors.white.withOpacity(0.45)
                              : Colors.white.withOpacity(0.15),
                        ),
                        boxShadow: hasParcels
                            ? [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.35),
                                  blurRadius: 30,
                                  offset: const Offset(0, 14),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _controller.statusLabel(status),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                count == 0
                                    ? 'No parcels'
                                    : '$count ${count == 1 ? 'parcel' : 'parcels'}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _statusDescription(status),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.white.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                statusColor.withOpacity(0.85),
                              ),
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: parcels.take(3).map((parcel) {
                                final document = parcel.Document_No ?? 'Unknown';
                                final routeText = _formatRoute(parcel);
                                return Tooltip(
                                  message: routeText == null
                                      ? document
                                      : '$document · $routeText',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.45),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_post_office_rounded,
                                          size: 14,
                                          color: statusColor.withOpacity(0.9),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          document,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (count > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '+${count - 3} more in this stage',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    ParcelStatus status,
    List<Parcel> parcels,
  ) {
    final theme = Theme.of(context);
    final statusColor = getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _controller.statusLabel(status),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    parcels.isEmpty
                        ? 'No parcels'
                        : '${parcels.length} ${parcels.length == 1 ? 'parcel' : 'parcels'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (parcels.isEmpty)
              Text(
                'No parcels in this status',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
              )
            else
              ...parcels.take(4).map(
                (parcel) => _buildParcelRow(context, parcel, statusColor),
              ),
            if (parcels.length > 4)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '+${parcels.length - 4} more',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelRow(
    BuildContext context,
    Parcel parcel,
    Color statusColor,
  ) {
    final theme = Theme.of(context);
    final route = _formatRoute(parcel) ?? 'Route unavailable';
    final sentDate = parcel.Date_sent != null
        ? DateFormat('dd MMM').format(parcel.Date_sent!)
        : 'No date';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parcel.Document_No ?? 'Unknown reference',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  route,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            sentDate,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    ParcelStatus status,
    bool isActive,
    Color statusColor,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? LinearGradient(
                colors: [
                  statusColor.withOpacity(0.95),
                  statusColor.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.white.withOpacity(0.08),
        border: Border.all(
          color: isActive ? Colors.white : Colors.white24,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: statusColor.withOpacity(0.45),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                ),
              ]
            : [],
      ),
      child: Icon(
        _statusIcon(status),
        color: isActive ? Colors.white : Colors.white54,
        size: 18,
      ),
    );
  }

  IconData _statusIcon(ParcelStatus status) {
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

  String _statusDescription(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.pending:
        return 'Newly logged parcels awaiting pickup or dispatch confirmation.';
      case ParcelStatus.inTransit:
        return 'Shipments moving between hubs or currently out with couriers.';
      case ParcelStatus.received:
        return 'Arrived at the destination hub and ready for customer collection.';
      case ParcelStatus.collected:
        return 'Parcels handed over to recipients and ready to close out the journey.';
    }
  }

  String? _formatRoute(Parcel parcel) {
    final parts = <String>[];

    final from = parcel.From?.trim();
    if (from != null && from.isNotEmpty) {
      parts.add(from);
    }

    final to = parcel.To?.trim();
    if (to != null && to.isNotEmpty) {
      parts.add(to);
    }

    if (parts.isEmpty) {
      return null;
    }

    if (parts.length == 1) {
      return parts.first;
    }

    return '${parts.first} → ${parts.last}';
  }
}


