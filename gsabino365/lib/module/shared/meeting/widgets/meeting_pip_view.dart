import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:livekit_client/livekit_client.dart';

/// Modern squircle Picture-in-Picture floating local camera tile.
class MeetingPipView extends StatelessWidget {
  final VideoTrack? localTrack;
  final bool isVideoMuted;
  final String label;
  final VoidCallback? onFlipCamera;
  final VoidCallback? onTap;

  const MeetingPipView({
    super.key,
    required this.localTrack,
    required this.isVideoMuted,
    this.label = 'You',
    this.onFlipCamera,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108.w,
        height: 152.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.5.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Content: Video renderer OR Camera Off State
              if (isVideoMuted || localTrack == null)
                _buildCameraOffState()
              else
                VideoTrackRenderer(
                  localTrack!,
                  fit: VideoViewFit.cover,
                  mirrorMode: VideoViewMirrorMode.mirror,
                ),

              // 2. Subtle Vignette at Bottom for Badge Readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 48.h,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Frosted "You" Micro-Pill
              Positioned(
                bottom: 8.h,
                left: 8.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 0.8.w,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5.r,
                            height: 5.r,
                            decoration: BoxDecoration(
                              color: isVideoMuted
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Quick Camera Flip Micro-Button (Top-Right)
              if (onFlipCamera != null && !isVideoMuted && localTrack != null)
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: GestureDetector(
                    onTap: onFlipCamera,
                    child: Container(
                      width: 28.r,
                      height: 28.r,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.w,
                        ),
                      ),
                      child: Icon(
                        Icons.flip_camera_ios_rounded,
                        color: Colors.white,
                        size: 14.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOffState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  width: 1.w,
                ),
              ),
              child: Icon(
                Icons.videocam_off_rounded,
                color: const Color(0xFFEF4444),
                size: 20.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Camera Off',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
