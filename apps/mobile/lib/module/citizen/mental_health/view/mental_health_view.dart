import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/module/citizen/mental_health/controller/mental_health_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class MentalHealthView extends GetView<MentalHealthController> {
  const MentalHealthView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Custom Blue App Bar Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1550A6),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 16.w,
                right: 20.w,
                top: MediaQuery.of(context).padding.top + 12.h,
                bottom: 20.h,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mental Health Services',
                              style: GoogleFonts.outfit(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Licensed Support & Crisis Counseling',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // Search Input
                  Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.w,
                      ),
                    ),
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: (val) => controller.searchQuery.value = val,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: 'Search specialists, trauma, anxiety...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.75),
                          size: 20.sp,
                        ),
                        suffixIcon: Obx(() {
                          if (controller.searchQuery.value.isNotEmpty) {
                            return IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 18),
                              onPressed: () {
                                controller.searchController.clear();
                                controller.searchQuery.value = '';
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Filter Pills
            Container(
              height: 52.h,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: controller.categories.length,
                separatorBuilder: (_, _) => SizedBox(width: 8.w),
                itemBuilder: (ctx, idx) {
                  final cat = controller.categories[idx];
                  return Obx(() {
                    final isSel = controller.selectedCategory.value == cat;
                    return InkWell(
                      onTap: () => controller.selectedCategory.value = cat,
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF1550A6) : Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSel ? const Color(0xFF1550A6) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1550A6).withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),

            // Main Doctor Feed
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF1550A6),
                onRefresh: () => controller.fetchDoctors(),
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  children: [
                    // Emergency Crisis Hotline Banner
                    _buildCrisisBanner(),
                    SizedBox(height: 16.h),

                    // Section Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Specialists',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.filteredDoctors.length} found',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Specialists Cards
                    Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: Color(0xFF1550A6)),
                          ),
                        );
                      }

                      final list = controller.filteredDoctors;
                      if (list.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Column(
                            children: [
                              Icon(Icons.person_off_rounded, size: 48.sp, color: Colors.grey.shade400),
                              SizedBox(height: 12.h),
                              Text(
                                'No specialists match your criteria',
                                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Try clearing your search or switching category filters',
                                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => SizedBox(height: 14.h),
                        itemBuilder: (ctx, idx) => _buildDoctorCard(list[idx]),
                      );
                    }),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrisisBanner() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24/7 Suicide & Crisis Lifeline',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Free, confidential support available anytime.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFB91C1C),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () async {
              final uri = Uri.parse('tel:988');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Text(
              'Call 988',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final name = doctor['name']?.toString() ?? 'Specialist';
    final title = doctor['title']?.toString() ?? 'Counselor';
    final specialty = doctor['specialty']?.toString() ?? 'Mental Health';
    final hospital = doctor['hospital']?.toString() ?? 'Health Network';
    final rating = (doctor['rating'] as num?)?.toDouble() ?? 4.8;
    final reviewCount = (doctor['reviewCount'] as num?)?.toInt() ?? 50;
    final isOnline = doctor['isOnline'] == true;
    final bio = doctor['bio']?.toString() ?? '';
    final rawImg = doctor['image']?.toString() ?? doctor['profilePicture']?.toString();
    final imgUrl = (rawImg != null && rawImg.isNotEmpty) ? ApiConstants.getFileUrl(rawImg) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: const Color(0xFF1550A6).withValues(alpha: 0.1),
                    backgroundImage: (imgUrl != null && imgUrl.isNotEmpty) ? NetworkImage(imgUrl) : null,
                    child: (imgUrl == null || imgUrl.isEmpty)
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'D',
                            style: GoogleFonts.outfit(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1550A6),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13.r,
                      height: 13.r,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.w),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : const Color(0xFF64748B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            isOnline ? 'ONLINE' : 'OFFLINE',
                            style: GoogleFonts.inter(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w700,
                              color: isOnline ? const Color(0xFF059669) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: const Color(0xFFF59E0B), size: 16.sp),
                        SizedBox(width: 3.w),
                        Text(
                          '$rating ($reviewCount reviews)',
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text('•', style: TextStyle(color: Colors.grey.shade400)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            hospital,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (specialty.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1550A6).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          specialty,
                          style: GoogleFonts.inter(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1550A6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (bio.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5.sp,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ],

          SizedBox(height: 14.h),

          // Action Button: Message (Citizen connects directly via chat; doctor schedules in chat)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1550A6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(vertical: 11.h),
              ),
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 17.sp),
              label: Text(
                'Message',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.sp),
              ),
              onPressed: () => controller.openChatWithDoctor(doctor),
            ),
          ),
        ],
      ),
    );
  }
}
