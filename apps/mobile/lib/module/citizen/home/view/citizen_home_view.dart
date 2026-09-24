import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/module/citizen/home/controller/citizen_home_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class CitizenHomeView extends GetView<CitizenHomeController> {
  const CitizenHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // A cleaner, softer slate-white background
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dynamic Blue Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF1550A6)], // Sleek, modern deep blues
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32.r),
                    bottomRight: Radius.circular(32.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1550A6).withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20.h,
                  bottom: 24.h,
                  left: 24.w,
                  right: 24.w,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Avatar + Name & Role + Top Right Quick Actions
                    Row(
                      children: [
                        // Avatar with premium border glow
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 2.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Obx(() {
                            final avatar = controller.avatarUrl;
                            final hasAvatar = avatar != null && avatar.isNotEmpty;
                            return CircleAvatar(
                              radius: 26.r,
                              backgroundImage: hasAvatar
                                  ? NetworkImage(avatar) as ImageProvider
                                  : const AssetImage(
                                      'assets/images/user_avatar.png',
                                    ),
                              onBackgroundImageError: hasAvatar ? (_, _) {} : null,
                              backgroundColor: Colors.white24,
                            );
                          }),
                        ),
                        SizedBox(width: 12.w),
                        // Greeting Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. User Name
                              Obx(
                                () => Text(
                                  controller.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 19.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              // 2. User Role
                              Obx(
                                () => Text(
                                  'Role: ${controller.userRole}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        // Top Right Actions: QR Scanner & Notification Bell
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: controller.openQrScanner,
                              child: Container(
                                width: 42.r,
                                height: 42.r,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.w,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: Colors.white,
                                    size: 21.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () => Get.toNamed(AppRoutes.citizenNotification),
                              child: Container(
                                width: 42.r,
                                height: 42.r,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.w,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 23.sp,
                                    ),
                                    Obx(() {
                                      if (controller.unreadNotificationCount.value > 0) {
                                        return Positioned(
                                          top: 10.h,
                                          right: 10.w,
                                          child: Container(
                                            width: 8.r,
                                            height: 8.r,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444), // Crimson Alert Dot
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    // Action Bar: ID Chip + Show QR Pill
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Obx(
                        () => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final hexId = controller.shortHexId;
                                Clipboard.setData(ClipboardData(text: hexId));
                                Get.rawSnackbar(
                                  message: 'Copied Short Hex ID: #$hexId',
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 0.8.w,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ID: #${controller.shortHexId}',
                                      style: GoogleFonts.sourceCodePro(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    SizedBox(width: 5.w),
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 11.sp,
                                      color: Colors.white.withValues(alpha: 0.65),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: controller.openQrDialog,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 0.8.w,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2_rounded,
                                      size: 13.sp,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'QR Card',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Redesigned Status Indicator Strip (GPS, Voice/Mic, Camera)
                    Obx(
                      () => Row(
                        children: [
                          // 1. GPS Status Card
                          Expanded(
                            child: _buildStatusCard(
                              icon: Icons.location_on_rounded,
                              title: 'GPS',
                              status: controller.isGpsActive.value ? 'ACTIVE' : 'DEACTIVATE',
                              isActive: controller.isGpsActive.value,
                              onTap: controller.toggleGps,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // 2. Voice / Mic Monitoring Card
                          Expanded(
                            child: _buildStatusCard(
                              icon: controller.isVoiceActive.value
                                  ? Icons.mic_rounded
                                  : Icons.mic_off_rounded,
                              title: 'VOICE',
                              status: controller.isVoiceActive.value ? 'ACTIVE' : 'DEACTIVATE',
                              isActive: controller.isVoiceActive.value,
                              onTap: controller.toggleVoice,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // 3. Camera Status Card
                          Expanded(
                            child: _buildStatusCard(
                              icon: controller.isCameraActive.value
                                  ? Icons.videocam_rounded
                                  : Icons.videocam_off_rounded,
                              title: 'CAMERA',
                              status: controller.isCameraActive.value ? 'ACTIVE' : 'DEACTIVATE',
                              isActive: controller.isCameraActive.value,
                              onTap: controller.toggleCamera,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Body Sections
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    // A. START GOVIA - Large Central Mic Button (Repositioned to the top)
                    Center(
                      child: Container(
                        width: 210.w,
                        height: 210.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1550A6).withValues(alpha: 0.2),
                              blurRadius: 25,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFEFF6FF), // Soft premium light blue border
                            width: 8.w,
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: () {
                                // Join as host with auto-recording & emergency notification
                                controller.startEmergencySession(reason: 'Start Govia Button');
                              },
                              customBorder: const CircleBorder(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 48.sp,
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'START GOVIA',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 36.h),

                    // B. Option 1: Stop/Unsafe Card
                    _buildOptionCard(
                      title: "I'm being stopped / I feel unsafe",
                      subtitle: "Launch emergency monitoring protocol",
                      icon: Icons.error_outline_rounded,
                      iconGradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                      onTap: () => controller.startEmergencySession(reason: 'Stop / Unsafe Card'),
                    ),
                    SizedBox(height: 16.h),

                    // C. Option 2: Highlight Hero Card
                    _buildOptionCard(
                      title: "Highlight a Hero",
                      subtitle: "Nominate and support local officers",
                      icon: Icons.shield_outlined,
                      iconGradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                      onTap: () => Get.toNamed(AppRoutes.citizenHighlightHero),
                    ),
                    SizedBox(height: 16.h),

                    // D. Option 3: GoVia AI Assistant Card
                    _buildOptionCard(
                      title: "GoVia AI Assistant",
                      subtitle: "Ask copilot for instant legal guidance",
                      icon: Icons.radar_rounded,
                      iconGradientColors: [const Color(0xFF8B5CF6), const Color(0xFF6366F1)],
                      onTap: () => Get.toNamed(AppRoutes.attorneyGoviaAi),
                    ),
                    SizedBox(height: 36.h),

                    // E. Bottom Action Buttons (Mental Health & Education)
                    Row(
                      children: [
                        // Mental Health Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.citizenMentalHealth),
                            child: Container(
                              height: 56.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF43F5E), Color(0xFFE11D48)], // Crimson/Rose warning gradient
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Mental Health',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        // Education Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final Uri url = Uri.parse(
                                'https://youtube.com/@goviahero?si=wViL-yYnTPXYT-Ak',
                              );
                              if (!await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              )) {
                                Get.snackbar(
                                  'Error',
                                  'Could not open link.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: const Color(0xFFDC2626),
                                  colorText: Colors.white,
                                );
                              }
                            },
                            child: Container(
                              height: 56.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)], // Slate/Dark gradient
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.school_rounded, color: Colors.white, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Education',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: FloatingActionButton(
            onPressed: () {
              Get.toNamed(AppRoutes.attorneyChatList);
            },
            backgroundColor: const Color(0xFF1550A6),
            shape: const CircleBorder(),
            elevation: 4,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }

  // Premium reusable Option Card widget
  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> iconGradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 16.h,
          horizontal: 16.w,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFFEDF2F7), // Soft border line
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient Icon Box
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: iconGradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Title & Subtitle block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B), // Premium dark text color
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B), // Soft slate subtext
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFFCBD5E1),
              size: 14.sp,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────── MODERN STATUS CARD BUILDER ────────────────
  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String status,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.08),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.08),
                    ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.10),
              width: 1.w,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Sensor Icon Badge & Glowing Live Status LED
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 26.w,
                    height: 26.w,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        size: 14.sp,
                      ),
                    ),
                  ),
                  // Glowing Live Status Dot
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 7.r,
                    height: 7.r,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF10B981) // Emerald Green
                          : const Color(0xFFEF4444), // Crimson Red
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isActive
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              // Sensor Title
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2.h),
              // Live Status Label
              Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: isActive
                      ? const Color(0xFF6EE7B7) // Bright Mint / Emerald
                      : const Color(0xFFFCA5A5), // Soft Crimson for DEACTIVATE
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
