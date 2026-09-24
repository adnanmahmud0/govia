import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:gsabino365/module/citizen/live_call/controller/live_call_controller.dart';
import 'package:gsabino365/module/attorney/live_call/controller/attorney_live_call_controller.dart';
import 'package:gsabino365/module/doctore/active_sessions/controller/doctor_live_call_controller.dart';

/// In-meeting bottom sheet with two tabs:
///   - "Show QR"  — displays this meeting's join QR code
///   - "Scan QR"  — opens camera, scans once, and joins the scanned meeting room
class MeetingQrSheet extends StatefulWidget {
  const MeetingQrSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MeetingQrSheet(),
    );
  }

  @override
  State<MeetingQrSheet> createState() => _MeetingQrSheetState();
}

class _MeetingQrSheetState extends State<MeetingQrSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _qrPayload;
  bool _loadingQr = true;
  bool _scanned = false;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  LiveCallController? get _controller =>
      Get.isRegistered<LiveCallController>() ? Get.find<LiveCallController>() : null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQrPayload();
  }

  Future<void> _loadQrPayload() async {
    String? payload;
    if (Get.isRegistered<LiveCallController>()) {
      payload = await Get.find<LiveCallController>().getMeetingJoinQrPayload();
    } else if (Get.isRegistered<AttorneyLiveCallController>()) {
      payload = await Get.find<AttorneyLiveCallController>().getMeetingJoinQrPayload();
    } else if (Get.isRegistered<DoctorLiveCallController>()) {
      payload = await Get.find<DoctorLiveCallController>().getMeetingJoinQrPayload();
    }
    if (mounted) setState(() { _qrPayload = payload; _loadingQr = false; });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.93),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
          ),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w, height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 22.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Meeting QR Code',
                              style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('Share or scan to instantly join this meeting',
                              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white.withValues(alpha: 0.55))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.7)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
                indicatorColor: const Color(0xFF60A5FA),
                indicatorWeight: 3.h,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.sp),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14.sp),
                tabs: const [
                  Tab(icon: Icon(Icons.qr_code_rounded, size: 18), text: 'Show QR'),
                  Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 18), text: 'Scan QR'),
                ],
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildShowQrTab(), _buildScanQrTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShowQrTab() {
    if (_loadingQr) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (_qrPayload == null) {
      return Center(child: Text('Meeting not active',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 14.sp)));
    }
    final topic = _controller?.currentMeeting.value?.topic ?? 'Govia Meeting';
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [BoxShadow(color: const Color(0xFF60A5FA).withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                QrImageView(
                  data: _qrPayload!,
                  version: QrVersions.auto,
                  size: 220.r,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 14.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFF1550A6).withValues(alpha: 0.2)),
                  ),
                  child: Text(topic,
                      style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1550A6))),
                ),
                SizedBox(height: 6.h),
                Text('Scan this QR to join the meeting',
                    style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _qrPayload!));
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Meeting join link copied', style: GoogleFonts.inter(fontSize: 13.sp)),
                  backgroundColor: const Color(0xFF1550A6),
                  duration: const Duration(seconds: 2),
                ));
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Join Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                padding: EdgeInsets.symmetric(vertical: 13.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanQrTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Text("Point camera at another user's meeting QR code",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white.withValues(alpha: 0.6))),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      if (_scanned) return;
                      for (final barcode in capture.barcodes) {
                        final val = barcode.rawValue;
                        if (val != null && val.isNotEmpty) {
                          _scanned = true;
                          _scannerController.stop();
                          HapticFeedback.heavyImpact();
                          Navigator.of(context).pop();
                          if (Get.isRegistered<LiveCallController>()) {
                            Get.find<LiveCallController>().joinFromQrPayload(val);
                          } else if (Get.isRegistered<AttorneyLiveCallController>()) {
                            Get.find<AttorneyLiveCallController>().joinFromQrPayload(val);
                          } else if (Get.isRegistered<DoctorLiveCallController>()) {
                            Get.find<DoctorLiveCallController>().joinFromQrPayload(val);
                          }
                          break;
                        }
                      }
                    },
                  ),
                  Container(
                    width: 200.w, height: 200.w,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF60A5FA), width: 3.w),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}
