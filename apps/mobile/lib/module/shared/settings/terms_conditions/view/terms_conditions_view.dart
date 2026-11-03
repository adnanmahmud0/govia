import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Column(
            children: [
              // Custom Light App Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: const Color(0xFF1550A6),
                          size: 18.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Terms & Conditions',
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1550A6),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 36.w),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Content container
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms & Conditions',
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Last updated: June 11, 2026',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Divider(height: 32.h, color: const Color(0xFFE2E8F0)),
                        
                        _buildSection(
                          '1. Acceptance of Agreement',
                          'By accessing or using the GoVia mobile application, you agree to comply with and be bound by all the terms and conditions outlined in this Agreement. If you do not agree, you must immediately terminate use of the app.',
                        ),
                        _buildSection(
                          '2. User Conduct & Security',
                          'You agree to use this application only for lawful purposes. You are prohibited from posting or transmitting any unlawful, threatening, libelous, defamatory, obscene, or offensive material. Violating application security protocols will result in account cancellation.',
                        ),
                        _buildSection(
                          '3. Intellectual Property Rights',
                          'All organization details, compiles, layouts, designs, graphics, and codebase elements related to GoVia are protected under applicable copyrights and trademark regulations. Any reproduction or distribution without explicit consent is strictly prohibited.',
                        ),
                        _buildSection(
                          '4. Disclaimer & Limitations',
                          'GoVia is provided on an "as-is" basis. We do not represent or warrant that the application will be uninterrupted, error-free, or entirely free of diagnostic delays, and we reject all representations and warranties.',
                        ),
                        _buildSection(
                          '5. Government Entity Non-Affiliation Disclaimer',
                          'GoVia is an independent private technology platform and DOES NOT represent, endorse, affiliate with, or operate on behalf of any government entity, federal/state law enforcement agency, court system, or municipality. GoVia is not a law firm and does not provide legal advice.',
                        ),
                        _buildSection(
                          '6. Government & Legal Information Sources',
                          'Any educational references, constitutional rights summaries, and roadside encounter guidelines within this app are sourced directly from official, publicly accessible United States government databases:\n\n'
                          '• U.S. Constitution & Bill of Rights (National Archives):\nhttps://www.archives.gov/founding-docs/bill-of-rights\n\n'
                          '• National Highway Traffic Safety Administration (NHTSA):\nhttps://www.nhtsa.gov\n\n'
                          '• U.S. Department of Justice (DOJ):\nhttps://www.justice.gov\n\n'
                          '• Federal Bureau of Investigation (FBI):\nhttps://www.fbi.gov\n\n'
                          '• USA.gov Official Government Resources:\nhttps://www.usa.gov',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
