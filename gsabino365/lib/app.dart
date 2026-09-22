import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/bindings/initial_binding.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'GoVia',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // appBarTheme: AppBarTheme(
            //   backgroundColor: Color(0xffF9FAFB),
            //   scrolledUnderElevation: 0,
            // ),
            scaffoldBackgroundColor: Color(0xffF9FAFB),
          ),
          initialRoute: AppRoutes.splash,
          getPages: pages,
          initialBinding: InitialBinding(),
        );
      },
    );
  }
}
