import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/module/citizen/live_call/controller/live_call_controller.dart';
import 'package:gsabino365/module/shared/meeting/widgets/meeting_ambient_background.dart';

class LiveCallConnectingView extends StatefulWidget {
  const LiveCallConnectingView({super.key});

  @override
  State<LiveCallConnectingView> createState() => _LiveCallConnectingViewState();
}

class _LiveCallConnectingViewState extends State<LiveCallConnectingView> {
  final LiveCallController controller = Get.find<LiveCallController>();
  bool _started = false;
  Worker? _sessionWorker;

  @override
  void initState() {
    super.initState();
    // Listen for session joined to navigate to live call view
    _sessionWorker = ever<bool>(controller.isSessionJoined, (joined) {
      if (joined && mounted) {
        if (Get.currentRoute != AppRoutes.citizenLiveCall) {
          Get.offNamed(AppRoutes.citizenLiveCall);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        _started = true;
        if (controller.isSessionJoined.value) {
          if (Get.currentRoute != AppRoutes.citizenLiveCall) {
            Get.offNamed(AppRoutes.citizenLiveCall);
          }
        } else if (controller.currentMeeting.value == null &&
            !controller.isLoading.value &&
            !controller.hasError.value) {
          controller.startGoviaMeeting();
        }
      }
    });
  }

  @override
  void dispose() {
    _sessionWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF070B14),
        body: SafeArea(
          child: Stack(
            children: [
              // 1. Ambient Background with Soft Lighting
              const Positioned.fill(
                child: MeetingAmbientBackground(),
              ),

              // 2. Top Navigation Bar (Frosted Back & Status Pill)
              Positioned(
                left: 20.w,
                right: 20.w,
                top: 12.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Frosted Back Pill
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Get.back(),
                            borderRadius: BorderRadius.circular(20.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  width: 1.w,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Cancel',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Secure Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: const Color(0xFF34D399),
                            size: 13.sp,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            '256-BIT ENCRYPTED',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6EE7B7),
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Center State (Radar Loading or Error)
              Center(
                child: Obx(() {
                  if (controller.hasError.value) {
                    return _buildErrorState(context);
                  }
                  return _buildModernLoadingState();
                }),
              ),

              // 4. Bottom Abort Action
              Positioned(
                bottom: 24.h,
                left: 32.w,
                right: 32.w,
                child: Obx(() {
                  if (controller.hasError.value) return const SizedBox.shrink();
                  return Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: TextButton.icon(
                          onPressed: () => Get.back(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: const Color(0xFFEF4444),
                            size: 18.sp,
                          ),
                          label: Text(
                            'Cancel Session Request',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFEF4444),
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 22.w,
                              vertical: 12.h,
                            ),
                            backgroundColor:
                                const Color(0xFFEF4444).withValues(alpha: 0.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.r),
                              side: BorderSide(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.28),
                                width: 1.w,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ambient Multi-Ring Radar Wave
          const _AmbientRadarWave(),

          SizedBox(height: 36.h),

          // Title
          Text(
            'Creating Your Secure\nGovia Session...',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),

          SizedBox(height: 12.h),

          // Reassuring Subtitle
          Text(
            'Initializing end-to-end encrypted WebRTC channel\nwith cloud incident recording active 🔴',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),

          SizedBox(height: 24.h),

          // Dynamic Status Pill
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
                SizedBox(
                  width: 12.r,
                  height: 12.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Waiting for live responder to pick up...',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                width: 1.5.w,
              ),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: const Color(0xFFEF4444),
              size: 36.sp,
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            'Unable to Connect',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10.h),
          Obx(
            () => Text(
              controller.errorMessage.value.isNotEmpty
                  ? controller.errorMessage.value
                  : 'A network error occurred while establishing the live video room.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 28.h),
          ElevatedButton.icon(
            onPressed: controller.retry,
            icon: Icon(Icons.refresh_rounded, size: 18.sp),
            label: Text(
              'Try Again',
              style: GoogleFonts.inter(
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              minimumSize: Size(180.w, 48.h),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              shadowColor: const Color(0xFF1D4ED8).withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Organic multi-ring radar wave animation
class _AmbientRadarWave extends StatefulWidget {
  const _AmbientRadarWave();

  @override
  State<_AmbientRadarWave> createState() => _AmbientRadarWaveState();
}

class _AmbientRadarWaveState extends State<_AmbientRadarWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
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
        return SizedBox(
          width: 190.r,
          height: 190.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildWaveRing(0),
              _buildWaveRing(1),
              _buildWaveRing(2),

              // Center Ambient Orb
              Container(
                width: 92.r,
                height: 92.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF0F172A),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.7),
                    width: 2.2.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.shield_rounded,
                    color: const Color(0xFF60A5FA),
                    size: 40.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaveRing(int index) {
    final progress = (_anim.value + (index * 0.33)) % 1.0;
    final size = 92.r + (progress * 90.r);
    final opacity = math.max(0.0, (1.0 - progress) * 0.3);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: opacity),
          width: 1.5.w,
        ),
        color: const Color(0xFF1D4ED8).withValues(alpha: opacity * 0.2),
      ),
    );
  }
}
