/// Empty state widgets for when no data is available
library;

import 'package:flutter/material.dart';

/// Generic empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
    this.iconSize = 64,
  });

  /// Empty state for no parcels
  factory EmptyState.noParcels({VoidCallback? onAddParcel}) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: 'No Parcels Yet',
      subtitle: 'Start by adding your first parcel',
      action: onAddParcel != null
          ? ElevatedButton.icon(
              onPressed: onAddParcel,
              icon: const Icon(Icons.add),
              label: const Text('Add Parcel'),
            )
          : null,
    );
  }

  /// Empty state for no search results
  factory EmptyState.noSearchResults({String? query, VoidCallback? onClear}) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      subtitle: query != null
          ? 'No parcels match "$query"'
          : 'Try adjusting your search',
      action: onClear != null
          ? TextButton(
              onPressed: onClear,
              child: const Text('Clear Search'),
            )
          : null,
    );
  }

  /// Empty state for filtered results
  factory EmptyState.noFilteredResults(
      {required String status, VoidCallback? onViewAll}) {
    return EmptyState(
      icon: Icons.filter_list_off,
      title: 'No $status Parcels',
      subtitle: 'There are no parcels with this status',
      action: onViewAll != null
          ? TextButton(
              onPressed: onViewAll,
              child: const Text('View All Parcels'),
            )
          : null,
    );
  }

  /// Empty state for network error
  factory EmptyState.networkError({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'No Connection',
      subtitle: 'Check your internet connection and try again',
      iconColor: Colors.orange,
      action: onRetry != null
          ? ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          : null,
    );
  }

  /// Empty state for error
  factory EmptyState.error({String? message, VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something Went Wrong',
      subtitle: message ?? 'An unexpected error occurred',
      iconColor: Colors.red,
      action: onRetry != null
          ? ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize + 32,
              height: iconSize + 32,
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.primary)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ??
                    theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline empty state for smaller spaces
class InlineEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  const InlineEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
