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

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                final status = statuses[index];
                final parcels = groups[status] ?? <Parcel>[];
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
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                ' parcel',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (parcels.isEmpty)
                          const Text('No parcels in this status')
                        else
                          ...parcels.take(4).map(
                            (parcel) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(parcel.Document_No ?? 'Unknown'),
                              subtitle: Text(
                                ' → ',
                              ),
                              trailing: Text(
                                DateFormat('dd MMM').format(parcel.Date_sent ?? DateTime.now()),
                              ),
                            ),
                          ),
                        if (parcels.length > 4)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '+ more',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}


