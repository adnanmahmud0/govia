import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/module/citizen/vault/controller/citizen_vault_controller.dart';
import 'package:gsabino365/module/citizen/vault/model/vault_models.dart';
import 'package:gsabino365/module/shared/schedule/controller/common_schedule_controller.dart';

class CommonScheduleView extends StatelessWidget {
  const CommonScheduleView({super.key});

  CommonScheduleController get controller {
    if (Get.isRegistered<CommonScheduleController>()) {
      return Get.find<CommonScheduleController>();
    }
    return Get.put(CommonScheduleController());
  }

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    final ctrl = controller;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Custom Header Bar ─────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                child: Row(
                  children: [
                    Container(
                      width: 42.r,
                      height: 42.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: const Color(0xFF1550A6),
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctrl.scheduleTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 18.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            ctrl.scheduleSubtitle,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Segmented Tab Filter (Upcoming vs Past) ───────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                child: Obx(() {
                  final isUpcoming = ctrl.selectedTab.value == 'Upcoming';
                  final upcomingCount = ctrl.upcomingMeetings.length;
                  final pastCount = ctrl.pastMeetings.length;

                  return Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => ctrl.selectedTab.value = 'Upcoming',
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              decoration: BoxDecoration(
                                color: isUpcoming ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(9.r),
                                boxShadow: isUpcoming
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Upcoming ($upcomingCount)',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: isUpcoming ? FontWeight.w700 : FontWeight.w500,
                                    color: isUpcoming ? const Color(0xFF1550A6) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => ctrl.selectedTab.value = 'Past',
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              decoration: BoxDecoration(
                                color: !isUpcoming ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(9.r),
                                boxShadow: !isUpcoming
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Past ($pastCount)',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: !isUpcoming ? FontWeight.w700 : FontWeight.w500,
                                    color: !isUpcoming ? const Color(0xFF1550A6) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              SizedBox(height: 10.h),

              // ─── Meeting List or Empty State ──────────────────────────────
              Expanded(
                child: Obx(() {
                  if (ctrl.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1550A6)),
                    );
                  }

                  final isUpcoming = ctrl.selectedTab.value == 'Upcoming';
                  final list = isUpcoming ? ctrl.upcomingMeetings : ctrl.pastMeetings;

                  if (list.isEmpty) {
                    return RefreshIndicator(
                      color: const Color(0xFF1550A6),
                      onRefresh: () => ctrl.fetchMyMeetings(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 80.h),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20.r),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isUpcoming ? Icons.event_available_rounded : Icons.history_rounded,
                                    size: 48.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  isUpcoming ? 'No upcoming consultations' : 'No past meetings found',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                                  child: Text(
                                    isUpcoming
                                        ? 'Consultations scheduled in your chat rooms will automatically appear here'
                                        : 'Concluded sessions and cloud recordings will appear here',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5.sp,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF1550A6),
                    onRefresh: () => ctrl.fetchMyMeetings(),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 80.h),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return _buildMeetingCard(context, item);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingCard(BuildContext context, Map<String, dynamic> meeting) {
    final meetingId = meeting['_id']?.toString() ?? meeting['id']?.toString() ?? '';
    final topic = meeting['topic']?.toString() ?? 'Consultation Session';
    final meetingType = meeting['meetingType']?.toString().toUpperCase() ?? 'SCHEDULED';
    final status = meeting['status']?.toString().toUpperCase() ?? 'ACTIVE';
    final recordingUrl = meeting['recordingUrl']?.toString() ?? '';
    final durationMinutes = meeting['durationMinutes'] ?? 30;
    final isCompleted = status == 'COMPLETED' || recordingUrl.isNotEmpty;
    final isCancelled = status == 'CANCELLED';
    final isInstant = meetingType == 'INSTANT' || status == 'ACTIVE';

    // Origin Category & Styling
    final rawCategory = meeting['category']?.toString().toUpperCase();
    final category = (rawCategory != null && rawCategory.isNotEmpty)
        ? rawCategory
        : (meetingType == 'EMERGENCY'
            ? 'EMERGENCY'
            : (topic.toLowerCase().contains('govia') ? 'ENCOUNTER' : 'CONSULTATION'));

    Color categoryColor = const Color(0xFF7C3AED);
    Color categoryBg = const Color(0xFFF5F3FF);
    IconData categoryIcon = Icons.video_call_rounded;
    String categoryName = 'CONSULTATION';

    if (category == 'DUTY' || category == 'DUTY BRIEFING') {
      categoryColor = const Color(0xFF0284C7);
      categoryBg = const Color(0xFFF0F9FF);
      categoryIcon = Icons.badge_outlined;
      categoryName = 'DUTY BRIEFING';
    } else if (category == 'BAIL' || category == 'BAIL VERIFICATION') {
      categoryColor = const Color(0xFF059669);
      categoryBg = const Color(0xFFECFDF5);
      categoryIcon = Icons.gavel_rounded;
      categoryName = 'BAIL CONSULTATION';
    } else if (category == 'LEGAL') {
      categoryColor = const Color(0xFF4F46E5);
      categoryBg = const Color(0xFFEEF2FF);
      categoryIcon = Icons.balance_rounded;
      categoryName = 'LEGAL CONSULTATION';
    } else if (category == 'ENCOUNTER') {
      categoryColor = const Color(0xFF1550A6);
      categoryBg = const Color(0xFFEFF6FF);
      categoryIcon = Icons.shield_rounded;
      categoryName = 'GOVIA ENCOUNTER';
    } else if (category == 'EMERGENCY') {
      categoryColor = const Color(0xFFDC2626);
      categoryBg = const Color(0xFFFEF2F2);
      categoryIcon = Icons.warning_amber_rounded;
      categoryName = 'EMERGENCY SOS';
    }

    // Vault folder linkage info
    Map<String, dynamic>? vaultFolder;
    if (meeting['vaultFolderId'] is Map) {
      vaultFolder = Map<String, dynamic>.from(meeting['vaultFolderId'] as Map);
    }
    final isInVault = vaultFolder != null;
    final vaultFolderName = vaultFolder?['name']?.toString() ?? '';
    final vaultFolderId = vaultFolder?['_id']?.toString() ?? '';

    // Formatted date & time
    String formattedDate = 'Now';
    if (meeting['startTime'] != null) {
      try {
        final d = DateTime.parse(meeting['startTime'].toString()).toLocal();
        formattedDate = DateFormat('EEE, MMM d, yyyy • h:mm a').format(d);
      } catch (_) {}
    }

    // Counterpart name / participant
    final callerName = meeting['callerName']?.toString();

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : isCancelled
                  ? const Color(0xFFE2E8F0)
                  : categoryColor.withValues(alpha: 0.35),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Category Badge + Status Badge + Options Popup
          Row(
            children: [
              // Category Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: categoryBg,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(categoryIcon, size: 12.sp, color: categoryColor),
                    SizedBox(width: 4.w),
                    Text(
                      categoryName,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFECFDF5)
                      : isCancelled
                          ? const Color(0xFFF1F5F9)
                          : isInstant
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isInstant && !isCompleted && !isCancelled) ...[
                      Container(
                        width: 6.r,
                        height: 6.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                    ],
                    Text(
                      isCompleted
                          ? 'RECORDED'
                          : isCancelled
                              ? 'CANCELLED'
                              : isInstant
                                  ? 'LIVE NOW'
                                  : 'UPCOMING',
                      style: GoogleFonts.inter(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? const Color(0xFF059669)
                            : isCancelled
                                ? const Color(0xFF64748B)
                                : isInstant
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF1550A6),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded, size: 18.sp, color: const Color(0xFF94A3B8)),
                onSelected: (val) {
                  if (val == 'reschedule') {
                    controller.showRescheduleDialog(meeting);
                  } else if (val == 'cancel') {
                    controller.confirmCancelMeeting(meetingId);
                  } else if (val == 'delete') {
                    controller.confirmDeleteMeeting(meetingId);
                  } else if (val == 'record') {
                    controller.showRecordingDialog(meeting);
                  } else if (val == 'vault') {
                    controller.showAddToVaultModal(meeting);
                  } else if (val == 'open_vault') {
                    _navigateToVaultFolder(vaultFolderId, vaultFolderName, category);
                  }
                },
                itemBuilder: (ctx) => [
                  if (isCompleted) ...[
                    const PopupMenuItem(
                      value: 'record',
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_fill_rounded, size: 18, color: Color(0xFF1550A6)),
                          SizedBox(width: 8),
                          Text('Watch Recording'),
                        ],
                      ),
                    ),
                    if (isInVault)
                      const PopupMenuItem(
                        value: 'open_vault',
                        child: Row(
                          children: [
                            Icon(Icons.folder_open_rounded, size: 18, color: Color(0xFF16A34A)),
                            SizedBox(width: 8),
                            Text('Open in Vault'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'vault',
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 18, color: Color(0xFF059669)),
                            SizedBox(width: 8),
                            Text('Add to Vault'),
                          ],
                        ),
                      ),
                  ],
                  if (!isCompleted && !isCancelled) ...[
                    const PopupMenuItem(
                      value: 'reschedule',
                      child: Row(
                        children: [
                          Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF1550A6)),
                          SizedBox(width: 8),
                          Text('Reschedule'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFD97706)),
                          SizedBox(width: 8),
                          Text('Cancel Meeting'),
                        ],
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Delete Meeting', style: TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // In Vault Badge (if linked)
          if (isInVault) ...[
            SizedBox(height: 8.h),
            InkWell(
              onTap: () => _navigateToVaultFolder(vaultFolderId, vaultFolderName, category),
              borderRadius: BorderRadius.circular(6.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_rounded, size: 13.sp, color: const Color(0xFF16A34A)),
                    SizedBox(width: 5.w),
                    Flexible(
                      child: Text(
                        'In Vault: $vaultFolderName',
                        style: GoogleFonts.inter(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15803D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.arrow_forward_ios_rounded, size: 9.sp, color: const Color(0xFF15803D)),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 8.h),

          // Topic / Agenda
          Text(
            topic,
            style: GoogleFonts.outfit(
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),

          if (callerName != null && callerName.isNotEmpty && !topic.contains(callerName)) ...[
            SizedBox(height: 3.h),
            Text(
              'Participant: $callerName',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          SizedBox(height: 8.h),

          // Time & Duration
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14.sp, color: const Color(0xFF64748B)),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Text('•', style: TextStyle(color: const Color(0xFFCBD5E1), fontSize: 14.sp)),
              SizedBox(width: 8.w),
              Text(
                '$durationMinutes mins',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // Action Buttons
          if (isCompleted)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.showRecordingDialog(meeting),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                    label: Text(
                      'Recording',
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: isInVault
                      ? OutlinedButton.icon(
                          onPressed: () => _navigateToVaultFolder(vaultFolderId, vaultFolderName, category),
                          icon: const Icon(Icons.folder_open_rounded, size: 16, color: Color(0xFF16A34A)),
                          label: Text(
                            'View in Vault',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            side: const BorderSide(color: Color(0xFF16A34A), width: 1.2),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => controller.showAddToVaultModal(meeting),
                          icon: const Icon(Icons.shield_outlined, size: 16),
                          label: Text(
                            'Add to Vault',
                            style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1550A6),
                            side: const BorderSide(color: Color(0xFF1550A6), width: 1.2),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                        ),
                ),
              ],
            )
          else if (isCancelled)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'Cancelled',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => controller.joinMeeting(meeting),
                    icon: const Icon(Icons.video_call_rounded, size: 18),
                    label: Text(
                      isInstant ? 'Join Live Call' : 'Join Consultation Room',
                      style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInstant ? const Color(0xFFDC2626) : const Color(0xFF1550A6),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                InkWell(
                  onTap: () => controller.showRescheduleDialog(meeting),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFF1550A6).withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.edit_calendar_rounded, size: 18.sp, color: const Color(0xFF1550A6)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _navigateToVaultFolder(String folderId, String folderName, String category) {
    if (folderId.isEmpty) return;
    CitizenVaultController vaultCtrl;
    try {
      vaultCtrl = Get.find<CitizenVaultController>();
    } catch (_) {
      vaultCtrl = Get.put(CitizenVaultController());
    }
    final existing = vaultCtrl.folders.firstWhereOrNull((f) => f.id == folderId);
    final target = existing ??
        VaultFolderModel(
          id: folderId,
          name: folderName.isNotEmpty ? folderName : 'Vault Folder',
          description: '',
          category: category,
          location: '',
          incidentDate: DateTime.now(),
          isArchived: false,
          itemCount: 1,
          counts: {'video': 1},
          createdAt: DateTime.now(),
        );
    Get.toNamed(AppRoutes.citizenVaultFolderDetails, arguments: target);
  }
}
