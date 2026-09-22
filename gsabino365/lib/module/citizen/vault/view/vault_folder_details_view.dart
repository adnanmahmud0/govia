import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/module/citizen/vault/controller/citizen_vault_controller.dart';
import 'package:gsabino365/module/citizen/vault/model/vault_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class VaultFolderDetailsView extends StatefulWidget {
  const VaultFolderDetailsView({super.key});

  @override
  State<VaultFolderDetailsView> createState() => _VaultFolderDetailsViewState();
}

class _VaultFolderDetailsViewState extends State<VaultFolderDetailsView> {
  late final CitizenVaultController controller;
  late VaultFolderModel folder;
  String selectedTypeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    controller = Get.find<CitizenVaultController>();
    folder = Get.arguments as VaultFolderModel;
    controller.fetchFolderDetails(folder.id, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
            onPressed: () => Get.back(),
          ),
          title: Text(
            folder.name,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1550A6)),
              tooltip: 'Refresh Evidence',
              onPressed: () => controller.fetchFolderDetails(folder.id, forceRefresh: true),
            ),
            if (!folder.isReadOnly)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showEditFolderDialog();
                  } else if (val == 'delete') {
                    _showDeleteFolderDialog();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1550A6)),
                        SizedBox(width: 8.w),
                        Text('Edit Folder Info', style: GoogleFonts.inter(fontSize: 14.sp)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                        SizedBox(width: 8.w),
                        Text('Delete Folder', style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFFDC2626))),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            if (folder.isReadOnly)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                color: const Color(0xFFEFF6FF),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: Color(0xFF1D4ED8), size: 16),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Shared Folder • View-Only mode (Upload & deletion restricted)',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildFolderHeader(),
            _buildFilterChips(),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingFolderDetails.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1550A6)),
                  );
                }

                final allItems = controller.folderItemsCache[folder.id] ?? [];
                final filteredItems = allItems.where((item) {
                  if (selectedTypeFilter == 'ALL') return true;
                  return item.fileType == selectedTypeFilter;
                }).toList();

                if (filteredItems.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 80.h),
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildEvidenceItemCard(item);
                  },
                );
              }),
            ),
          ],
        ),
        floatingActionButton: folder.isReadOnly
            ? null
            : FloatingActionButton.extended(
                onPressed: _showAddEvidenceBottomSheet,
                backgroundColor: const Color(0xFF1550A6),
                elevation: 4,
                icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
                label: Text(
                  'Add Evidence',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  // ──────────────────────── FOLDER HEADER ────────────────────────
  Widget _buildFolderHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: const Color(0xFF1550A6).withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open_rounded, size: 14.sp, color: const Color(0xFF1550A6)),
                    SizedBox(width: 5.w),
                    Text(
                      'Case Folder',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1550A6),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.shield_rounded, size: 14.sp, color: const Color(0xFF059669)),
              SizedBox(width: 4.w),
              Text(
                'Tamper-Proof',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          if (folder.description.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              folder.description,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ],
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14.sp, color: const Color(0xFF64748B)),
              SizedBox(width: 4.w),
              Text(
                folder.formattedDate,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (folder.location.isNotEmpty) ...[
                SizedBox(width: 12.w),
                Icon(Icons.location_on_rounded, size: 14.sp, color: const Color(0xFF64748B)),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    folder.location,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────── FILTER CHIPS ────────────────────────
  Widget _buildFilterChips() {
    final filters = [
      {'key': 'ALL', 'label': 'All'},
      {'key': 'VIDEO', 'label': 'Videos'},
      {'key': 'IMAGE', 'label': 'Photos'},
      {'key': 'AUDIO', 'label': 'Audio'},
      {'key': 'DOCUMENT', 'label': 'Docs'},
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = selectedTypeFilter == f['key'];
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedTypeFilter = f['key']!;
                  });
                },
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1550A6) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    f['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ──────────────────────── EVIDENCE ITEM CARD ────────────────────────
  Widget _buildEvidenceItemCard(VaultItemModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
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
          // Media Thumbnail or Preview Area
          if (item.fileType == 'IMAGE') _buildImagePreview(item)
          else if (item.fileType == 'VIDEO') _buildVideoPreview(item)
          else if (item.fileType == 'AUDIO') _buildAudioPreview(item)
          else _buildDocumentPreview(item),

          // Metadata & Controls
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Importance Badges Row
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Auto-assigned category badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: item.categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5.r),
                        border: Border.all(color: item.categoryColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.categoryIcon, size: 11.sp, color: item.categoryColor),
                          SizedBox(width: 4.w),
                          Text(
                            item.categoryDisplayName,
                            style: GoogleFonts.inter(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: item.categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Importance badge (for uploaded evidence or when importance is set)
                    if (item.category == 'UPLOADED' || item.importance != 'GENERAL')
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: item.importanceColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5.r),
                          border: Border.all(color: item.importanceColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.importanceIcon, size: 11.sp, color: item.importanceColor),
                            SizedBox(width: 4.w),
                            Text(
                              item.importanceDisplayName,
                              style: GoogleFonts.inter(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                color: item.importanceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Sub-category badge if present
                    if (item.subCategory.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(5.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          item.subCategory,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8.h),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: item.fileColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(item.fileIcon, color: item.fileColor, size: 18.sp),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayTitle,
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.description.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              item.description,
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
                SizedBox(height: 10.h),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      item.formattedDate,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    if (item.formattedFileSize.isNotEmpty) ...[
                      Text(' • ', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 11.sp)),
                      Text(
                        item.formattedFileSize,
                        style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                    const Spacer(),
                    // Download Button
                    Obx(() {
                      final isDownloading = controller.downloadingUrls.contains(item.fullUrl);
                      return isDownloading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1550A6)),
                            )
                          : InkWell(
                              onTap: () => controller.downloadEvidence(item),
                              borderRadius: BorderRadius.circular(8.r),
                              child: Padding(
                                padding: EdgeInsets.all(6.w),
                                child: Icon(
                                  Icons.download_rounded,
                                  color: const Color(0xFF1550A6),
                                  size: 20.sp,
                                ),
                              ),
                            );
                    }),
                    if (!folder.isReadOnly) ...[
                      SizedBox(width: 6.w),
                      // Delete Button
                      InkWell(
                        onTap: () => _confirmDeleteItem(item),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Padding(
                          padding: EdgeInsets.all(6.w),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: const Color(0xFFDC2626),
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── PREVIEWS ────────────────────────
  Widget _buildImagePreview(VaultItemModel item) {
    return GestureDetector(
      onTap: () => _openImageLightbox(item),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(13.r),
          topRight: Radius.circular(13.r),
        ),
        child: Stack(
          children: [
            Image.network(
              item.fullUrl,
              height: 180.h,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 140.h,
                color: const Color(0xFFE2E8F0),
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 36),
              ),
            ),
            Positioned(
              bottom: 8.h,
              right: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4.w),
                    Text('Tap to view', style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(VaultItemModel item) {
    return GestureDetector(
      onTap: () => _playMedia(item),
      child: Container(
        height: 160.h,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(13.r),
            topRight: Radius.circular(13.r),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.black.withValues(alpha: 0.3)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                color: const Color(0xFF1550A6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
            ),
            if (item.formattedDuration.isNotEmpty)
              Positioned(
                bottom: 10.h,
                right: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    item.formattedDuration,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPreview(VaultItemModel item) {
    return GestureDetector(
      onTap: () => _playMedia(item),
      child: Container(
        height: 90.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E1065), Color(0xFF4C1D95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(13.r),
            topRight: Radius.circular(13.r),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.h,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audio Recording / Evidence Log',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.formattedDuration.isNotEmpty ? 'Duration: ${item.formattedDuration}' : 'Tap to listen',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.graphic_eq_rounded, color: Colors.white60, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(VaultItemModel item) {
    return Container(
      height: 70.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(13.r),
          topRight: Radius.circular(13.r),
        ),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: const Icon(Icons.description_rounded, color: Color(0xFFD97706), size: 24),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              item.displayTitle,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1550A6).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.folder_open_rounded, size: 56.sp, color: const Color(0xFF1550A6)),
            ),
            SizedBox(height: 18.h),
            Text(
              'No Evidence in Folder',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Upload videos, photos, voice recordings or documents as proof for this incident.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: _showAddEvidenceBottomSheet,
              icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
              label: Text(
                'Add Evidence Now',
                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.white),
              ),
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

  // ──────────────────────── LIGHTBOX & MEDIA VIEWER ────────────────────────
  void _openImageLightbox(VaultItemModel item) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(color: Colors.black.withValues(alpha: 0.9)),
            ),
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  item.fullUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40.h,
              right: 16.w,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
                    onPressed: () => controller.downloadEvidence(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playMedia(VaultItemModel item) async {
    final fullUrl = item.fullUrl;
    if (fullUrl.isEmpty) return;
    try {
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        controller.downloadEvidence(item);
      }
    } catch (_) {
      controller.downloadEvidence(item);
    }
  }

  // ──────────────────────── ADD EVIDENCE SHEET ────────────────────────
  void _showAddEvidenceBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Add Incident Proof / Evidence',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Select the type of proof you want to add to this folder.',
              style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF64748B)),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.videocam_rounded,
                    title: 'Record Video',
                    color: const Color(0xFF1550A6),
                    onTap: () {
                      Get.back();
                      _pickAndUpload(type: 'video');
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.camera_alt_rounded,
                    title: 'Take Photo',
                    color: const Color(0xFF059669),
                    onTap: () {
                      Get.back();
                      _pickAndUpload(type: 'photo');
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.mic_rounded,
                    title: 'Audio File',
                    color: const Color(0xFF7C3AED),
                    onTap: () {
                      Get.back();
                      _pickAndUpload(type: 'audio');
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.description_rounded,
                    title: 'Document',
                    color: const Color(0xFFD97706),
                    onTap: () {
                      Get.back();
                      _pickAndUpload(type: 'document');
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload({required String type}) async {
    File? selectedFile;
    String detectedType = 'DOCUMENT';

    try {
      if (type == 'video') {
        final picker = ImagePicker();
        final picked = await picker.pickVideo(source: ImageSource.camera);
        if (picked != null) {
          selectedFile = File(picked.path);
          detectedType = 'VIDEO';
        } else {
          // Fallback to gallery
          final gallery = await picker.pickVideo(source: ImageSource.gallery);
          if (gallery != null) {
            selectedFile = File(gallery.path);
            detectedType = 'VIDEO';
          }
        }
      } else if (type == 'photo') {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
        if (picked != null) {
          selectedFile = File(picked.path);
          detectedType = 'IMAGE';
        } else {
          final gallery = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
          if (gallery != null) {
            selectedFile = File(gallery.path);
            detectedType = 'IMAGE';
          }
        }
      } else if (type == 'audio') {
        final result = await FilePicker.pickFiles(type: FileType.audio);
        if (result.isNotEmpty && result.first.path != null) {
          selectedFile = File(result.first.path!);
          detectedType = 'AUDIO';
        }
      } else {
        final result = await FilePicker.pickFiles(type: FileType.any);
        if (result.isNotEmpty && result.first.path != null) {
          selectedFile = File(result.first.path!);
          detectedType = 'DOCUMENT';
        }
      }

      if (selectedFile == null) return;

      // Ask for optional Title, Importance Level, Sub-Category & Description
      final titleCtrl = TextEditingController();
      final descCtrl = TextEditingController();
      final subCategoryCtrl = TextEditingController();
      final selectedImportance = 'GENERAL'.obs;

      final importanceOptions = [
        {
          'key': 'CRITICAL',
          'label': 'Critical Proof',
          'desc': 'Crucial encounter footage or violation proof',
          'color': const Color(0xFFDC2626),
        },
        {
          'key': 'HIGH',
          'label': 'High Importance',
          'desc': 'Key witness statement, citation, or damage proof',
          'color': const Color(0xFFEA580C),
        },
        {
          'key': 'SUPPORTING',
          'label': 'Supporting Proof',
          'desc': 'Context, ID photo, location receipt, or metadata',
          'color': const Color(0xFF2563EB),
        },
        {
          'key': 'GENERAL',
          'label': 'General Info',
          'desc': 'Standard background document or casual notes',
          'color': const Color(0xFF64748B),
        },
      ];

      final quickChips = [
        'Officer ID & Badge',
        'Traffic Citation',
        'Scene / Vehicle Damage',
        'Witness Statement',
        'Medical / Injury Report',
        'ID & Documentation',
      ];

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF1550A6), size: 20),
              ),
              SizedBox(width: 8.w),
              Text(
                'Evidence Details',
                style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categorize and describe your uploaded evidence for clear proof organization.',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
                ),
                SizedBox(height: 14.h),

                // Title
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Evidence Title',
                    hintText: 'e.g. Officer Badge interaction',
                    labelStyle: GoogleFonts.inter(fontSize: 12.sp),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
                SizedBox(height: 14.h),

                // Importance Level
                Text(
                  'Importance Level',
                  style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
                SizedBox(height: 6.h),
                Obx(() {
                  return DropdownButtonFormField<String>(
                    initialValue: selectedImportance.value,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    ),
                    items: importanceOptions.map((opt) {
                      final col = opt['color'] as Color;
                      final label = opt['label'] as String;
                      final key = opt['key'] as String;
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Row(
                          children: [
                            Container(
                              width: 10.w,
                              height: 10.h,
                              decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                            ),
                            SizedBox(width: 8.w),
                            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: col)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) selectedImportance.value = val;
                    },
                  );
                }),
                SizedBox(height: 14.h),

                // Sub-category / Tag
                Text(
                  'Evidence Sub-Category (Optional)',
                  style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
                SizedBox(height: 6.h),
                TextField(
                  controller: subCategoryCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Officer ID & Badge, Citation...',
                    hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 5.w,
                  runSpacing: 4.h,
                  children: quickChips.map((chip) {
                    return InkWell(
                      onTap: () {
                        subCategoryCtrl.text = chip;
                      },
                      borderRadius: BorderRadius.circular(4.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          chip,
                          style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFF475569)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 14.h),

                // Description
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description / Context (Optional)',
                    labelStyle: GoogleFonts.inter(fontSize: 12.sp),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                controller.uploadEvidence(
                  folderId: folder.id,
                  file: selectedFile!,
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  fileType: detectedType,
                  category: 'UPLOADED',
                  importance: selectedImportance.value,
                  subCategory: subCategoryCtrl.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1550A6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text('Upload Evidence', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    } catch (e) {
      Helpers.showError('Could not select evidence file: $e');
    }
  }

  // ──────────────────────── EDIT FOLDER DIALOG ────────────────────────
  void _showEditFolderDialog() {
    final nameCtrl = TextEditingController(text: folder.name);
    final descCtrl = TextEditingController(text: folder.description);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Edit Folder Details', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Folder Title *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Get.back();
              final ok = await controller.updateFolder(
                folderId: folder.id,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              if (ok) {
                setState(() {
                  folder = VaultFolderModel(
                    id: folder.id,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    category: folder.category,
                    location: folder.location,
                    incidentDate: folder.incidentDate,
                    isArchived: folder.isArchived,
                    itemCount: folder.itemCount,
                    counts: folder.counts,
                    createdAt: folder.createdAt,
                  );
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1550A6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── DELETE FOLDER DIALOG ────────────────────────
  void _showDeleteFolderDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Delete Folder?', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${folder.name}" and all attached evidence files? This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final ok = await controller.deleteFolder(folder.id);
              if (ok) {
                Get.back();
              }
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

  // ──────────────────────── DELETE ITEM DIALOG ────────────────────────
  void _confirmDeleteItem(VaultItemModel item) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Delete Evidence?', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to remove "${item.displayTitle}" from this folder?',
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
              controller.deleteEvidenceItem(itemId: item.id, folderId: folder.id);
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
