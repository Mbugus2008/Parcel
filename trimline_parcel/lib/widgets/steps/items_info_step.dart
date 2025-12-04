import 'package:flutter/material.dart';

import '../../controllers/parcel_controller.dart';
import '../../models/Parcel_Details.dart';
import '../form_builders.dart';

/// Step 3: Parcel Items
/// Displays and manages the list of items in the parcel
class ItemsInfoStep extends StatelessWidget {
  final ParcelController controller;
  final bool isViewOnly;
  final Future<void> Function(BuildContext, Parcel_Details, int) onEditItem;
  final VoidCallback onItemsChanged;

  const ItemsInfoStep({
    super.key,
    required this.controller,
    required this.isViewOnly,
    required this.onEditItem,
    required this.onItemsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final details = controller.parcel?.parcelDetails ?? <Parcel_Details>[];

    return FormBuilders.buildSectionCard(
      context,
      icon: Icons.list_alt_outlined,
      title: 'Parcel Items',
      subtitle: 'Breakdown of contents and values',
      children: [
        if (details.isEmpty)
          _buildEmptyState()
        else
          _buildItemsList(context, details),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No parcel items yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the + button in the step header to add items',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<Parcel_Details> details) {
    return Column(
      children: [
        for (var i = 0; i < details.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == details.length - 1 ? 0 : 12,
            ),
            child: ParcelDetailTile(
              detail: details[i],
              index: i,
              onTap: () => onEditItem(context, details[i], i),
              onDelete: isViewOnly
                  ? null
                  : () {
                      controller.removeParcelDetail(i);
                      onItemsChanged();
                    },
            ),
          ),
      ],
    );
  }
}

/// A single parcel item tile
class ParcelDetailTile extends StatelessWidget {
  final Parcel_Details detail;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ParcelDetailTile({
    super.key,
    required this.detail,
    required this.index,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item number indicator
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.blueAccent.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            // Item details
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
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Amount and delete
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
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Remove item',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
