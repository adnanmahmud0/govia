import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CustomDatePickerField extends StatefulWidget {
  final String hintText;
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool isLabelVisible;

  const CustomDatePickerField({
    super.key,
    required this.hintText,
    required this.label,
    required this.controller,
    this.isLabelVisible = true,
    this.validator,
  });

  @override
  State<CustomDatePickerField> createState() => _CustomDatePickerFieldState();
}

class _CustomDatePickerFieldState extends State<CustomDatePickerField> {
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2009),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      widget.controller.text = formattedDate;
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

        /// ================= DATE PICKER FIELD =================
        TextFormField(
          validator: widget.validator,
          controller: widget.controller,
          readOnly: true,
          onTap: () => _selectDate(context),

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

            suffixIcon: const Icon(Icons.calendar_today, color: Color(0xff9945FF)),

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
