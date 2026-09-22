import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/module/attorney/live_call/controller/attorney_live_call_controller.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_ambient_background.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_controls_bar.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_end_dialog.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_pip_view.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_qr_sheet.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_top_hud.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_waiting_presence.dart';

class AttorneyLiveCallView extends GetView<AttorneyLiveCallController> {
  const AttorneyLiveCallView({super.key});

  String get _currentRole {
    try {
      return AuthService.to.currentUser.value?.role?.toUpperCase() ?? 'ATTORNEY';
    } catch (_) {
      return 'ATTORNEY';
    }
  }

  bool get _isPolice => _currentRole == 'POLICE';
  bool get _isBailBondsman => _currentRole == 'BAIL_BONDSMAN';

  @override
  Widget build(BuildContext context) {
    final isPolice = _isPolice;
    final isBailBondsman = _isBailBondsman;

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
                // ─── 1. Remote Video Layer or Modern Waiting Presence ─────────
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
                              'The caller\'s phone is locked or minimized.\nLive audio call remains active and connected.',
                          roleBadge: 'Audio Active • Screen Locked',
                          centerIcon: Icons.phone_in_talk_rounded,
                          callerName: controller.remoteParticipantName.value,
                        ),
                      );
                    }

                    return MeetingAmbientBackground(
                      child: MeetingWaitingPresence(
                        title: 'Connected with ${controller.remoteParticipantName.value}',
                        subtitle: isPolice
                            ? 'LiveKit Encrypted Police Encounter\nSubscribed to incoming live audio & video feed.'
                            : isBailBondsman
                                ? 'LiveKit Encrypted Bail Consultation\nSubscribed to incoming live audio & video feed.'
                                : 'LiveKit Encrypted Legal Consultation\nSubscribed to incoming live audio & video feed.',
                        roleBadge: isPolice
                            ? 'Verified Law Enforcement'
                            : isBailBondsman
                                ? 'Verified Bail Bondsman'
                                : 'Verified Legal Counsel',
                        centerIcon: isPolice
                            ? Icons.local_police_rounded
                            : isBailBondsman
                                ? Icons.security_rounded
                                : Icons.gavel_rounded,
                        callerName: controller.remoteParticipantName.value,
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
                      liveLabel: isPolice
                          ? 'OFFICER LIVE'
                          : isBailBondsman
                              ? 'BONDSMAN LIVE'
                              : 'ATTORNEY LIVE',
                      isRecording: true,
                      isSpeakerOn: controller.isSpeakerOn.value,
                      onToggleSpeaker: () => controller.toggleSpeaker(),
                      onFlipCamera: () => controller.switchCamera(),
                    ),
                  ),
                ),

                // ─── 3. Local Camera Floating Picture-in-Picture ──────────────
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
                      label: isPolice
                          ? 'You (Officer)'
                          : isBailBondsman
                              ? 'You (Bail Agent)'
                              : 'You (Counsel)',
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
    final isPolice = _isPolice;
    final isBailBondsman = _isBailBondsman;

    MeetingEndDialog.show(
      title: isPolice
          ? 'Leave Incident Room?'
          : isBailBondsman
              ? 'Leave Bail Consultation?'
              : 'Leave Consultation?',
      message: isPolice
          ? 'You will exit the incident video room. The citizen encounter remains securely recorded.'
          : isBailBondsman
              ? 'You will exit the bail consultation room. The citizen encounter remains active.'
              : 'You will exit the video room. The citizen host incident remains active.',
      confirmLabel: 'Leave Session',
      onConfirmEnd: () => controller.leaveCall(),
    );
  }
}

