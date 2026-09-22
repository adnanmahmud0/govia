import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // ─── Base URL ─────────────────────────────────────────────────────────────
  // Read from .env file → API_BASE_URL key.
  // Fallback to https://adnan5000.binarybards.online/api/v1
  static String get baseUrl {
    final raw = dotenv.env['API_BASE_URL'] ??
        'https://adnan5000.binarybards.online/api/v1';
    final trimmed = raw.trim();
    final noTrailingSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    if (!noTrailingSlash.endsWith('/api/v1')) {
      return '$noTrailingSlash/api/v1';
    }
    return noTrailingSlash;
  }

  // Server Origin (root host without /api/v1) for static files and uploads
  static String get serverOrigin {
    final uri = Uri.tryParse(baseUrl);
    if (uri != null) {
      return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    }
    return 'https://adnan5000.binarybards.online';
  }

  // Full URL for an attachment or upload path
  static String getFileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '$serverOrigin/$clean';
  }

  // ─── Auth Endpoints ───────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forget-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerifyEmail = '/auth/resend-verify-email';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // ─── User Endpoints ───────────────────────────────────────────────────────
  static const String signup = '/user/register';
  static const String profile = '/user/profile';
  static String userLookup(String identifier) => '/user/lookup/${Uri.encodeComponent(identifier)}';

  // ─── Meeting Endpoints ────────────────────────────────────────────────────
  static const String meetings = '/meetings';
  static const String startGovia = '/meetings/start-govia';
  static const String emergencyCall = '/meetings/emergency-call';
  static const String scheduleMeeting = '/meetings/schedule';
  static const String myMeetings = '/meetings/my-meetings';
  static const String activeMeetings = '/meetings/active';
  static String meetingDetails(String id) => '/meetings/$id';
  static String joinMeeting(String id) => '/meetings/$id/join';
  static String endMeeting(String id) => '/meetings/$id/end';
  static String leaveMeeting(String id) => '/meetings/$id/leave';
  static String rejoinMeeting(String id) => '/meetings/$id/rejoin';
  static String cancelMeeting(String id) => '/meetings/$id/cancel';
  static String meetingToken(String id) => '/meetings/$id/token';
  static String meetingSdkToken(String id) => '/meetings/$id/sdk-token';
  static String startRecording(String id) => '/meetings/$id/recording/start';
  static String stopRecording(String id) => '/meetings/$id/recording/stop';
  static String uploadRecording(String id) => '/meetings/$id/recording-upload';
  static String attachRecording(String id) => '/meetings/$id/attach-recording';

  // ─── AI Assistant Endpoints ───────────────────────────────────────────────
  static const String aiAssistant = '/aiAssistant';
  static const String aiChats = '/aiAssistant/chats';
  static String aiChatHistory(String id) => '/aiAssistant/chats/$id';
  static String deleteAiChat(String id) => '/aiAssistant/chats/$id';

  // ─── Direct Messaging Endpoints ───────────────────────────────────────────
  static const String conversations = '/conversation';
  static String conversationDetails(String id) => '/conversation/$id';
  static String deleteConversation(String id) => '/conversation/$id';
  static const String messages = '/message';
  static String messagesByConversation(String conversationId) => '/message/$conversationId';
  static String markMessagesAsRead(String conversationId) => '/message/read/$conversationId';
  static String editMessage(String messageId) => '/message/$messageId';
  static String deleteMessage(String messageId) => '/message/$messageId';
  static const String createMeetingInChat = '/message/meeting';
  static const String openChat = '/message/open-chat';

  // ─── Evidence Vault Endpoints ─────────────────────────────────────────────
  static const String vaultFolders = '/vault/folders';
  static String vaultFolderDetails(String id) => '/vault/folders/$id';
  static String vaultFolder(String id) => vaultFolderDetails(id);
  static String vaultFolderShare(String id) => '/vault/folders/$id/share';
  static const String vaultSharedWithMe = '/vault/folders/shared-with-me';
  static const String vaultRecordings = '/vault/recordings';
  static const String vaultUpload = '/vault/items/upload';
  static const String vaultLinkMeeting = '/vault/items/link-meeting';
  static String vaultItem(String id) => '/vault/items/$id';

  // ─── Community Resource Endpoints ─────────────────────────────────────────
  static const String communityResources = '/communityResource';
  static String communityResourceDetails(String id) =>
      '/communityResource/$id';
}


