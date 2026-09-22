import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/module/shared/chat/controller/chat_controller.dart';

class ChatDetailsView extends GetView<ChatController> {
  const ChatDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 44.w,
          leading: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Center(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 34.r,
                  height: 34.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: const Color(0xFF1550A6),
                    size: 15.sp,
                  ),
                ),
              ),
            ),
          ),
          title: Obx(() {
            final partner = controller.activeChatPartner.value ?? {};
            final name = partner['name']?.toString() ?? 'GoVia User';
            final role = partner['role']?.toString() ?? 'CITIZEN';

            return GestureDetector(
              onTap: () => _showUserProfileModal(context, partner),
              child: Row(
                children: [
                  Builder(builder: (_) {
                    final avatarUrl = partner['profilePicture']?.toString() ??
                        partner['image']?.toString() ??
                        partner['avatar']?.toString();
                    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;
                    return Container(
                      width: 38.r,
                      height: 38.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1550A6), width: 1.5.w),
                      ),
                      child: ClipOval(
                        child: hasAvatar
                            ? Image.network(
                                ApiConstants.getFileUrl(avatarUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFEFF6FF),
                                  child: Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: GoogleFonts.outfit(
                                        fontSize: 17.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1550A6),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFEFF6FF),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: GoogleFonts.outfit(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1550A6),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    );
                  }),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(Icons.info_outline_rounded, size: 14.sp, color: const Color(0xFF94A3B8)),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              role.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1550A6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569)),
              onSelected: (val) {
                switch (val) {
                  case 'profile':
                    _showUserProfileModal(context, controller.activeChatPartner.value ?? {});
                    break;
                  case 'schedule':
                    _showScheduleMeetingModal(context);
                    break;
                  case 'instant':
                    controller.startInstantMeetingInChat();
                    break;
                  case 'delete_conv':
                    _confirmDeleteConversation(context);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF1550A6)),
                      SizedBox(width: 10),
                      Text('View User Profile'),
                    ],
                  ),
                ),
                if (controller.canScheduleInChat)
                  const PopupMenuItem(
                    value: 'schedule',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF7C3AED)),
                        SizedBox(width: 10),
                        Text('Schedule Meeting'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'instant',
                  child: Row(
                    children: [
                      Icon(Icons.videocam_outlined, size: 18, color: Color(0xFF2563EB)),
                      SizedBox(width: 10),
                      Text('Start Instant Meeting'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete_conv',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      SizedBox(width: 10),
                      Text('Delete Conversation', style: TextStyle(color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.h),
            child: Container(color: const Color(0xFFE2E8F0), height: 1.h),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Chat Messages Stream
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingMessages.value && controller.chatMessages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.chatMessages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.r),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                color: const Color(0xFF1550A6),
                                size: 32.sp,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'End-to-End Encrypted Session',
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'Messages, file attachments, and meeting schedules are secured with GoVia protocols.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12.5.sp,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              alignment: WrapAlignment.center,
                              children: [
                                if (controller.canScheduleInChat)
                                  ActionChip(
                                    avatar: const Icon(Icons.calendar_month_rounded, size: 16),
                                    label: const Text('Schedule Meeting'),
                                    onPressed: () => _showScheduleMeetingModal(context),
                                  ),
                                if (controller.isPartnerMentalHealthProfessional && controller.isCurrentUserCitizen)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.info_outline_rounded, size: 15.sp, color: const Color(0xFF1550A6)),
                                        SizedBox(width: 6.w),
                                        Text(
                                          'Doctor will schedule consultation in this chat',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5.sp,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1550A6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ActionChip(
                                  avatar: const Icon(Icons.videocam_rounded, size: 16),
                                  label: const Text('Instant Consultation'),
                                  onPressed: () => controller.startInstantMeetingInChat(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller.scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    itemCount: controller.chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = controller.chatMessages[index];
                      return _buildMessageBubble(context, message);
                    },
                  );
                }),
              ),

              // Inline Edit Message Banner (WhatsApp style)
              Obx(() {
                final editing = controller.editingMessage.value;
                if (editing == null) return const SizedBox.shrink();

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    border: Border(top: BorderSide(color: const Color(0xFFFDE68A), width: 1.h)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_rounded, color: Color(0xFFB45309), size: 18),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Editing Message',
                              style: GoogleFonts.inter(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            Text(
                              editing['text']?.toString() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: const Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF92400E)),
                        onPressed: controller.cancelEditing,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),

              // Message Input Bar
              _buildInputBar(context),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────── MESSAGE BUBBLE BUILDER ────────────────────────────

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> message) {
    final senderId = (message['sender'] is Map
            ? message['sender']['_id'] ?? message['sender']['id']
            : message['sender'])
        ?.toString();
    final isMe = senderId == controller.currentUserId;
    final isDeleted = message['isDeleted'] == true;
    final isEdited = message['isEdited'] == true;
    final text = message['text']?.toString() ?? '';
    final messageType = message['messageType']?.toString() ?? 'text';
    final timestamp = controller.formatTimestamp(message['createdAt']);
    final attachment = message['attachment']?.toString();
    final meetingId = message['meetingId'];

    final partner = controller.activeChatPartner.value ?? {};
    final partnerAvatar = partner['profilePicture']?.toString() ??
        partner['image']?.toString() ??
        partner['avatar']?.toString();
    final partnerInitial = (partner['name']?.toString().isNotEmpty ?? false)
        ? partner['name']!.toString()[0].toUpperCase()
        : '?';

    return GestureDetector(
      onLongPress: () => _showMessageContextMenu(context, message, isMe),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              Padding(
                padding: EdgeInsets.only(right: 8.w, bottom: 20.h),
                child: Container(
                  width: 30.r,
                  height: 30.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: ClipOval(
                    child: (partnerAvatar != null && partnerAvatar.trim().isNotEmpty)
                        ? Image.network(
                            ApiConstants.getFileUrl(partnerAvatar),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildBubbleInitial(partnerInitial),
                          )
                        : _buildBubbleInitial(partnerInitial),
                  ),
                ),
              ),
            ],
            Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
            // Deleted Message Bubble
            if (isDeleted)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block_rounded, size: 14.sp, color: const Color(0xFF94A3B8)),
                    SizedBox(width: 6.w),
                    Text(
                      'This message was deleted',
                      style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              )
            // Meeting Invitation Message Bubble (Fiverr Style)
            else if (messageType == 'meeting' || meetingId != null)
              _buildMeetingMessageCard(context, message, isMe)
            // Regular Text / Image / File Message Bubble
            else
              Container(
                constraints: BoxConstraints(maxWidth: 280.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF1550A6) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft: isMe ? Radius.circular(16.r) : Radius.circular(4.r),
                    bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(16.r),
                  ),
                  border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x04000000),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview if present
                    if (attachment != null && attachment.isNotEmpty && messageType == 'image')
                      Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _openImageViewer(
                                context,
                                attachment,
                                attachment.split('/').last,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.network(
                                  ApiConstants.getFileUrl(attachment),
                                  height: 160.h,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    height: 80.h,
                                    color: Colors.black12,
                                    child: const Center(child: Icon(Icons.broken_image)),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8.h,
                              right: 8.w,
                              child: Obx(() {
                                final fullUrl = ApiConstants.getFileUrl(attachment);
                                final isDownloading = controller.downloadingUrls.contains(fullUrl);
                                return GestureDetector(
                                  onTap: () => controller.downloadAttachment(
                                    attachmentPath: attachment,
                                    isImage: true,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      shape: BoxShape.circle,
                                    ),
                                    child: isDownloading
                                        ? SizedBox(
                                            width: 16.r,
                                            height: 16.r,
                                            child: const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            Icons.download_rounded,
                                            color: Colors.white,
                                            size: 16.sp,
                                          ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      )
                    // File document preview if present
                    else if (attachment != null && attachment.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: GestureDetector(
                          onTap: () => controller.downloadAttachment(
                            attachmentPath: attachment,
                            isImage: false,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: isMe ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.insert_drive_file_rounded,
                                    color: isMe ? Colors.white : const Color(0xFF1550A6),
                                    size: 18.sp,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attachment.split('/').last,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          color: isMe ? Colors.white : const Color(0xFF0F172A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Tap to download',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.sp,
                                          color: isMe ? Colors.white70 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Obx(() {
                                  final fullUrl = ApiConstants.getFileUrl(attachment);
                                  final isDownloading = controller.downloadingUrls.contains(fullUrl);
                                  if (isDownloading) {
                                    return SizedBox(
                                      width: 18.r,
                                      height: 18.r,
                                      child: CircularProgressIndicator(
                                        color: isMe ? Colors.white : const Color(0xFF1550A6),
                                        strokeWidth: 2,
                                      ),
                                    );
                                  }
                                  return Icon(
                                    Icons.download_for_offline_rounded,
                                    color: isMe ? Colors.white : const Color(0xFF1550A6),
                                    size: 22.sp,
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Message text
                    if (text.isNotEmpty)
                      Text(
                        text,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: isMe ? Colors.white : const Color(0xFF0F172A),
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),

            // Timestamp and Indicators
            SizedBox(height: 3.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEdited && !isDeleted)
                  Padding(
                    padding: EdgeInsets.only(right: 4.w),
                    child: Text(
                      '(edited)',
                      style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFF94A3B8)),
                    ),
                  ),
                Text(
                  timestamp,
                  style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFF94A3B8)),
                ),
                if (isMe && !isDeleted) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    message['read'] == true ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14.sp,
                    color: message['read'] == true ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    ),
  ),
);
  }

  Widget _buildBubbleInitial(String initial) {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1550A6),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── MEETING CARD BUILDER (Fiverr Style) ───────────────

  Widget _buildMeetingMessageCard(BuildContext context, Map<String, dynamic> message, bool isMe) {
    final meeting = message['meetingId'] is Map ? message['meetingId'] as Map : {};
    final meetingId = meeting['_id']?.toString() ?? message['meetingId']?.toString() ?? '';
    final topic = meeting['topic'] ?? message['text'] ?? 'Meeting Consultation';
    final meetingType = meeting['meetingType']?.toString().toUpperCase() ?? 'SCHEDULED';
    final status = meeting['status']?.toString().toUpperCase() ?? 'ACTIVE';
    final recordingUrl = meeting['recordingUrl']?.toString() ?? '';
    final startTimeRaw = meeting['startTime'];
    final isInstant = meetingType == 'INSTANT';
    final isCompleted = status == 'COMPLETED' || recordingUrl.isNotEmpty;
    final isCancelled = status == 'CANCELLED';

    String formattedDate = '';
    if (startTimeRaw != null) {
      try {
        final d = DateTime.parse(startTimeRaw.toString()).toLocal();
        formattedDate = DateFormat('EEE, MMM d, yyyy • h:mm a').format(d);
      } catch (_) {}
    }

    return Container(
      constraints: BoxConstraints(maxWidth: 300.w),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981)
              : isCancelled
                  ? const Color(0xFFCBD5E1)
                  : isInstant
                      ? const Color(0xFFF87171)
                      : const Color(0xFF93C5FD),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted
                    ? const Color(0xFF10B981)
                    : isInstant
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1550A6))
                .withValues(alpha: 0.08),
            blurRadius: 10,
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
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFECFDF5)
                      : (isInstant ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.videocam_outlined
                      : isInstant
                          ? Icons.videocam_rounded
                          : Icons.calendar_month_rounded,
                  color: isCompleted
                      ? const Color(0xFF059669)
                      : isInstant
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF1550A6),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted
                          ? 'MEETING ENDED • RECORDED'
                          : isCancelled
                              ? 'MEETING CANCELLED'
                              : isInstant
                                  ? 'INSTANT INCIDENT CALL'
                                  : 'SCHEDULED CONSULTATION',
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        color: isCompleted
                            ? const Color(0xFF059669)
                            : isCancelled
                                ? const Color(0xFF64748B)
                                : isInstant
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF1550A6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      topic,
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Card options menu for Edit / End / Delete
              if (!isCancelled && (isMe || controller.isCurrentUserDoctor || isCompleted))
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert_rounded, size: 18.sp, color: const Color(0xFF94A3B8)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditMeetingModal(context, Map<String, dynamic>.from(meeting));
                    } else if (val == 'delete') {
                      controller.deleteMeetingInChat(meetingId);
                    } else if (val == 'end') {
                      controller.endMeetingInChat(meetingId);
                    } else if (val == 'record') {
                      controller.showMeetingEndedDialog(Map<String, dynamic>.from(meeting));
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!isCompleted && (isMe || controller.isCurrentUserDoctor))
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Text('Edit Meeting'),
                          ],
                        ),
                      ),
                    if (!isCompleted && (isMe || controller.isCurrentUserDoctor))
                      const PopupMenuItem(
                        value: 'end',
                        child: Row(
                          children: [
                            Icon(Icons.stop_circle_outlined, size: 18, color: Color(0xFFDC2626)),
                            SizedBox(width: 8),
                            Text('End Meeting for All'),
                          ],
                        ),
                      ),
                    if (isCompleted)
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
                    if (isMe || controller.isCurrentUserDoctor)
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
          if (formattedDate.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14.sp, color: const Color(0xFF64748B)),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12.h),

          // Action Button: Watch Recording OR Join Meeting
          if (isCompleted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.showMeetingEndedDialog(Map<String, dynamic>.from(meeting)),
                icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                label: Text(
                  'Watch Recording',
                  style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  elevation: 1,
                ),
              ),
            ),
          ] else if (isCancelled) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'Meeting Cancelled',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.joinMeetingFromChat(Map<String, dynamic>.from(meeting)),
                icon: const Icon(Icons.video_call_rounded, size: 18),
                label: Text(
                  isInstant ? 'Join Live Incident Call' : 'Join Consultation Room',
                  style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInstant ? const Color(0xFFDC2626) : const Color(0xFF1550A6),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────── BOTTOM INPUT BAR ──────────────────────────────────

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE2E8F0), width: 1.h)),
      ),
      child: Row(
        children: [
          // (+) Action Button for Attachments & Meetings
          GestureDetector(
            onTap: () => _showAttachmentMenu(context),
            child: Container(
              width: 40.r,
              height: 40.r,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: const Color(0xFF1550A6), size: 24.sp),
            ),
          ),
          SizedBox(width: 10.w),

          // Message Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.messageController,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => controller.sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Send / Save Edit Button
          Obx(() {
            final isEditing = controller.editingMessage.value != null;

            return GestureDetector(
              onTap: controller.sendMessage,
              child: Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: isEditing ? const Color(0xFFD97706) : const Color(0xFF1550A6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isEditing ? const Color(0xFFD97706) : const Color(0xFF1550A6))
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isEditing ? Icons.check_rounded : Icons.send_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ──────────────────────── ATTACHMENT & MEETING MENU ─────────────────────────

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Share & Schedule in Chat',
              style: GoogleFonts.outfit(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Photo',
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.pickAndSendImage(source: ImageSource.gallery);
                  },
                ),
                _buildActionTile(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: const Color(0xFF059669),
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.pickAndSendImage(source: ImageSource.camera);
                  },
                ),
                _buildActionTile(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Document',
                  color: const Color(0xFFD97706),
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.pickAndSendDocument();
                  },
                ),
                if (controller.canScheduleInChat)
                  _buildActionTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'Schedule',
                    color: const Color(0xFF7C3AED),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showScheduleMeetingModal(context);
                    },
                  ),
                _buildActionTile(
                  icon: Icons.videocam_rounded,
                  label: 'Instant',
                  color: const Color(0xFFDC2626),
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.startInstantMeetingInChat();
                  },
                ),
              ],
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── MESSAGE CONTEXT MENU (WhatsApp Style) ─────────────

  void _showMessageContextMenu(BuildContext context, Map<String, dynamic> message, bool isMe) {
    final text = message['text']?.toString() ?? '';
    final msgId = message['_id']?.toString() ?? '';
    final isDeleted = message['isDeleted'] == true;
    final messageType = message['messageType']?.toString() ?? 'text';
    final isMeeting = messageType == 'meeting' || message['meetingId'] != null;
    final attachment = message['attachment']?.toString();

    if (isMeeting) {
      final meeting = message['meetingId'] is Map ? message['meetingId'] as Map : {};
      final meetingId = meeting['_id']?.toString() ?? message['meetingId']?.toString() ?? '';
      final status = meeting['status']?.toString().toUpperCase() ?? 'ACTIVE';
      final isCompleted = status == 'COMPLETED';

      // 🚫 CRITICAL REQUIREMENT: User cannot copy meeting cards! Only Edit / Delete / End / Recording.
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompleted)
                ListTile(
                  leading: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF1550A6)),
                  title: const Text('Edit Meeting Schedule'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditMeetingModal(context, Map<String, dynamic>.from(meeting));
                  },
                ),
              if (!isCompleted)
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined, color: Color(0xFFDC2626)),
                  title: const Text('End Meeting for All'),
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.endMeetingInChat(meetingId);
                  },
                ),
              if (isCompleted)
                ListTile(
                  leading: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF059669)),
                  title: const Text('Watch Recording'),
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.showMeetingEndedDialog(Map<String, dynamic>.from(meeting));
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: const Text('Delete Meeting', style: TextStyle(color: Color(0xFFEF4444))),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.deleteMeetingInChat(meetingId);
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachment != null && attachment.isNotEmpty && !isDeleted)
              ListTile(
                leading: const Icon(Icons.download_rounded, color: Color(0xFF059669)),
                title: Text(
                  messageType == 'image' ? 'Download Image' : 'Download Document',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.downloadAttachment(
                    attachmentPath: attachment,
                    isImage: messageType == 'image',
                  );
                },
              ),
            if (!isDeleted)
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Color(0xFF1550A6)),
                title: const Text('Copy Message Text'),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.copyMessageText(text);
                },
              ),
            if (isMe && !isDeleted)
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Color(0xFFD97706)),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.startEditing(message);
                },
              ),
            if (isMe && !isDeleted)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: const Text('Delete Message', style: TextStyle(color: Color(0xFFEF4444))),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.deleteMessage(msgId);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── EDIT MEETING MODAL ────────────────────────────────

  void _showEditMeetingModal(BuildContext context, Map<String, dynamic> meeting) {
    final meetingId = meeting['_id']?.toString() ?? '';
    final currentTopic = meeting['topic']?.toString() ?? 'Legal Consultation';
    final currentAgenda = meeting['agenda']?.toString() ?? '';
    final currentDuration = int.tryParse(meeting['durationMinutes']?.toString() ?? '30') ?? 30;

    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    if (meeting['startTime'] != null) {
      try {
        selectedDate = DateTime.parse(meeting['startTime'].toString()).toLocal();
      } catch (_) {}
    }

    final topicCtrl = TextEditingController(text: currentTopic);
    final agendaCtrl = TextEditingController(text: currentAgenda);
    int duration = currentDuration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  'Edit Meeting Schedule',
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: topicCtrl,
                  decoration: InputDecoration(
                    labelText: 'Meeting Topic / Title',
                    labelStyle: GoogleFonts.inter(fontSize: 13.sp),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                SizedBox(height: 12.h),
                // Date & Time Picker Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                selectedDate.hour,
                                selectedDate.minute,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDate = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(DateFormat('h:mm a').format(selectedDate)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Duration selection
                Text('Duration', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 6.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [15, 30, 45, 60].map((d) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: ChoiceChip(
                          label: Text('$d mins'),
                          selected: duration == d,
                          onSelected: (val) {
                            if (val) setModalState(() => duration = d);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: agendaCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Agenda / Description',
                    labelStyle: GoogleFonts.inter(fontSize: 13.sp),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                SizedBox(height: 18.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    controller.updateMeetingScheduleInChat(
                      meetingId: meetingId,
                      topic: topicCtrl.text.trim(),
                      startTime: selectedDate,
                      durationMinutes: duration,
                      agenda: agendaCtrl.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1550A6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── SCHEDULE MEETING MODAL (Fiverr Style) ────────────

  void _showScheduleMeetingModal(BuildContext context) {
    if (!controller.canScheduleInChat) {
      Helpers.showWarning(
        'In clinical consultations, only the mental health professional / doctor can schedule meetings.',
        title: 'Schedule Restricted',
      );
      return;
    }

    final isDoctorChat = controller.isPartnerMentalHealthProfessional || controller.isCurrentUserDoctor;
    final topicCtrl = TextEditingController(
      text: isDoctorChat
          ? 'Clinical Consultation & Mental Health Support'
          : 'Legal Consultation & Case Review',
    );
    final agendaCtrl = TextEditingController(
      text: isDoctorChat ? 'Telehealth consultation and emotional well-being check' : '',
    );
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 2));
    int duration = 30;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  'Schedule Meeting in Chat',
                  style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 16.h),

                // Topic Field
                TextField(
                  controller: topicCtrl,
                  decoration: InputDecoration(
                    labelText: 'Meeting Topic',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                SizedBox(height: 12.h),

                // Date & Time Picker Tile
                ListTile(
                  tileColor: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  leading: const Icon(Icons.access_time_rounded, color: Color(0xFF1550A6)),
                  title: Text(
                    DateFormat('EEE, MMM d, yyyy • h:mm a').format(selectedDate),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.sp),
                  ),
                  trailing: const Text('Change', style: TextStyle(color: Color(0xFF1550A6))),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (d != null) {
                      if (!context.mounted) return;
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (t != null) {
                        setModalState(() {
                          selectedDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                        });
                      }
                    }
                  },
                ),
                SizedBox(height: 12.h),

                // Duration Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text('Duration: ', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      SizedBox(width: 8.w),
                      ...[15, 30, 45, 60].map(
                        (m) => Padding(
                          padding: EdgeInsets.only(right: 6.w),
                          child: ChoiceChip(
                            label: Text('$m m'),
                            selected: duration == m,
                            onSelected: (selected) {
                              if (selected) setModalState(() => duration = m);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // Agenda Field
                TextField(
                  controller: agendaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Agenda / Details (Optional)',
                    hintText: 'e.g. Discuss citation details and evidence',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 20.h),

                // Submit Schedule
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    controller.scheduleMeetingInChat(
                      topic: topicCtrl.text.trim(),
                      startTime: selectedDate,
                      durationMinutes: duration,
                      agenda: agendaCtrl.text.trim().isNotEmpty ? agendaCtrl.text.trim() : null,
                    );
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Confirm & Send Schedule to Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1550A6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── USER PROFILE MODAL IN CHAT ────────────────────────

  void _showUserProfileModal(BuildContext context, Map<String, dynamic> partner) {
    final name = partner['name']?.toString() ?? 'GoVia User';
    final role = partner['role']?.toString() ?? 'CITIZEN';
    final email = partner['email']?.toString() ?? '';
    final phone = partner['phoneNumber']?.toString() ?? partner['phone']?.toString() ?? '';
    final firmOrPrecinct = partner['lawFirmName'] ?? partner['departmentOrPrecinct'] ?? partner['officeName'] ?? '';
    final badge = partner['badgeNumber']?.toString() ?? '';
    final activeMeeting = partner['activeMeeting'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Center(
              child: Container(
                width: 64.r,
                height: 64.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(fontSize: 28.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1550A6)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Center(
              child: Text(
                name,
                style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(height: 4.h),
            Center(
              child: Text(
                '${role.toUpperCase()}${firmOrPrecinct.toString().isNotEmpty ? ' • $firmOrPrecinct' : ''}${badge.isNotEmpty ? ' (#$badge)' : ''}',
                style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1550A6)),
              ),
            ),
            SizedBox(height: 16.h),

            if (email.isNotEmpty || phone.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (email.isNotEmpty) Text('✉️ $email', style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF475569))),
                    if (phone.isNotEmpty) Text('📞 $phone', style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF475569))),
                  ],
                ),
              ),

            SizedBox(height: 12.h),

            // ACTIVE INCIDENT MEETING STATUS (if present)
            if (activeMeeting != null && activeMeeting is Map) ...[
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.videocam_rounded, color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 6.w),
                        Text(
                          '🚨 ACTIVE INCIDENT MEETING IN PROGRESS',
                          style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Topic: ${activeMeeting['topic'] ?? 'Emergency Session'}',
                      style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF7F1D1D)),
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        controller.joinMeetingFromChat(Map<String, dynamic>.from(activeMeeting));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                      child: const Text('Join Incident Meeting Now'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteConversation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Delete Conversation?'),
        content: const Text('Are you sure you want to delete this full conversation? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              Get.back();
              controller.deleteFullConversation(controller.activeConversationId.value);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── FULL SCREEN IMAGE VIEWER & DOWNLOAD ────────────────

  void _openImageViewer(BuildContext context, String attachmentPath, String fileName) {
    final fullUrl = ApiConstants.getFileUrl(attachmentPath);

    Get.dialog(
      Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.96),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
            onPressed: () => Get.back(),
          ),
          title: Text(
            fileName,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Obx(() {
              final isDownloading = controller.downloadingUrls.contains(fullUrl);
              return IconButton(
                icon: isDownloading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, color: Colors.white, size: 24),
                tooltip: 'Download Image',
                onPressed: () {
                  controller.downloadAttachment(
                    attachmentPath: attachmentPath,
                    customFileName: fileName,
                    isImage: true,
                  );
                },
              );
            }),
            SizedBox(width: 8.w),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(24),
            minScale: 0.8,
            maxScale: 4.5,
            child: Image.network(
              fullUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              },
              errorBuilder: (_, _, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 52),
                  SizedBox(height: 12.h),
                  Text(
                    'Unable to load full resolution image',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13.sp),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          color: Colors.transparent,
          child: SafeArea(
            child: Obx(() {
              final isDownloading = controller.downloadingUrls.contains(fullUrl);
              return ElevatedButton.icon(
                onPressed: isDownloading
                    ? null
                    : () {
                        controller.downloadAttachment(
                          attachmentPath: attachmentPath,
                          customFileName: fileName,
                          isImage: true,
                        );
                      },
                icon: isDownloading
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined, color: Colors.white),
                label: Text(
                  isDownloading ? 'Downloading Image...' : 'Save to Downloads',
                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1550A6),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  elevation: 0,
                ),
              );
            }),
          ),
        ),
      ),
      barrierColor: Colors.black,
    );
  }
}
