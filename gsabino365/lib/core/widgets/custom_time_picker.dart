import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CustomTimePickerField extends StatefulWidget {
  final String hintText;
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool isLabelVisible;

  const CustomTimePickerField({
    super.key,
    required this.hintText,
    required this.label,
    required this.controller,
    this.isLabelVisible = true,
    this.validator,
  });

  @override
  State<CustomTimePickerField> createState() => _CustomTimePickerFieldState();
}

class _CustomTimePickerFieldState extends State<CustomTimePickerField> {
  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      String formattedTime = DateFormat('hh:mm a').format(selectedDateTime);
      widget.controller.text = formattedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ================= LABEL =================
        if (widget.isLabelVisible)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xff333333),
              ),
            ),
          ),

        /// ================= TIME PICKER FIELD =================
        TextFormField(
          validator: widget.validator,
          controller: widget.controller,
          readOnly: true,
          onTap: () => _selectTime(context),

          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xff333333),
            fontWeight: FontWeight.w400,
          ),

          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),

            contentPadding: EdgeInsets.symmetric(
              vertical: 14.h,
              horizontal: 16.w,
            ),

            suffixIcon: const Icon(Icons.access_time, color: Color(0xff9945FF)),

            filled: true,
            fillColor: const Color(0xffF2F2F7),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide.none,
            ),

            errorStyle: TextStyle(fontSize: 11.sp, color: Colors.red),
          ),
        ),
      ],
    );
  }
}
