import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/shared/govia_ai/controller/govia_ai_controller.dart';

class GoviaAiView extends GetView<GoviaAiController> {
  const GoviaAiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildDisclaimerBanner(),
            Expanded(child: _buildChatArea(context)),
            _buildTypingIndicator(),
            _buildInputArea(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 44.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 12.w),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF0F3A79),
            size: 20.sp,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1550A6), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1550A6).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'GoVia AI Copilot',
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A192F),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Obx(
                      () => Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          controller.userRole.value,
                          style: GoogleFonts.inter(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Container(
                      width: 7.r,
                      height: 7.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Active • Grounded in US Law',
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
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment_outlined, color: Color(0xFF1550A6)),
          tooltip: 'New Conversation',
          onPressed: () => controller.startNewChat(),
        ),
        IconButton(
          icon: const Icon(Icons.history_rounded, color: Color(0xFF475569)),
          tooltip: 'Chat History',
          onPressed: () => _showChatHistoryBottomSheet(context),
        ),
        SizedBox(width: 4.w),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(color: const Color(0xFFE2E8F0), height: 1.h),
      ),
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border(
          bottom: BorderSide(color: const Color(0xFFDBEAFE), width: 1.h),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: const Color(0xFF1D4ED8),
            size: 15.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'GoVia AI provides legal informational guidance. It does not replace formal legal counsel.',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(BuildContext context) {
    return Obx(() {
      final messages = controller.messages;
      final showSuggestions = messages.length <= 1;

      return ListView.builder(
        controller: controller.scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: messages.length + (showSuggestions ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < messages.length) {
            final msg = messages[index];
            final isUser = msg['isUser'] as bool;
            final text = msg['text'] as String;
            final time = msg['time'] as String;
            return _buildMessageRow(context, text: text, isUser: isUser, time: time);
          } else {
            return _buildSuggestionsSection();
          }
        },
      );
    });
  }

  Widget _buildMessageRow(
    BuildContext context, {
    required String text,
    required bool isUser,
    required String time,
  }) {
    if (isUser) {
      return Padding(
        padding: EdgeInsets.only(bottom: 16.h, left: 40.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1550A6), Color(0xFF0F3A79)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18.r),
                        topRight: Radius.circular(18.r),
                        bottomLeft: Radius.circular(18.r),
                        bottomRight: Radius.circular(4.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1550A6).withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        height: 1.45,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(bottom: 18.h, right: 32.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28.r,
              height: 28.r,
              margin: EdgeInsets.only(top: 2.h, right: 8.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bolt_rounded, color: Colors.white, size: 16.sp),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4.r),
                        topRight: Radius.circular(18.r),
                        bottomLeft: Radius.circular(18.r),
                        bottomRight: Radius.circular(18.r),
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildFormattedText(text),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$time • GoVia Copilot',
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      GestureDetector(
                        onTap: () => controller.copyMessage(text),
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 12.sp, color: const Color(0xFF64748B)),
                            SizedBox(width: 4.w),
                            Text(
                              'Copy',
                              style: GoogleFonts.inter(
                                fontSize: 10.5.sp,
                                color: const Color(0xFF64748B),
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
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFormattedText(String text) {
    // Split into paragraphs for readable display
    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(SizedBox(height: 8.h));
      } else if (trimmed.startsWith('## ') || trimmed.startsWith('### ')) {
        final title = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final content = trimmed.substring(2);
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF1550A6), fontWeight: FontWeight.bold)),
                Expanded(
                  child: _buildRichText(content),
                ),
              ],
            ),
          ),
        );
      } else if (trimmed.startsWith(RegExp(r'^\d+\.\s+'))) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
            child: _buildRichText(trimmed),
          ),
        );
      } else if (trimmed.startsWith('*Disclaimer:')) {
        widgets.add(
          Container(
            margin: EdgeInsets.only(top: 10.h),
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              trimmed.replaceAll('*', ''),
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: _buildRichText(trimmed),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(String raw) {
    // Quick inline bold parser: **word**
    final parts = raw.split('**');
    if (parts.length <= 1) {
      return Text(
        raw,
        style: GoogleFonts.inter(
          fontSize: 13.5.sp,
          height: 1.5,
          color: const Color(0xFF334155),
          fontWeight: FontWeight.w400,
        ),
      );
    }

    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: GoogleFonts.inter(
            fontSize: 13.5.sp,
            height: 1.5,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF334155),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildSuggestionsSection() {
    return Padding(
      padding: EdgeInsets.only(top: 12.h, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16.sp, color: const Color(0xFFD97706)),
              SizedBox(width: 6.w),
              Text(
                'Suggested Topics for ${controller.userRole.value}:',
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Obx(
            () => Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: controller.suggestedPrompts.map((prompt) {
                return ActionChip(
                  elevation: 0,
                  pressElevation: 1,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  avatar: const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF1550A6)),
                  label: Text(
                    prompt,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  onPressed: () => controller.sendSuggestedPrompt(prompt),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Obx(() {
      if (!controller.isProcessing.value) return const SizedBox.shrink();
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14.r,
                height: 14.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1550A6)),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'GoVia Copilot is analyzing US statutes...',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 10.h,
        bottom: 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE2E8F0), width: 1.h)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: controller.messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.sendMessage(),
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Ask about US laws, rights, procedures...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Obx(
            () => Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                gradient: controller.isProcessing.value
                    ? const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)])
                    : const LinearGradient(colors: [Color(0xFF1550A6), Color(0xFF2563EB)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                onPressed: controller.isProcessing.value ? null : () => controller.sendMessage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatHistoryBottomSheet(BuildContext context) {
    controller.fetchChatList();
    Get.bottomSheet(
      Container(
        height: 0.65.sh,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Previous Conversations',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Get.back();
                      controller.startNewChat();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Chat'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingChats.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.chatList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 48.sp, color: const Color(0xFFCBD5E1)),
                        SizedBox(height: 12.h),
                        Text(
                          'No previous conversations found.',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  itemCount: controller.chatList.length,
                  separatorBuilder: (_, _) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final chat = controller.chatList[index];
                    final chatId = chat['_id']?.toString() ?? '';
                    final title = chat['title']?.toString() ?? 'Conversation';
                    final isCurrent = controller.currentChatId.value == chatId;

                    return Container(
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isCurrent ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFF1550A6) : const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_outlined,
                            size: 16.sp,
                            color: isCurrent ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                        title: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13.5.sp,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                          onPressed: () => controller.deleteChat(chatId),
                        ),
                        onTap: () {
                          Get.back();
                          controller.loadChat(chatId);
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
