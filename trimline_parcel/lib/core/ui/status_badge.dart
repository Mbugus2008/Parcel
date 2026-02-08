import 'package:flutter/material.dart';

/// Status configuration for badges
class StatusConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final bool shouldPulse;

  const StatusConfig({
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.shouldPulse = false,
  });
}

/// Animated status badge widget
class StatusBadge extends StatefulWidget {
  final String status;
  final bool showIcon;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    final config = _getStatusConfig(widget.status);
    if (config.shouldPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      final config = _getStatusConfig(widget.status);
      if (config.shouldPulse) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return StatusConfig(
          backgroundColor: Colors.orange.shade100,
          textColor: Colors.orange.shade800,
          icon: Icons.schedule,
          shouldPulse: true,
        );
      case 'in_transit':
      case 'in transit':
        return StatusConfig(
          backgroundColor: Colors.blue.shade100,
          textColor: Colors.blue.shade800,
          icon: Icons.local_shipping,
          shouldPulse: true,
        );
      case 'delivered':
        return StatusConfig(
          backgroundColor: Colors.green.shade100,
          textColor: Colors.green.shade800,
          icon: Icons.check_circle,
        );
      case 'failed':
      case 'cancelled':
        return StatusConfig(
          backgroundColor: Colors.red.shade100,
          textColor: Colors.red.shade800,
          icon: Icons.error,
        );
      case 'returned':
        return StatusConfig(
          backgroundColor: Colors.purple.shade100,
          textColor: Colors.purple.shade800,
          icon: Icons.replay,
        );
      case 'processing':
        return StatusConfig(
          backgroundColor: Colors.amber.shade100,
          textColor: Colors.amber.shade800,
          icon: Icons.autorenew,
          shouldPulse: true,
        );
      default:
        return StatusConfig(
          backgroundColor: Colors.grey.shade200,
          textColor: Colors.grey.shade700,
          icon: Icons.info_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(widget.status);

    Widget badge = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon && config.icon != null) ...[
            Icon(
              config.icon,
              size: widget.fontSize + 2,
              color: config.textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _formatStatus(widget.status),
            style: TextStyle(
              color: config.textColor,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (config.shouldPulse) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: badge,
      );
    }

    return badge;
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}

/// Mini status indicator (just a colored dot)
class StatusIndicator extends StatelessWidget {
  final String status;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 8,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_transit':
      case 'in transit':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      case 'returned':
        return Colors.purple;
      case 'processing':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        shape: BoxShape.circle,
      ),
    );
  }
}
