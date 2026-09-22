import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import '../services/auth_service.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}
