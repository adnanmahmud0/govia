import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/attorney/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';
import 'package:gsabino365/module/attorney/home/view/attorney_home_view.dart';
import 'package:gsabino365/module/attorney/schedule/view/attorney_schedule_view.dart';
import 'package:gsabino365/module/attorney/notification/view/attorney_notification_view.dart';
import 'package:gsabino365/module/attorney/profile/view/attorney_profile_view.dart';

class AttorneyBottomNavBarView extends GetView<AttorneyBottomNavBarController> {
  const AttorneyBottomNavBarView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const AttorneyHomeView(),
      const AttorneyScheduleView(),
      const AttorneyNotificationView(),
      const AttorneyProfileView(),
    ];

    return Obx(() {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: screens[controller.selectedIndex.value],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            onTap: controller.changeTabIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1550A6),
            unselectedItemColor: const Color(0xFF5F6E80),
            selectedLabelStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded),
                    if (controller.unreadNotificationsCount > 0)
                      Positioned(
                        top: -3.h,
                        right: -4.w,
                        child: Container(
                          padding: EdgeInsets.all(3.5.r),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 14.r,
                            minHeight: 14.r,
                          ),
                          child: Center(
                            child: Text(
                              controller.unreadNotificationsCount > 99
                                  ? '99+'
                                  : '${controller.unreadNotificationsCount}',
                              style: GoogleFonts.inter(
                                fontSize: 8.5.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_rounded),
                    if (controller.unreadNotificationsCount > 0)
                      Positioned(
                        top: -3.h,
                        right: -4.w,
                        child: Container(
                          padding: EdgeInsets.all(3.5.r),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 14.r,
                            minHeight: 14.r,
                          ),
                          child: Center(
                            child: Text(
                              controller.unreadNotificationsCount > 99
                                  ? '99+'
                                  : '${controller.unreadNotificationsCount}',
                              style: GoogleFonts.inter(
                                fontSize: 8.5.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Notification',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      );
    });
  }
}
