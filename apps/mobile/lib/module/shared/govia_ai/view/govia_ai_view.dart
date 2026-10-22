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
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody(context)),
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
      centerTitle: false,
      leadingWidth: 44.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 10.w),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF0F172A),
            size: 18.sp,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: const BoxDecoration(
              color: Color(0xFF1550A6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Govia AI',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Legal & Rights Assistant',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history_rounded, color: const Color(0xFF475569), size: 22.sp),
          tooltip: 'History',
          onPressed: () => _showChatHistoryBottomSheet(context),
        ),
        IconButton(
          icon: Icon(Icons.edit_note_rounded, color: const Color(0xFF1550A6), size: 24.sp),
          tooltip: 'New Chat',
          onPressed: () => controller.startNewChat(),
        ),
        SizedBox(width: 4.w),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(color: const Color(0xFFF1F5F9), height: 1.h),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (controller.messages.isEmpty) {
        return _buildEmptyWelcomeState();
      }

      final msgCount = controller.messages.length;
      final showTyping = controller.isProcessing.value;

      return ListView.builder(
        controller: controller.scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: msgCount + (showTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < msgCount) {
            final msg = controller.messages[index];
            final isUser = msg['isUser'] as bool;
            final text = msg['text'] as String;
            final time = msg['time'] as String;
            return _buildMessageRow(context, text: text, isUser: isUser, time: time);
          } else {
            return _buildTypingBubble();
          }
        },
      );
    });
  }

  Widget _buildEmptyWelcomeState() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20.h),
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: const Color(0xFF1550A6).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: const Color(0xFF1550A6),
                size: 24.sp,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'How can I help you today?',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Ask about your constitutional rights, traffic stops, court procedures, or legal guidance.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          SizedBox(height: 28.h),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
                  child: Text(
                    'Suggested Questions',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                ...controller.suggestedPrompts.map((prompt) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: InkWell(
                      onTap: () => controller.sendSuggestedPrompt(prompt),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 14.sp,
                              color: const Color(0xFF64748B),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                prompt,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(
    BuildContext context, {
    required String text,
    required bool isUser,
    required String time,
  }) {
    if (isUser) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12.h, left: 48.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1550A6),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13.5.sp,
                  height: 1.45,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(bottom: 14.h, right: 36.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _buildFormattedText(text),
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(width: 8.w),
                InkWell(
                  onTap: () => controller.copyMessage(text),
                  borderRadius: BorderRadius.circular(4.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 11.sp, color: const Color(0xFF94A3B8)),
                        SizedBox(width: 3.w),
                        Text(
                          'Copy',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h, right: 120.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12.r,
              height: 12.r,
              child: const CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1550A6)),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'Thinking...',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text) {
    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(SizedBox(height: 6.h));
      } else if (trimmed.startsWith('## ') || trimmed.startsWith('### ')) {
        final title = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: 6.h, bottom: 3.h),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.5.sp,
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
            padding: EdgeInsets.only(left: 4.w, bottom: 3.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF1550A6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(child: _buildRichText(content)),
              ],
            ),
          ),
        );
      } else if (trimmed.startsWith(RegExp(r'^\d+\.\s+'))) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 3.h),
            child: _buildRichText(trimmed),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 3.h),
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

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 14.w,
        right: 14.w,
        top: 8.h,
        bottom: 8.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFF1F5F9), width: 1.w)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.only(left: 14.w, right: 4.w, top: 2.h, bottom: 2.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => controller.sendMessage(),
                    style: GoogleFonts.inter(
                      fontSize: 13.5.sp,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask Govia AI...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 13.sp,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
                Obx(() {
                  final isReady = controller.hasText.value && !controller.isProcessing.value;
                  return Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: isReady ? const Color(0xFF1550A6) : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.arrow_upward_rounded,
                        size: 18.sp,
                        color: isReady ? Colors.white : const Color(0xFF94A3B8),
                      ),
                      onPressed: isReady ? () => controller.sendMessage() : null,
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'GoVia AI provides informational guidance. Not legal counsel.',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: const Color(0xFF94A3B8),
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
        height: 0.6.sh,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Conversations',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Get.back();
                      controller.startNewChat();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Chat'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingChats.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.chatList.isEmpty) {
                  return Center(
                    child: Text(
                      'No previous conversations.',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  itemCount: controller.chatList.length,
                  separatorBuilder: (_, _) => SizedBox(height: 6.h),
                  itemBuilder: (context, index) {
                    final chat = controller.chatList[index];
                    final chatId = chat['_id']?.toString() ?? '';
                    final title = chat['title']?.toString() ?? 'Conversation';
                    final isCurrent = controller.currentChatId.value == chatId;

                    return Container(
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isCurrent ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16.sp,
                          color: isCurrent ? const Color(0xFF1550A6) : const Color(0xFF64748B),
                        ),
                        title: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
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
