import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1550A6),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24.r),
                    bottomRight: Radius.circular(24.r),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 24.w,
                  right: 24.w,
                  top: MediaQuery.of(context).padding.top + 12.h,
                  bottom: 24.h,
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
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 32.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left GoVia star logo
                        Container(
                          width: 24.r,
                          height: 24.r,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                            ),
                          ),
                          child: Icon(Icons.auto_awesome, color: Colors.white, size: 12.sp),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Highlight a Hero',
                          style: GoogleFonts.inter(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Right GoVia star logo
                        Container(
                          width: 24.r,
                          height: 24.r,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                            ),
                          ),
                          child: Icon(Icons.auto_awesome, color: Colors.white, size: 12.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Share positive feedback about an officer's exceptional service and professionalism",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

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
                return _buildNominationForm();
              }),
            ],
          ),
        ),
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
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.heroFeed.length,
              separatorBuilder: (_, _) => SizedBox(height: 14.h),
              itemBuilder: (ctx, idx) => _buildHeroCard(controller.heroFeed[idx]),
            );
          }),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> hero) {
    final name = hero['officerName']?.toString() ?? 'Officer';
    final badge = hero['badgeNumber']?.toString() ?? '';
    final agency = hero['agency']?.toString() ?? '';
    final date = hero['date']?.toString() ?? '';
    final location = hero['location']?.toString() ?? '';
    final story = hero['story']?.toString() ?? '';
    final respect = (hero['respectRating'] as num?)?.toDouble() ?? 8.0;
    final deesc = (hero['deescalationRating'] as num?)?.toDouble() ?? 8.0;
    final likes = (hero['likes'] as num?)?.toInt() ?? 0;
    final isSaluted = hero['saluted'] == true;
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
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_rounded, color: const Color(0xFF1550A6), size: 22.sp),
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

          // Rating badges row
          Row(
            children: [
              _buildMetricPill('Respect', '${respect.toStringAsFixed(1)}/10', const Color(0xFF1550A6)),
              SizedBox(width: 8.w),
              _buildMetricPill('De-escalation', '${deesc.toStringAsFixed(1)}/10', const Color(0xFF0D9488)),
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
                  Clipboard.setData(ClipboardData(text: '$name from $agency was highlighted for exceptional community service on GoVia!'));
                  Helpers.showSuccess('Commendation text copied to clipboard.', title: 'Share Hero');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildNominationForm() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          // Card 1: Officer Information
          _buildSectionCard(
            icon: Icons.person_outline_rounded,
            title: 'Officer Information',
            children: [
              _buildInputField(
                label: 'Officer Name',
                hint: "Enter officer's name",
                controller: controller.nameController,
              ),
              SizedBox(height: 16.h),
              _buildInputField(
                label: 'Badge Number (Optional)',
                hint: 'Enter badge number if known',
                controller: controller.badgeController,
              ),
              SizedBox(height: 16.h),
              _buildInputField(
                label: 'Agency',
                hint: 'Enter your Agency',
                controller: controller.agencyController,
              ),
              SizedBox(height: 16.h),
              _buildInputField(
                label: 'Car Number',
                hint: 'Enter your car number',
                controller: controller.carController,
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Card 2: Performance Rating
          _buildSectionCard(
            icon: Icons.star_border_rounded,
            title: 'Performance Rating',
            children: [
              Obx(() => _buildRatingSlider(
                label: 'Respect',
                value: controller.respectRating.value,
                onChanged: (val) => controller.respectRating.value = val,
              )),
              SizedBox(height: 16.h),
              Obx(() => _buildRatingSlider(
                label: 'De-escalation',
                value: controller.deescalationRating.value,
                onChanged: (val) => controller.deescalationRating.value = val,
              )),
              SizedBox(height: 16.h),
              Obx(() => _buildRatingSlider(
                label: 'Communication',
                value: controller.communicationRating.value,
                onChanged: (val) => controller.communicationRating.value = val,
              )),
            ],
          ),

          SizedBox(height: 16.h),

          // Card 3: What did the officer do well?
          _buildSectionCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'What did the officer do well?',
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                ),
                child: TextField(
                  controller: controller.feedbackController,
                  maxLines: 4,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter your feedback",
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
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

          // Card 4: Incident Details
          _buildSectionCard(
            icon: Icons.access_time_rounded,
            title: 'Incident Details',
            children: [
              _buildInputField(
                label: 'Date',
                hint: 'MM/DD/YYYY',
                controller: controller.dateController,
                suffixIcon: Icons.calendar_today_outlined,
              ),
              SizedBox(height: 16.h),
              _buildInputField(
                label: 'Location',
                hint: 'Enter location',
                controller: controller.locationController,
                suffixIcon: Icons.location_on_outlined,
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Card 5: Sharing Options
          _buildSectionCard(
            icon: Icons.reply_rounded,
            title: 'Sharing Options',
            children: [
              Obx(() => _buildCheckboxItem(
                label: "Share with officer's agency",
                value: controller.shareWithAgency.value,
                onChanged: (val) => controller.shareWithAgency.value = val ?? false,
              )),
              Obx(() => _buildCheckboxItem(
                label: 'Include in performance metrics',
                value: controller.includeInMetrics.value,
                onChanged: (val) => controller.includeInMetrics.value = val ?? false,
              )),
              Obx(() => _buildCheckboxItem(
                label: 'Share with the court (GPS)',
                value: controller.shareWithCourt.value,
                onChanged: (val) => controller.shareWithCourt.value = val ?? false,
              )),
              _buildCheckboxItem(
                label: '4. Affidavit',
                value: true,
                onChanged: null,
                enabled: false,
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Submit Button
          Obx(
            () => CustomButton(
              text: controller.isSubmitting.value ? 'Submitting Commendation...' : 'Submit Commendation',
              onPressed: controller.isSubmitting.value ? () {} : () => controller.submitHeroHighlight(),
              backgroundColor: const Color(0xFF1550A6),
              borderRadius: 24,
              icon: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
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
          // Section Title Row
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1550A6), size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
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
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFB4C6E7), width: 1.w),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFF94A3B8),
              ),
              suffixIcon: suffixIcon != null
                  ? Icon(
                      suffixIcon,
                      color: const Color(0xFF64748B),
                      size: 20.sp,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '${value.round()}/10',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1550A6),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF1550A6),
            inactiveTrackColor: const Color(0xFFE2E8F0),
            thumbColor: const Color(0xFF1550A6),
            overlayColor: const Color(0xFF1550A6).withValues(alpha: 0.12),
            trackHeight: 6.h,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxItem({
    required String label,
    required bool value,
    required ValueChanged<bool?>? onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Theme(
            data: ThemeData(
              disabledColor: const Color(0xFF94A3B8),
            ),
            child: Checkbox(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: enabled ? const Color(0xFF1550A6) : const Color(0xFFCBD5E1),
              checkColor: enabled ? Colors.white : const Color(0xFF94A3B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: enabled ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
