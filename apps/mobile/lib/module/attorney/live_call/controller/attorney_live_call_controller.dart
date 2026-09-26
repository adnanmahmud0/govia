import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/services/call_background_service.dart';
import 'package:gsabino365/core/services/location_service.dart';
import 'package:gsabino365/core/services/wakelock_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/meeting_model.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';

class AttorneyLiveCallController extends GetxController with WidgetsBindingObserver {
  final MeetingRepository meetingRepo;

  AttorneyLiveCallController({required this.meetingRepo});

  // ─── LiveKit Room & Listener ─────────────────────────────────────────
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  Room? get room => _room;

  // ─── Session State ───────────────────────────────────────────────────
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isSessionJoined = false.obs;

  MeetingModel? meeting;
  String? meetingId;
  String roomName = 'govia_consultation';

  final Rxn<VideoTrack> localVideoTrack = Rxn<VideoTrack>();
  final Rxn<VideoTrack> remoteVideoTrack = Rxn<VideoTrack>();
  final RxString remoteParticipantName = 'Citizen Caller'.obs;

  // ─── Live Location State ─────────────────────────────────────────────
  final RxnDouble liveLatitude = RxnDouble();
  final RxnDouble liveLongitude = RxnDouble();
  final RxString liveLocationAddress = ''.obs;

  bool get hasLiveLocation =>
      (liveLatitude.value != null && liveLongitude.value != null) ||
      (meeting?.latitude != null && meeting?.longitude != null) ||
      liveLocationAddress.value.isNotEmpty ||
      (meeting?.locationAddress != null &&
          meeting!.locationAddress!.isNotEmpty);

  double? get currentLat => liveLatitude.value ?? meeting?.latitude;
  double? get currentLng => liveLongitude.value ?? meeting?.longitude;

  String get currentLocationText {
    if (liveLocationAddress.value.isNotEmpty) return liveLocationAddress.value;
    if (meeting?.locationAddress != null &&
        meeting!.locationAddress!.isNotEmpty) {
      return meeting!.locationAddress!;
    }
    final lat = currentLat;
    final lng = currentLng;
    if (lat != null && lng != null) {
      return LocationService.formatCoordinates(lat, lng);
    }
    return '';
  }

  void openLiveGoogleMaps() {
    final lat = currentLat;
    final lng = currentLng;
    if (lat != null && lng != null) {
      LocationService.openGoogleMaps(latitude: lat, longitude: lng);
    } else if (currentLocationText.isNotEmpty) {
      LocationService.openGoogleMapsByQuery(currentLocationText);
    }
  }

  // ─── Phone Lock / Background State ───────────────────────────────────
  final RxBool isRemotePhoneLocked = false.obs;
  bool _wasCameraActiveBeforeLock = false;

  // ─── Media Controls State ────────────────────────────────────────────
  final RxBool isMuted = false.obs;
  final RxBool isVideoMuted = false.obs;
  final RxBool isSpeakerOn = true.obs;
  CameraPosition _cameraPosition = CameraPosition.front;

  // ─── Call Timer ──────────────────────────────────────────────────────
  final RxInt duration = 0.obs;
  Timer? _timer;
  Timer? _retryPoller;

  // ─── Reconnect State ─────────────────────────────────────────────────
  String? _lastLivekitUrl;
  String? _lastLivekitToken;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;

  String get formattedTime {
    final minutes = (duration.value / 60).floor();
    final seconds = duration.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _timer?.cancel();
    final start = meeting?.createdAt ?? DateTime.now();
    final diff = DateTime.now().difference(start).inSeconds;
    if (diff > 0) {
      duration.value = diff;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      duration.value++;
    });
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    WakelockService.enable();
    CallBackgroundService.start(
      title: 'GoVia Live Consultation',
      text: 'Call active • Live audio & video',
    );
    _extractMeetingArguments();
    joinCallSession();
  }

  void _extractMeetingArguments() {
    final args = Get.arguments;
    if (args is MeetingModel) {
      meeting = args;
      meetingId = args.id;
      roomName = args.roomName.isNotEmpty ? args.roomName : 'govia_${args.id}';
      if (args.callerName != null && args.callerName!.isNotEmpty) {
        remoteParticipantName.value = args.callerName!;
      }
      // ── Extract live location from meeting ──
      if (args.latitude != null) liveLatitude.value = args.latitude;
      if (args.longitude != null) liveLongitude.value = args.longitude;
      if (args.locationAddress != null && args.locationAddress!.isNotEmpty) {
        liveLocationAddress.value = args.locationAddress!;
      }
    } else if (args is Map) {
      // Meeting may be nested under 'meeting' key
      final rawMeeting = args.containsKey('meeting') ? args['meeting'] : null;
      final m = (rawMeeting is Map) ? rawMeeting : args;
      meetingId = m['_id']?.toString() ?? m['meetingId']?.toString() ?? m['id']?.toString();
      roomName = m['roomName']?.toString() ??
          m['sessionName']?.toString() ??
          (meetingId != null && meetingId!.isNotEmpty ? 'govia_$meetingId' : 'govia_consultation');
      if (m['callerName'] != null) {
        remoteParticipantName.value = m['callerName'].toString();
      } else if (m['topic'] != null) {
        remoteParticipantName.value = m['topic'].toString();
      }
      // ── Extract live location from map args ──
      final latVal = args['latitude'] ?? m['latitude'];
      final lngVal = args['longitude'] ?? m['longitude'];
      final locAddrVal = args['locationAddress'] ?? m['locationAddress'];
      if (latVal != null) liveLatitude.value = double.tryParse(latVal.toString());
      if (lngVal != null) liveLongitude.value = double.tryParse(lngVal.toString());
      if (locAddrVal != null && locAddrVal.toString().isNotEmpty) {
        liveLocationAddress.value = locAddrVal.toString();
      }
      // If MeetingModel was passed under 'meeting' key
      if (rawMeeting is MeetingModel) {
        meeting = rawMeeting;
        if (rawMeeting.latitude != null) liveLatitude.value = rawMeeting.latitude;
        if (rawMeeting.longitude != null) liveLongitude.value = rawMeeting.longitude;
        if (rawMeeting.locationAddress != null && rawMeeting.locationAddress!.isNotEmpty) {
          liveLocationAddress.value = rawMeeting.locationAddress!;
        }
      }
    }
  }

  Future<void> joinCallSession() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    // 1. Request camera + microphone permissions
    final permStatus = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final camGranted = permStatus[Permission.camera]?.isGranted ?? false;
    final micGranted = permStatus[Permission.microphone]?.isGranted ?? false;

    if (!camGranted || !micGranted) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Camera and microphone permissions are required to join.';
      return;
    }

    if (meeting != null) {
      final st = meeting!.status.toUpperCase();
      if (st == 'COMPLETED' || st == 'CANCELLED' || meeting!.endedAt != null) {
        isLoading.value = false;
        hasError.value = true;
        errorMessage.value = 'This encounter has already ended.';
        Helpers.showWarning('This encounter has already ended.');
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Get.currentRoute == AppRoutes.attorneyLiveCall) {
            Get.back();
          }
        });
        return;
      }
    }

    // 2. Resolve LiveKit URL & Token
    String livekitUrl = dotenv.env['LIVEKIT_URL'] ?? 'wss://govia-0f13ke90.livekit.cloud';
    String? token;

    if (Get.arguments is MeetingModel) {
      final m = Get.arguments as MeetingModel;
      if (m.livekitUrl != null && m.livekitUrl!.isNotEmpty && !m.livekitUrl!.contains('govia.com')) {
        livekitUrl = m.livekitUrl!;
      }
      token = m.token;
    } else if (Get.arguments is Map) {
      final raw = Get.arguments as Map;
      final m = (raw.containsKey('meeting') && raw['meeting'] is Map)
          ? raw['meeting'] as Map
          : raw;
      if (m['livekitUrl'] != null && !m['livekitUrl'].toString().contains('govia.com')) {
        livekitUrl = m['livekitUrl'].toString();
      }
      token = m['token']?.toString() ?? m['livekitToken']?.toString();
    }

    if ((token == null || token.isEmpty) && meetingId != null && meetingId!.isNotEmpty) {
      final tokenData = await meetingRepo.getMeetingToken(meetingId!);
      if (tokenData != null) {
        token = tokenData['token']?.toString() ?? tokenData['livekitToken']?.toString();
      } else {
        final err = meetingRepo.lastErrorMessage ?? 'This encounter has ended and is no longer available to join.';
        isLoading.value = false;
        hasError.value = true;
        errorMessage.value = err;
        Helpers.showWarning(err);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Get.currentRoute == AppRoutes.attorneyLiveCall) {
            Get.back();
          }
        });
        return;
      }
    }

    // Fallback token generator using project keys
    final apiKey = dotenv.env['LIVEKIT_API_KEY'] ?? 'API6NLt8C36WoQ8';
    final apiSecret = dotenv.env['LIVEKIT_API_SECRET'] ?? 'hhc2Hz8oTvHN6flpBOGWTxDBU2h9hOWHwRXUSh49DuY';
    if (token == null || token.isEmpty) {
      if (meetingId != null && meetingId!.isNotEmpty) {
        final err = meetingRepo.lastErrorMessage ?? 'This encounter has ended and is no longer available to join.';
        isLoading.value = false;
        hasError.value = true;
        errorMessage.value = err;
        Helpers.showWarning(err);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Get.currentRoute == AppRoutes.attorneyLiveCall) {
            Get.back();
          }
        });
        return;
      }
      String professionalName = 'Attorney Sarah Jenkins';
      String professionalId = 'attorney_${DateTime.now().millisecondsSinceEpoch}';
      if (Get.isRegistered<AuthService>()) {
        final auth = Get.find<AuthService>();
        final user = auth.currentUser.value;
        final role = user?.role?.toUpperCase() ?? 'ATTORNEY';
        final defaultName = role == 'POLICE'
            ? 'Officer'
            : role == 'BAIL_BONDSMAN'
                ? 'Bail Agent'
                : 'Attorney';
        professionalName = user?.name ?? defaultName;
        professionalId = user?.id ?? '${role.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';
      }

      token = _generateLiveKitToken(
        apiKey: apiKey,
        apiSecret: apiSecret,
        roomName: roomName,
        identity: professionalId,
        name: professionalName,
      );
    }

    // 3. Connect to LiveKit Room
    try {
      await _connectLiveKit(livekitUrl, token);
      isLoading.value = false;
      _startTimer();
    } catch (e) {
      debugPrint('⚠️ Error joining attorney call: $e');
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Failed to connect to video session: $e';
    }
  }

  Future<void> _connectLiveKit(String url, String token) async {
    await _cleanupRoom();

    // Store last connection params for auto-reconnect
    _lastLivekitUrl = url;
    _lastLivekitToken = token;

    final room = Room(
      roomOptions: const RoomOptions(
        // ── Low-Latency Configuration ──────────────────────────────────────
        // Disabled adaptiveStream & dynacast: in a 2-person call these features
        // require simulcast layers that we don't publish. Leaving them on with
        // simulcast=false causes the receiver-side adaptive logic to pause/resume
        // the single track, which builds a growing jitter buffer (visible lag).
        adaptiveStream: false,
        dynacast: false,
        // ──────────────────────────────────────────────────────────────────
        defaultAudioPublishOptions: AudioPublishOptions(
          name: 'microphone',
          dtx: true,
          // 24 kbps is sufficient for voice — leaves more headroom for video.
          encoding: AudioEncoding(maxBitrate: 24000),
        ),
        defaultVideoPublishOptions: VideoPublishOptions(
          simulcast: false,
          videoEncoding: VideoEncoding(
            // 1.5 Mbps @ 30fps: encoder has enough budget to flush every frame
            // immediately without queuing. Previously 900kbps@24fps caused
            // keyframe starvation under load → growing receiver delay.
            maxBitrate: 1500000,
            maxFramerate: 30,
          ),
        ),
      ),
    );
    _room = room;

    final listener = room.createListener();
    _listener = listener;

    _setupLiveKitListeners(listener, room);

    await room.connect(
      url,
      token,
      fastConnectOptions: FastConnectOptions(
        camera: const TrackOption(enabled: true),
        microphone: const TrackOption(enabled: true),
      ),
    );

    // Reset reconnect counter on successful connection
    _reconnectAttempts = 0;
    _isReconnecting = false;

    // Publish local camera at 540p@30fps for instant, low-latency streaming.
    await room.localParticipant?.setCameraEnabled(
      true,
      cameraCaptureOptions: CameraCaptureOptions(
        cameraPosition: _cameraPosition,
        params: VideoParametersPresets.h540_169,
      ),
    );
    await room.localParticipant?.setMicrophoneEnabled(true);

    _updateTracks(room);
    isSessionJoined.value = true;

    // Retry checking remote tracks during initial seconds to catch early incoming video
    _retryPoller?.cancel();
    _retryPoller = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (t.tick > 10 || remoteVideoTrack.value != null || _room == null) {
        t.cancel();
        _retryPoller = null;
      } else if (_room != null) {
        _updateTracks(_room!);
      }
    });
  }

  void _setupLiveKitListeners(EventsListener<RoomEvent> listener, Room room) {
    listener
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('🔴 Attorney LiveKit RoomDisconnected: ${event.reason}');
        isSessionJoined.value = false;
        localVideoTrack.value = null;
        remoteVideoTrack.value = null;

        // Auto-reconnect on unexpected network drops (EOF / signal close)
        final reason = event.reason;
        final isUserInitiated = reason == DisconnectReason.clientInitiated ||
            reason == DisconnectReason.participantRemoved ||
            reason == DisconnectReason.roomDeleted ||
            reason == DisconnectReason.roomClosed;

        if (!isUserInitiated &&
            !_isReconnecting &&
            _reconnectAttempts < 3 &&
            _lastLivekitUrl != null &&
            _lastLivekitToken != null) {
          _isReconnecting = true;
          _reconnectAttempts++;
          final delaySeconds = _reconnectAttempts * 2;
          debugPrint('🔄 Attorney auto-reconnect in ${delaySeconds}s (attempt $_reconnectAttempts/3)...');
          Future.delayed(Duration(seconds: delaySeconds), () async {
            // Abort if user explicitly cleaned up the room
            if (_lastLivekitUrl == null) {
              _isReconnecting = false;
              return;
            }
            try {
              await _connectLiveKit(_lastLivekitUrl!, _lastLivekitToken!);
              debugPrint('✅ Attorney LiveKit reconnected successfully');
            } catch (e) {
              debugPrint('⚠️ Attorney reconnect attempt $_reconnectAttempts failed: $e');
              _isReconnecting = false;
            }
          });
        }
      })
      ..on<ParticipantConnectedEvent>((event) {
        debugPrint('👤 LiveKit ParticipantConnected: ${event.participant.identity}');
        _updateTracks(room);
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        debugPrint('👤 LiveKit ParticipantDisconnected: ${event.participant.identity}');
        _updateTracks(room);
      })
      ..on<TrackSubscribedEvent>((event) {
        debugPrint('📹 LiveKit TrackSubscribed: ${event.track.kind}');
        _updateTracks(room);
      })
      ..on<TrackUnsubscribedEvent>((event) {
        debugPrint('📹 LiveKit TrackUnsubscribed: ${event.track.kind}');
        _updateTracks(room);
      })
      ..on<TrackPublishedEvent>((event) {
        debugPrint('📹 LiveKit TrackPublished: ${event.publication.kind}');
        _updateTracks(room);
      })
      ..on<TrackUnpublishedEvent>((event) {
        debugPrint('📹 LiveKit TrackUnpublished: ${event.publication.kind}');
        _updateTracks(room);
      })
      ..on<TrackMutedEvent>((event) {
        debugPrint('📹 LiveKit TrackMuted: ${event.publication.kind}');
        _updateTracks(room);
      })
      ..on<TrackUnmutedEvent>((event) {
        debugPrint('📹 LiveKit TrackUnmuted: ${event.publication.kind}');
        _updateTracks(room);
      })
      ..on<TrackStreamStateUpdatedEvent>((event) {
        debugPrint('📹 LiveKit TrackStreamStateUpdated: ${event.streamState}');
        _updateTracks(room);
      })
      ..on<LocalTrackPublishedEvent>((event) {
        debugPrint('📹 LiveKit LocalTrackPublished: ${event.publication.kind}');
        _updateTracks(room);
      })
      ..on<LocalTrackUnpublishedEvent>((event) {
        debugPrint('📹 LiveKit LocalTrackUnpublished: ${event.publication.kind}');
        _updateTracks(room);
      })
      ..on<DataReceivedEvent>((event) {
        try {
          final msg = utf8.decode(event.data);
          if (msg == 'meeting_ended') {
            debugPrint('🔔 Host ended meeting — concluding attorney session');
            _onHostEndedMeeting();
          } else if (msg.contains('"type":"lock_state"') || msg.contains('"type": "lock_state"')) {
            final map = jsonDecode(msg) as Map<String, dynamic>;
            isRemotePhoneLocked.value = map['isLocked'] == true;
            debugPrint('📱 Remote participant phone lock state: ${isRemotePhoneLocked.value}');
          }
        } catch (_) {}
      });
  }

  void _updateTracks(Room room) {
    // Local video track (Attorney's own camera)
    final localPub = room.localParticipant?.videoTrackPublications.firstOrNull;
    if (localPub?.track is VideoTrack) {
      localVideoTrack.value = localPub!.track as VideoTrack;
    } else {
      localVideoTrack.value = null;
    }

    // Remote video track (Citizen's camera stream)
    VideoTrack? foundRemoteTrack;
    String caller = '';

    for (final participant in room.remoteParticipants.values) {
      for (final pub in participant.videoTrackPublications) {
        if (pub.track is VideoTrack) {
          foundRemoteTrack = pub.track as VideoTrack;
          caller = participant.name.isNotEmpty
              ? participant.name
              : (participant.identity.isNotEmpty ? participant.identity : 'Citizen Caller');
          break;
        }
      }
      if (foundRemoteTrack != null) break;
    }

    remoteVideoTrack.value = foundRemoteTrack;
    if (caller.isNotEmpty) {
      remoteParticipantName.value = caller;
    }
  }

  Future<void> toggleMute() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    try {
      final newMuted = !isMuted.value;
      await participant.setMicrophoneEnabled(!newMuted);
      isMuted.value = newMuted;
    } catch (e) {
      debugPrint('Error toggling audio: $e');
    }
  }

  Future<void> toggleVideo() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    try {
      final newVideoMuted = !isVideoMuted.value;
      await participant.setCameraEnabled(!newVideoMuted);
      isVideoMuted.value = newVideoMuted;
      if (newVideoMuted) {
        localVideoTrack.value = null;
      } else if (_room != null) {
        _updateTracks(_room!);
      }
    } catch (e) {
      debugPrint('Error toggling video: $e');
    }
  }

  Future<void> switchCamera() async {
    final localPub = _room?.localParticipant?.videoTrackPublications.firstOrNull;
    final videoTrack = localPub?.track;
    if (videoTrack is LocalVideoTrack) {
      try {
        final newPosition = _cameraPosition == CameraPosition.front
            ? CameraPosition.back
            : CameraPosition.front;
        await videoTrack.setCameraPosition(newPosition);
        _cameraPosition = newPosition;
      } catch (e) {
        debugPrint('Error switching camera: $e');
      }
    }
  }

  Future<void> toggleSpeaker() async {
    isSpeakerOn.toggle();
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(isSpeakerOn.value);
    } catch (e) {
      debugPrint('Error toggling attorney speakerphone: $e');
    }
  }

  Future<void> endCall() => leaveCall();

  Future<void> leaveCall() async {
    _timer?.cancel();
    final mId = meetingId ?? meeting?.id;
    if (mId != null && mId.isNotEmpty) {
      try {
        await meetingRepo.leaveMeeting(mId);
      } catch (_) {}
    }
    // Attorney leaves session only — do NOT mark meeting as ended so the citizen host remains live
    await _cleanupRoom();
    Get.back();
    Helpers.showSuccess('Consultation session left.');
  }

  // ─── In-Meeting QR Join Payload ───────────────────────────────────────
  /// Returns a JSON string that encodes this meeting's join info for QR sharing
  Future<String?> getMeetingJoinQrPayload() async {
    final mId = meetingId ?? meeting?.id;
    if (mId == null || mId.isEmpty) return null;

    String? guestToken;
    try {
      final tokenData = await meetingRepo.getMeetingToken(mId);
      guestToken = tokenData?['token']?.toString() ?? tokenData?['livekitToken']?.toString();
    } catch (_) {}

    guestToken ??= meeting?.token;

    return jsonEncode({
      'type': 'meeting_join',
      'meetingId': mId,
      'roomName': roomName,
      'topic': meeting?.topic ?? 'Live Consultation',
      'token': guestToken ?? '',
      'livekitUrl': meeting?.livekitUrl ?? '',
      'category': meeting?.category ?? 'ENCOUNTER',
      'meetingType': meeting?.meetingType ?? 'INSTANT',
    });
  }

  /// Parses a meeting QR payload and joins the encoded meeting room
  Future<void> joinFromQrPayload(String jsonPayload) async {
    try {
      final map = jsonDecode(jsonPayload) as Map<String, dynamic>;
      if (map['type'] != 'meeting_join') return;
      final mId = map['meetingId']?.toString();
      if (mId != null && mId.isNotEmpty) {
        final tokenData = await meetingRepo.getMeetingToken(mId);
        if (tokenData == null) {
          Helpers.showWarning('This encounter has already ended.');
          return;
        }
      }
      meetingId = mId;
      roomName = map['roomName']?.toString() ?? 'govia_$meetingId';
      final token = map['token']?.toString();
      final url = map['livekitUrl']?.toString() ?? dotenv.env['LIVEKIT_URL'] ?? 'wss://govia-0f13ke90.livekit.cloud';
      if (token != null && token.isNotEmpty) {
        await _connectLiveKit(url, token);
      }
    } catch (e) {
      Helpers.showError('Invalid meeting QR code.', title: 'Error');
    }
  }

  void _onHostEndedMeeting() {
    _timer?.cancel();
    _cleanupRoom();
    Get.back();
    Helpers.showError('The host has ended the session.', title: 'Meeting Ended');
  }

  Future<void> _cleanupRoom() async {
    WakelockService.disable();
    CallBackgroundService.stop();
    _retryPoller?.cancel();
    _retryPoller = null;
    // Clear reconnect params so any pending timer won't fire after intentional leave
    _lastLivekitUrl = null;
    _lastLivekitToken = null;
    _isReconnecting = false;
    try {
      await _listener?.dispose();
      _listener = null;
      await _room?.disconnect();
      await _room?.dispose();
      _room = null;
    } catch (e) {
      debugPrint('Error cleaning up room: $e');
    }
  }

  String _generateLiveKitToken({
    required String apiKey,
    required String apiSecret,
    required String roomName,
    required String identity,
    required String name,
  }) {
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = {
      'exp': now + 21600,
      'nbf': now - 10,
      'iss': apiKey,
      'sub': identity,
      'name': name,
      'video': {
        'room': roomName,
        'roomJoin': true,
        'canPublish': true,
        'canSubscribe': true,
        'canPublishData': true,
      },
    };

    String base64UrlNoPadding(String str) {
      return base64Url.encode(utf8.encode(str)).replaceAll('=', '');
    }

    final encodedHeader = base64UrlNoPadding(jsonEncode(header));
    final encodedPayload = base64UrlNoPadding(jsonEncode(payload));
    final dataToSign = '$encodedHeader.$encodedPayload';

    final hmac = Hmac(sha256, utf8.encode(apiSecret));
    final digest = hmac.convert(utf8.encode(dataToSign));
    final encodedSignature = base64Url.encode(digest.bytes).replaceAll('=', '');

    return '$dataToSign.$encodedSignature';
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockService.disable();
    CallBackgroundService.stop();
    _timer?.cancel();
    _retryPoller?.cancel();
    _retryPoller = null;
    _cleanupRoom();
    super.onClose();
  }

  // ─── Lifecycle Handling (Phone Lock / Unlock) ────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('📱 [AttorneyLiveCallController] App lifecycle changed: $state');

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Phone is locked or minimized: Keep audio active, pause camera gracefully
      if (!isVideoMuted.value && localVideoTrack.value != null) {
        _wasCameraActiveBeforeLock = true;
        _room?.localParticipant?.setCameraEnabled(false);
        localVideoTrack.value = null;
      }
      _broadcastLockState(true);
      CallBackgroundService.start(
        title: 'GoVia Live Consultation',
        text: 'Phone locked • Live audio active',
      );
    } else if (state == AppLifecycleState.resumed) {
      // Phone is unlocked: Restore video feed automatically
      _broadcastLockState(false);
      CallBackgroundService.start(
        title: 'GoVia Live Consultation',
        text: 'Call active • Live audio & video',
      );

      if (_wasCameraActiveBeforeLock && !isVideoMuted.value) {
        _wasCameraActiveBeforeLock = false;
        _room?.localParticipant?.setCameraEnabled(
          true,
          cameraCaptureOptions: CameraCaptureOptions(
            cameraPosition: _cameraPosition,
            params: VideoParametersPresets.h540_169,
          ),
        ).then((_) {
          if (_room != null) {
            _updateTracks(_room!);
          }
        }).catchError((e) {
          debugPrint('⚠️ Error auto-resuming camera on unlock: $e');
        });
      }
    }
  }

  Future<void> _broadcastLockState(bool isLocked) async {
    try {
      final payload = jsonEncode({
        'type': 'lock_state',
        'isLocked': isLocked,
      });
      await _room?.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
      );
    } catch (_) {}
  }
}
