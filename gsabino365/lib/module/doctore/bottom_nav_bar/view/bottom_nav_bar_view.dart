import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/doctore/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';
import 'package:gsabino365/module/doctore/home/view/doctor_home_view.dart';
import 'package:gsabino365/module/doctore/schedule/view/doctor_schedule_view.dart';
import 'package:gsabino365/module/doctore/notification/controller/doctor_notification_controller.dart';
import 'package:gsabino365/module/doctore/notification/view/doctor_notification_view.dart';
import 'package:gsabino365/module/doctore/profile/view/doctor_profile_view.dart';

class DoctorBottomNavBarView extends GetView<DoctorBottomNavBarController> {
  const DoctorBottomNavBarView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DoctorHomeView(),
      const DoctorScheduleView(),
      const DoctorNotificationView(),
      const DoctorProfileView(),
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
                icon: Builder(
                  builder: (context) {
                    int unread = 0;
                    if (Get.isRegistered<DoctorNotificationController>()) {
                      unread = Get.find<DoctorNotificationController>().unreadCount;
                    }
                    if (unread > 0) {
                      return Badge(
                        label: Text(
                          '$unread',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        child: const Icon(Icons.notifications_none_rounded),
                      );
                    }
                    return const Icon(Icons.notifications_none_rounded);
                  },
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

