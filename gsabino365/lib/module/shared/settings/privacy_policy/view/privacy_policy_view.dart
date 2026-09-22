import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/services/storage_service.dart';

class Stroke {
  final List<Offset> points;
  Stroke(this.points);
}

class PrivacyPolicyView extends StatefulWidget {
  const PrivacyPolicyView({super.key});

  @override
  State<PrivacyPolicyView> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  List<Stroke> _strokes = [];
  bool _isSigned = false;
  String? _signedAtStr;
  bool _isSaving = false;

  static const String _sigKey = 'govia_privacy_policy_signature';
  static const String _sigDateKey = 'govia_privacy_policy_signed_at';
  static const String _sigStatusKey = 'govia_privacy_policy_signed';

  @override
  void initState() {
    super.initState();
    _loadSavedSignature();
  }

  Future<void> _loadSavedSignature() async {
    try {
      final savedJson = await StorageService.getString(_sigKey);
      final isSigned = await StorageService.getBool(_sigStatusKey) ?? false;
      final signedAt = await StorageService.getString(_sigDateKey);

      if (savedJson.isNotEmpty) {
        final strokes = _deserializeStrokes(savedJson);
        if (mounted) {
          setState(() {
            _strokes = strokes;
            _isSigned = isSigned || strokes.isNotEmpty;
            if (signedAt.isNotEmpty) {
              try {
                final dt = DateTime.parse(signedAt);
                _signedAtStr =
                    'Signed on ${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
              } catch (_) {
                _signedAtStr = 'Signed & Verified';
              }
            } else if (strokes.isNotEmpty) {
              _signedAtStr = 'Signed & Saved';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved signature: $e');
    }
  }

  static String _serializeStrokes(List<Stroke> strokes) {
    final list = strokes
        .map((s) => s.points.map((p) => [p.dx, p.dy]).toList())
        .toList();
    return jsonEncode(list);
  }

  static List<Stroke> _deserializeStrokes(String raw) {
    if (raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((strokeItem) {
        final pts = (strokeItem as List<dynamic>).map((pt) {
          final pair = pt as List<dynamic>;
          return Offset((pair[0] as num).toDouble(), (pair[1] as num).toDouble());
        }).toList();
        return Stroke(pts);
      }).toList();
    } catch (e) {
      debugPrint('Error deserializing strokes: $e');
      return [];
    }
  }

  void _openSignatureBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Draw Signature',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.close,
                    color: const Color(0xFF64748B),
                    size: 22.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Sign inside the box below using your finger',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 16.h),
            SignaturePad(
              initialStrokes: _strokes,
              onSave: (savedStrokes) async {
                setState(() {
                  _strokes = savedStrokes;
                });
                if (savedStrokes.isNotEmpty) {
                  await StorageService.setString(
                    _sigKey,
                    _serializeStrokes(savedStrokes),
                  );
                }
                Get.back();
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _confirmAgreement() async {
    if (_strokes.isEmpty) {
      Get.snackbar(
        'Signature Required',
        'Please draw your signature to confirm the agreement.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
      );
      return;
    }

    setState(() => _isSaving = true);
    final serialized = _serializeStrokes(_strokes);
    final now = DateTime.now();
    final signedAt = now.toIso8601String();

    await StorageService.setString(_sigKey, serialized);
    await StorageService.setString(_sigDateKey, signedAt);
    await StorageService.setBool(_sigStatusKey, true);

    try {
      if (Get.isRegistered<AuthService>()) {
        await AuthService.to.updateProfile({
          'privacyPolicySigned': true,
          'privacyPolicySignedAt': signedAt,
        });
      }
    } catch (e) {
      debugPrint('Syncing signature status error: $e');
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isSigned = true;
        _signedAtStr =
            'Signed on ${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
      });
    }

    Get.snackbar(
      'Agreement Confirmed',
      'Your signature has been securely saved and verified.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF059669),
      colorText: Colors.white,
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && Navigator.canPop(context)) {
        Get.back();
      }
    });
  }

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
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.w,
                          ),
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
                          'Privacy Policy',
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

              // Scrollable Policy content
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 12.h),

                      // Section 1
                      Text(
                        '1. Information We Collect',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Personal Information title
                      Text(
                        'Personal Information',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Bullets
                      _buildTextListItem('Full name and profile photo'),
                      _buildTextListItem('Email address and phone number'),
                      _buildTextListItem(
                        'Payment details and billing information',
                      ),
                      _buildTextListItem(
                        'Driver\'s license and vehicle information',
                      ),

                      SizedBox(height: 24.h),

                      // How We Use Your Information card
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: const Color(0xFFEBF0F5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.settings_outlined,
                                    color: const Color(0xFF1D4ED8),
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'How We Use Your Information',
                                        style: GoogleFonts.inter(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Your data helps us deliver a better experience',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                            _buildUseItem(
                              'Improve and personalize your ride experience',
                            ),
                            _buildUseItem(
                              'Match drivers and riders efficiently',
                            ),
                            _buildUseItem(
                              'Send ride notifications, updates, and promotions',
                            ),
                            _buildUseItem(
                              'Process payments and manage billing',
                            ),
                            _buildUseItem(
                              'Ensure safety and prevent fraud or abuse',
                            ),
                            _buildUseItem(
                              'Provide customer support and respond to inquiries',
                            ),
                            _buildUseItem(
                              'Analyze app performance and user behavior',
                            ),
                            _buildUseItem(
                              'Comply with legal obligations and regulations',
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Digital Signature Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Digital Signature',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          if (_isSigned)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: const Color(0xFF86EFAC),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14.sp,
                                    color: const Color(0xFF15803D),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    _signedAtStr ?? 'Signed & Verified',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Signature Canvas Box
                      GestureDetector(
                        onTap: _openSignatureBottomSheet,
                        child: Container(
                          width: double.infinity,
                          height: 140.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: CustomPaint(
                            painter: DashedBorderPainter(),
                            child: _strokes.isEmpty
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.gesture_rounded,
                                        color: const Color(0xFF94A3B8),
                                        size: 32.sp,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'Tap to sign',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: CustomPaint(
                                      painter: SignaturePainter(
                                        _strokes,
                                        fitToSize: true,
                                      ),
                                      size: Size.infinite,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Canvas buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              onPressed: _openSignatureBottomSheet,
                              icon: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Draw Signature',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  side: const BorderSide(
                                    color: Color(0xFFEBF0F5),
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                setState(() {
                                  _strokes.clear();
                                  _isSigned = false;
                                  _signedAtStr = null;
                                });
                                await StorageService.remove(_sigKey);
                                await StorageService.remove(_sigDateKey);
                                await StorageService.remove(_sigStatusKey);
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFF475569),
                              ),
                              label: Text(
                                'Clear',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF475569),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 32.h),

                      // Sign & Confirm button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1550A6),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                          onPressed: _isSaving ? null : _confirmAgreement,
                          icon: _isSaving
                              ? SizedBox(
                                  width: 20.sp,
                                  height: 20.sp,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _isSaving
                                ? 'Saving Signature...'
                                : _isSigned
                                    ? 'Update & Confirm Signature'
                                    : 'Sign & Confirm Agreement',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextListItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUseItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: const Color(0xFF1E3A8A), size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignaturePad extends StatefulWidget {
  final List<Stroke> initialStrokes;
  final ValueChanged<List<Stroke>> onSave;

  const SignaturePad({
    super.key,
    required this.initialStrokes,
    required this.onSave,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  late List<Stroke> _strokes;

  @override
  void initState() {
    super.initState();
    _strokes = List.from(
      widget.initialStrokes.map((s) => Stroke(List.from(s.points))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 250.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5.w),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: GestureDetector(
              onPanStart: (details) {
                final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(
                  details.globalPosition,
                );
                setState(() {
                  _strokes.add(Stroke([localPosition]));
                });
              },
              onPanUpdate: (details) {
                final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(
                  details.globalPosition,
                );
                setState(() {
                  if (_strokes.isNotEmpty) {
                    _strokes.last.points.add(localPosition);
                  }
                });
              },
              child: CustomPaint(
                painter: SignaturePainter(_strokes),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: const BorderSide(color: Color(0xFFEBF0F5)),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _strokes.clear();
                  });
                },
                icon: const Icon(Icons.clear, color: Color(0xFF475569)),
                label: Text(
                  'Clear',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1550A6),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () {
                  widget.onSave(_strokes);
                },
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Stroke> strokes;
  final bool fitToSize;

  SignaturePainter(this.strokes, {this.fitToSize = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    if (fitToSize) {
      double minX = double.infinity;
      double maxX = -double.infinity;
      double minY = double.infinity;
      double maxY = -double.infinity;

      int totalPoints = 0;
      for (var stroke in strokes) {
        for (var p in stroke.points) {
          if (p.dx < minX) minX = p.dx;
          if (p.dx > maxX) maxX = p.dx;
          if (p.dy < minY) minY = p.dy;
          if (p.dy > maxY) maxY = p.dy;
          totalPoints++;
        }
      }

      if (totalPoints > 1 && maxX > minX && maxY > minY) {
        double width = maxX - minX;
        double height = maxY - minY;

        double scaleX = (size.width - 24) / width;
        double scaleY = (size.height - 24) / height;
        double scale = scaleX < scaleY ? scaleX : scaleY;

        if (scale > 1.5) scale = 1.5;

        canvas.save();
        double dx = (size.width - width * scale) / 2 - minX * scale;
        double dy = (size.height - height * scale) / 2 - minY * scale;
        canvas.translate(dx, dy);
        canvas.scale(scale);
      }
    }

    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    if (fitToSize) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => true;
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    this.color = const Color(0xFFCBD5E1),
    this.strokeWidth = 1.5,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius.r),
        ),
      );

    final dashPath = Path();
    double distance = 0.0;
    for (var pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) => false;
}
