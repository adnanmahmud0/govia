import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/module/shared/preferred_providers/controller/preferred_providers_controller.dart';

class PreferredProvidersView extends GetView<PreferredProvidersController> {
  const PreferredProvidersView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Custom Blue App Bar Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1550A6),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 16.w,
                right: 24.w,
                top: MediaQuery.of(context).padding.top + 12.h,
                bottom: 24.h,
              ),
              child: Row(
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
                        size: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferred Providers',
                          style: GoogleFonts.outfit(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Legal Representation & Bail Services',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF1550A6),
                onRefresh: () => controller.refreshProviders(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emergency Info Banner
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1550A6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.security_rounded,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Protection Network',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'During any active stop, emergency call, or incident, GoVia automatically references these designated contacts. Link via QR scan, User ID, or Contacts with instant auto-save.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF334155),
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Card 1: Preferred Attorney / Law Firm
                      Obx(() => _buildProviderSection(
                            title: 'Preferred Attorney / Law Firm',
                            badgeText: 'Legal Counsel',
                            badgeColor: const Color(0xFF1550A6),
                            icon: Icons.gavel_rounded,
                            profile: controller.attorneyProfile.value,
                            forAttorney: true,
                            helper:
                                'Primary legal counsel notified when initiating GoVia emergency legal assistance.',
                            onBrowseMarketplace: () =>
                                controller.openProviderMarketplaceSheet(forAttorney: true),
                            onScanQr: () => controller.openQrScanner(forAttorney: true),
                            onLookupId: () => controller.openIdLookupDialog(forAttorney: true),
                            onFromContacts: () => controller.openRecentContactsSheet(forAttorney: true),
                            onDisconnect: () => controller.disconnectProvider(forAttorney: true),
                          )),

                      SizedBox(height: 20.h),

                      // Card 2: Preferred Bail Bondsman
                      Obx(() => _buildProviderSection(
                            title: 'Preferred Bail Bondsman',
                            badgeText: 'Bail Bond Service',
                            badgeColor: const Color(0xFF0D9488),
                            icon: Icons.monetization_on_rounded,
                            profile: controller.bailBondsmanProfile.value,
                            forAttorney: false,
                            helper:
                                'Licensed bail bonds agency contacted immediately if custody or bail arrangement is required.',
                            onBrowseMarketplace: () =>
                                controller.openProviderMarketplaceSheet(forAttorney: false),
                            onScanQr: () => controller.openQrScanner(forAttorney: false),
                            onLookupId: () => controller.openIdLookupDialog(forAttorney: false),
                            onFromContacts: () => controller.openRecentContactsSheet(forAttorney: false),
                            onDisconnect: () => controller.disconnectProvider(forAttorney: false),
                          )),

                      SizedBox(height: 28.h),

                      // Auto-Saved Confirmation Card (replaces manual save button)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_done_rounded,
                                color: Color(0xFF059669),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Protection Coverage Synced',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Connected providers are synced in real-time. Payments secured via Stripe.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5.sp,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSection({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Map<String, dynamic>? profile,
    required bool forAttorney,
    required String helper,
    required VoidCallback onBrowseMarketplace,
    required VoidCallback onScanQr,
    required VoidCallback onLookupId,
    required VoidCallback onFromContacts,
    required VoidCallback onDisconnect,
  }) {
    final bool isConnected = profile != null &&
        profile['name'] != null &&
        profile['name'].toString().trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isConnected ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of card
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: badgeColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Provider Body: Connected Profile Card OR Empty Add Actions
          if (isConnected)
            _buildConnectedProfileCard(
              profile: profile,
              badgeColor: badgeColor,
              forAttorney: forAttorney,
              onChange: onBrowseMarketplace,
              onDisconnect: onDisconnect,
            )
          else
            _buildEmptyProviderPrompt(
              badgeColor: badgeColor,
              forAttorney: forAttorney,
              onBrowseMarketplace: onBrowseMarketplace,
              onScanQr: onScanQr,
              onLookupId: onLookupId,
              onFromContacts: onFromContacts,
            ),

          SizedBox(height: 12.h),

          Text(
            helper,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedProfileCard({
    required Map<String, dynamic> profile,
    required Color badgeColor,
    required bool forAttorney,
    required VoidCallback onChange,
    required VoidCallback onDisconnect,
  }) {
    final name = profile['name']?.toString() ?? 'Provider';
    final role = profile['role']?.toString() ?? 'Verified Provider';
    final avatar = profile['image']?.toString() ?? profile['profilePicture']?.toString();
    final bool isActive = controller.isCoverageActive(forAttorney: forAttorney);
    final int remainingDays = controller.getCoverageRemainingDays(forAttorney: forAttorney);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.w),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: badgeColor.withValues(alpha: 0.12),
                backgroundImage: (avatar != null && avatar.isNotEmpty)
                    ? NetworkImage(ApiConstants.getFileUrl(avatar))
                    : null,
                child: (avatar == null || avatar.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'P',
                        style: GoogleFonts.inter(
                          color: badgeColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 14.w),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      role,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: (isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                        .withValues(alpha: 0.3),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      isActive ? 'Active Protection' : 'Coverage Expired',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: isActive ? const Color(0xFF059669) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isActive) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Retainer protection active • $remainingDays days remaining',
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Coverage is inactive. Renew to enable priority roadside assistance.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 12.h),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onChange,
                icon: Icon(Icons.storefront_rounded, size: 16.sp, color: const Color(0xFF1550A6)),
                label: Text(
                  isActive ? 'Change Provider' : 'Renew / Change',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1550A6),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              TextButton.icon(
                onPressed: onDisconnect,
                icon: Icon(Icons.link_off_rounded, size: 16.sp, color: const Color(0xFFEF4444)),
                label: Text(
                  'Disconnect',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProviderPrompt({
    required Color badgeColor,
    required bool forAttorney,
    required VoidCallback onBrowseMarketplace,
    required VoidCallback onScanQr,
    required VoidCallback onLookupId,
    required VoidCallback onFromContacts,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Primary Action: Browse Verified Directory & Pricing
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1550A6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
              ),
              onPressed: onBrowseMarketplace,
              icon: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          forAttorney ? 'Browse Verified Attorneys' : 'Browse Verified Bondsmen',
                          style: GoogleFonts.inter(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'View prices, short bios & activate via Stripe',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),

          SizedBox(height: 14.h),

          // Divider with "Or link directly"
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Text(
                  'Or link directly',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),

          SizedBox(height: 12.h),

          // Secondary Quick action buttons: Scan, ID, Contacts
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  label: 'Scan QR',
                  icon: Icons.qr_code_scanner_rounded,
                  color: badgeColor,
                  onTap: onScanQr,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildQuickActionButton(
                  label: 'User ID',
                  icon: Icons.tag_rounded,
                  color: const Color(0xFF475569),
                  onTap: onLookupId,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildQuickActionButton(
                  label: 'Contacts',
                  icon: Icons.contacts_rounded,
                  color: const Color(0xFF475569),
                  onTap: onFromContacts,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.w),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16.sp, color: color),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
