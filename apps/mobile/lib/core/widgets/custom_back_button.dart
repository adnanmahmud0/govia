import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';



class CustomBackButton extends StatelessWidget {
  const CustomBackButton({super.key, this.iconSize, this.containerSize});
  final double? iconSize;
  final double? containerSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 15.w),
      child: GestureDetector(
        onTap: () {
          Get.back();
        },
        child: Container(
          height: containerSize ?? 30.w,
          width: containerSize ?? 30.w,
          decoration: BoxDecoration(
            color: Color(0xffF5F5F5),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_ios_new_outlined, size: 20.sp),
        ),
      ),
    );
  }
}
