import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/citizen/vault/controller/citizen_vault_controller.dart';

class IncidentLocationView extends StatelessWidget {
  const IncidentLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the encounter argument passed from the list
    final EncounterModel encounter = Get.arguments ?? EncounterModel(
      id: '0',
      title: 'Incident Location',
      dateTime: 'N/A',
      locationName: 'Unknown Location',
      duration: '0:00',
      imageUrl: '',
      latitude: 0.0,
      longitude: 0.0,
      description: 'No details available.',
    );

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
                          'Incident Location',
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

              // Map Mockup Container
              Expanded(
                child: Stack(
                  children: [
                    // Styled Map Background
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 24.w),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: const Color(0xFFC7D2FE), width: 2.w),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22.r),
                        child: Stack(
                          children: [
                            // Grid line representations to look like map street sections
                            Positioned.fill(
                              child: CustomPaint(
                                painter: MapGridPainter(),
                              ),
                            ),
                            
                            // A pulsing location pin at center
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Pulse Rings
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 50.r,
                                        height: 50.r,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1550A6).withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: 30.r,
                                        height: 30.r,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1550A6).withValues(alpha: 0.35),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(4.r),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1550A6),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 6,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.person_pin_circle_rounded,
                                          color: Colors.white,
                                          size: 24.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Map Control Overlays
                            Positioned(
                              top: 20.h,
                              right: 20.w,
                              child: Column(
                                children: [
                                  _buildMapControl(Icons.add),
                                  SizedBox(height: 8.h),
                                  _buildMapControl(Icons.remove),
                                  SizedBox(height: 8.h),
                                  _buildMapControl(Icons.my_location),
                                ],
                              ),
                            ),

                            // Compass indicator overlay
                            Positioned(
                              top: 20.h,
                              left: 20.w,
                              child: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.explore_outlined,
                                  color: const Color(0xFF475569),
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Details card at bottom
              Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            encounter.title,
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Logged',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      encounter.dateTime,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Divider(height: 24.h, color: const Color(0xFFF1F5F9)),
                    
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: const Color(0xFF1550A6), size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          encounter.locationName,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.gps_fixed_rounded, color: const Color(0xFF64748B), size: 16.sp),
                        SizedBox(width: 8.w),
                        Text(
                          '${encounter.latitude.toStringAsFixed(4)}° N, ${encounter.longitude.toStringAsFixed(4)}° W',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF64748B),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      encounter.description,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapControl(IconData icon) {
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: const Color(0xFF475569),
        size: 20.sp,
      ),
    );
  }
}

// Custom painter to draw realistic looking map roads/grids
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7D2FE)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final greenPaint = Paint()
      ..color = const Color(0xFFA5F3FC).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Draw a "park" area
    canvas.drawRect(Rect.fromLTWH(20.w, 40.h, 100.w, 120.h), greenPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - 120.w, size.height - 180.h, 100.w, 140.h), greenPaint);

    // Draw road grids
    // Vertical road 1
    canvas.drawLine(Offset(60.w, 0), Offset(60.w, size.height), paint);
    // Vertical road 2
    canvas.drawLine(Offset(size.width - 80.w, 0), Offset(size.width - 80.w, size.height), paint);
    
    // Horizontal road 1
    canvas.drawLine(Offset(0, 80.h), Offset(size.width, 80.h), paint);
    // Horizontal road 2
    canvas.drawLine(Offset(0, size.height - 100.h), Offset(size.width, size.height - 100.h), paint);

    // Draw some diagonal secondary roads
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(0, 0), Offset(150.w, 150.h), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - 150.w, 150.h), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
