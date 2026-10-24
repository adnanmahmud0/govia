import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/module/citizen/highlight_hero/controller/highlight_hero_controller.dart';

class HighlightHeroView extends GetView<HighlightHeroController> {
  const HighlightHeroView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Blue App Bar Header
              _buildHeader(context),

              // Tab Switcher (Nominate vs Community Feed)
              Obx(() => Container(
                margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 4.h),
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: 'Nominate Hero',
                        icon: Icons.edit_note_rounded,
                        isSelected: controller.selectedTab.value == 0,
                        onTap: () => controller.selectedTab.value = 0,
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Community Highlights',
                        icon: Icons.stars_rounded,
                        isSelected: controller.selectedTab.value == 1,
                        onTap: () => controller.selectedTab.value = 1,
                      ),
                    ),
                  ],
                ),
              )),

              // Content based on selected tab
              Obx(() {
                if (controller.selectedTab.value == 1) {
                  return _buildCommunityFeed();
                }
                return _buildNominationForm(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────── HEADER ────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1550A6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: MediaQuery.of(context).padding.top + 12.h,
        bottom: 22.h,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_rounded, color: const Color(0xFF67E8F9), size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(
                      'OFFICIAL COMMENDATION',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26.r,
                height: 26.r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  ),
                ),
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 13.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                'Highlight a Hero',
                style: GoogleFonts.inter(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                width: 26.r,
                height: 26.r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  ),
                ),
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 13.sp),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            "Recognize law enforcement officers for outstanding conduct, patience, and peaceful community de-escalation.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? const Color(0xFF1550A6) : const Color(0xFF64748B),
            ),
            SizedBox(width: 6.w),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.5.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF1550A6) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── NOMINATION FORM ────────────────────────
  Widget _buildNominationForm(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          // Step 1: Officer Selection / Identification
          _buildOfficerIdentificationSection(context),

          SizedBox(height: 16.h),

          // Step 2: Single Overall Rating (1 to 5)
          _buildOverallRatingSection(),

          SizedBox(height: 16.h),

          // Step 3: Commendation Story
          _buildSectionCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'What did the officer do well?',
            subtitle: 'Share the positive story to be added to their commendation record',
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.w),
                ),
                child: TextField(
                  controller: controller.feedbackController,
                  maxLines: 4,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: "Describe the incident: how the officer de-escalated, spoke calmly, provided roadside help, or protected your rights...",
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16.w),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Auto-captured metadata notice
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: const Color(0xFF1550A6), size: 16.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Incident timestamp and current GPS location are automatically attached to this commendation.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Submit Button
          Obx(
            () {
              final isRatingsOff = controller.selectedOfficer.value != null &&
                  controller.selectedOfficer.value!['allowCitizenRatings'] == false;

              if (isRatingsOff) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block_rounded, color: const Color(0xFF64748B), size: 18.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Ratings Disabled by Officer',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return CustomButton(
                text: controller.isSubmitting.value ? 'Submitting Commendation...' : 'Submit Commendation',
                onPressed: controller.isSubmitting.value ? () {} : () => controller.submitHeroHighlight(),
                backgroundColor: const Color(0xFF1550A6),
                borderRadius: 24,
                icon: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              );
            },
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  // ──────────────────────── STEP 1: OFFICER IDENTIFICATION ────────────────────────
  Widget _buildOfficerIdentificationSection(BuildContext context) {
    return Obx(() {
      final officer = controller.selectedOfficer.value;

      // Case A: Officer is Identified & Selected
      if (officer != null) {
        return _buildSelectedOfficerCard(officer);
      }

      // Case B: No Officer Selected Yet -> Show 3 Discovery Options
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_outlined, color: const Color(0xFF1550A6), size: 20.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Officer to Commend',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Identify the officer via directory, QR scan, or badge #',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 18.h),

            // 3 Selection Action Cards
            Row(
              children: [
                // 1. Select / Browse Roster
                Expanded(
                  child: _buildDiscoveryActionCard(
                    icon: Icons.badge_rounded,
                    title: 'Select Officer',
                    subtitle: 'Browse roster',
                    badgeColor: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF1550A6),
                    onTap: () => _showOfficerSelectionSheet(context),
                  ),
                ),
                SizedBox(width: 10.w),

                // 2. Scan QR Code
                Expanded(
                  child: _buildDiscoveryActionCard(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Scan QR Code',
                    subtitle: 'Point at badge',
                    badgeColor: const Color(0xFFF0FDF4),
                    iconColor: const Color(0xFF16A34A),
                    onTap: () => _showQrScannerModal(context),
                  ),
                ),
                SizedBox(width: 10.w),

                // 3. Enter Badge / ID
                Expanded(
                  child: _buildDiscoveryActionCard(
                    icon: Icons.pin_rounded,
                    title: 'Enter Badge #',
                    subtitle: 'Instant lookup',
                    badgeColor: const Color(0xFFFAF5FF),
                    iconColor: const Color(0xFF9333EA),
                    onTap: () => _showEnterIdDialog(context),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Toggle for manual fallback
            Center(
              child: GestureDetector(
                onTap: () {
                  if (controller.isManualEntry.value) {
                    controller.isManualEntry.value = false;
                  } else {
                    controller.enableManualEntry();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                  child: Text(
                    controller.isManualEntry.value
                        ? '▲ Hide manual fields'
                        : 'Officer not listed? Enter details manually ▼',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1550A6),
                    ),
                  ),
                ),
              ),
            ),

            // If manual entry expanded:
            if (controller.isManualEntry.value) ...[
              SizedBox(height: 14.h),
              const Divider(color: Color(0xFFF1F5F9)),
              SizedBox(height: 14.h),
              _buildInputField(
                label: 'Officer Name',
                hint: "e.g. Officer Miller",
                controller: controller.nameController,
              ),
              SizedBox(height: 12.h),
              _buildInputField(
                label: 'Badge Number (Optional)',
                hint: 'e.g. CPD-4402',
                controller: controller.badgeController,
              ),
              SizedBox(height: 12.h),
              _buildInputField(
                label: 'Agency / Precinct',
                hint: 'e.g. Central Metro Division',
                controller: controller.agencyController,
              ),
              SizedBox(height: 12.h),
              _buildInputField(
                label: 'Patrol Car / Unit #',
                hint: 'e.g. UNIT-71',
                controller: controller.carController,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildDiscoveryActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color badgeColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.inter(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9.5.sp,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── VERIFIED OFFICER PROFILE CARD ────────────────────────
  Widget _buildSelectedOfficerCard(Map<String, dynamic> officer) {
    final allowRatings = officer['allowCitizenRatings'] != false;
    final name = (officer['name'] ?? 'Officer').toString();
    final rank = (officer['rank'] ?? 'Patrol Officer').toString();
    final badge = (officer['badgeNumber'] ?? '').toString();
    final agency = (officer['agency'] ?? 'Police Department').toString();
    final car = (officer['carNumber'] ?? '').toString();
    final img = (officer['image'] ?? '').toString();
    final rating = (officer['rating'] as num?)?.toDouble() ?? 4.9;
    final total = (officer['totalCommendations'] as num?)?.toInt() ?? 18;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B5C), Color(0xFF1550A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1550A6).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 60.r,
                    height: 60.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5.w),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30.r),
                      child: img.isNotEmpty
                          ? Image.network(
                              ApiConstants.getFileUrl(img),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _avatarFallback(),
                            )
                          : _avatarFallback(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(2.r),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, color: Colors.white, size: 12.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 14.w),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'POLICE',
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '$rank • $agency',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // Chips Row
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        if (badge.isNotEmpty)
                          _buildWhiteChip('BADGE #${badge.replaceFirst('#', '')}', Icons.verified_rounded),
                        if (car.isNotEmpty && car != 'N/A')
                          _buildWhiteChip('CAR: $car', Icons.directions_car_rounded),
                        if (allowRatings)
                          _buildWhiteChip('${rating.toStringAsFixed(1)} ★', Icons.star_rounded)
                        else
                          _buildWhiteChip('Ratings Disabled', Icons.do_not_disturb_on_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),
          const Divider(color: Colors.white24, height: 1),
          SizedBox(height: 10.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: const Color(0xFFFBBF24), size: 15.sp),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        allowRatings ? '$total Commendations' : 'Ratings Off',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: controller.clearSelectedOfficer,
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 14.sp),
                      SizedBox(width: 3.w),
                      Text(
                        'Change Officer',
                        style: GoogleFonts.inter(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (!allowRatings) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: const Color(0xFFDC2626), size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'This officer has turned off citizen ratings & reviews.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWhiteChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 10.sp),
          SizedBox(width: 3.w),
          Text(
            label,
            style: GoogleFonts.sourceCodePro(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(Icons.local_police_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  // ──────────────────────── DIALOG 1: SELECT OFFICER SHEET ────────────────────────
  void _showOfficerSelectionSheet(BuildContext context) {
    controller.officerSearchController.clear();
    controller.filterOfficers('');

    Get.bottomSheet(
      Container(
        height: 600.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Sheet Title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_police_rounded, color: const Color(0xFF1550A6), size: 22.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified Police Officers',
                        style: GoogleFonts.inter(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Select an active duty officer to highlight',
                        style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Get.back(),
                ),
              ],
            ),

            SizedBox(height: 14.h),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: const Color(0xFF64748B), size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: controller.officerSearchController,
                      onChanged: controller.filterOfficers,
                      style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Search by name, badge, precinct...',
                        hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (controller.officerSearchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        controller.officerSearchController.clear();
                        controller.filterOfficers('');
                      },
                      child: Icon(Icons.clear_rounded, color: const Color(0xFF64748B), size: 18.sp),
                    ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // List of Officers
            Expanded(
              child: Obx(() {
                if (controller.isLoadingOfficers.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final officers = controller.filteredOfficersList;
                if (officers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48.sp, color: const Color(0xFF94A3B8)),
                        SizedBox(height: 10.h),
                        Text(
                          'No officers found',
                          style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Try searching another badge or enter manually.',
                          style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: officers.length,
                  separatorBuilder: (_, _) => SizedBox(height: 10.h),
                  itemBuilder: (ctx, idx) {
                    final item = officers[idx];
                    return _buildOfficerListItem(item);
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildOfficerListItem(Map<String, dynamic> item) {
    final allowRatings = item['allowCitizenRatings'] != false;
    final name = (item['name'] ?? 'Officer').toString();
    final rank = (item['rank'] ?? 'Patrol Officer').toString();
    final badge = (item['badgeNumber'] ?? '').toString();
    final agency = (item['agency'] ?? 'Police Department').toString();
    final car = (item['carNumber'] ?? '').toString();
    final img = (item['image'] ?? '').toString();
    final rating = (item['rating'] as num?)?.toDouble() ?? 4.9;

    return InkWell(
      onTap: () {
        controller.selectOfficer(item);
        Get.back();
      },
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: const Color(0xFF1550A6).withValues(alpha: 0.1),
            backgroundImage: img.isNotEmpty ? NetworkImage(ApiConstants.getFileUrl(img)) : null,
            child: img.isEmpty
                ? Icon(Icons.local_police_rounded, color: const Color(0xFF1550A6), size: 24.sp)
                : null,
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
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.verified_rounded, color: const Color(0xFF10B981), size: 14.sp),
                    SizedBox(width: 6.w),
                    if (allowRatings)
                      Text('$rating ★', style: GoogleFonts.inter(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)))
                    else
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Ratings Off',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  '$rank • $agency',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11.5.sp, color: const Color(0xFF64748B)),
                ),
                SizedBox(height: 5.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'BADGE #${badge.replaceFirst('#', '')}',
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1550A6),
                        ),
                      ),
                    ),
                    if (car.isNotEmpty && car != 'N/A')
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Car: $car',
                          style: GoogleFonts.inter(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () {
              controller.selectOfficer(item);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1550A6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              elevation: 0,
            ),
            child: Text(
              'Select',
              style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

  // ──────────────────────── DIALOG 2: QR CAMERA SCANNER ────────────────────────
  void _showQrScannerModal(BuildContext context) {
    final scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Container(
          height: 480.h,
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.qr_code_scanner_rounded, color: const Color(0xFF1550A6), size: 20.sp),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Scan Officer QR / Badge',
                        style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () {
                      scannerController.dispose();
                      Get.back();
                    },
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Point camera at the officer’s GoVia QR card or badge code',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
              ),
              SizedBox(height: 12.h),

              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: scannerController,
                        onDetect: (capture) async {
                          final barcode = capture.barcodes.firstOrNull;
                          if (barcode == null || barcode.rawValue == null) return;
                          final raw = barcode.rawValue!.trim();
                          if (raw.isEmpty) return;

                          await scannerController.stop();
                          scannerController.dispose();
                          Get.back(); // close scanner dialog

                          await controller.handleScannedQr(raw);
                        },
                      ),
                      // Crosshairs overlay
                      Container(
                        width: 200.r,
                        height: 200.r,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF1550A6), width: 2.5.w),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12.h),
              Text(
                'Instant detection • Keep badge steady',
                style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  // ──────────────────────── DIALOG 3: ENTER BADGE / ID ────────────────────────
  void _showEnterIdDialog(BuildContext context) {
    controller.badgeLookupController.clear();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAF5FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.pin_rounded, color: const Color(0xFF9333EA), size: 22.sp),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Enter Officer Badge # or ID',
                      style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Enter the officer badge number (e.g. CPD-4402 or 4402), LEO license number, or digital short ID.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B), height: 1.35),
              ),
              SizedBox(height: 16.h),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFB4C6E7), width: 1.2.w),
                ),
                child: TextField(
                  controller: controller.badgeLookupController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (val) async {
                    final ok = await controller.lookupOfficerById(val);
                    if (ok) Get.back();
                  },
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 1.0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. CPD-4402 or A11134E8',
                    hintStyle: GoogleFonts.sourceCodePro(fontSize: 14.sp, color: const Color(0xFF94A3B8), letterSpacing: 0),
                    prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF1550A6)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              Text(
                'Recent / Quick badges:',
                style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  _buildQuickBadgeChip('CPD-4402', 'Miller'),
                  _buildQuickBadgeChip('CPD-2108', 'Walker'),
                ],
              ),

              SizedBox(height: 18.h),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Obx(() => ElevatedButton(
                      onPressed: controller.isLookingUpOfficer.value
                          ? null
                          : () async {
                              final text = controller.badgeLookupController.text.trim();
                              final ok = await controller.lookupOfficerById(text);
                              if (ok) Get.back();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1550A6),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        elevation: 0,
                      ),
                      child: controller.isLookingUpOfficer.value
                          ? SizedBox(width: 16.r, height: 16.r, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Find Officer', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickBadgeChip(String badge, String officerName) {
    return InkWell(
      onTap: () async {
        controller.badgeLookupController.text = badge;
        final ok = await controller.lookupOfficerById(badge);
        if (ok) Get.back();
      },
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: const Color(0xFF1550A6), size: 14.sp),
            SizedBox(width: 4.w),
            Text(
              '$badge ($officerName)',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1550A6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── SECTION CARD BUILDERS ────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1550A6), size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
            ),
          ],
          SizedBox(height: 18.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.w),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(
              fontSize: 14.5.sp,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF94A3B8),
              ),
              suffixIcon: suffixIcon != null
                  ? Icon(suffixIcon, color: const Color(0xFF64748B), size: 18.sp)
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallRatingSection() {
    return _buildSectionCard(
      icon: Icons.star_rounded,
      title: 'Overall Performance Rating',
      subtitle: 'Select an overall rating from 1 to 5 stars',
      children: [
        Obx(() {
          final rating = controller.overallRating.value;

          String description;
          Color statusColor;
          if (rating >= 4.8) {
            description = 'Exceptional Service & Conduct';
            statusColor = const Color(0xFF16A34A);
          } else if (rating >= 4.0) {
            description = 'Great & Professional Conduct';
            statusColor = const Color(0xFF2563EB);
          } else if (rating >= 3.0) {
            description = 'Good & Courteous Conduct';
            statusColor = const Color(0xFFD97706);
          } else if (rating >= 2.0) {
            description = 'Fair / Standard Interaction';
            statusColor = const Color(0xFFEA580C);
          } else {
            description = 'Basic Conduct';
            statusColor = const Color(0xFFDC2626);
          }

          return Column(
            children: [
              // Rating Badge & Description
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: const Color(0xFFF59E0B), size: 18.sp),
                        SizedBox(width: 4.w),
                        Text(
                          '${rating.toStringAsFixed(1)} / 5.0',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Interactive 5 Large Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isFilled = rating >= starIndex;
                  final isHalf = !isFilled && rating >= (starIndex - 0.5);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.overallRating.value = starIndex.toDouble();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Icon(
                        isFilled
                            ? Icons.star_rounded
                            : (isHalf ? Icons.star_half_rounded : Icons.star_outline_rounded),
                        color: (isFilled || isHalf) ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                        size: 38.sp,
                      ),
                    ),
                  );
                }),
              ),

              SizedBox(height: 12.h),

              // Smooth 1 to 5 Slider
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF1550A6),
                  inactiveTrackColor: const Color(0xFFE2E8F0),
                  thumbColor: const Color(0xFF1550A6),
                  overlayColor: const Color(0xFF1550A6).withValues(alpha: 0.12),
                  trackHeight: 6.h,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                ),
                child: Slider(
                  value: rating,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  onChanged: (val) {
                    controller.overallRating.value = val;
                  },
                ),
              ),

              // 1 to 5 labels
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 Star', style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                    Text('2', style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                    Text('3', style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                    Text('4', style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                    Text('5 Stars', style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // ──────────────────────── TAB 2: COMMUNITY HIGHLIGHTS FEED ────────────────────────
  Widget _buildCommunityFeed() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Community Commendations',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Obx(
                () => Text(
                  '${controller.heroFeed.length} stories',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Obx(() {
            if (controller.isLoadingFeed.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.heroFeed.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32.r),
                  child: Text(
                    'No community highlights yet. Be the first to commend a hero!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF64748B)),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.heroFeed.length,
              separatorBuilder: (_, _) => SizedBox(height: 14.h),
              itemBuilder: (ctx, idx) => _buildHeroCard(controller.heroFeed[idx]),
            );
          }),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> hero) {
    final name = hero['officerName']?.toString() ?? 'Officer';
    final badge = hero['badgeNumber']?.toString() ?? '';
    final agency = hero['agency']?.toString() ?? '';
    final date = hero['date']?.toString() ?? 'Recent';
    final location = hero['location']?.toString() ?? '';
    final story = hero['story']?.toString() ?? '';
    final avatar = hero['officerAvatar']?.toString() ?? '';
    final respect = (hero['respectRating'] as num?)?.toDouble() ?? 5.0;
    final overall = (hero['overallRating'] as num?)?.toDouble() ??
        (respect > 5 ? (respect / 2) : respect);
    final likes = (hero['likes'] as num?)?.toInt() ?? 0;
    final isSaluted = hero['saluted'] == true || controller.salutedHeroIds.contains(hero['id']);
    final id = hero['id']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: const Color(0xFF1550A6).withValues(alpha: 0.1),
                backgroundImage: avatar.isNotEmpty ? NetworkImage(ApiConstants.getFileUrl(avatar)) : null,
                child: avatar.isEmpty
                    ? Icon(Icons.shield_rounded, color: const Color(0xFF1550A6), size: 22.sp)
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$badge • $agency',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  date,
                  style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          Text(
            story,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF334155),
              height: 1.45,
            ),
          ),

          SizedBox(height: 12.h),

          // Rating pill row
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: const Color(0xFFD97706), size: 15.sp),
                    SizedBox(width: 4.w),
                    Text(
                      '${overall.toStringAsFixed(1)} / 5 Overall Rating',
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              if (location.isNotEmpty) ...[
                const Spacer(),
                Icon(Icons.location_on_outlined, size: 13.sp, color: const Color(0xFF94A3B8)),
                SizedBox(width: 2.w),
                Flexible(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 12.h),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          SizedBox(height: 8.h),

          // Salute / Like button & Share
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => controller.likeHero(id),
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSaluted ? const Color(0xFFEF4444).withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSaluted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18.sp,
                        color: isSaluted ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        isSaluted ? 'Saluted ($likes)' : 'Salute ($likes)',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isSaluted ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.share_outlined, size: 18.sp, color: const Color(0xFF94A3B8)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '$name from $agency was commended for exceptional community service on GoVia!'));
                  Helpers.showSuccess('Commendation text copied to clipboard.', title: 'Share Hero');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
