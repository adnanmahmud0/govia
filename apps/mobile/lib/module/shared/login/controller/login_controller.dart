import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/module/shared/splash/splash_controller.dart';
import 'package:gsabino365/config/routes/app_pages.dart';

class DemoAccountItem {
  final String role;
  final String roleLabel;
  final String name;
  final String email;
  final String subtitle;
  final IconData icon;

  const DemoAccountItem({
    required this.role,
    required this.roleLabel,
    required this.name,
    required this.email,
    required this.subtitle,
    required this.icon,
  });
}

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isPasswordObscured = true.obs;
  final RxBool isLoading = false.obs;

  // Selected role for API request: { email, role, password }
  final RxString selectedRole = 'CITIZEN'.obs;

  final List<String> availableRoles = const [
    'CITIZEN',
    'ATTORNEY',
    'POLICE',
    'MENTAL_HEALTH_PROFESSIONAL',
    'BAIL_BONDSMAN',
  ];

  final Map<String, String> roleLabels = const {
    'CITIZEN': 'Citizen',
    'ATTORNEY': 'Attorney',
    'POLICE': 'Police Officer',
    'MENTAL_HEALTH_PROFESSIONAL': 'Mental Health Professional',
    'BAIL_BONDSMAN': 'Bail Bondsman',
  };

  final List<DemoAccountItem> demoAccounts = const [
    DemoAccountItem(
      role: 'CITIZEN',
      roleLabel: 'Citizen',
      name: 'Adnan Mahmud',
      email: 'adnan99mahmud@gmail.com',
      subtitle: 'Primary Citizen (QR, Vault, SOS)',
      icon: Icons.person_rounded,
    ),
    DemoAccountItem(
      role: 'CITIZEN',
      roleLabel: 'Citizen',
      name: 'Jordan Hayes',
      email: 'citizen@govia.com',
      subtitle: 'Secondary Citizen Demo',
      icon: Icons.person_outline_rounded,
    ),
    DemoAccountItem(
      role: 'ATTORNEY',
      roleLabel: 'Attorney',
      name: 'Attorney Sarah Jenkins',
      email: 'attorney@govia.com',
      subtitle: 'Jenkins & Assoc. Defense (Dispatch, WebRTC)',
      icon: Icons.gavel_rounded,
    ),
    DemoAccountItem(
      role: 'ATTORNEY',
      roleLabel: 'Attorney',
      name: 'Attorney David Sterling',
      email: 'attorney.sterling@govia.com',
      subtitle: 'Sterling Law Group LLP (NY Bar)',
      icon: Icons.balance_rounded,
    ),
    DemoAccountItem(
      role: 'MENTAL_HEALTH_PROFESSIONAL',
      roleLabel: 'Mental Health',
      name: 'Dr. Emily Chen, PsyD',
      email: 'doctor@govia.com',
      subtitle: 'Crisis Response Network (De-escalation)',
      icon: Icons.psychology_rounded,
    ),
    DemoAccountItem(
      role: 'MENTAL_HEALTH_PROFESSIONAL',
      roleLabel: 'Mental Health',
      name: 'Dr. Robert Harris, LCSW',
      email: 'doctor.harris@govia.com',
      subtitle: 'Metro Wellness & Support Center',
      icon: Icons.health_and_safety_rounded,
    ),
    DemoAccountItem(
      role: 'POLICE',
      roleLabel: 'Police Officer',
      name: 'Officer James Miller',
      email: 'police@govia.com',
      subtitle: 'Central Metro Division - Unit 71',
      icon: Icons.local_police_rounded,
    ),
    DemoAccountItem(
      role: 'POLICE',
      roleLabel: 'Police Sergeant',
      name: 'Sergeant Patricia Walker',
      email: 'police.walker@govia.com',
      subtitle: 'Traffic & Patrol Division - Patrol 12',
      icon: Icons.shield_rounded,
    ),
    DemoAccountItem(
      role: 'BAIL_BONDSMAN',
      roleLabel: 'Bail Bondsman',
      name: 'Dana Morgan',
      email: 'bailbonds@govia.com',
      subtitle: 'Dana Bail Bonds & Surety Services',
      icon: Icons.monetization_on_rounded,
    ),
    DemoAccountItem(
      role: 'BAIL_BONDSMAN',
      roleLabel: 'Bail Bondsman',
      name: 'Victor Stone',
      email: 'bailbonds.stone@govia.com',
      subtitle: 'Freedom Fast Bail Bonds LLC',
      icon: Icons.attach_money_rounded,
    ),
  ];

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  void setSelectedRole(String? role) {
    if (role != null && role.isNotEmpty) {
      selectedRole.value = role;
    }
  }

  void fillDemoAttorney() {
    emailController.text = 'attorney@govia.com';
    passwordController.text = 'Password123!';
    selectedRole.value = 'ATTORNEY';
    loginWithRole('ATTORNEY');
  }

  void loginWithDemoAccount(DemoAccountItem account) {
    // Fill text fields if still attached
    try {
      emailController.text = account.email;
      passwordController.text = 'Password123!';
    } catch (_) {}
    selectedRole.value = account.role;

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    loginDirect(
      email: account.email,
      password: 'Password123!',
      role: account.role,
    );
  }

  void onLoginPressed() {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    showRolePickerBottomSheet();
  }

  void showDemoAccountsBottomSheet() {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: 0.85.sh,
        ),
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: const Color(0xFF1550A6),
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Demo Account',
                          style: GoogleFonts.inter(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0A192F),
                          ),
                        ),
                        Text(
                          '1-tap login with pre-configured multiple roles',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: demoAccounts.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1.h,
                    color: const Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, index) {
                    final item = demoAccounts[index];
                    return InkWell(
                      onTap: () => loginWithDemoAccount(item),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 11.h,
                          horizontal: 4.w,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F6FF),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                item.icon,
                                color: const Color(0xFF1550A6),
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0A192F),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          item.roleLabel,
                                          style: GoogleFonts.inter(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    item.email,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1550A6),
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    item.subtitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: const Color(0xFF94A3B8),
                              size: 14.sp,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void showRolePickerBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select User Flow to Test',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A192F),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Choose a role flow to navigate to the bottom navbar dashboard.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5F6E80),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              _buildRoleOption(
                title: 'Citizen',
                roleValue: 'CITIZEN',
                icon: Icons.verified_user_rounded,
              ),
              _buildRoleOption(
                title: 'Attorney',
                roleValue: 'ATTORNEY',
                icon: Icons.gavel_rounded,
              ),
              _buildRoleOption(
                title: 'Mental Health Professional',
                roleValue: 'MENTAL_HEALTH_PROFESSIONAL',
                icon: Icons.psychology_rounded,
              ),
              _buildRoleOption(
                title: 'Police',
                roleValue: 'POLICE',
                icon: Icons.local_police_rounded,
              ),
              _buildRoleOption(
                title: 'Bail Bondsman',
                roleValue: 'BAIL_BONDSMAN',
                icon: Icons.monetization_on_rounded,
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String roleValue,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        Get.back();
        loginWithRole(roleValue);
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF1550A6),
              size: 24.sp,
            ),
            SizedBox(width: 18.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A192F),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFF90A0B3),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loginWithRole(String role) async {
    selectedRole.value = role;
    await login();
  }

  Future<void> loginDirect({
    required String email,
    required String password,
    required String role,
  }) async {
    isLoading.value = true;
    final authService = Get.find<AuthService>();

    try {
      final result = await authService.login(
        email: email,
        role: role,
        password: password,
      );

      isLoading.value = false;

      if (result.isUnverified) {
        Helpers.showError(
          'Please verify your account. A verification code was sent to your email.',
          title: 'Account Unverified',
        );

        Get.toNamed(
          AppRoutes.otpVerification,
          arguments: {
            'email': email,
            'role': role,
            'flow': 'signup',
          },
        );
        return;
      }

      if (result.success) {
        Helpers.showSuccess(
          result.message ?? 'Logged in successfully!',
          title: 'Welcome Back',
        );

        final targetRoute = SplashController.getDashboardForRole(result.role);
        Get.offAllNamed(targetRoute);
      } else {
        Helpers.showError(
          result.message ?? 'Invalid email, role, or password.',
          title: 'Login Failed',
        );
      }
    } catch (e) {
      isLoading.value = false;
      Helpers.showError(
        'An unexpected error occurred. Please try again.',
        title: 'Error',
      );
    }
  }

  Future<void> login() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;
    final role = selectedRole.value;

    await loginDirect(email: email, password: password, role: role);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
