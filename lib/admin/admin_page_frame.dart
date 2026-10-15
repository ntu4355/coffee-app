import 'package:flutter/material.dart';

class AdminPageFrame extends StatelessWidget {
  const AdminPageFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const coffeeBrown = Color(0xFF6B4F35);
    const panelBackground = Color(0xFFf4eee3);

    return ColoredBox(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final panelRadius = isWide
              ? BorderRadius.circular(24)
              : BorderRadius.zero;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: panelBackground,
                    borderRadius: panelRadius,
                    boxShadow: isWide
                        ? [
                            BoxShadow(
                              color: coffeeBrown.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(borderRadius: panelRadius, child: child),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
