import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/doctore/dispatch/controller/doctor_request_community_controller.dart';

class DoctorRequestCommunityView
    extends GetView<DoctorRequestCommunityController> {
  const DoctorRequestCommunityView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Column(
            children: [
              // Light Premium App Bar
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
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.w,
                          ),
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
                          'Community Resources Map',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 36.w),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: const Color(0xFF64748B),
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => controller.updateSearchQuery(val),
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search shelter, kitchen, pantry...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12.h,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Categories Horizontal List
              SizedBox(
                height: 40.h,
                child: Obx(() {
                  final activeCat = controller.activeCategory.value;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    itemCount: controller.categories.length,
                    itemBuilder: (context, index) {
                      final cat = controller.categories[index];
                      final isSel = activeCat == cat;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: GestureDetector(
                          onTap: () => controller.selectCategory(cat),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF1550A6)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isSel
                                    ? Colors.transparent
                                    : const Color(0xFFE2E8F0),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(cat),
                                  size: 16.sp,
                                  color: isSel
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  cat,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSel
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              SizedBox(height: 16.h),

              // Map Stack with Pins and Detail Card
              Expanded(
                child: Stack(
                  children: [
                    // Mock Map Background
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.r),
                          topRight: Radius.circular(30.r),
                        ),
                        child: Image.asset(
                          'assets/images/community_map_mockup.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFE2E8F0),
                              child: Center(
                                child: Icon(
                                  Icons.map_outlined,
                                  size: 64.sp,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    Obx(() {
                      final resources = controller.filteredResources;
                      final selected = controller.selectedResource.value;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: resources.map((res) {
                              final isSel =
                                  selected != null &&
                                  selected['id'] == res['id'];
                              // Approximate offset adjustments to align the pointer tip on target coordinates
                              final xPos =
                                  (res['dx'] as double) * constraints.maxWidth -
                                  20.w;
                              final yPos =
                                  (res['dy'] as double) *
                                      constraints.maxHeight -
                                  40.h;
                              return Positioned(
                                left: xPos,
                                top: yPos,
                                child: GestureDetector(
                                  onTap: () =>
                                      controller.selectResourcePin(res),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Pin Icon Container
                                      Container(
                                        padding: EdgeInsets.all(8.r),
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? Colors.red
                                              : _getCategoryColor(
                                                  res['category'],
                                                ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.w,
                                          ),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(res['category']),
                                          color: Colors.white,
                                          size: 16.sp,
                                        ),
                                      ),
                                      // Little triangle pointer
                                      Container(
                                        width: 8.w,
                                        height: 8.h,
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? Colors.red
                                              : _getCategoryColor(
                                                  res['category'],
                                                ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    }),

                    // Bottom info card overlay
                    Positioned(
                      left: 20.w,
                      right: 20.w,
                      bottom: 20.h,
                      child: Obx(() {
                        final res = controller.selectedResource.value;
                        if (res == null) {
                          return Container(
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: const Color(0xFF1550A6),
                                  size: 18.sp,
                                ),
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Text(
                                    'Tap any pin on the map to view details',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          padding: EdgeInsets.all(18.r),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top details: category tag & distance
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(
                                        res['category'],
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      res['category'].toString().toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w800,
                                        color: _getCategoryColor(
                                          res['category'],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    res['distance'],
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),

                              // Name & Close
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      res['name'],
                                      style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        controller.selectedResource.value =
                                            null,
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: const Color(0xFF94A3B8),
                                      size: 20.sp,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),

                              // Address
                              Text(
                                res['address'],
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              SizedBox(height: 8.h),

                              // Description
                              Text(
                                res['details'],
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF334155),
                                  height: 1.3,
                                ),
                              ),
                              SizedBox(height: 12.h),

                              // Phone & Hours info
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: const Color(0xFF94A3B8),
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    res['hours'],
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.phone_outlined,
                                    color: const Color(0xFF94A3B8),
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    res['phone'],
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Get.snackbar(
                                          'Routing...',
                                          'Calculating directions to ${res['name']}',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: const Color(
                                            0xFF1550A6,
                                          ),
                                          colorText: Colors.white,
                                        );
                                      },
                                      icon: Icon(
                                        Icons.directions_rounded,
                                        size: 16.sp,
                                      ),
                                      label: const Text('Get Directions'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1550A6,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                        ),
                                        textStyle: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Get.snackbar(
                                          'Calling Resource',
                                          'Connecting call to ${res['phone']}',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: const Color(
                                            0xFF0F172A,
                                          ),
                                          colorText: Colors.white,
                                        );
                                      },
                                      icon: Icon(
                                        Icons.call_rounded,
                                        size: 16.sp,
                                      ),
                                      label: const Text('Call Facility'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF0F172A,
                                        ),
                                        side: BorderSide(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1.w,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                        ),
                                        textStyle: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Shelter':
        return Icons.night_shelter_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Clothing':
        return Icons.checkroom_outlined;
      case 'Church':
        return Icons.church_outlined;
      default:
        return Icons.grid_view_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Shelter':
        return const Color(0xFF10B981); // Green
      case 'Food':
        return const Color(0xFFF59E0B); // Orange/Amber
      case 'Clothing':
        return const Color(0xFF8B5CF6); // Purple
      case 'Church':
        return const Color(0xFF1550A6); // Blue
      default:
        return const Color(0xFF64748B);
    }
  }
}
