import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/module/citizen/live_call/controller/live_call_controller.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_ambient_background.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_controls_bar.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_end_dialog.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_pip_view.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_qr_sheet.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_top_hud.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_waiting_presence.dart';

class LiveCallView extends StatefulWidget {
  const LiveCallView({super.key});

  @override
  State<LiveCallView> createState() => _LiveCallViewState();
}

class _LiveCallViewState extends State<LiveCallView> {
  final LiveCallController controller = Get.find<LiveCallController>();

  @override
  Widget build(BuildContext context) {
    String? userName;
    if (Get.isRegistered<AuthService>()) {
      userName = Get.find<AuthService>().currentUser.value?.name;
    }

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
          body: SafeArea(
            child: Stack(
              children: [
                // ─── 1. Ambient Background & Remote Video Stream ──────────────
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
                      final name = controller.remoteParticipantName.value.isNotEmpty
                          ? controller.remoteParticipantName.value
                          : 'Responder';
                      return MeetingAmbientBackground(
                        child: MeetingWaitingPresence(
                          title: '$name (Audio-Only)',
                          subtitle:
                              'The other party\'s phone is locked or minimized.\nLive audio call remains active and connected.',
                          roleBadge: 'Audio Active • Screen Locked',
                          centerIcon: Icons.phone_in_talk_rounded,
                          callerName: userName,
                        ),
                      );
                    }

                    // Modern Organic Waiting / Audio-Only Presence
                    return MeetingAmbientBackground(
                      child: MeetingWaitingPresence(
                        title: 'Connecting with Responder...',
                        subtitle:
                            'Govia consultation is end-to-end encrypted.\nAudio and video will stream as soon as responder connects.',
                        roleBadge: 'Verified Incident Responder',
                        centerIcon: Icons.shield_rounded,
                        callerName: userName,
                      ),
                    );
                  }),
                ),

                // ─── 2. Glassmorphic Floating Top HUD ─────────────────────────
                Positioned(
                  top: 4.h,
                  left: 0,
                  right: 0,
                  child: Obx(
                    () => MeetingTopHud(
                      formattedTime: controller.formattedTime,
                      liveLabel: controller.isHost.value ? 'HOST • LIVE' : 'SECURE LIVE',
                      isRecording: controller.isRecording.value,
                      isSpeakerOn: controller.isSpeakerOn.value,
                      onToggleSpeaker: () => controller.toggleSpeaker(),
                      onFlipCamera: () => controller.switchCamera(),
                    ),
                  ),
                ),

                // ─── 2.5 Live Location Floating Pill (host-only, Interactive Google Maps) ──
                Positioned(
                  top: 72.h,
                  left: 16.w,
                  child: Obx(() {
                    // Only the host can see the location pill — guests must not
                    // see the host's GPS coordinates.
                    if (!controller.isHost.value || !controller.hasLiveLocation) {
                      return const SizedBox.shrink();
                    }
                    final locationText = controller.currentLocationText;
                    return GestureDetector(
                      onTap: () => controller.openLiveGoogleMaps(),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                            width: 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.r,
                              height: 8.r,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.location_on_rounded,
                              size: 13.sp,
                              color: const Color(0xFF38BDF8),
                            ),
                            SizedBox(width: 4.w),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 160.w),
                              child: Text(
                                locationText.isNotEmpty ? locationText : 'Live GPS Active',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Maps ↗',
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),

                // ─── 3. Floating Picture-in-Picture Local Camera Preview ──────
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
                      label: 'You',
                      onFlipCamera: () => controller.switchCamera(),
                    );
                  }),
                ),

                // ─── 4. Ergonomic Floating Glass Controls Island ──────────────
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
                      onEndCall: () => _showEndCallDialog(),
                      onShowQr: () => MeetingQrSheet.show(context),
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
    final isHost = controller.isHost.value;
    MeetingEndDialog.show(
      title: isHost ? 'End Session for Everyone?' : 'Leave Govia Session?',
      message: isHost
          ? 'Ending the session will conclude the meeting and save recordings to your Vault.'
          : 'You will leave the session. The meeting and recording will continue for the host and other participants.',
      confirmLabel: isHost ? 'End for Everyone' : 'Leave Meeting',
      onConfirmEnd: () => isHost ? controller.endMeeting() : controller.leaveMeeting(),
      // "Leave Temporarily" removed — host must explicitly end for everyone.
    );
  }
}
