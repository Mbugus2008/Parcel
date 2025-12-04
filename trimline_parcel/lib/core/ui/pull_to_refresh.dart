/// Pull to refresh wrapper with custom styling
library;

import 'package:flutter/material.dart';

/// Enhanced pull to refresh wrapper
class PullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? backgroundColor;
  final Color? color;
  final double displacement;
  final double edgeOffset;

  const PullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.backgroundColor,
    this.color,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      color: color ?? theme.colorScheme.primary,
      displacement: displacement,
      edgeOffset: edgeOffset,
      strokeWidth: 2.5,
      child: child,
    );
  }
}

/// Custom refresh indicator with sync status
class SyncRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<bool> Function() onRefresh;
  final bool showSyncStatus;

  const SyncRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.showSyncStatus = true,
  });

  @override
  State<SyncRefreshIndicator> createState() => _SyncRefreshIndicatorState();
}

class _SyncRefreshIndicatorState extends State<SyncRefreshIndicator> {
  bool _lastSyncSuccess = true;
  DateTime? _lastSyncTime;

  Future<void> _handleRefresh() async {
    final success = await widget.onRefresh();
    if (mounted) {
      setState(() {
        _lastSyncSuccess = success;
        _lastSyncTime = DateTime.now();
      });

      if (widget.showSyncStatus) {
        _showSyncStatus(success);
      }
    }
  }

  void _showSyncStatus(bool success) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(success ? 'Synced successfully' : 'Sync failed'),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: widget.child,
    );
  }
}
