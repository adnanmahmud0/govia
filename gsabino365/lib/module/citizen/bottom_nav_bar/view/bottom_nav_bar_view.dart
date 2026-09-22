import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/citizen/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';
import 'package:gsabino365/module/citizen/home/view/citizen_home_view.dart';
import 'package:gsabino365/module/citizen/schedule/view/citizen_schedule_view.dart';
import 'package:gsabino365/module/citizen/community/view/citizen_community_view.dart';
import 'package:gsabino365/module/citizen/vault/view/citizen_vault_view.dart';
import 'package:gsabino365/module/citizen/profile/view/citizen_profile_view.dart';

class CitizenBottomNavBarView extends GetView<CitizenBottomNavBarController> {
  const CitizenBottomNavBarView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const CitizenHomeView(),
      const CitizenScheduleView(),
      const CitizenCommunityView(),
      const CitizenVaultView(),
      const CitizenProfileView(),
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
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month_rounded),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_outlined),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_shared_outlined),
                label: 'Vault',
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
