import 'package:dio/dio.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/data/models/meeting_model.dart';

class MeetingRepository {
  final ApiClient apiClient;

  MeetingRepository({required this.apiClient});

  /// POST /meetings/start-govia
  /// Creates an instant Zoom meeting with cloud auto-recording.
  /// Returns the meeting data including zoomMeetingId and password
  /// needed to construct the web client URL.
  Future<MeetingModel?> startGovia({
    String? topic,
    double? latitude,
    double? longitude,
    String? locationAddress,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (topic != null && topic.isNotEmpty) {
        body['topic'] = topic;
      }
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (locationAddress != null) body['locationAddress'] = locationAddress;
      final response = await apiClient.postData(
        ApiConstants.startGovia,
        body,
      );

      final responseData = response.data;
      if (responseData == null) return null;

      // Response shape: { success: true, data: { _id, zoomMeetingId, ... } }
      final data = responseData['data'] ?? responseData;
      if (data == null) return null;

      return MeetingModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString();
      if (msg != null && msg.isNotEmpty) {
        throw Exception(msg);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH /meetings/:id/end
  /// Marks the meeting as completed and triggers recording sync.
  Future<bool> endMeeting(String meetingId) async {
    try {
      final response = await apiClient.patchData(
        ApiConstants.endMeeting(meetingId),
        {},
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      return false;
    }
  }

  /// POST /meetings/:id/leave
  /// Host leaving triggers 5 min timer; participant leaving exits session without ending for host.
  Future<bool> leaveMeeting(String meetingId) async {
    try {
      final response = await apiClient.postData(
        ApiConstants.leaveMeeting(meetingId),
        {},
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      return false;
    }
  }

  /// POST /meetings/:id/rejoin
  /// Host rejoins within 5 min window (cancels auto-end timer).
  Future<bool> rejoinMeeting(String meetingId) async {
    try {
      final response = await apiClient.postData(
        ApiConstants.rejoinMeeting(meetingId),
        {},
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      return false;
    }
  }

  /// GET /meetings/:id/token
  /// Fetches a fresh LiveKit room token for a meeting session.
  Future<Map<String, dynamic>?> getMeetingToken(String meetingId) async {
    try {
      final response = await apiClient.getData(ApiConstants.meetingToken(meetingId));
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Backward-compatible alias for getMeetingToken
  Future<Map<String, dynamic>?> getMeetingSdkToken(String meetingId) =>
      getMeetingToken(meetingId);

  /// GET /meetings/active
  /// Retrieves list of active meetings for Attorneys / Responders.
  Future<List<MeetingModel>> getActiveMeetings() async {
    try {
      final response = await apiClient.getData(ApiConstants.activeMeetings);
      final responseData = response.data;
      if (responseData == null) return [];

      final rawList = responseData['data'] ?? responseData;
      if (rawList is List) {
        return rawList
            .map((item) => MeetingModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// POST /meetings/:id/join
  /// Attorney joins an active meeting session and gets LiveKit credentials.
  Future<MeetingModel?> joinMeeting(String meetingId) async {
    try {
      final response = await apiClient.postData(
        ApiConstants.joinMeeting(meetingId),
        {},
      );
      final responseData = response.data;
      if (responseData == null) return null;

      final data = responseData['data'] ?? responseData;
      if (data is Map<String, dynamic>) {
        return MeetingModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// POST /meetings/:id/recording/start
  /// Best-effort recording start — non-blocking, failure is tolerated.
  Future<bool> startRecording(String meetingId) async {
    try {
      final response = await apiClient.postData(
        ApiConstants.startRecording(meetingId),
        {},
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      return false;
    }
  }

  /// POST /meetings/:id/recording/stop
  Future<bool> stopRecording(String meetingId) async {
    try {
      final response = await apiClient.postData(
        ApiConstants.stopRecording(meetingId),
        {},
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      return false;
    }
  }

  /// POST /meetings/:id/attach-recording
  Future<bool> attachRecording(String meetingId, String recordingUrl) async {
    try {
      final response = await apiClient.postData(
        ApiConstants.attachRecording(meetingId),
        {'recordingUrl': recordingUrl},
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      return false;
    }
  }

  /// POST /meetings/emergency-call
  /// Triggers emergency incident dispatch & notifies/rings preferred providers.
  Future<MeetingModel?> startEmergencyCall({
    String? topic,
    String? preferredAttorney,
    String? preferredBailBondsman,
    double? latitude,
    double? longitude,
    String? locationAddress,
  }) async {
    try {
      final body = <String, dynamic>{
        'topic': topic ?? 'Emergency Incident Stop',
      };
      if (preferredAttorney != null && preferredAttorney.isNotEmpty) {
        body['preferredAttorney'] = preferredAttorney;
      }
      if (preferredBailBondsman != null && preferredBailBondsman.isNotEmpty) {
        body['preferredBailBondsman'] = preferredBailBondsman;
      }
      if (latitude != null) {
        body['latitude'] = latitude;
      }
      if (longitude != null) {
        body['longitude'] = longitude;
      }
      if (locationAddress != null && locationAddress.isNotEmpty) {
        body['locationAddress'] = locationAddress;
      }
      final response = await apiClient.postData(
        ApiConstants.emergencyCall,
        body,
      );
      final responseData = response.data;
      if (responseData == null) return null;
      final data = responseData['data'] ?? responseData;
      if (data is Map<String, dynamic>) {
        return MeetingModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// PATCH /meetings/:id
  /// Updates live GPS coordinates on an active meeting.
  Future<bool> updateMeetingLocation({
    required String meetingId,
    required double latitude,
    required double longitude,
    String? locationAddress,
  }) async {
    try {
      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'locationAddress': ?locationAddress,
      };
      final response = await apiClient.patchData(
        '${ApiConstants.meetings}/$meetingId',
        body,
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }
}
