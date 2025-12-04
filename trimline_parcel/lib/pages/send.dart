import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/parcel_controller.dart';
import '../models/parcel_model.dart';
import '../widgets/parcel_card.dart';

/// Send Parcel Page - Shows pending parcels ready to be dispatched
class SendParcelPage extends StatelessWidget {
  const SendParcelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ParcelController controller = Get.find<ParcelController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Parcels'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        // Filter only pending parcels
        final pendingParcels = controller.parcelsRx
            .where((p) =>
                (p.Status ?? ParcelStatus.pending) == ParcelStatus.pending)
            .toList();

        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (pendingParcels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending parcels',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All parcels have been dispatched',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingParcels.length,
          itemBuilder: (context, index) {
            final parcel = pendingParcels[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ParcelCard(parcel: parcel),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _dispatchParcel(context, controller, parcel),
                            icon: const Icon(Icons.local_shipping),
                            label: const Text('Dispatch'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
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
      }),
    );
  }

  Future<void> _dispatchParcel(
    BuildContext context,
    ParcelController controller,
    Parcel parcel,
  ) async {
    final theme = Theme.of(context);

    // Show dispatch confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispatch Parcel'),
        content: Text(
          'Mark parcel ${parcel.Document_No} as dispatched?\n\n'
          'From: ${parcel.From}\n'
          'To: ${parcel.To}\n'
          'Receiver: ${parcel.Receiver_Name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Dispatch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.dispatchParcel(parcel);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parcel ${parcel.Document_No} dispatched'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

/// Receive Parcel Page - Shows parcels in transit ready to be received
class ReceiveParcelListPage extends StatelessWidget {
  const ReceiveParcelListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ParcelController controller = Get.find<ParcelController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Parcels'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        // Filter only in-transit parcels
        final inTransitParcels = controller.parcelsRx
            .where((p) =>
                (p.Status ?? ParcelStatus.pending) == ParcelStatus.inTransit)
            .toList();

        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (inTransitParcels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No parcels in transit',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No parcels are currently being delivered',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: inTransitParcels.length,
          itemBuilder: (context, index) {
            final parcel = inTransitParcels[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ParcelCard(parcel: parcel),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _receiveParcel(context, controller, parcel),
                            icon: const Icon(Icons.inventory_2),
                            label: const Text('Mark as Received'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
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
      }),
    );
  }

  Future<void> _receiveParcel(
    BuildContext context,
    ParcelController controller,
    Parcel parcel,
  ) async {
    // Show receive confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receive Parcel'),
        content: Text(
          'Mark parcel ${parcel.Document_No} as received?\n\n'
          'From: ${parcel.From}\n'
          'Sender: ${parcel.Sender_Name}\n'
          'Driver: ${parcel.Driver ?? "Not assigned"}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Receive'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.updateParcelStatus(parcel, ParcelStatus.received);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parcel ${parcel.Document_No} received'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
