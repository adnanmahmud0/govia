import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/police/birds_eye/controller/police_birds_eye_controller.dart';

class PoliceBirdsEyeView extends GetView<PoliceBirdsEyeController> {
  const PoliceBirdsEyeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Back Navigation
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: const Color(0xFF1550A6),
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Title Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bird's Eye View",
                            style: GoogleFonts.inter(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4A4A4A),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Case #882-019-BRAVO • Complete Narrative Sync",
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8C8C8C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.snackbar(
                          'Add Feed',
                          'Action to add a new sync channel feed...',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFF1550A6),
                          colorText: Colors.white,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: const BoxDecoration(
                          color: Color(0xFF114FA8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Scrollable Feeds list
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  child: Column(
                    children: [
                      // Feed 1: Citizen Camera Feed
                      Obx(() => _buildFeedCard(
                            title: 'CITIZEN CAMERA FEED',
                            titleColor: const Color(0xFF8B5A2B),
                            icon: Icons.location_on_outlined,
                            imageAsset: 'assets/images/street_sunset.png',
                            isPlaying: controller.isPlaying1.value,
                            position: controller.position1.value,
                            totalDuration: controller.totalDuration1,
                            onPlayPauseTap: controller.togglePlay1,
                            onSliderChanged: (val) => controller.position1.value = val,
                          )),
                      SizedBox(height: 20.h),

                      // Feed 2: Integrated Bodycam
                      Obx(() => _buildFeedCard(
                            title: 'INTEGRATED BODYCAM',
                            titleColor: const Color(0xFF0F766E),
                            icon: Icons.videocam_outlined,
                            imageAsset: 'assets/images/onbordingImage1.png',
                            isPlaying: controller.isPlaying2.value,
                            position: controller.position2.value,
                            totalDuration: controller.totalDuration2,
                            onPlayPauseTap: controller.togglePlay2,
                            onSliderChanged: (val) => controller.position2.value = val,
                            isBodycam: true,
                          )),
                      SizedBox(height: 20.h),

                      // Feed 3: Live Call Session
                      Obx(() => _buildFeedCard(
                            title: 'LIVE CALL SESSION',
                            titleColor: const Color(0xFF8B5A2B),
                            icon: Icons.videocam_rounded,
                            imageAsset: 'assets/images/street_sunset.png',
                            isPlaying: controller.isPlaying3.value,
                            position: controller.position3.value,
                            totalDuration: controller.totalDuration3,
                            onPlayPauseTap: controller.togglePlay3,
                            onSliderChanged: (val) => controller.position3.value = val,
                          )),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard({
    required String title,
    required Color titleColor,
    required IconData icon,
    required String imageAsset,
    required bool isPlaying,
    required double position,
    required double totalDuration,
    required VoidCallback onPlayPauseTap,
    required ValueChanged<double> onSliderChanged,
    bool isBodycam = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle / Title Row
          Row(
            children: [
              Icon(
                icon,
                color: titleColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Mock Video Frame
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 160.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.asset(
                    imageAsset,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.image,
                        color: Colors.white30,
                        size: 48.sp,
                      ),
                    ),
                  ),
                ),
              ),
              if (isBodycam)
                Positioned(
                  bottom: 12.h,
                  left: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'CAM_02_AXON_782',
                      style: GoogleFonts.robotoMono(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Control Bar: Play/Pause, Slider, Time indicators
          Row(
            children: [
              // Play / Pause Icon
              GestureDetector(
                onTap: onPlayPauseTap,
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFF64748B),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 8.w),

              // Thin Custom Progress Bar (Slider)
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2.h,
                    activeTrackColor: isBodycam ? const Color(0xFF0F766E) : const Color(0xFF8B5A2B),
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    thumbColor: isBodycam ? const Color(0xFF0F766E) : const Color(0xFF8B5A2B),
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4.r),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 8.r),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: totalDuration,
                    value: position.clamp(0.0, totalDuration),
                    onChanged: onSliderChanged,
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // Time stamps
              Text(
                '${controller.formatTime(position)} / ${controller.formatTime(totalDuration)}',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
