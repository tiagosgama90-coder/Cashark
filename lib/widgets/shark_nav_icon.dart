import 'package:flutter/material.dart';

/// Bottom-nav icon: always the Cashark shark mascot + a small role badge.
class SharkNavIcon extends StatelessWidget {
  final IconData badge;
  final bool selected;
  final Color badgeColor;

  const SharkNavIcon({
    super.key,
    required this.badge,
    required this.selected,
    this.badgeColor = const Color(0xFFFFC107),
  });

  @override
  Widget build(BuildContext context) {
    final size = selected ? 30.0 : 26.0;
    return SizedBox(
      width: 40,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.white54,
                width: selected ? 2.2 : 1.4,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/cashark_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Icon(badge, size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
