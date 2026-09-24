import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/module/doctore/active_sessions/controller/doctor_live_call_controller.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_ambient_background.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_controls_bar.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_end_dialog.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_pip_view.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_qr_sheet.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_top_hud.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_waiting_presence.dart';

class DoctorLiveCallView extends GetView<DoctorLiveCallController> {
  const DoctorLiveCallView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showEndCallDialog();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF070B14),
          body: Stack(
            children: [
              // ─── 1. Ambient Background & Remote Participant Video Stream ────
              Positioned.fill(
                child: Obx(() {
                  final remoteTrack = controller.remoteVideoTrack.value;
                  if (remoteTrack != null) {
                    return MeetingAmbientBackground(
                      child: VideoTrackRenderer(
                        remoteTrack,
                        fit: VideoViewFit.cover,
                      ),
                    );
                  }

                  if (controller.isRemotePhoneLocked.value) {
                    return MeetingAmbientBackground(
                      child: MeetingWaitingPresence(
                        title: '${controller.remoteParticipantName.value} (Audio-Only)',
                        subtitle:
                            'The patient\'s phone is locked or minimized.\nLive encrypted audio call remains active.',
                        roleBadge: 'Audio Active • Screen Locked',
                        centerIcon: Icons.phone_in_talk_rounded,
                        callerName: controller.remoteParticipantName.value,
                      ),
                    );
                  }

                  return MeetingAmbientBackground(
                    child: MeetingWaitingPresence(
                      title: 'Connected with ${controller.remoteParticipantName.value}',
                      subtitle:
                          'LiveKit Encrypted Medical Consultation\nSubscribed to incoming live audio & video feed.',
                      roleBadge: 'Verified Patient Encounter',
                      centerIcon: Icons.medical_services_rounded,
                      callerName: controller.remoteParticipantName.value,
                    ),
                  );
                }),
              ),

              // ─── 2. Safe Area Foreground Elements ───────────────────────────
              SafeArea(
                child: Stack(
                  children: [
                    // Top Glassmorphic Floating Island HUD
                    Positioned(
                      top: 4.h,
                      left: 0,
                      right: 0,
                      child: Obx(
                        () => MeetingTopHud(
                          formattedTime: controller.formattedTime,
                          liveLabel: 'MEDICAL LIVE',
                          isRecording: true,
                          isSpeakerOn: controller.isSpeakerOn.value,
                          onToggleSpeaker: () => controller.toggleSpeaker(),
                          onFlipCamera: () => controller.switchCamera(),
                          onMoreOptions: () => _showCallOptions(),
                        ),
                      ),
                    ),

                    // Floating Picture-in-Picture Local Camera Preview (Doctor)
                    Positioned(
                      top: 72.h,
                      right: 16.w,
                      child: Obx(() {
                        final localTrack = controller.localVideoTrack.value;
                        final isMuted = controller.isVideoMuted.value;
                        if (localTrack == null && !isMuted) {
                          return const SizedBox.shrink();
                        }

                        return MeetingPipView(
                          localTrack: localTrack,
                          isVideoMuted: isMuted,
                          label: 'You (Doctor)',
                          onFlipCamera: () => controller.switchCamera(),
                        );
                      }),
                    ),

                    // Centered Frosted License Pill
                    Positioned(
                      bottom: 96.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1.w,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7.r,
                                    height: 7.r,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Obx(() => Text(
                                    controller.licenseText.value,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5.sp,
                                      letterSpacing: 0.5,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Ergonomic Floating Bottom Controls Island
                    Positioned(
                      bottom: 20.h,
                      left: 18.w,
                      right: 18.w,
                      child: Obx(
                        () => MeetingControlsBar(
                          isMuted: controller.isMuted.value,
                          isVideoMuted: controller.isVideoMuted.value,
                          isSpeakerOn: controller.isSpeakerOn.value,
                          onToggleMute: () => controller.toggleMute(),
                          onToggleVideo: () => controller.toggleVideo(),
                          onToggleSpeaker: () => controller.toggleSpeaker(),
                          onSwitchCamera: () => controller.switchCamera(),
                          onOptions: () => _showCallOptions(),
                          onEndCall: () => _showEndCallDialog(),
                          onShowQr: () => MeetingQrSheet.show(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCallOptions() {
    Get.bottomSheet(
      ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26.r),
          topRight: Radius.circular(26.r),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.95),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(26.r),
                topRight: Radius.circular(26.r),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.w,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Consultation Options',
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(AppRoutes.doctorTransferSession);
                  },
                  icon: const Icon(
                    Icons.swap_calls_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    'Handoff Call / Transfer',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14.5.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'Dismiss',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEndCallDialog() {
    MeetingEndDialog.show(
      title: 'Conclude Medical Session?',
      message:
          'The active medical consultation will terminate. Session records will be stored with patient encounter notes.',
      confirmLabel: 'Leave Session',
      onConfirmEnd: () => controller.endCall(),
    );
  }
}
