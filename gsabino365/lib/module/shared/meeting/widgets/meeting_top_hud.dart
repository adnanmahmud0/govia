import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glassmorphic floating top HUD for meetings.
class MeetingTopHud extends StatelessWidget {
  final String formattedTime;
  final String liveLabel;
  final bool isRecording;
  final bool? isSpeakerOn;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onFlipCamera;
  final VoidCallback? onMoreOptions;

  const MeetingTopHud({
    super.key,
    required this.formattedTime,
    this.liveLabel = 'SECURE LIVE',
    this.isRecording = true,
    this.isSpeakerOn,
    this.onToggleSpeaker,
    this.onFlipCamera,
    this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Live & Encryption Pill
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: isRecording
                        ? const Color(0xFFEF4444).withValues(alpha: 0.16)
                        : const Color(0xFF10B981).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isRecording
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : const Color(0xFF10B981).withValues(alpha: 0.4),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BreathingBeaconDot(
                        color: isRecording
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        liveLabel,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Monospace-Style Tabular Duration Counter
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fiber_manual_record_rounded,
                        size: 8.sp,
                        color: const Color(0xFF38BDF8),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        formattedTime,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Quick Action Buttons (Speaker, Flip, Options)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onToggleSpeaker != null && isSpeakerOn != null) ...[
                      _buildQuickIconButton(
                        icon: isSpeakerOn!
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        isActive: isSpeakerOn!,
                        onTap: onToggleSpeaker!,
                        tooltip: 'Speaker',
                      ),
                      SizedBox(width: 8.w),
                    ],
                    if (onFlipCamera != null) ...[
                      _buildQuickIconButton(
                        icon: Icons.flip_camera_ios_rounded,
                        isActive: true,
                        onTap: onFlipCamera!,
                        tooltip: 'Flip Camera',
                      ),
                    ],
                    if (onMoreOptions != null) ...[
                      SizedBox(width: 8.w),
                      _buildQuickIconButton(
                        icon: Icons.more_vert_rounded,
                        isActive: true,
                        onTap: onMoreOptions!,
                        tooltip: 'Options',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickIconButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          width: 34.r,
          height: 34.r,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.w,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.white60,
            size: 17.sp,
          ),
        ),
      ),
    );
  }
}

/// Gently breathing organic glowing beacon dot
class _BreathingBeaconDot extends StatefulWidget {
  final Color color;

  const _BreathingBeaconDot({required this.color});

  @override
  State<_BreathingBeaconDot> createState() => _BreathingBeaconDotState();
}

class _BreathingBeaconDotState extends State<_BreathingBeaconDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final scale = 0.85 + (_anim.value * 0.3);
        final glow = 0.3 + (_anim.value * 0.5);
        return Container(
          width: 7.r * scale,
          height: 7.r * scale,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: glow),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
