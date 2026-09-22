import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/module/citizen/community/controller/citizen_community_controller.dart';

class CitizenCommunityView extends GetView<CitizenCommunityController> {
  const CitizenCommunityView({super.key});

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
                child: Center(
                  child: Text(
                    'Community Resources',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1550A6),
                    ),
                  ),
                ),
              ),

              // Grid Content
              Expanded(
                child: Obx(
                  () => RefreshIndicator(
                    onRefresh: controller.fetchResources,
                    color: const Color(0xFF1550A6),
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 20.h,
                        childAspectRatio: 0.76,
                      ),
                      itemCount: controller.resources.length,
                      itemBuilder: (context, index) {
                        final resource = controller.resources[index];
                        return GestureDetector(
                          onTap: () => controller.openResource(resource),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Circle Logo Container
                              Container(
                                width: 76.w,
                                height: 76.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: (resource.logo != null &&
                                          resource.logo!.isNotEmpty)
                                      ? Image.network(
                                          ApiConstants.getFileUrl(
                                              resource.logo),
                                          fit: BoxFit.cover,
                                          width: 76.w,
                                          height: 76.w,
                                          errorBuilder: (_, _, _) =>
                                              _buildLogo(resource.type),
                                        )
                                      : _buildLogo(resource.type),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // Label text
                              Expanded(
                                child: Text(
                                  resource.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF334155),
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

  Widget _buildLogo(String type) {
    switch (type) {
      case 'aclu':
        return Center(
          child: Text(
            'ACLU',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F52BA),
              letterSpacing: -0.5,
            ),
          ),
        );
      case 'las':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LAS',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
              Text(
                'LEGAL AID',
                style: GoogleFonts.inter(
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      case 'naacp':
        return Container(
          color: const Color(0xFF0F172A),
          padding: EdgeInsets.all(4.r),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5.w),
            ),
            alignment: Alignment.center,
            child: Text(
              'NAACP',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFD4AF37),
              ),
            ),
          ),
        );
      case 'splc':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SP',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
              Text(
                'LC',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
            ],
          ),
        );
      case 'eji':
        return Container(
          color: const Color(0xFFFDE8E8),
          alignment: Alignment.center,
          child: Text(
            'eji',
            style: GoogleFonts.inter(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFDC2626),
            ),
          ),
        );
      case 'ppd':
        return Container(
          color: const Color(0xFFFCFDF5),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.spa_rounded,
                color: const Color(0xFFD4AF37),
                size: 20.sp,
              ),
              Text(
                'PPD',
                style: GoogleFonts.inter(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      case 'bmha':
        return Container(
          color: const Color(0xFFFFF7ED),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                color: const Color(0xFFF97316),
                size: 18.sp,
              ),
              Text(
                'BMHA',
                style: GoogleFonts.inter(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7C2D12),
                ),
              ),
            ],
          ),
        );
      case 'faf':
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white, width: 1.5.w),
          ),
          child: Text(
            'FAF',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        );
      case 'fbi':
        return Center(
          child: Text(
            'FBI',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: 1.0,
            ),
          ),
        );
      case 'doj':
        return Container(
          color: const Color(0xFF1E3A8A),
          alignment: Alignment.center,
          child: Icon(
            Icons.gavel_rounded,
            color: const Color(0xFFD4AF37),
            size: 28.sp,
          ),
        );
      case 'nacole':
        return Container(
          color: const Color(0xFFEFF6FF),
          alignment: Alignment.center,
          child: Icon(
            Icons.balance_rounded,
            color: const Color(0xFF1D4ED8),
            size: 28.sp,
          ),
        );
      case 'ohio':
        return Container(
          color: const Color(0xFF0284C7),
          alignment: Alignment.center,
          child: Icon(
            Icons.location_city_rounded,
            color: Colors.white,
            size: 26.sp,
          ),
        );
      case 'cuyahoga':
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12.w, height: 12.w, color: Colors.green),
                  SizedBox(height: 2.h),
                  Container(width: 12.w, height: 12.w, color: Colors.orange),
                ],
              ),
              SizedBox(width: 2.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12.w, height: 12.w, color: Colors.blue),
                  SizedBox(height: 2.h),
                  Container(width: 12.w, height: 12.w, color: Colors.red),
                ],
              ),
            ],
          ),
        );
      case 'marshall':
        return Container(
          color: const Color(0xFF0F172A),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                width: 4.w,
                height: 28.h,
                color: Colors.white,
              ),
            ),
          ),
        );
      case 'ohchr':
        return Container(
          color: const Color(0xFFF0F9FF),
          alignment: Alignment.center,
          child: Icon(
            Icons.public_rounded,
            color: const Color(0xFF0284C7),
            size: 28.sp,
          ),
        );
      case 'cleveland':
        return Container(
          color: const Color(0xFFFEF3C7),
          alignment: Alignment.center,
          child: Icon(
            Icons.gavel_rounded,
            color: const Color(0xFFD97706),
            size: 26.sp,
          ),
        );
      case 'daily':
        return Container(
          color: const Color(0xFF1E3A8A),
          alignment: Alignment.center,
          child: Text(
            'daily',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );
      case 'compass':
        return Container(
          color: const Color(0xFFF0FDF4),
          alignment: Alignment.center,
          child: Icon(
            Icons.explore_rounded,
            color: const Color(0xFF16A34A),
            size: 28.sp,
          ),
        );
      case 'bail':
        return Container(
          color: Colors.black,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          alignment: Alignment.center,
          child: Text(
            'BAIL',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        );
      case 'price':
        return Container(
          color: const Color(0xFFFAF7F0),
          alignment: Alignment.center,
          child: Icon(
            Icons.shield_rounded,
            color: const Color(0xFFC5A880),
            size: 28.sp,
          ),
        );
      case 'stand':
        return Container(
          color: const Color(0xFFECFDF5),
          alignment: Alignment.center,
          child: Icon(
            Icons.handshake_rounded,
            color: const Color(0xFF059669),
            size: 28.sp,
          ),
        );
      case 'crimestoppers':
        return Container(
          color: const Color(0xFFFEF2F2),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFDC2626),
                size: 16.sp,
              ),
              Text(
                'STOPPERS',
                style: GoogleFonts.inter(
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        );
      case 'glide':
        return Container(
          color: const Color(0xFFFFF5F5),
          alignment: Alignment.center,
          child: Icon(
            Icons.favorite_rounded,
            color: const Color(0xFFEF4444),
            size: 32.sp,
          ),
        );
      case 'nationalpolice':
        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Icon(
            Icons.security_rounded,
            color: const Color(0xFFD4AF37),
            size: 26.sp,
          ),
        );
      case 'danabond':
        return Container(
          color: Colors.black,
          padding: EdgeInsets.all(4.r),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5.w),
            ),
            child: Container(
              margin: EdgeInsets.all(1.5.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 0.5.w),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_vintage_outlined,
                    color: const Color(0xFFD4AF37),
                    size: 14.sp,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Dana',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFD4AF37),
                      height: 0.9,
                    ),
                  ),
                  Text(
                    'Bail Bonds',
                    style: GoogleFonts.inter(
                      fontSize: 5.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFD4AF37),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      default:
        return const Center(child: Icon(Icons.business_rounded));
    }
  }
}
