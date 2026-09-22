import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gsabino365/config/constants/image_paths.dart';
import 'package:gsabino365/module/shared/splash/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFE3EBF6,
      ), // Matches the light blue-grey background in the design
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeIn,
                builder: (context, opacity, child) {
                  return Opacity(opacity: opacity, child: child);
                },
                child: child,
              ),
            );
          },
          child: Image.asset(
            ImagePaths.splashLogo,
            width: 200.w, // Responsive width
            height: 200.h, // Responsive height
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
