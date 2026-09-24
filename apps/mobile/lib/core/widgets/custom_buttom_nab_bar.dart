/*
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/image_paths.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: const BoxDecoration(
          color: Color(0xffFFFAF8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(
              index: 0,
              icon: ImagePaths.homeIcon,
              label: "Home",
              color: const Color(0xff0D8BD6),
            ),
            _navItem(
              index: 1,
              icon: ImagePaths.findProfileIcon,
              label: "Find Profile",
              color: const Color(0xffFF89CA),
            ),
            _navItem(
              index: 2,
              icon: ImagePaths.createUserIcon,
              label: "Create Profile",
              color: const Color(0xff19B23F),
            ),
            _navItem(
              index: 3,
              icon: ImagePaths.settingIcon,
              label: "Setting",
              color: const Color(0xffFD7839),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= NAV ITEM ================= ///
  Widget _navItem({
    required int index,
    required String icon,
    required String label,
    required Color color,
  }) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => onTap(index),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// SVG ICON
            SvgPicture.asset(icon, width: 24.w, height: 24.w),

            SizedBox(height: 4.h),

            /// LABEL
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 4.h),

            /// UNDERLINE INDICATOR
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 2.h,
              width: isSelected ? 45.w : 0,
              decoration: BoxDecoration(
                color: color,
              ),
            ),

            Container( width: 60.w, color: Colors.transparent),
          ],
        ),
      ),
    );
  }
}
*/
