import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/data/models/meeting_model.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';
import 'package:gsabino365/module/citizen/live_call/controller/live_call_controller.dart';
import 'package:gsabino365/module/shared/chat/controller/chat_controller.dart';

class UserQrCardDialog extends StatefulWidget {
  final String userName;
  final String userRole;
  final String shortHexId;
  final String fullId;
  final String? avatarUrl;
  final int initialTabIndex;

  const UserQrCardDialog({
    super.key,
    required this.userName,
    required this.userRole,
    required this.shortHexId,
    required this.fullId,
    this.avatarUrl,
    this.initialTabIndex = 0,
  });

  static void show({
    required String userName,
    required String userRole,
    required String shortHexId,
    required String fullId,
    String? avatarUrl,
    int initialTabIndex = 0,
  }) {
    Get.dialog(
      UserQrCardDialog(
        userName: userName,
        userRole: userRole,
        shortHexId: shortHexId,
        fullId: fullId,
        avatarUrl: avatarUrl,
        initialTabIndex: initialTabIndex,
      ),
      barrierDismissible: true,
    );
  }

  @override
  State<UserQrCardDialog> createState() => _UserQrCardDialogState();
}

class _UserQrCardDialogState extends State<UserQrCardDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _cardRepaintKey = GlobalKey();

  bool _isDownloading = false;

  // Scanner state
  late MobileScannerController _scannerController;
  bool _hasScanned = false;
  Map<String, dynamic>? _scannedUserData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _tabController.addListener(() {
      if (_tabController.index == 1 && _hasScanned) {
        _resetScanner();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _scannedUserData = null;
    });
    _scannerController.start();
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final rawVal = barcode.rawValue!.trim();
    if (rawVal.isEmpty) return;

    // Guard: single scan
    _hasScanned = true;
    HapticFeedback.mediumImpact();

    // Immediately stop camera to avoid multiple triggers & save battery
    await _scannerController.stop();

    Map<String, dynamic> decoded = {};
    // Parse QR payload
    try {
      if (rawVal.startsWith('{') && rawVal.endsWith('}')) {
        decoded = Map<String, dynamic>.from(jsonDecode(rawVal) as Map);
      } else {
        decoded = {
          'name': 'Govia User',
          'role': 'Member',
          'shortId': rawVal.length >= 8 ? rawVal.substring(rawVal.length - 8).toUpperCase() : rawVal,
          'id': rawVal,
        };
      }
    } catch (_) {
      decoded = {
        'name': 'Govia User',
        'role': 'Member',
        'shortId': rawVal.length >= 8 ? rawVal.substring(rawVal.length - 8).toUpperCase() : rawVal,
        'id': rawVal,
      };
    }

    // Check if target user has an active live incident meeting or if this is a meeting QR
    try {
      final apiClient = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();
      final targetUserId = decoded['id']?.toString() ?? decoded['_id']?.toString() ?? rawVal;
      final targetShortId = decoded['shortId']?.toString() ?? '';
      final lookupKey = targetUserId.isNotEmpty ? targetUserId : (targetShortId.isNotEmpty ? targetShortId : rawVal);

      // Call lookup endpoint which returns user details + activeMeeting securely for all roles
      try {
        final lookupRes = await apiClient.getData('/users/lookup/$lookupKey');
        if (lookupRes.statusCode == 200 && lookupRes.data != null) {
          final uData = lookupRes.data['data'] as Map<String, dynamic>?;
          if (uData != null) {
            decoded['name'] = uData['name'] ?? decoded['name'];
            decoded['role'] = uData['role'] ?? decoded['role'];
            decoded['avatar'] = uData['image'] ?? decoded['avatar'];
            decoded['shortId'] = uData['shortHexId'] ?? decoded['shortId'];
            decoded['id'] = uData['_id'] ?? decoded['id'];
            if (uData['activeMeeting'] != null) {
              final m = Map<String, dynamic>.from(uData['activeMeeting'] as Map);
              final category = (m['category'] ?? '').toString().toUpperCase();
              final meetingType = (m['meetingType'] ?? '').toString().toUpperCase();
              // Top QR button only allows Type 1 (ENCOUNTER) and Type 2 (EMERGENCY), excluding Type 3 (CONSULTATION)
              if (category != 'CONSULTATION' && meetingType != 'SCHEDULED') {
                decoded['activeMeeting'] = m;
                decoded['meetingId'] = m['_id']?.toString() ?? m['id']?.toString();
                decoded['hasActiveIncident'] = true;
                decoded['incidentTopic'] = m['topic'] ?? 'Active Live Encounter';
                decoded['roomName'] = m['roomName'] ?? '';
              }
            }
          }
        }
      } catch (_) {}

      // Fallback: Check active meetings repository if still not found
      if (decoded['hasActiveIncident'] != true) {
        try {
          final meetingRepo = Get.isRegistered<MeetingRepository>()
              ? Get.find<MeetingRepository>()
              : MeetingRepository(apiClient: apiClient);
          final activeMeetings = await meetingRepo.getActiveMeetings();
          final activeMeeting = activeMeetings.firstWhereOrNull((m) {
            final category = (m.category ?? '').toUpperCase();
            final meetingType = m.meetingType.toUpperCase();
            if (category == 'CONSULTATION' || meetingType == 'SCHEDULED') {
              return false;
            }
            return m.userId == targetUserId ||
                (targetShortId.isNotEmpty && m.userId?.endsWith(targetShortId) == true) ||
                (m.callerName != null && m.callerName!.isNotEmpty && m.callerName == decoded['name']);
          });
          if (activeMeeting != null) {
            decoded['activeMeeting'] = activeMeeting;
            decoded['meetingId'] = activeMeeting.id;
            decoded['hasActiveIncident'] = true;
            decoded['incidentTopic'] = activeMeeting.topic;
            decoded['roomName'] = activeMeeting.roomName;
          }
        } catch (_) {}
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _scannedUserData = decoded;
      });
    }
  }

  Future<void> _downloadQrCard() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      final boundary =
          _cardRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not render QR card');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Image conversion failed');
      final pngBytes = byteData.buffer.asUint8List();

      Directory? downloadDir;
      if (Platform.isAndroid) {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          downloadDir = publicDownload;
        } else {
          downloadDir = await getExternalStorageDirectory();
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      final fileName =
          'GoVia_Card_${widget.shortHexId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${downloadDir?.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      Get.rawSnackbar(
        title: 'QR Card Downloaded',
        message: 'Saved to Downloads:\n$fileName',
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.download_done_rounded, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Download Error',
        message: 'Could not save QR card: $e',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrPayload = widget.fullId.isNotEmpty && widget.fullId != 'N/A'
        ? '{"app":"govia","id":"${widget.fullId}","shortId":"${widget.shortHexId}","name":"${widget.userName}","role":"${widget.userRole}"}'
        : widget.shortHexId;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28.r),
      ),
      backgroundColor: Colors.white,
      elevation: 16,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Container(
        constraints: BoxConstraints(maxWidth: 390.w, maxHeight: 680.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar with Tabs & Close
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 16.w, 8.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 22.r,
                      height: 22.r,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.qr_code_scanner_rounded,
                        color: const Color(0xFF1E3A8A),
                        size: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Digital ID & QR',
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: const Color(0xFF64748B),
                      size: 22.sp,
                    ),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'My Digital Card'),
                  Tab(text: 'Scan QR'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: My Card
                  _buildMyCardTab(qrPayload),
                  // Tab 2: Scan QR
                  _buildScanQrTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── TAB 1: MY CARD ────────────────────────
  Widget _buildMyCardTab(String qrPayload) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        children: [
          // RepaintBoundary captured for downloading
          RepaintBoundary(
            key: _cardRepaintKey,
            child: Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Card Header: App Name & Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 32.r,
                              height: 32.r,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 32.r,
                                height: 32.r,
                                color: const Color(0xFF1E3A8A),
                                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GoVia',
                                style: GoogleFonts.outfit(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E3A8A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Official Digital Identity',
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'VERIFIED',
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF059669),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  SizedBox(height: 14.h),

                  // User Info Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                        backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                            ? NetworkImage(ApiConstants.getFileUrl(widget.avatarUrl)) as ImageProvider
                            : const AssetImage('assets/images/user_avatar.png'),
                        onBackgroundImageError: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                            ? (exception, stackTrace) {}
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                widget.userRole,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // QR Code
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: QrImageView(
                        data: qrPayload,
                        version: QrVersions.auto,
                        size: 160.r,
                        gapless: true,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1E3A8A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // IDs summary inside card
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ID: #${widget.shortHexId}',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A8A),
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'GoVia Network',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),

          // Action Buttons: Copy ID & Download QR Card
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.shortHexId));
                    Get.rawSnackbar(
                      message: 'Copied Short ID: #${widget.shortHexId}',
                      duration: const Duration(seconds: 2),
                      backgroundColor: const Color(0xFF1E3A8A),
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  icon: Icon(Icons.copy_rounded, size: 16.sp),
                  label: Text(
                    'Copy ID',
                    style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadQrCard,
                  icon: _isDownloading
                      ? SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.download_rounded, size: 16.sp),
                  label: Text(
                    _isDownloading ? 'Saving...' : 'Download Card',
                    style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────── TAB 2: SCAN QR ────────────────────────
  Widget _buildScanQrTab() {
    if (_hasScanned && _scannedUserData != null) {
      return _buildScannedResultView();
    }

    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Text(
            'Point camera at a Govia QR code',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),

          // Camera Viewport
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _handleBarcodeDetected,
                  ),
                  // Scan Crosshair overlay
                  Container(
                    width: 200.r,
                    height: 200.r,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF1E3A8A), width: 2.5.w),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Scanner detects instantly and closes camera.',
            style: GoogleFonts.inter(fontSize: 11.5.sp, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── SCANNED RESULT VIEW ────────────────────────
  Widget _buildScannedResultView() {
    final data = _scannedUserData ?? {};
    final category = (data['category'] ?? data['activeMeeting']?['category'] ?? '').toString().toUpperCase();
    final isConsultation = category == 'CONSULTATION' || data['meetingType'] == 'SCHEDULED';
    final hasActiveIncident = !isConsultation && data['hasActiveIncident'] == true;
    final isMeeting = !isConsultation && (data['type'] == 'meeting_join' || data['meetingId'] != null || hasActiveIncident);
    final currentRole = AuthService.to.currentUser.value?.role?.toUpperCase() ?? '';

    final scannedName = data['name']?.toString() ?? 'Govia Member';
    final scannedRole = data['role']?.toString() ?? 'Citizen';
    final idStr = data['id']?.toString() ?? data['_id']?.toString() ?? '';
    final scannedShortId = data['shortId']?.toString() ??
        (idStr.length >= 8
            ? idStr.substring(idStr.length - 8).toUpperCase()
            : (idStr.isNotEmpty ? idStr.toUpperCase() : 'N/A'));
    final scannedFullId = idStr.isNotEmpty ? idStr : 'N/A';
    final scannedAvatar = data['avatar']?.toString() ??
        data['image']?.toString() ??
        data['profilePicture']?.toString();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: hasActiveIncident ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                width: hasActiveIncident ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasActiveIncident
                              ? Icons.warning_amber_rounded
                              : (isMeeting ? Icons.videocam_rounded : Icons.check_circle_rounded),
                          color: hasActiveIncident ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          hasActiveIncident
                              ? 'Live Incident Active'
                              : (isMeeting ? 'Meeting Found' : 'Verified Govia Member'),
                          style: GoogleFonts.outfit(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: hasActiveIncident ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: hasActiveIncident
                            ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                            : const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        hasActiveIncident
                            ? 'INCIDENT'
                            : (isMeeting ? 'MEETING' : scannedRole.toUpperCase()),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: hasActiveIncident ? const Color(0xFFDC2626) : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                SizedBox(height: 14.h),

                // Avatar and Name
                CircleAvatar(
                  radius: 32.r,
                  backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                  backgroundImage: (scannedAvatar != null && scannedAvatar.isNotEmpty)
                      ? NetworkImage(ApiConstants.getFileUrl(scannedAvatar)) as ImageProvider
                      : const AssetImage('assets/images/user_avatar.png'),
                ),
                SizedBox(height: 10.h),
                Text(
                  isMeeting ? (data['topic']?.toString() ?? 'Govia Session') : scannedName,
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'ID: #$scannedShortId',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  scannedFullId,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if (hasActiveIncident) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 20),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Incident in Progress',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                              Text(
                                data['incidentTopic']?.toString() ?? 'Active live call started by citizen',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: const Color(0xFFB91C1C),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // CTA: If meeting / incident -> Join meeting role-aware
          if (isMeeting) ...[
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Get.back();
                  final meetingId = data['meetingId']?.toString() ?? '';
                  final activeMeeting = data['activeMeeting'];

                  MeetingModel? joinedMeeting;
                  if (meetingId.isNotEmpty) {
                    try {
                      final meetingRepo = Get.isRegistered<MeetingRepository>()
                          ? Get.find<MeetingRepository>()
                          : MeetingRepository(apiClient: Get.find<ApiClient>());
                      joinedMeeting = await meetingRepo.joinMeeting(meetingId);
                    } catch (_) {}
                  }

                  final meetingArgs = joinedMeeting ?? activeMeeting ?? data;

                  if (currentRole == 'ATTORNEY' || currentRole == 'POLICE' || currentRole == 'BAIL_BONDSMAN') {
                    Get.toNamed(AppRoutes.attorneyLiveCall, arguments: meetingArgs);
                  } else if (currentRole == 'DOCTOR' || currentRole == 'MENTAL_HEALTH_PROFESSIONAL') {
                    Get.toNamed(AppRoutes.doctorLiveCall, arguments: meetingArgs);
                  } else {
                    if (Get.isRegistered<LiveCallController>()) {
                      Get.find<LiveCallController>().joinIncomingOrExistingMeeting(
                        meetingArgs is Map<String, dynamic> ? meetingArgs : data,
                      );
                    } else {
                      Get.toNamed(AppRoutes.citizenLiveCall, arguments: meetingArgs);
                    }
                  }
                },
                icon: const Icon(Icons.videocam_rounded),
                label: Text(
                  currentRole == 'POLICE'
                      ? 'Join Encounter as Officer'
                      : currentRole == 'ATTORNEY'
                          ? 'Join Meeting as Attorney'
                          : currentRole == 'BAIL_BONDSMAN'
                              ? 'Join Meeting as Bail Agent'
                              : currentRole == 'DOCTOR' || currentRole == 'MENTAL_HEALTH_PROFESSIONAL'
                                  ? 'Join Session as Doctor'
                                  : 'Join Meeting Now',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],

          // Always offer Message User button
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.back();
                if (Get.isRegistered<ChatController>()) {
                  Get.find<ChatController>().openOrCreateChatWithUser({
                    '_id': scannedFullId,
                    'name': scannedName,
                    'role': scannedRole,
                    'profilePicture': scannedAvatar,
                  });
                } else {
                  Get.toNamed(AppRoutes.attorneyChatDetails, arguments: {
                    '_id': scannedFullId,
                    'name': scannedName,
                    'role': scannedRole,
                  });
                }
              },
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text('Message User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          OutlinedButton.icon(
            onPressed: _resetScanner,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan Another QR'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ],
      ),
    );
  }
}
