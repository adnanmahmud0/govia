import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/bail_bondsman/history/controller/bail_bondsman_history_controller.dart';

class BailBondsmanHistoryView extends GetView<BailBondsmanHistoryController> {
  const BailBondsmanHistoryView({super.key});

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
              // Custom Light App Bar
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
                    Expanded(
                      child: Center(
                        child: Text(
                          'Encounter History',
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1550A6),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 36.w),
                  ],
                ),
              ),

              // Video Player Box
              Obx(() {
                if (controller.recordings.isEmpty) {
                  return const SizedBox.shrink();
                }

                final currentVideo = controller.recordings[controller.selectedIndex.value];
                final maxDuration = (currentVideo['durationSeconds'] as double?) ?? 300.0;

                return Container(
                  width: double.infinity,
                  height: 220.h,
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Video Poster Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Image.asset(
                          'assets/images/street_sunset.png',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFF0F172A),
                            child: const Center(
                              child: Icon(Icons.videocam_rounded, color: Colors.white30, size: 50),
                            ),
                          ),
                        ),
                      ),

                      // Dark overlay for controls readability
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),

                      // REC Pill overlay (top-left)
                      Positioned(
                        top: 16.h,
                        left: 16.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.r,
                                height: 8.r,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'REC ${currentVideo['recTime']}',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Progress Bar & Controls Column (bottom)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            // Progress bar
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3.h,
                                activeTrackColor: const Color(0xFF2563EB),
                                inactiveTrackColor: Colors.white24,
                                thumbColor: const Color(0xFF2563EB),
                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                                overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
                                overlayColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                min: 0.0,
                                max: maxDuration,
                                value: controller.currentPosition.value.clamp(0.0, maxDuration),
                                onChanged: (value) {
                                  controller.currentPosition.value = value;
                                },
                              ),
                            ),

                            // Control buttons row
                            Padding(
                              padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h, top: 4.h),
                              child: Row(
                              children: [
                                // Play/Pause icon
                                GestureDetector(
                                  onTap: () => controller.togglePlay(),
                                  child: Icon(
                                    controller.isPlaying.value
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 26.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),

                                // Timestamp
                                Text(
                                  '${controller.formatTime(controller.currentPosition.value)} / ${currentVideo['duration']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),

                                const Spacer(),

                                // Volume toggle
                                GestureDetector(
                                  onTap: () => controller.toggleMute(),
                                  child: Icon(
                                    controller.isMuted.value
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    color: Colors.white,
                                    size: 22.sp,
                                  ),
                                ),
                                SizedBox(width: 16.w),

                                // Copy Recording Link
                                GestureDetector(
                                  onTap: controller.copyRecordingUrl,
                                  child: Icon(
                                    Icons.link_rounded,
                                    color: Colors.white,
                                    size: 22.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 20.h),

            // History Section Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                'Recordings History',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Scrollable Recordings List
            Expanded(
              child: Obx(() {
                if (controller.recordings.isEmpty) {
                  return Center(
                    child: Text(
                      'No recorded encounters available.',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF1550A6),
                  onRefresh: () => controller.loadHistory(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                    itemCount: controller.recordings.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final item = controller.recordings[index];
                      final isSelected = controller.selectedIndex.value == index;
                      return GestureDetector(
                        onTap: () => controller.selectVideo(index),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE2E8F0),
                              width: 1.5.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.01),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10.r),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_circle_outline_rounded,
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF64748B),
                                      size: 22.sp,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),

                                  // Text details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          '${item['date']} • ${item['size']}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.sp,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Duration text badge
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      item['duration'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item['notes'] != null) ...[
                                SizedBox(height: 12.h),
                                const Divider(color: Color(0xFFF1F5F9), height: 1),
                                SizedBox(height: 12.h),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      color: const Color(0xFF1550A6),
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        item['notes'] as String,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          color: const Color(0xFF475569),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
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
}
