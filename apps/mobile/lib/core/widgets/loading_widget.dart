import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ===================== PREMIUM LOADING WIDGET =====================
/// A modern, high-end loading indicator with smooth animations.
class LoadingWidget extends StatefulWidget {
  final String? message;
  final Color? color;
  final double? size;
  final bool isLinear;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size,
    this.isLinear = false,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? Theme.of(context).primaryColor;
    final secondaryColor = primaryColor.withValues(alpha: 0.2);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLinear)
            _buildPremiumLinear(primaryColor, secondaryColor)
          else
            _buildPremiumCircular(primaryColor, secondaryColor),

          if (widget.message != null) ...[
            SizedBox(height: 24.h),
            _buildAnimatedText(widget.message!, primaryColor),
          ],
        ],
      ),
    );
  }

  // ──────────────────── CIRCULAR DESIGN (IPHONE STYLE) ────────────────────
  Widget _buildPremiumCircular(Color primary, Color secondary) {
    final double size = widget.size ?? 50.sp;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                // Background Track
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 4.w,
                    color: secondary,
                  ),
                ),
                // Glowing Head
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: 0.3,
                    strokeWidth: 4.w,
                    strokeCap: StrokeCap.round,
                    color: primary,
                  ),
                ),
                // Inner Shine
                // Center(
                //   child: Container(
                //     width: size * 0.7,
                //     height: size * 0.7,
                //     decoration: BoxDecoration(
                //       shape: BoxShape.circle,
                //       gradient: RadialGradient(
                //         colors: [primary.withValues(alpha: 0.15), Colors.transparent],
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────── LINEAR DESIGN (MODERN BAR) ────────────────────
  Widget _buildPremiumLinear(Color primary, Color secondary) {
    return Container(
      width: 240.w,
      height: 8.h,
      decoration: BoxDecoration(
        color: secondary,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  left: -100.w + (_controller.value * 340.w),
                  child: Container(
                    width: 100.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary.withValues(alpha: .005),
                          primary,
                          primary.withValues(alpha: .005),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ──────────────────── ANIMATED TEXT ────────────────────
  Widget _buildAnimatedText(String text, Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.5 + (math.sin(_controller.value * math.pi) * 0.5);
        return Opacity(
          opacity: opacity,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: color,
            ),
          ),
        );
      },
    );
  }
}
