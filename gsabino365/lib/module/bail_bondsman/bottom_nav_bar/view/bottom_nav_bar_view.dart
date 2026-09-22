import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/bail_bondsman/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';
import 'package:gsabino365/module/bail_bondsman/home/view/bail_bondsman_home_view.dart';
import 'package:gsabino365/module/bail_bondsman/schedule/view/bail_bondsman_schedule_view.dart';
import 'package:gsabino365/module/bail_bondsman/notification/view/bail_bondsman_notification_view.dart';
import 'package:gsabino365/module/bail_bondsman/profile/view/bail_bondsman_profile_view.dart';

class BailBondsmanBottomNavBarView extends GetView<BailBondsmanBottomNavBarController> {
  const BailBondsmanBottomNavBarView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const BailBondsmanHomeView(),
      const BailBondsmanScheduleView(),
      const BailBondsmanNotificationView(),
      const BailBondsmanProfileView(),
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none_rounded),
                label: 'Notification',
              ),
              BottomNavigationBarItem(
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
