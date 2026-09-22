import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/module/shared/chat/controller/chat_controller.dart';

class ChatListView extends GetView<ChatController> {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 52.w,
          leading: Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: Center(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: const Color(0xFF1550A6),
                    size: 16.sp,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            'Messages',
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: const Color(0xFF64748B), size: 22.sp),
              tooltip: 'Refresh conversations',
              onPressed: controller.fetchConversations,
            ),
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: const Color(0xFF1550A6),
                    size: 20.sp,
                  ),
                ),
                tooltip: 'New Message / Scan QR',
                onPressed: () => _showNewChatBottomSheet(context),
              ),
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
              // Search Filter Bar
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x05000000),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller.searchInputController,
                    onChanged: (val) => controller.searchQuery.value = val,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search conversations or roles...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13.5.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: const Color(0xFF64748B),
                        size: 20.sp,
                      ),
                      suffixIcon: Obx(
                        () => controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  controller.searchInputController.clear();
                                  controller.searchQuery.value = '';
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    ),
                  ),
                ),
              ),

              // Conversations Stream
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingConversations.value && controller.conversations.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final list = controller.filteredConversations;

                  if (list.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: controller.fetchConversations,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 60.h),
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80.r,
                                  height: 80.r,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: const Color(0xFF1550A6),
                                    size: 38.sp,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  'No Conversations Yet',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Scan a user\'s GoVia QR code or enter their ID to start a conversation.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                ElevatedButton.icon(
                                  onPressed: () => _showNewChatBottomSheet(context),
                                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                                  label: const Text('Start New Conversation'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1550A6),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                      vertical: 14.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.r),
                                    ),
                                    elevation: 2,
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
                    onRefresh: controller.fetchConversations,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final conv = list[index];
                        final convId = conv['_id']?.toString() ?? '';
                        final partner = controller.getOtherParticipant(conv);
                        final partnerName = partner['name']?.toString() ?? 'GoVia User';
                        final partnerRole = partner['role']?.toString() ?? 'CITIZEN';
                        final lastMsg = conv['lastMessageText']?.toString() ?? 'No messages yet';
                        final unreadCount = (conv['unreadCount'] as num?)?.toInt() ?? 0;
                        final timestamp = controller.formatTimestamp(
                          conv['lastMessageAt'] ?? conv['updatedAt'],
                        );

                        return _buildConversationItem(
                          context: context,
                          convId: convId,
                          partnerName: partnerName,
                          partnerRole: partnerRole,
                          lastMsg: lastMsg,
                          timestamp: timestamp,
                          unreadCount: unreadCount,
                          partner: partner,
                          onTap: () => controller.openExistingConversation(conv),
                          onDelete: () => _confirmDeleteConversation(context, convId),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showNewChatBottomSheet(context),
          backgroundColor: const Color(0xFF1550A6),
          elevation: 4,
          icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
          label: Text(
            'New Chat',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationItem({
    required BuildContext context,
    required String convId,
    required String partnerName,
    required String partnerRole,
    required String lastMsg,
    required String timestamp,
    required int unreadCount,
    required Map<String, dynamic> partner,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: unreadCount > 0 ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
          width: unreadCount > 0 ? 1.5.w : 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x04000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                // Avatar Badge
                _buildRoleAvatar(
                  partnerName,
                  partnerRole,
                  avatarUrl: partner['profilePicture']?.toString() ??
                      partner['image']?.toString() ??
                      partner['avatar']?.toString(),
                ),
                SizedBox(width: 14.w),

                // Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    partnerName,
                                    style: GoogleFonts.inter(
                                      fontSize: 15.sp,
                                      fontWeight: unreadCount > 0
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                _buildRoleBadge(partnerRole),
                              ],
                            ),
                          ),
                          Text(
                            timestamp,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: unreadCount > 0
                                  ? const Color(0xFF1550A6)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              lastMsg,
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: unreadCount > 0
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1550A6),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 18.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (val) {
                                if (val == 'delete') {
                                  onDelete();
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded,
                                          color: Color(0xFFEF4444), size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete Conversation',
                                        style: TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleAvatar(String name, String role, {String? avatarUrl}) {
    Color bg;
    switch (role.toUpperCase()) {
      case 'ATTORNEY':
        bg = const Color(0xFF7C3AED);
        break;
      case 'POLICE':
        bg = const Color(0xFF2563EB);
        break;
      case 'MENTAL_HEALTH_PROFESSIONAL':
      case 'DOCTOR':
        bg = const Color(0xFF059669);
        break;
      case 'BAIL_BONDSMAN':
        bg = const Color(0xFFD97706);
        break;
      default:
        bg = const Color(0xFF1550A6);
    }

    final initial = name.trim().isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : '?';
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;
    final fullUrl = hasAvatar ? ApiConstants.getFileUrl(avatarUrl) : '';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50.r,
          height: 50.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: bg.withValues(alpha: 0.35), width: 1.5.w),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: hasAvatar
                ? Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildInitialAvatar(initial, bg),
                  )
                : _buildInitialAvatar(initial, bg),
          ),
        ),
        Positioned(
          bottom: 1.h,
          right: 1.w,
          child: Container(
            width: 12.r,
            height: 12.r,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.w),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialAvatar(String initial, Color bg) {
    return Container(
      color: bg.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: bg,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;
    String label;
    switch (role.toUpperCase()) {
      case 'ATTORNEY':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF7C3AED);
        label = 'Attorney';
        break;
      case 'POLICE':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        label = 'Police';
        break;
      case 'MENTAL_HEALTH_PROFESSIONAL':
      case 'DOCTOR':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        label = 'Doctor';
        break;
      case 'BAIL_BONDSMAN':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Bondsman';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = 'Citizen';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.5.sp,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  void _confirmDeleteConversation(BuildContext context, String convId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Delete Conversation?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete this full conversation? All messages will be permanently removed.',
          style: GoogleFonts.inter(fontSize: 13.5.sp, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () {
              Get.back();
              controller.deleteFullConversation(convId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── START NEW CHAT BOTTOM SHEET ───────────────────────

  void _showNewChatBottomSheet(BuildContext context) {
    controller.idInputController.clear();
    controller.foundUserProfile.value = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewChatSheet(controller: controller),
    );
  }
}

// ──────────────────────── NEW CHAT BOTTOM SHEET COMPONENT ──────────────────────

class _NewChatSheet extends StatefulWidget {
  final ChatController controller;
  const _NewChatSheet({required this.controller});

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // QR single-scan latch: prevents the camera from firing onDetect multiple times
  bool _scanned = false;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          SizedBox(height: 12.h),
          Container(
            width: 44.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 12.h),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start New Message',
                      style: GoogleFonts.outfit(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Scan a user\'s QR card or enter their User ID',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Tabs: Input ID vs Scan QR
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1550A6),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF1550A6),
            indicatorWeight: 3.h,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.sp),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14.sp),
            tabs: const [
              Tab(icon: Icon(Icons.badge_outlined, size: 20), text: 'Input ID / Hex'),
              Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 20), text: 'Scan QR Code'),
            ],
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Input User ID
                _buildIdInputTab(),

                // TAB 2: Scan QR Code
                _buildQrScanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdInputTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter GoVia Digital ID',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Supports Short Hex ID (e.g. #96EE7686), assigned badge number, or full ObjectId.',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller.idInputController,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 96EE7686 or 6aa25...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        ),
                        onSubmitted: (val) => widget.controller.lookupUserByIdOrQr(val),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Obx(
                      () => ElevatedButton(
                        onPressed: widget.controller.isSearchingUser.value
                            ? null
                            : () => widget.controller.lookupUserByIdOrQr(
                                  widget.controller.idInputController.text,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1550A6),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: widget.controller.isSearchingUser.value
                            ? SizedBox(
                                width: 18.r,
                                height: 18.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Lookup'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Found User Profile Section
          Obx(() {
            final user = widget.controller.foundUserProfile.value;
            if (user == null) return const SizedBox.shrink();

            return _buildFoundUserProfileCard(user);
          }),
        ],
      ),
    );
  }

  Widget _buildQrScanTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            'Point camera at the other user\'s GoVia QR Card',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF475569)),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    // Single-scan latch: ignore every detection after the first
                    if (_scanned) return;
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final val = barcode.rawValue;
                      if (val != null && val.isNotEmpty) {
                        _scanned = true;
                        // Stop the camera immediately so no further frames fire
                        _scannerController.stop();
                        HapticFeedback.heavyImpact();
                        widget.controller.lookupUserByIdOrQr(val);
                        // Switch to ID tab to show the result card
                        _tabController.animateTo(0);
                        break;
                      }
                    }
                  },
                ),
                // Scanner reticle
                Container(
                  width: 220.w,
                  height: 220.w,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1550A6), width: 3.w),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Result preview
        Obx(() {
          final user = widget.controller.foundUserProfile.value;
          if (user == null) return const SizedBox.shrink();

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: _buildFoundUserProfileCard(user),
          );
        }),
      ],
    );
  }

  Widget _buildFoundUserProfileCard(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? 'User Profile';
    final role = user['role']?.toString() ?? 'CITIZEN';
    final email = user['email']?.toString() ?? '';
    final phone = user['phoneNumber']?.toString() ?? user['phone']?.toString() ?? '';
    final activeMeeting = user['activeMeeting'];
    final firmOrPrecinct = user['lawFirmName'] ?? user['departmentOrPrecinct'] ?? user['officeName'] ?? '';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF1550A6), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1550A6).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded, color: const Color(0xFF1550A6), size: 26.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${role.toUpperCase()}${firmOrPrecinct.toString().isNotEmpty ? ' • $firmOrPrecinct' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1550A6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          if (email.isNotEmpty || phone.isNotEmpty)
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (email.isNotEmpty)
                    Text('✉️ $email', style: GoogleFonts.inter(fontSize: 11.5.sp, color: const Color(0xFF475569))),
                  if (phone.isNotEmpty)
                    Text('📞 $phone', style: GoogleFonts.inter(fontSize: 11.5.sp, color: const Color(0xFF475569))),
                ],
              ),
            ),

          SizedBox(height: 10.h),

          // LIVE INCIDENT MEETING STATUS (if active)
          if (activeMeeting != null && activeMeeting is Map)
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
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
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '🚨 LIVE INCIDENT MEETING IN PROGRESS',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFDC2626),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Topic: ${activeMeeting['topic'] ?? 'Active Emergency Incident'}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFF7F1D1D),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.controller.joinMeetingFromChat(Map<String, dynamic>.from(activeMeeting));
                    },
                    icon: const Icon(Icons.videocam_rounded, size: 16),
                    label: const Text('Join Incident Meeting Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '🟢 No active incident meeting currently in session',
                style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF475569)),
              ),
            ),

          // Message Action Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.controller.openOrCreateChatWithUser(user);
            },
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(
              'Send Message',
              style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1550A6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
