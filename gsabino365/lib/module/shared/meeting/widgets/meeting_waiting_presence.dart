import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern organic waiting & audio-only participant card with breathing aura ripples.
class MeetingWaitingPresence extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? participantName;
  final String? roleBadge;
  final IconData centerIcon;
  final String? callerName;

  const MeetingWaitingPresence({
    super.key,
    this.title = 'Connecting with Responder...',
    this.subtitle =
        'Live consultation is end-to-end encrypted.\nAudio and video will appear as soon as responder joins.',
    this.participantName,
    this.roleBadge,
    this.centerIcon = Icons.shield_rounded,
    this.callerName,
  });

  @override
  State<MeetingWaitingPresence> createState() => _MeetingWaitingPresenceState();
}

class _MeetingWaitingPresenceState extends State<MeetingWaitingPresence>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _equalizerController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _equalizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ─── 1. Multi-Ring Concentric Breathing Aura ─────────────────────
            SizedBox(
              width: 170.r,
              height: 170.r,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildRippleRing(index: 0),
                  _buildRippleRing(index: 1),
                  _buildRippleRing(index: 2),

                  // Center Glowing Avatar Emblem
                  Container(
                    width: 96.r,
                    height: 96.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF1E3A8A),
                          Color(0xFF0F172A),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                        width: 2.2.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.centerIcon,
                        color: const Color(0xFF60A5FA),
                        size: 42.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // ─── 2. Animated Voice Equalizer Bars ─────────────────────────────
            _buildEqualizer(),

            SizedBox(height: 20.h),

            // ─── 3. Participant Role / Verified Badge ─────────────────────────
            if (widget.roleBadge != null && widget.roleBadge!.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: const Color(0xFF34D399),
                      size: 13.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      widget.roleBadge!,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6EE7B7),
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // ─── 4. Title Typography ──────────────────────────────────────────
            Text(
              widget.participantName != null && widget.participantName!.isNotEmpty
                  ? widget.participantName!
                  : widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),

            SizedBox(height: 8.h),

            // ─── 5. Reassurance Subtitle ──────────────────────────────────────
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 12.5.sp,
                height: 1.5,
              ),
            ),

            // ─── 6. Caller Identity Tag ───────────────────────────────────────
            if (widget.callerName != null && widget.callerName!.isNotEmpty) ...[
              SizedBox(height: 18.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Caller: ${widget.callerName!}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFCBD5E1),
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRippleRing({required int index}) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        final progress = (_rippleController.value + (index * 0.33)) % 1.0;
        final size = 96.r + (progress * 70.r);
        final opacity = math.max(0.0, (1.0 - progress) * 0.28);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: opacity),
              width: 1.5.w,
            ),
            color: const Color(0xFF1D4ED8).withValues(alpha: opacity * 0.3),
          ),
        );
      },
    );
  }

  Widget _buildEqualizer() {
    return AnimatedBuilder(
      animation: _equalizerController,
      builder: (context, child) {
        final v = _equalizerController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBar(height: 8.h + (math.sin(v * math.pi) * 8.h)),
            SizedBox(width: 4.w),
            _buildBar(height: 14.h + (math.cos(v * math.pi) * 10.h)),
            SizedBox(width: 4.w),
            _buildBar(height: 18.h + (math.sin((v + 0.5) * math.pi) * 12.h)),
            SizedBox(width: 4.w),
            _buildBar(height: 12.h + (math.cos((v + 0.3) * math.pi) * 8.h)),
            SizedBox(width: 4.w),
            _buildBar(height: 7.h + (math.sin(v * math.pi * 1.5) * 6.h)),
          ],
        );
      },
    );
  }

  Widget _buildBar({required double height}) {
    return Container(
      width: 3.5.w,
      height: height.clamp(4.0, 30.0),
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}
