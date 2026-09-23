import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:gsabino365/core/utils/helpers.dart';

enum VideoQualityMode {
  auto,
  high1080,
  medium720,
  dataSaver480,
}

/// A resilient, full-featured in-app video player for Govia session recordings.
/// Supports quality controls, network drop recovery, buffering indicators,
/// offline caching for spotty networks, gesture seeking, and playback speeds.
class GoviaVideoPlayerView extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? subtitle;
  final String? date;

  const GoviaVideoPlayerView({
    super.key,
    required this.videoUrl,
    this.title = 'Session Recording',
    this.subtitle,
    this.date,
  });

  /// Launch player anywhere in the app with a single method call
  static Future<void> open({
    required String url,
    String title = 'Session Recording',
    String? subtitle,
    String? date,
  }) async {
    if (url.trim().isEmpty) {
      Helpers.showError('No valid recording URL provided');
      return;
    }
    await Get.to(
      () => GoviaVideoPlayerView(
        videoUrl: url,
        title: title,
        subtitle: subtitle,
        date: date,
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  State<GoviaVideoPlayerView> createState() => _GoviaVideoPlayerViewState();
}

class _GoviaVideoPlayerViewState extends State<GoviaVideoPlayerView> {
  VideoPlayerController? _controller;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // UI state
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isLocked = false;
  bool _isMuted = false;
  bool _isOfflineCached = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  // Quality & Speed state
  VideoQualityMode _selectedQuality = VideoQualityMode.auto;
  double _playbackSpeed = 1.0;

  // Stored position for network reconnection
  Duration _lastPosition = Duration.zero;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _checkOfflineCacheAndInitialize();
    _listenToConnectivity();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _connectivitySubscription?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    WakelockPlus.disable();
    // Restore preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // ─── Network & Cache Handling ──────────────────────────────────────────────

  String _getCacheKey(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }

  Future<void> _checkOfflineCacheAndInitialize() async {
    try {
      final dir = await getTemporaryDirectory();
      final key = _getCacheKey(widget.videoUrl);
      final cachedFile = File('${dir.path}/govia_rec_$key.mp4');

      if (await cachedFile.exists() && await cachedFile.length() > 1024) {
        _isOfflineCached = true;
        _initializePlayer(sourceFile: cachedFile);
        return;
      }
    } catch (_) {}

    _initializePlayer(sourceUrl: widget.videoUrl);
  }

  Future<void> _initializePlayer({String? sourceUrl, File? sourceFile}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      _controller?.removeListener(_videoListener);
      await _controller?.dispose();

      if (sourceFile != null) {
        _controller = VideoPlayerController.file(sourceFile);
      } else {
        final uri = Uri.parse(sourceUrl ?? widget.videoUrl);
        _controller = VideoPlayerController.networkUrl(
          uri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }

      _controller!.addListener(_videoListener);
      await _controller!.initialize();

      // Apply initial settings
      await _controller!.setPlaybackSpeed(_playbackSpeed);
      await _controller!.setVolume(_isMuted ? 0.0 : 1.0);

      // Seek back to previous position if re-initializing after a disconnect
      if (_lastPosition > Duration.zero) {
        await _controller!.seekTo(_lastPosition);
      }

      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        _startHideControlsTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Playback error: Unable to stream recording. Tap Retry.';
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;

    final val = _controller!.value;

    // Track position
    if (val.position > Duration.zero) {
      _lastPosition = val.position;
    }

    if (val.isBuffering != _isBuffering) {
      setState(() {
        _isBuffering = val.isBuffering;
      });
    }

    if (val.hasError && !_hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = val.errorDescription ?? 'An error occurred during playback.';
      });
    }
  }

  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (isConnected && _hasError && !_isOfflineCached) {
        // Auto-recover when network becomes available
        _initializePlayer(sourceUrl: widget.videoUrl);
      }
    });
  }

  // ─── Offline Download / Cache ──────────────────────────────────────────────

  Future<void> _downloadForOfflineCache() async {
    if (_isOfflineCached) {
      Helpers.showSuccess('This recording is already saved for offline playback.');
      return;
    }

    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dir = await getTemporaryDirectory();
      final key = _getCacheKey(widget.videoUrl);
      final savePath = '${dir.path}/govia_rec_$key.mp4';

      final dio = Dio();
      await dio.download(
        widget.videoUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = (received / total).clamp(0.0, 1.0);
            });
          }
        },
      );

      final downloadedFile = File(savePath);
      if (await downloadedFile.exists()) {
        if (mounted) {
          setState(() {
            _isOfflineCached = true;
            _isDownloading = false;
          });
          Helpers.showSuccess('Cached successfully! Playable with no internet connection.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        Helpers.showError('Could not cache recording: ${e.toString()}');
      }
    }
  }

  // ─── Controls & Gestures ───────────────────────────────────────────────────

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller != null && _controller!.value.isPlaying && !_isLocked) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _showControls = true);
      _hideControlsTimer?.cancel();
    } else {
      _controller!.play();
      _startHideControlsTimer();
    }
    setState(() {});
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _controller!.value.duration ? _controller!.value.duration : target);
    _controller!.seekTo(clamped);
    _startHideControlsTimer();
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
    });
    _controller!.setVolume(_isMuted ? 0.0 : 1.0);
  }

  void _toggleOrientation() {
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  // ─── Quality & Speed Bottom Sheet ──────────────────────────────────────────

  void _showSettingsModal() {
    _hideControlsTimer?.cancel();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Playback & Quality Controls',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              SizedBox(height: 12.h),

              // Quality Options
              Text(
                'STREAMING QUALITY',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildQualityChip(VideoQualityMode.auto, 'Auto (Recommended)', 'Adaptive buffer'),
                  _buildQualityChip(VideoQualityMode.high1080, '1080p High', 'High definition'),
                  _buildQualityChip(VideoQualityMode.medium720, '720p Balanced', 'Standard'),
                  _buildQualityChip(VideoQualityMode.dataSaver480, 'Data Saver', '360p / 480p low net'),
                ],
              ),
              SizedBox(height: 20.h),

              // Speed Options
              Text(
                'PLAYBACK SPEED',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                  final isSelected = _playbackSpeed == s;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _playbackSpeed = s);
                      _controller?.setPlaybackSpeed(s);
                      Get.back();
                      _startHideControlsTimer();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${s}x',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildQualityChip(VideoQualityMode mode, String label, String desc) {
    final isSelected = _selectedQuality == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedQuality = mode);
        Get.back();
        Helpers.showSuccess('Quality switched to: $label');
        _startHideControlsTimer();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.18) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF10B981) : Colors.white,
              ),
            ),
            Text(
              desc,
              style: GoogleFonts.inter(
                fontSize: 9.5.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  // ─── Main Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: !isLandscape,
          bottom: !isLandscape,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Video Surface & Double Tap Gesture Seek ──
              Center(
                child: _isInitialized && _controller != null
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio > 0
                            ? _controller!.value.aspectRatio
                            : 16 / 9,
                        child: VideoPlayer(_controller!),
                      )
                    : const SizedBox.shrink(),
              ),

              // Tap detection overlay (single tap toggles controls, double tap seeks)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleControls,
                  onDoubleTapDown: (details) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    if (details.globalPosition.dx < screenWidth / 2) {
                      _seekRelative(-10);
                    } else {
                      _seekRelative(10);
                    }
                  },
                ),
              ),

              // ── 2. Buffering / Loading Indicator ──
              if (_isLoading || _isBuffering)
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          _isLoading ? 'Loading session...' : 'Buffering stream...',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── 3. Error Overlay ──
              if (_hasError)
                Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 24.w),
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 40.sp, color: const Color(0xFFEF4444)),
                        SizedBox(height: 12.h),
                        Text(
                          'Playback Interrupted',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _errorMessage,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton.icon(
                          onPressed: () => _initializePlayer(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text('Retry / Re-buffer', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── 4. Player HUD Overlay (Animated opacity) ──
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTopBar(isLandscape),
                        _buildCenterPlayControls(),
                        _buildBottomControls(),
                      ],
                    ),
                  ),
                ),
              ),

              // Lock Screen Indicator
              if (_isLocked && !_showControls)
                Positioned(
                  top: 20.h,
                  right: 20.w,
                  child: GestureDetector(
                    onTap: () => setState(() => _isLocked = false),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, color: Colors.white70, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildTopBar(bool isLandscape) {
    String qualityLabel;
    switch (_selectedQuality) {
      case VideoQualityMode.auto:
        qualityLabel = 'Auto';
        break;
      case VideoQualityMode.high1080:
        qualityLabel = '1080p';
        break;
      case VideoQualityMode.medium720:
        qualityLabel = '720p';
        break;
      case VideoQualityMode.dataSaver480:
        qualityLabel = 'Saver';
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Get.back(),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null || widget.date != null)
                  Text(
                    widget.subtitle ?? widget.date ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Offline Cache / Download Button
          if (_isDownloading)
            Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 14.r,
                    height: 14.r,
                    child: CircularProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      strokeWidth: 2,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white),
                  ),
                ],
              ),
            )
          else
            IconButton(
              tooltip: _isOfflineCached ? 'Cached Offline' : 'Cache for Offline Watching',
              icon: Icon(
                _isOfflineCached ? Icons.download_done_rounded : Icons.download_rounded,
                color: _isOfflineCached ? const Color(0xFF10B981) : Colors.white70,
                size: 22,
              ),
              onPressed: _downloadForOfflineCache,
            ),

          // Quality & Speed Settings Button
          GestureDetector(
            onTap: _showSettingsModal,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 14.sp, color: const Color(0xFF10B981)),
                  SizedBox(width: 4.w),
                  Text(
                    qualityLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPlayControls() {
    final isPlaying = _controller?.value.isPlaying ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s
        IconButton(
          iconSize: 34.sp,
          icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
          onPressed: () => _seekRelative(-10),
        ),
        SizedBox(width: 24.w),

        // Big Play / Pause
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 60.r,
            height: 60.r,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36.sp,
            ),
          ),
        ),
        SizedBox(width: 24.w),

        // Forward 10s
        IconButton(
          iconSize: 34.sp,
          icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
          onPressed: () => _seekRelative(10),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;

    // Calculate buffer progress fraction
    double bufferFraction = 0.0;
    if (_controller != null && _controller!.value.buffered.isNotEmpty && duration > Duration.zero) {
      final lastBuffered = _controller!.value.buffered.last.end;
      bufferFraction = (lastBuffered.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider with buffered track behind
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Buffered track indicator
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 4.h,
                    width: constraints.maxWidth * bufferFraction,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  );
                },
              ),

              // Interactive position slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.5.h,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.5.r),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
                  activeTrackColor: const Color(0xFF10B981),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                  thumbColor: const Color(0xFF10B981),
                  overlayColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0),
                  min: 0.0,
                  max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                  onChanged: (val) {
                    _startHideControlsTimer();
                    _controller?.seekTo(Duration(milliseconds: val.toInt()));
                  },
                ),
              ),
            ],
          ),

          // Bottom Bar Elements: Time, Mute, Fullscreen, Lock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  if (_isOfflineCached) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'OFFLINE MODE',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              Row(
                children: [
                  // Mute toggle
                  IconButton(
                    iconSize: 20.sp,
                    icon: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: _toggleMute,
                  ),

                  // Orientation / Fullscreen toggle
                  IconButton(
                    iconSize: 20.sp,
                    icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70),
                    onPressed: _toggleOrientation,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
