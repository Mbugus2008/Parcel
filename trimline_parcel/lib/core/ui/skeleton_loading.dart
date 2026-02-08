import 'package:flutter/material.dart';

/// Skeleton loading widget for shimmer effects
class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
    this.isCircle = false,
  });

  /// Creates a text line skeleton
  factory SkeletonLoading.text({double width = 100, double height = 14}) {
    return SkeletonLoading(width: width, height: height, borderRadius: 4);
  }

  /// Creates a circular avatar skeleton
  factory SkeletonLoading.avatar({double size = 40}) {
    return SkeletonLoading(width: size, height: size, isCircle: true);
  }

  /// Creates a rectangular card skeleton
  factory SkeletonLoading.card({double height = 100}) {
    return SkeletonLoading(height: height, borderRadius: 8);
  }

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                0.0,
                0.5 + (_animation.value * 0.25),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated builder helper
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

/// Skeleton for a parcel list item
class ParcelSkeletonItem extends StatelessWidget {
  const ParcelSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoading.avatar(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoading.text(width: 120, height: 16),
                    const SizedBox(height: 8),
                    SkeletonLoading.text(width: 180, height: 14),
                  ],
                ),
              ),
              const SkeletonLoading(width: 60, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          SkeletonLoading.text(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          SkeletonLoading.text(width: 200, height: 14),
        ],
      ),
    );
  }
}

/// Skeleton list for loading state
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
  });

  /// Creates a skeleton list for parcels
  factory SkeletonList.parcels({int itemCount = 5}) {
    return SkeletonList(
      itemCount: itemCount,
      itemBuilder: (context, index) => const ParcelSkeletonItem(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
