import 'package:flutter/material.dart';

/// A gradient summary card for displaying statistics
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(
                    icon,
                    size: 32,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Predefined gradient colors for summary cards
class SummaryCardGradients {
  static const pending = [Color(0xFFf093fb), Color(0xFFf5576c)];
  static const transit = [Color(0xFF4facfe), Color(0xFF00f2fe)];
  static const delivered = [Color(0xFF43e97b), Color(0xFF38f9d7)];
  static const today = [Color(0xFFfa709a), Color(0xFFfee140)];
  static const total = [Color(0xFF667eea), Color(0xFF764ba2)];
  static const returned = [Color(0xFFff6b6b), Color(0xFFee5a5a)];
}
