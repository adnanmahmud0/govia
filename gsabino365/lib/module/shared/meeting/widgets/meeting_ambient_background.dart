import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Ambient dark canvas for video/audio meetings with organic lighting and vignettes.
class MeetingAmbientBackground extends StatelessWidget {
  final Widget? child;

  const MeetingAmbientBackground({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Deep Midnight Base
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF070B14),
                Color(0xFF0B1222),
                Color(0xFF0F172A),
              ],
            ),
          ),
        ),

        // 2. Organic Radial Ambient Glows
        Positioned(
          top: -60.h,
          left: -40.w,
          child: Container(
            width: 280.r,
            height: 280.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1E40AF).withValues(alpha: 0.22),
                  const Color(0xFF1E40AF).withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100.h,
          right: -50.w,
          child: Container(
            width: 260.r,
            height: 260.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0D9488).withValues(alpha: 0.16),
                  const Color(0xFF0D9488).withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // 3. Child (Video Track or Placeholder)
        if (child != null) Positioned.fill(child: child!),

        // 4. Top Vignette Overlay for Crisp Floating HUD
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 140.h,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 5. Bottom Vignette Overlay for Crisp Floating Island Controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 180.h,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
