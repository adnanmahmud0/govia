import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/services/call_background_service.dart';
import 'package:gsabino365/core/services/location_service.dart';
import 'package:gsabino365/core/services/wakelock_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/meeting_model.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';

class LiveCallController extends GetxController with WidgetsBindingObserver {
  final MeetingRepository meetingRepo;

  LiveCallController({required this.meetingRepo});

  // ─── LiveKit Room & Listener ─────────────────────────────────────────
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  Room? get room => _room;

  // ─── Session State ───────────────────────────────────────────────────
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<MeetingModel> currentMeeting = Rxn<MeetingModel>();
  String? activeMeetingId;

  // ─── Live Location State ─────────────────────────────────────────────
  final RxnDouble liveLatitude = RxnDouble();
  final RxnDouble liveLongitude = RxnDouble();
  final RxString liveLocationAddress = ''.obs;

  bool get hasLiveLocation =>
      (liveLatitude.value != null && liveLongitude.value != null) ||
      (currentMeeting.value?.latitude != null &&
          currentMeeting.value?.longitude != null) ||
      liveLocationAddress.value.isNotEmpty ||
      (currentMeeting.value?.locationAddress != null &&
          currentMeeting.value!.locationAddress!.isNotEmpty);

  double? get currentLat =>
      liveLatitude.value ?? currentMeeting.value?.latitude;
  double? get currentLng =>
      liveLongitude.value ?? currentMeeting.value?.longitude;

  String get currentLocationText {
    if (liveLocationAddress.value.isNotEmpty) return liveLocationAddress.value;
    if (currentMeeting.value?.locationAddress != null &&
        currentMeeting.value!.locationAddress!.isNotEmpty) {
      return currentMeeting.value!.locationAddress!;
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

  final RxBool isSessionJoined = false.obs;
  final Rxn<VideoTrack> localVideoTrack = Rxn<VideoTrack>();
  final Rxn<VideoTrack> remoteVideoTrack = Rxn<VideoTrack>();
  final RxString remoteParticipantName = ''.obs;

  // ─── Phone Lock / Background State ───────────────────────────────────
  final RxBool isRemotePhoneLocked = false.obs;
  bool _wasCameraActiveBeforeLock = false;

  // ─── Media Controls State ────────────────────────────────────────────
  final RxBool isMuted = false.obs;
  final RxBool isVideoMuted = false.obs;
  final RxBool isSpeakerOn = true.obs;
  CameraPosition _cameraPosition = CameraPosition.front;

  // ─── Host & Recording State ──────────────────────────────────────────
  final RxBool isHost = false.obs;
  final RxBool isRecording = false.obs;

  // ─── Call Timer ──────────────────────────────────────────────────────
  final RxInt callSeconds = 0.obs;
  Timer? _timer;
  Timer? _retryPoller;

  // ─── Reconnect State ─────────────────────────────────────────────────
  String? _lastLivekitUrl;
  String? _lastLivekitToken;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;

  String get formattedTime {
    final m = (callSeconds.value ~/ 60).toString().padLeft(2, '0');
    final s = (callSeconds.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startTimer() {
    _timer?.cancel();
    final start = currentMeeting.value?.createdAt ?? DateTime.now();
    final diff = DateTime.now().difference(start).inSeconds;
    if (diff > 0) {
      callSeconds.value = diff;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      callSeconds.value++;
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
    final args = Get.arguments;

    if (args is MeetingModel) {
      joinIncomingOrExistingMeeting(args);
    } else if (args is Map) {
      if (args['isHost'] is bool) {
        isHost.value = args['isHost'] as bool;
      }
      if (args['meeting'] is MeetingModel ||
          args['meetingId'] != null ||
          args['_id'] != null ||
          args['id'] != null ||
          args['token'] != null ||
          (args['meeting'] is Map &&
              ((args['meeting'] as Map)['meetingId'] != null ||
                  (args['meeting'] as Map)['_id'] != null ||
                  (args['meeting'] as Map)['id'] != null))) {
        joinIncomingOrExistingMeeting(args);
      } else {
        startGoviaMeeting();
      }
    } else {
      startGoviaMeeting();
    }
  }

  Future<void> joinIncomingOrExistingMeeting(dynamic args) async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    final permStatus = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final camGranted = permStatus[Permission.camera]?.isGranted ?? false;
    final micGranted = permStatus[Permission.microphone]?.isGranted ?? false;

    if (!camGranted || !micGranted) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value =
          'Camera and microphone permissions are required for Govia sessions.';
      return;
    }

    String? mId;
    String rName = 'govia_consultation';
    String? token;
    String livekitUrl = dotenv.env['LIVEKIT_URL'] ?? 'wss://govia-0f13ke90.livekit.cloud';

    if (args is MeetingModel) {
      mId = args.id;
      rName = args.roomName.isNotEmpty ? args.roomName : 'govia_${args.id}';
      token = args.token;
      if (args.livekitUrl != null && args.livekitUrl!.isNotEmpty && !args.livekitUrl!.contains('govia.com')) {
        livekitUrl = args.livekitUrl!;
      }
      currentMeeting.value = args;
      activeMeetingId = args.id;
      if (args.latitude != null) liveLatitude.value = args.latitude;
      if (args.longitude != null) liveLongitude.value = args.longitude;
      if (args.locationAddress != null && args.locationAddress!.isNotEmpty) {
        liveLocationAddress.value = args.locationAddress!;
      }
    } else if (args is Map) {
      final latVal = args['latitude'] ?? (args['meeting'] is Map ? args['meeting']['latitude'] : null);
      final lngVal = args['longitude'] ?? (args['meeting'] is Map ? args['meeting']['longitude'] : null);
      final locAddrVal = args['locationAddress'] ?? (args['meeting'] is Map ? args['meeting']['locationAddress'] : null);
      if (latVal != null) liveLatitude.value = double.tryParse(latVal.toString());
      if (lngVal != null) liveLongitude.value = double.tryParse(lngVal.toString());
      if (locAddrVal != null && locAddrVal.toString().isNotEmpty) {
        liveLocationAddress.value = locAddrVal.toString();
      }

      if (args['meeting'] is MeetingModel) {
        final mObj = args['meeting'] as MeetingModel;
        mId = mObj.id;
        rName = mObj.roomName.isNotEmpty ? mObj.roomName : 'govia_${mObj.id}';
        token = mObj.token;
        if (mObj.livekitUrl != null && mObj.livekitUrl!.isNotEmpty && !mObj.livekitUrl!.contains('govia.com')) {
          livekitUrl = mObj.livekitUrl!;
        }
        currentMeeting.value = mObj;
        activeMeetingId = mObj.id;
        if (mObj.latitude != null) liveLatitude.value = mObj.latitude;
        if (mObj.longitude != null) liveLongitude.value = mObj.longitude;
        if (mObj.locationAddress != null && mObj.locationAddress!.isNotEmpty) {
          liveLocationAddress.value = mObj.locationAddress!;
        }
      } else {
        final m = (args.containsKey('meeting') && args['meeting'] is Map)
            ? args['meeting'] as Map
            : args;
        mId = m['_id']?.toString() ?? m['meetingId']?.toString() ?? m['id']?.toString();
        rName = m['roomName']?.toString() ??
            m['sessionName']?.toString() ??
            (mId != null && mId.isNotEmpty ? 'govia_$mId' : 'govia_consultation');
        token = m['token']?.toString() ?? m['livekitToken']?.toString();
        if (m['livekitUrl'] != null && !m['livekitUrl'].toString().contains('govia.com')) {
          livekitUrl = m['livekitUrl'].toString();
        }
        final double? parsedLat = m['latitude'] != null ? double.tryParse(m['latitude'].toString()) : liveLatitude.value;
        final double? parsedLng = m['longitude'] != null ? double.tryParse(m['longitude'].toString()) : liveLongitude.value;
        final String? parsedAddr = m['locationAddress']?.toString() ?? (liveLocationAddress.value.isNotEmpty ? liveLocationAddress.value : null);

        currentMeeting.value = MeetingModel(
          id: mId ?? '',
          roomName: rName,
          topic: m['topic']?.toString() ?? 'Govia Consultation',
          status: m['status']?.toString() ?? 'ACTIVE',
          meetingType: m['meetingType']?.toString() ?? 'INSTANT',
          token: token,
          livekitUrl: livekitUrl,
          sessionName: rName,
          callerName: m['callerName']?.toString() ?? m['topic']?.toString(),
          latitude: parsedLat,
          longitude: parsedLng,
          locationAddress: parsedAddr,
        );
        activeMeetingId = mId;
      }
    }

    if (isHost.value && liveLatitude.value == null) {
      _syncHostLocationInBackground();
    }

    if ((token == null || token.isEmpty) && mId != null && mId.isNotEmpty) {
      final tokenData = await meetingRepo.getMeetingToken(mId);
      if (tokenData != null) {
        token = tokenData['token']?.toString() ??
            tokenData['livekitToken']?.toString();
      }
    }

    final apiKey = dotenv.env['LIVEKIT_API_KEY'] ?? 'API6NLt8C36WoQ8';
    final apiSecret = dotenv.env['LIVEKIT_API_SECRET'] ?? 'hhc2Hz8oTvHN6flpBOGWTxDBU2h9hOWHwRXUSh49DuY';
    if (token == null || token.isEmpty) {
      String userName = 'Citizen User';
      String userId = mId ?? 'citizen_${DateTime.now().millisecondsSinceEpoch}';
      if (Get.isRegistered<AuthService>()) {
        final auth = Get.find<AuthService>();
        userName = auth.currentUser.value?.name ?? 'Citizen User';
        userId = auth.currentUser.value?.id ?? userId;
      }
      token = _generateLiveKitToken(
        apiKey: apiKey,
        apiSecret: apiSecret,
        roomName: rName,
        identity: userId,
        name: userName,
      );
    }

    try {
      await _connectLiveKit(livekitUrl, token);
      isLoading.value = false;
      _startTimer();

      // Auto-start cloud Egress recording if this device is the call host
      if (isHost.value) {
        debugPrint('⏺ Host starting recording in joinIncomingOrExistingMeeting for meeting: $mId');
        _startRecording();
      }
    } catch (e) {
      debugPrint('⚠️ Error joining LiveKit session: $e');
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Failed to join video session: $e';
    }
  }

  void _syncHostLocationInBackground() async {
    try {
      final pos = await LocationService.getCurrentLocation(
        timeout: const Duration(seconds: 3),
      );
      if (pos != null) {
        liveLatitude.value = pos.latitude;
        liveLongitude.value = pos.longitude;
        liveLocationAddress.value = LocationService.formatCoordinates(pos.latitude, pos.longitude);
        if (activeMeetingId != null && activeMeetingId!.isNotEmpty) {
          await meetingRepo.updateMeetingLocation(
            meetingId: activeMeetingId!,
            latitude: pos.latitude,
            longitude: pos.longitude,
            locationAddress: liveLocationAddress.value,
          );
        }
      }
    } catch (_) {}
  }

  // ─── Start Govia (Create & Join Native LiveKit Session) ───────────────
  Future<void> startGoviaMeeting() async {
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
      errorMessage.value =
          'Camera and microphone permissions are required for Govia sessions.';
      return;
    }

    // 2. Query device GPS location for live location sharing
    Position? pos;
    try {
      pos = await LocationService.getCurrentLocation(timeout: const Duration(seconds: 3));
      if (pos != null) {
        liveLatitude.value = pos.latitude;
        liveLongitude.value = pos.longitude;
        liveLocationAddress.value = LocationService.formatCoordinates(pos.latitude, pos.longitude);
      }
    } catch (_) {}

    // 3. Call API to create session & retrieve room name & token
    final meeting = await meetingRepo.startGovia(
      topic: 'Govia Consultation',
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      locationAddress: liveLocationAddress.value.isNotEmpty ? liveLocationAddress.value : null,
    );

    if (meeting == null || meeting.id.isEmpty) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value =
          'Failed to create session. Please check your connection and try again.';
      return;
    }

    // ── Mark this device as the call HOST immediately after creation ──
    isHost.value = true;

    currentMeeting.value = meeting;
    activeMeetingId = meeting.id;

    if (liveLatitude.value == null) {
      _syncHostLocationInBackground();
    }

    // 3. Obtain LiveKit Token & URL
    String livekitUrl = dotenv.env['LIVEKIT_URL'] ?? 'wss://govia-0f13ke90.livekit.cloud';
    if (meeting.livekitUrl != null &&
        meeting.livekitUrl!.isNotEmpty &&
        !meeting.livekitUrl!.contains('govia.com')) {
      livekitUrl = meeting.livekitUrl!;
    }

    String? token = meeting.token;
    if (token == null || token.isEmpty) {
      final tokenData = await meetingRepo.getMeetingToken(meeting.id);
      if (tokenData != null) {
        token = tokenData['token']?.toString() ??
            tokenData['livekitToken']?.toString();
      }
    }

    // If server token is missing or server is running older keys, generate token with project keys
    final apiKey = dotenv.env['LIVEKIT_API_KEY'] ?? 'API6NLt8C36WoQ8';
    final apiSecret = dotenv.env['LIVEKIT_API_SECRET'] ?? 'hhc2Hz8oTvHN6flpBOGWTxDBU2h9hOWHwRXUSh49DuY';
    if (token == null || token.isEmpty) {
      String userName = 'Citizen User';
      String userId = meeting.id;
      if (Get.isRegistered<AuthService>()) {
        final auth = Get.find<AuthService>();
        userName = auth.currentUser.value?.name ?? 'Citizen User';
        userId = auth.currentUser.value?.id ?? meeting.id;
      }
      token = _generateLiveKitToken(
        apiKey: apiKey,
        apiSecret: apiSecret,
        roomName: meeting.roomName,
        identity: userId,
        name: userName,
      );
    }

    // 4. Connect to LiveKit Room
    try {
      await _connectLiveKit(livekitUrl, token);
    } catch (e) {
      debugPrint('⚠️ Error joining LiveKit session: $e');
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Failed to join video session: $e';
      return;
    }

    isLoading.value = false;
    _startTimer();

    // Auto-start cloud Egress recording. Only the host triggers this so
    // there is exactly one Egress per room (prevents duplicate recordings).
    if (isHost.value) {
      debugPrint('⏺ Host starting recording for meeting: ${meeting.id}');
      _startRecording();
    }
  }

  Future<void> _connectLiveKit(String url, String token) async {
    // Clean up previous room if any
    await _cleanupRoom();

    // Store last connection params for auto-reconnect
    _lastLivekitUrl = url;
    _lastLivekitToken = token;

    final room = Room(
      roomOptions: const RoomOptions(
        // ── Low-Latency Configuration ─────────────────────────────────────
        // Disabled adaptiveStream & dynacast: in a 2-person call these features
        // require simulcast layers that we don't publish. Leaving them on with
        // simulcast=false causes the receiver-side adaptive logic to pause/resume
        // the single track, which builds a growing jitter buffer (visible lag).
        adaptiveStream: false,
        dynacast: false,
        // ─────────────────────────────────────────────────────────────────
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

    // Cancel 5-min leave timer if host is re-entering
    final mId = currentMeeting.value?.id ?? activeMeetingId;
    if (isHost.value && mId != null && mId.isNotEmpty) {
      meetingRepo.rejoinMeeting(mId);
    }

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
        debugPrint('🔴 LiveKit RoomDisconnected: ${event.reason}');
        isSessionJoined.value = false;
        localVideoTrack.value = null;
        remoteVideoTrack.value = null;

        // Auto-reconnect on unexpected network drops (EOF / signal close)
        // Hosts and guests can both benefit from this.
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
          debugPrint('🔄 Citizen auto-reconnect in ${delaySeconds}s (attempt $_reconnectAttempts/3)...');
          Future.delayed(Duration(seconds: delaySeconds), () async {
            if (_lastLivekitUrl == null) {
              _isReconnecting = false;
              return;
            }
            try {
              await _connectLiveKit(_lastLivekitUrl!, _lastLivekitToken!);
              debugPrint('✅ Citizen LiveKit reconnected successfully');
            } catch (e) {
              debugPrint('⚠️ Citizen reconnect attempt $_reconnectAttempts failed: $e');
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
      // ── Host broadcast: "meeting_ended" & "lock_state" ──
      ..on<DataReceivedEvent>((event) {
        try {
          final msg = utf8.decode(event.data);
          if (msg == 'meeting_ended') {
            debugPrint('🔔 Host ended meeting — navigating all guests home');
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
    // Update local video track
    final localPub = room.localParticipant?.videoTrackPublications.firstOrNull;
    if (localPub?.track is VideoTrack) {
      localVideoTrack.value = localPub!.track as VideoTrack;
    } else {
      localVideoTrack.value = null;
    }

    // Update remote video track
    VideoTrack? foundRemoteTrack;
    String responderName = '';

    for (final participant in room.remoteParticipants.values) {
      for (final pub in participant.videoTrackPublications) {
        if (pub.track is VideoTrack) {
          foundRemoteTrack = pub.track as VideoTrack;
          responderName = participant.name.isNotEmpty
              ? participant.name
              : (participant.identity.isNotEmpty ? participant.identity : 'Responder');
          break;
        }
      }
      if (foundRemoteTrack != null) break;
    }

    remoteVideoTrack.value = foundRemoteTrack;
    remoteParticipantName.value = responderName;
  }

  // ─── Hardware & Call Controls ────────────────────────────────────────
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
    try {
      final track = _room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
      if (track is LocalVideoTrack) {
        final nextPos = _cameraPosition == CameraPosition.front
            ? CameraPosition.back
            : CameraPosition.front;
        await track.setCameraPosition(nextPos);
        _cameraPosition = nextPos;
      }
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  Future<void> toggleSpeaker() async {
    isSpeakerOn.toggle();
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(isSpeakerOn.value);
    } catch (e) {
      debugPrint('Error toggling speakerphone: $e');
    }
  }

  // ─── Recording ───────────────────────────────────────────────────────
  void _startRecording() {
    isRecording.value = true;
    final mId = currentMeeting.value?.id;
    debugPrint('⏺ Starting cloud Egress recording for meeting: $mId');
    if (mId != null && mId.isNotEmpty) {
      meetingRepo.startRecording(mId).then((ok) {
        debugPrint(ok ? '✅ Egress recording started on LiveKit Cloud' : '⚠️ Egress start returned false — S3 credentials may be missing');
      }).catchError((e) {
        debugPrint('⚠️ Backend recording start failed (continuing anyway): $e');
      });
    }
  }

  // ─── Host ends for everyone ──────────────────────────────────────────
  Future<void> _broadcastMeetingEnded() async {
    try {
      await _room?.localParticipant?.publishData(
        utf8.encode('meeting_ended'),
        reliable: true,
      );
      // Short delay to ensure data reaches all remote participants before disconnect
      await Future.delayed(const Duration(milliseconds: 600));
    } catch (e) {
      debugPrint('⚠️ Error broadcasting meeting_ended: $e');
    }
  }

  void _onHostEndedMeeting() {
    _timer?.cancel();
    _cleanupRoom();
    currentMeeting.value = null;
    callSeconds.value = 0;
    isSessionJoined.value = false;
    Get.offAllNamed(AppRoutes.citizenDashboard);
    Helpers.showError('The host has ended the session.', title: 'Meeting Ended');
  }

  // ─── In-Meeting QR Join Payload ───────────────────────────────────────
  /// Returns a JSON string that encodes this meeting's join info for the QR code.
  Future<String?> getMeetingJoinQrPayload() async {
    final meeting = currentMeeting.value;
    if (meeting == null) return null;

    // Fetch a fresh guest token so anyone scanning can join
    String? guestToken;
    try {
      final tokenData = await meetingRepo.getMeetingToken(meeting.id);
      guestToken = tokenData?['token']?.toString() ?? tokenData?['livekitToken']?.toString();
    } catch (_) {}

    // Fall back to the host token if no separate guest token available
    guestToken ??= meeting.token;

    return jsonEncode({
      'type': 'meeting_join',
      'meetingId': meeting.id,
      'roomName': meeting.roomName,
      'topic': meeting.topic,
      'token': guestToken ?? '',
      'livekitUrl': meeting.livekitUrl ?? '',
      'category': meeting.category,
      'meetingType': meeting.meetingType,
    });
  }

  /// Parses a meeting QR payload and joins the encoded meeting room.
  Future<void> joinFromQrPayload(String jsonPayload) async {
    try {
      final map = jsonDecode(jsonPayload) as Map<String, dynamic>;
      if (map['type'] != 'meeting_join') return;
      await joinIncomingOrExistingMeeting(map);
    } catch (e) {
      Helpers.showError('Invalid meeting QR code.', title: 'Error');
    }
  }

  // ─── End Meeting ─────────────────────────────────────────────────────
  Future<void> endMeeting() async {
    _timer?.cancel();

    final idToEnd = currentMeeting.value?.id.isNotEmpty == true
        ? currentMeeting.value!.id
        : (activeMeetingId ?? '');

    // Step 1: Stop the Egress recording so LiveKit flushes the MP4 to S3.
    // Do this BEFORE disconnecting so LiveKit knows the room is still valid.
    if (isHost.value && isRecording.value && idToEnd.isNotEmpty) {
      try {
        await meetingRepo.stopRecording(idToEnd);
        debugPrint('⏹ Egress recording stop requested for: $idToEnd');
      } catch (e) {
        debugPrint('⚠️ stopRecording error (non-fatal): $e');
      }
      // Short wait so LiveKit processes the stop before we disconnect
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // Step 2: If host — broadcast 'meeting_ended' to all guests
    if (isHost.value) {
      await _broadcastMeetingEnded();
    }

    // Step 3: Leave LiveKit room
    await _cleanupRoom();

    // Step 4: Notify backend to mark COMPLETED & trigger S3 URL attachment
    if (idToEnd.isNotEmpty) {
      try {
        final ok = await meetingRepo.endMeeting(idToEnd);
        debugPrint('🏁 Backend endMeeting response: $ok for id: $idToEnd');
      } catch (e) {
        debugPrint('⚠️ Error calling endMeeting on backend: $e');
      }
    }

    currentMeeting.value = null;
    activeMeetingId = null;
    callSeconds.value = 0;
    isSessionJoined.value = false;
    localVideoTrack.value = null;
    remoteVideoTrack.value = null;
    isRecording.value = false;
    isHost.value = false;

    Get.offAllNamed(AppRoutes.citizenDashboard);
    Get.delete<LiveCallController>(force: true);
    Helpers.showSuccess('Meeting ended. Recording will be available in Evidence Vault.');
  }

  /// Guest participant leaving session, or host leaving temporarily (initiating 5-minute auto-end timer)
  Future<void> leaveMeeting() async {
    _timer?.cancel();
    final mId = currentMeeting.value?.id.isNotEmpty == true
        ? currentMeeting.value!.id
        : (activeMeetingId ?? '');

    if (mId.isNotEmpty) {
      try {
        await meetingRepo.leaveMeeting(mId);
      } catch (_) {}
    }

    await _cleanupRoom();

    final wasHost = isHost.value;
    currentMeeting.value = null;
    activeMeetingId = null;
    callSeconds.value = 0;
    isSessionJoined.value = false;
    localVideoTrack.value = null;
    remoteVideoTrack.value = null;
    isRecording.value = false;
    isHost.value = false;

    Get.offAllNamed(AppRoutes.citizenDashboard);
    Get.delete<LiveCallController>(force: true);
    Helpers.showSuccess(
      wasHost
          ? 'You left the meeting. It will automatically end in 5 minutes unless you rejoin.'
          : 'Left the meeting session.',
    );
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

  void retry() => startGoviaMeeting();

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockService.disable();
    CallBackgroundService.stop();
    _timer?.cancel();
    _retryPoller?.cancel();
    _retryPoller = null;
    final mId = currentMeeting.value?.id.isNotEmpty == true
        ? currentMeeting.value!.id
        : (activeMeetingId ?? '');
    if (mId.isNotEmpty && isHost.value) {
      meetingRepo.leaveMeeting(mId);
    }
    _cleanupRoom();
    super.onClose();
  }

  // ─── Lifecycle Handling (Phone Lock / Unlock) ────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('📱 [LiveCallController] App lifecycle changed: $state');

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
