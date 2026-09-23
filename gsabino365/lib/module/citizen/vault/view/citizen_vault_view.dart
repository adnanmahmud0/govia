import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/core/widgets/govia_video_player_view.dart';
import 'package:gsabino365/module/citizen/vault/controller/citizen_vault_controller.dart';
import 'package:gsabino365/module/citizen/vault/model/vault_models.dart';
import 'package:gsabino365/module/citizen/vault/widgets/vault_share_modal.dart';

class CitizenVaultView extends GetView<CitizenVaultController> {
  const CitizenVaultView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1550A6), size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.shield_outlined, color: const Color(0xFF1550A6), size: 22.sp),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evidence Vault',
                    style: GoogleFonts.inter(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Tamper-Proof • Encrypted Storage',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1550A6)),
              tooltip: 'Refresh Vault',
              onPressed: () {
                controller.fetchFolders();
                controller.fetchSharedFolders();
                controller.fetchAllRecordings();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                controller.fetchFolders(showLoader: false),
                controller.fetchSharedFolders(showLoader: false),
                controller.fetchAllRecordings(showLoader: false),
              ]);
            },
            color: const Color(0xFF1550A6),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Metric Cards
                      _buildMetricCards(),

                      // Segmented 3-Tab Switcher
                      _buildTabBar(),

                      // Search Input
                      _buildSearchBar(),

                      SizedBox(height: 8.h),

                      // Dynamic Section Header
                      _buildSectionHeader(context),
                      SizedBox(height: 6.h),
                    ],
                  ),
                ),

                // Dynamic Body based on Selected Tab
                Obx(() {
                  final tab = controller.selectedTab.value;
                  if (tab == 'Recordings') {
                    return _buildAllRecordingsList(context);
                  } else if (tab == 'My Folders') {
                    return _buildMyFoldersList(context);
                  } else {
                    return _buildSharedWithMeList(context);
                  }
                }),
              ],
            ),
          ),
        ),
        floatingActionButton: Obx(() {
          if (controller.selectedTab.value != 'My Folders') {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _showCreateFolderDialog(),
            backgroundColor: const Color(0xFF1550A6),
            elevation: 4,
            icon: const Icon(Icons.create_new_folder_rounded, color: Colors.white),
            label: Text(
              'New Folder',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ──────────────────────── SEGMENTED TAB SWITCHER ────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final current = controller.selectedTab.value;
        return Row(
          children: [
            _buildTabButton(
              title: 'Recordings',
              icon: Icons.videocam_rounded,
              isSelected: current == 'Recordings',
              count: controller.allRecordings.length,
              onTap: () => controller.switchTab('Recordings'),
            ),
            _buildTabButton(
              title: 'My Folders',
              icon: Icons.folder_rounded,
              isSelected: current == 'My Folders',
              count: controller.folders.length,
              onTap: () => controller.switchTab('My Folders'),
            ),
            _buildTabButton(
              title: 'Shared',
              icon: Icons.folder_shared_rounded,
              isSelected: current == 'Shared' || current == 'Shared with Me',
              count: controller.sharedFolders.length,
              onTap: () => controller.switchTab('Shared'),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required int count,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1550A6) : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14.sp,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────── SECTION HEADER ────────────────────────
  Widget _buildSectionHeader(BuildContext context) {
    return Obx(() {
      final tab = controller.selectedTab.value;
      if (tab == 'Recordings') {
        final count = controller.filteredRecordings.length;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Session Recordings ($count)',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Encounters & Consultations',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1550A6),
                ),
              ),
            ],
          ),
        );
      } else if (tab == 'My Folders') {
        final count = controller.filteredFolders.length;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Case Folders ($count)',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Full Edit & Share Access',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showCreateFolderDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Create New Vault Folder',
                    style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1550A6),
                    side: const BorderSide(color: Color(0xFF1550A6), width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (tab == 'Shared with Me') {
        final count = controller.filteredSharedFolders.length;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shared Folders ($count)',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 12.sp, color: const Color(0xFF059669)),
                    SizedBox(width: 4.w),
                    Text(
                      'View-Only Access',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        final count = controller.filteredRecordings.length;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Recordings ($count)',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Encounters & Consultations',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  // ──────────────────────── LIST 1: MY FOLDERS ────────────────────────
  Widget _buildMyFoldersList(BuildContext context) {
    if (controller.isLoading.value) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF1550A6))),
      );
    }

    final folders = controller.filteredFolders;
    if (folders.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final folder = folders[index];
            return _buildFolderCard(context, folder);
          },
          childCount: folders.length,
        ),
      ),
    );
  }

  // ──────────────────────── LIST 2: SHARED WITH ME ────────────────────────
  Widget _buildSharedWithMeList(BuildContext context) {
    if (controller.isLoadingShared.value) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF1550A6))),
      );
    }

    final shared = controller.filteredSharedFolders;
    if (shared.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(22.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.folder_shared_outlined, size: 56.sp, color: const Color(0xFF059669)),
                ),
                SizedBox(height: 18.h),
                Text(
                  'No Shared Folders Yet',
                  style: GoogleFonts.inter(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Folders shared with you by other members, attorneys, or clients will appear here with encrypted view-only access.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final folder = shared[index];
            return _buildSharedFolderCard(context, folder);
          },
          childCount: shared.length,
        ),
      ),
    );
  }

  // ──────────────────────── LIST 3: ALL RECORDINGS ────────────────────────
  Widget _buildAllRecordingsList(BuildContext context) {
    if (controller.isLoadingRecordings.value) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF1550A6))),
      );
    }

    final recordings = controller.filteredRecordings;
    if (recordings.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(22.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.videocam_outlined, size: 56.sp, color: const Color(0xFF1550A6)),
                ),
                SizedBox(height: 18.h),
                Text(
                  'No Recordings Found',
                  style: GoogleFonts.inter(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'All completed GoVia emergency encounters and consultations will be recorded and organized here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final rec = recordings[index];
            return _buildRecordingCard(context, rec);
          },
          childCount: recordings.length,
        ),
      ),
    );
  }

  // ──────────────────────── FOLDER CARD (OWNER) ────────────────────────
  Widget _buildFolderCard(BuildContext context, VaultFolderModel folder) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            Get.toNamed(
              AppRoutes.citizenVaultFolderDetails,
              arguments: folder,
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1550A6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        color: const Color(0xFF1550A6),
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (folder.description.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              folder.description,
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: const Color(0xFF64748B),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Quick Share Icon Button
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: Color(0xFF1550A6), size: 20),
                      tooltip: 'Share Folder',
                      onPressed: () => VaultShareModal.show(context, folder: folder),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8), size: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      onSelected: (val) {
                        if (val == 'open') {
                          Get.toNamed(AppRoutes.citizenVaultFolderDetails, arguments: folder);
                        } else if (val == 'share') {
                          VaultShareModal.show(context, folder: folder);
                        } else if (val == 'delete') {
                          _showDeleteFolderDialog(folder);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              const Icon(Icons.folder_open_rounded, size: 18, color: Color(0xFF1550A6)),
                              SizedBox(width: 8.w),
                              Text('Open Folder', style: GoogleFonts.inter(fontSize: 13.sp)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              const Icon(Icons.share_rounded, size: 18, color: Color(0xFF059669)),
                              SizedBox(width: 8.w),
                              Text('Share Folder', style: GoogleFonts.inter(fontSize: 13.sp)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                              SizedBox(width: 8.w),
                              Text('Delete Folder', style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFFDC2626))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 12.h),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                SizedBox(height: 10.h),

                // Bottom Row: Date & Evidence Breakdown
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 13.sp, color: const Color(0xFF94A3B8)),
                    SizedBox(width: 5.w),
                    Text(
                      folder.formattedDate,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        folder.evidenceSummary,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
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
        ),
      ),
    );
  }

  // ──────────────────────── SHARED FOLDER CARD (VIEW-ONLY) ────────────────────────
  Widget _buildSharedFolderCard(BuildContext context, VaultFolderModel folder) {
    final sharedByName = folder.sharedByName ?? 'Govia Member';
    final sharedByRole = folder.sharedByRole ?? 'User';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            Get.toNamed(
              AppRoutes.citizenVaultFolderDetails,
              arguments: folder,
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.folder_shared_rounded,
                        color: const Color(0xFF059669),
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  folder.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  'VIEW ONLY',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.person_rounded, size: 13.sp, color: const Color(0xFF64748B)),
                              SizedBox(width: 4.w),
                              Text(
                                'Shared by: $sharedByName ($sharedByRole)',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1550A6),
                                ),
                              ),
                            ],
                          ),
                          if (folder.description.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              folder.description,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                SizedBox(height: 10.h),

                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 13.sp, color: const Color(0xFF94A3B8)),
                    SizedBox(width: 5.w),
                    Text(
                      folder.formattedDate,
                      style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        folder.evidenceSummary,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
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
        ),
      ),
    );
  }

  // ──────────────────────── RECORDING CARD ────────────────────────
  Widget _buildRecordingCard(BuildContext context, Map<String, dynamic> rec) {
    final title = (rec['topic'] ?? rec['title'] ?? 'Incident Session Recording').toString();
    final meetingId = (rec['meetingId'] is Map
        ? rec['meetingId']['_id']
        : rec['meetingId'] ?? rec['_id'] ?? rec['id'] ?? '').toString();
    final callerName = (rec['callerName'] ?? rec['hostName'] ?? rec['name'] ?? 'Citizen Encounter').toString();
    final category = (rec['category'] ?? (rec['meetingType'] == 'EMERGENCY' ? 'EMERGENCY' : 'CONSULTATION')).toString().toUpperCase();

    // Check if already linked to a folder
    final linkedFolder = rec['vaultFolderId'] ?? rec['folderId'];
    String? folderName;
    if (linkedFolder is Map) {
      folderName = linkedFolder['name']?.toString();
    }

    DateTime? createdAt;
    if (rec['createdAt'] != null) {
      createdAt = DateTime.tryParse(rec['createdAt'].toString());
    }
    final dateStr = createdAt != null ? DateFormat('MMM dd, yyyy • h:mm a').format(createdAt) : 'Recently Recorded';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(Icons.videocam_rounded, color: Color(0xFFDC2626), size: 24),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Recorded session with $callerName',
                      style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1550A6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1550A6)),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 13.sp, color: const Color(0xFF94A3B8)),
              SizedBox(width: 4.w),
              Text(dateStr, style: GoogleFonts.inter(fontSize: 11.5.sp, color: const Color(0xFF94A3B8))),
              if (folderName != null && folderName.isNotEmpty) ...[
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 12.sp, color: const Color(0xFF1D4ED8)),
                      SizedBox(width: 4.w),
                      Text(
                        folderName,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1D4ED8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showWatchRecordingDialog(context, rec),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                  label: Text('Watch', style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddToFolderModal(context, meetingId, title),
                  icon: Icon(folderName != null ? Icons.drive_file_move_rounded : Icons.drive_file_move_outline, size: 16),
                  label: Text(folderName != null ? 'Move / Add' : 'Add to Folder', style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1550A6),
                    side: const BorderSide(color: Color(0xFF1550A6), width: 1.2),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────── WATCH RECORDING DIALOG ────────────────────────
  void _showWatchRecordingDialog(BuildContext context, Map<String, dynamic> rec) {
    final title = (rec['topic'] ?? rec['title'] ?? 'Meeting Recording').toString();
    final url = (rec['recordingUrl'] ?? rec['fileUrl'] ?? '').toString();

    if (url.isNotEmpty) {
      // Directly launch the resilient native in-app Video Player
      GoviaVideoPlayerView.open(
        url: url,
        title: title,
        subtitle: 'Tamper-Proof Encrypted Session Recording',
        date: rec['createdAt']?.toString(),
      );
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.r,
                height: 56.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_top_rounded, color: const Color(0xFFD97706), size: 30.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 17.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Cloud Recording Processing',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFD97706), fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16.h),
              Text(
                'Your session recording is finalizing in secure cloud storage. It will be playable here shortly.',
                style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1550A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text('OK', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────── ADD RECORDING TO FOLDER MODAL ────────────────────────
  void _showAddToFolderModal(BuildContext context, String meetingId, String topic) {
    if (controller.folders.isEmpty) {
      Helpers.showWarning('Please create a vault folder first');
      _showCreateFolderDialog();
      return;
    }

    final availableFolders = controller.folders
        .where((f) => !f.linkedMeetingIds.contains(meetingId))
        .toList();

    if (availableFolders.isEmpty) {
      Helpers.showInfo('This recording is already added to all your vault folders.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.drive_file_move_rounded, color: const Color(0xFF1550A6), size: 22.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Select Case Folder',
                    style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'Attach recording "$topic" to an existing case folder:',
              style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF64748B)),
            ),
            SizedBox(height: 16.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 280.h),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: availableFolders.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (c, idx) {
                  final folder = availableFolders[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    tileColor: const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    leading: const Icon(Icons.folder_rounded, color: Color(0xFF1550A6)),
                    title: Text(
                      folder.name,
                      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                    subtitle: Text('${folder.itemCount} files • ${folder.categoryDisplayName}', style: GoogleFonts.inter(fontSize: 11.5.sp, color: const Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await controller.linkMeetingToFolder(
                        folderId: folder.id,
                        meetingId: meetingId,
                        title: topic,
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── METRICS OVERVIEW ────────────────────────
  Widget _buildMetricCards() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
      child: Obx(() {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Active Folders',
                    value: '${controller.totalFolders}',
                    icon: Icons.folder_rounded,
                    color: const Color(0xFF60A5FA),
                  ),
                ),
                Container(width: 1.w, height: 36.h, color: Colors.white12),
                Expanded(
                  child: _buildStatItem(
                    label: 'Total Evidence',
                    value: '${controller.totalEvidenceItems}',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF34D399),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Container(height: 1.h, color: Colors.white12),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMediaTypeCount(Icons.videocam_rounded, '${controller.totalVideos} Videos', const Color(0xFFF87171)),
                _buildMediaTypeCount(Icons.mic_rounded, '${controller.totalAudios} Audios', const Color(0xFFFBBF24)),
                _buildMediaTypeCount(Icons.image_rounded, '${controller.totalImages} Photos', const Color(0xFF60A5FA)),
                _buildMediaTypeCount(Icons.description_rounded, '${controller.totalDocs} Docs', const Color(0xFFA78BFA)),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatItem({required String label, required String value, required IconData icon, required Color color}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: color, size: 22.sp),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(label, style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white60)),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaTypeCount(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 4.w),
        Text(text, style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w500, color: Colors.white70)),
      ],
    );
  }

  // ──────────────────────── SEARCH BAR ────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextField(
          onChanged: controller.setSearchQuery,
          style: GoogleFonts.inter(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'Search folders, shared cases, or recordings...',
            hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
            suffixIcon: Obx(() {
              if (controller.searchQuery.value.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                onPressed: () => controller.setSearchQuery(''),
              );
            }),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── EMPTY STATE ────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(22.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1550A6).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_outlined, size: 60.sp, color: const Color(0xFF1550A6)),
            ),
            SizedBox(height: 20.h),
            Text(
              'No Vault Folders Found',
              style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
            SizedBox(height: 8.h),
            Text(
              'Create a folder to store video records, emergency logs, or meeting proof.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF64748B), height: 1.4),
            ),
            SizedBox(height: 22.h),
            ElevatedButton.icon(
              onPressed: _showCreateFolderDialog,
              icon: const Icon(Icons.create_new_folder_rounded, color: Colors.white, size: 18),
              label: Text('Create New Folder', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1550A6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── CREATE FOLDER DIALOG ────────────────────────
  void _showCreateFolderDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'New Vault Folder',
          style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a case folder to store your recordings and evidence.',
              style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Folder Title *',
                hintText: 'e.g., Traffic Stop on Hwy 101',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Notes regarding what occurred...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen == true) Get.back();
            },
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          Obx(() {
            final isLoading = controller.isActionLoading.value;
            return ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final title = nameCtrl.text.trim();
                      if (title.isEmpty) {
                        Helpers.showWarning('Please enter a folder title');
                        return;
                      }
                      final newFolder = await controller.createFolder(
                        name: title,
                        description: descCtrl.text.trim(),
                        showSuccessToast: false,
                      );
                      if (newFolder != null) {
                        if (Get.isDialogOpen == true) Get.back();
                        if (Get.isBottomSheetOpen == true) Get.back();
                        Helpers.showSuccess('Folder "${newFolder.name}" created successfully');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1550A6),
                disabledBackgroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text('Create Folder', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            );
          }),
        ],
      ),
    );
  }

  // ──────────────────────── DELETE FOLDER DIALOG ────────────────────────
  void _showDeleteFolderDialog(VaultFolderModel folder) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Delete Folder?', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${folder.name}" and all attached evidence files? This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteFolder(folder.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
