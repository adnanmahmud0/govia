import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final String hintText;
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final bool isLabelVisible;
  final Color? fillColor;
  final String? errorText;

  const CustomDropdownField({
    super.key,
    required this.hintText,
    required this.label,
    required this.items,
    required this.itemLabelBuilder,
    this.value,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.isLabelVisible = false,
    this.fillColor,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ================= LABEL =================
        if (isLabelVisible)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              label,
              style: GoogleFonts.arimo(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xff333333),
              ),
            ),
          ),

        /// ================= DROPDOWN FIELD =================
        DropdownButtonFormField<T>(
          initialValue: value,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xff8E8E93),
            size: 24.sp,
          ),
          dropdownColor: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(16.r),
          style: GoogleFonts.arimo(
            fontSize: 17.sp,

            fontWeight: FontWeight.w400,
            color: Color(0xff8E8E93),
          ),

          decoration: InputDecoration(
            errorText: errorText,
            hintText: hintText,
            hintStyle: GoogleFonts.arimo(
              fontSize: 17.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xff8E8E93),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: 14.h,
              horizontal: 16.w,
            ),
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: fillColor ?? const Color(0xffF2F2F7),

            /// ====== BORDER STATES (Matching CustomTextField) ======
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none, // Optional: highlight focus
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            errorStyle: GoogleFonts.arimo(fontSize: 11.sp, color: Colors.red),
          ),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabelBuilder(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.arimo(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff8E8E93),
                ),
              ),
            );
          }).toList(),
          // Custom menu styling
          selectedItemBuilder: (BuildContext context) {
            return items.map((T item) {
              return Text(
                itemLabelBuilder(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.arimo(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff8E8E93),
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }
}
