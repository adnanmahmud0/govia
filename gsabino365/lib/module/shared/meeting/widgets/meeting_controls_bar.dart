import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Ergonomic floating glass island bottom controls for meetings.
class MeetingControlsBar extends StatelessWidget {
  final bool isMuted;
  final bool isVideoMuted;
  final bool isSpeakerOn;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onEndCall;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onOptions;
  final VoidCallback? onShowQr;

  const MeetingControlsBar({
    super.key,
    required this.isMuted,
    required this.isVideoMuted,
    required this.isSpeakerOn,
    required this.onToggleMute,
    required this.onToggleVideo,
    required this.onToggleSpeaker,
    required this.onEndCall,
    this.onSwitchCamera,
    this.onOptions,
    this.onShowQr,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(40.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. Microphone Toggle
              _buildRoundAction(
                icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                isActive: !isMuted,
                activeColor: Colors.white.withValues(alpha: 0.16),
                inactiveColor: const Color(0xFFEF4444),
                onTap: onToggleMute,
                tooltip: isMuted ? 'Unmute' : 'Mute',
              ),

              // 2. Video Camera Toggle
              _buildRoundAction(
                icon: isVideoMuted
                    ? Icons.videocam_off_rounded
                    : Icons.videocam_rounded,
                isActive: !isVideoMuted,
                activeColor: Colors.white.withValues(alpha: 0.16),
                inactiveColor: const Color(0xFFEF4444),
                onTap: onToggleVideo,
                tooltip: isVideoMuted ? 'Start Video' : 'Stop Video',
              ),

              // 3. Centerpiece: End Call Button
              GestureDetector(
                onTap: onEndCall,
                child: Container(
                  width: 58.r,
                  height: 58.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEF4444),
                        Color(0xFFDC2626),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                ),
              ),

              // 4. Speaker Audio Toggle
              _buildRoundAction(
                icon: isSpeakerOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                isActive: isSpeakerOn,
                activeColor: Colors.white.withValues(alpha: 0.16),
                inactiveColor: const Color(0xFF64748B),
                onTap: onToggleSpeaker,
                tooltip: isSpeakerOn ? 'Speaker On' : 'Speaker Off',
              ),

              // 5. QR Code (show / scan to join meeting) — available to all
              if (onShowQr != null)
                _buildRoundAction(
                  icon: Icons.qr_code_rounded,
                  isActive: true,
                  activeColor: Colors.white.withValues(alpha: 0.12),
                  inactiveColor: Colors.white.withValues(alpha: 0.12),
                  onTap: onShowQr!,
                  tooltip: 'Meeting QR',
                ),

              // 6. Flip Camera or Options
              if (onSwitchCamera != null)
                _buildRoundAction(
                  icon: Icons.flip_camera_ios_rounded,
                  isActive: true,
                  activeColor: Colors.white.withValues(alpha: 0.12),
                  inactiveColor: Colors.white.withValues(alpha: 0.12),
                  onTap: onSwitchCamera!,
                  tooltip: 'Switch Camera',
                )
              else if (onOptions != null)
                _buildRoundAction(
                  icon: Icons.more_horiz_rounded,
                  isActive: true,
                  activeColor: Colors.white.withValues(alpha: 0.12),
                  inactiveColor: Colors.white.withValues(alpha: 0.12),
                  onTap: onOptions!,
                  tooltip: 'More Options',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundAction({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    final bool isAlert = !isActive && inactiveColor == const Color(0xFFEF4444);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25.r),
        child: Container(
          width: 48.r,
          height: 48.r,
          decoration: BoxDecoration(
            color: isAlert
                ? const Color(0xFFEF4444).withValues(alpha: 0.22)
                : (isActive
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.08)),
            shape: BoxShape.circle,
            border: Border.all(
              color: isAlert
                  ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.18),
              width: 1.w,
            ),
          ),
          child: Icon(
            icon,
            color: isAlert ? const Color(0xFFEF4444) : Colors.white,
            size: 22.sp,
          ),
        ),
      ),
    );
  }
}
