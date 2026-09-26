import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/core/widgets/govia_video_player_view.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';

class ChatController extends GetxController {
  ApiClient get _apiClient => Get.find<ApiClient>();
  AuthService get _authService => Get.find<AuthService>();

  Timer? _messagePollingTimer;
  Timer? _inboxPollingTimer;

  // ──────────────────────── CONVERSATION INBOX STATE ────────────────────────
  final RxList<Map<String, dynamic>> conversations = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingConversations = false.obs;
  final RxString searchQuery = ''.obs;

  // ──────────────────────── ACTIVE CHAT ROOM STATE ───────────────────────────
  final RxString activeConversationId = ''.obs;
  final Rxn<Map<String, dynamic>> activeChatPartner = Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> chatMessages = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSendingMessage = false.obs;

  // Download & Attachment State
  final RxSet<String> downloadingUrls = <String>{}.obs;
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;

  // Controllers
  late TextEditingController messageController;
  late ScrollController scrollController;
  late TextEditingController searchInputController;

  // Editing Message state (WhatsApp style)
  final Rxn<Map<String, dynamic>> editingMessage = Rxn<Map<String, dynamic>>();

  // User Lookup & QR Code State
  final RxBool isSearchingUser = false.obs;
  final Rxn<Map<String, dynamic>> foundUserProfile = Rxn<Map<String, dynamic>>();
  late TextEditingController idInputController;

  // Current authenticated user getters
  String get currentUserId {
    final user = _authService.currentUser.value;
    return user?.id ?? '';
  }

  String get currentUserRole {
    return _authService.currentUser.value?.role?.toUpperCase() ?? 'CITIZEN';
  }

  /// Whether the chat partner is a Mental Health Professional / Doctor
  bool get isPartnerMentalHealthProfessional {
    final partner = activeChatPartner.value;
    if (partner == null) return false;
    final role = (partner['role']?.toString() ?? '').toUpperCase();
    final subRole = (partner['subRole']?.toString() ?? '').toLowerCase();
    final specialty = (partner['specialty']?.toString() ?? '').toLowerCase();
    return role == 'MENTAL_HEALTH_PROFESSIONAL' ||
        role == 'DOCTOR' ||
        subRole.contains('therapist') ||
        subRole.contains('psych') ||
        subRole.contains('counselor') ||
        specialty.contains('mental') ||
        specialty.contains('trauma') ||
        specialty.contains('psych');
  }

  /// Whether current user is a Mental Health Professional / Doctor
  bool get isCurrentUserDoctor {
    final role = currentUserRole.toUpperCase();
    return role == 'MENTAL_HEALTH_PROFESSIONAL' || role == 'DOCTOR';
  }

  /// Whether current user is a Citizen or standard user
  bool get isCurrentUserCitizen {
    final role = currentUserRole.toUpperCase();
    return role == 'CITIZEN' || role == 'USER';
  }

  /// In chats involving a Mental Health Professional (Doctor) and Citizen:
  /// The Citizen CANNOT schedule. ONLY the Doctor can schedule.
  bool get canScheduleInChat {
    if (isPartnerMentalHealthProfessional && isCurrentUserCitizen) {
      return false;
    }
    return true;
  }

  @override
  void onInit() {
    super.onInit();
    messageController = TextEditingController();
    scrollController = ScrollController();
    searchInputController = TextEditingController();
    idInputController = TextEditingController();

    fetchConversations();
    startInboxPolling();
  }

  @override
  void onClose() {
    stopInboxPolling();
    stopMessagePolling();
    messageController.dispose();
    scrollController.dispose();
    searchInputController.dispose();
    idInputController.dispose();
    super.onClose();
  }

  // ──────────────────────── CONVERSATION LIST METHODS ────────────────────────

  void startInboxPolling() {
    _inboxPollingTimer?.cancel();
    _inboxPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollConversationsSilently();
    });
  }

  void stopInboxPolling() {
    _inboxPollingTimer?.cancel();
    _inboxPollingTimer = null;
  }

  Future<void> _pollConversationsSilently() async {
    try {
      final response = await _apiClient.getData(ApiConstants.conversations);
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'];
        List items = [];
        if (rawData is List) {
          items = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          items = rawData['data'] as List;
        }
        final incoming = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (incoming.isNotEmpty) {
          conversations.assignAll(incoming);
        }
      }
    } catch (_) {}
  }

  Future<void> fetchConversations() async {
    try {
      isLoadingConversations.value = true;
      final response = await _apiClient.getData(ApiConstants.conversations);

      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'];
        if (rawData is List) {
          conversations.assignAll(
            rawData.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          );
        } else if (rawData is Map && rawData['data'] is List) {
          conversations.assignAll(
            (rawData['data'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
          );
        }
      }
    } catch (_) {
    } finally {
      isLoadingConversations.value = false;
    }
  }

  List<Map<String, dynamic>> get filteredConversations {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return conversations;

    return conversations.where((conv) {
      final partner = getOtherParticipant(conv);
      final name = partner['name']?.toString().toLowerCase() ?? '';
      final role = partner['role']?.toString().toLowerCase() ?? '';
      final lastMsg = conv['lastMessageText']?.toString().toLowerCase() ?? '';
      return name.contains(q) || role.contains(q) || lastMsg.contains(q);
    }).toList();
  }

  Map<String, dynamic> getOtherParticipant(Map<String, dynamic> conv) {
    final participants = conv['participants'];
    if (participants is List && participants.isNotEmpty) {
      for (final p in participants) {
        if (p is Map) {
          final id = p['_id']?.toString() ?? p['id']?.toString() ?? '';
          if (id != currentUserId) {
            return Map<String, dynamic>.from(p);
          }
        }
      }
      return Map<String, dynamic>.from(participants.first as Map);
    }
    return {};
  }

  Future<void> deleteFullConversation(String conversationId) async {
    try {
      HapticFeedback.mediumImpact();
      final response = await _apiClient.deleteData(ApiConstants.deleteConversation(conversationId));

      if (response.statusCode == 200) {
        conversations.removeWhere((c) => (c['_id']?.toString() ?? '') == conversationId);
        Helpers.showCustomSnackBar('Conversation deleted successfully', type: SnackBarType.success);

        if (activeConversationId.value == conversationId) {
          Get.back();
        }
      } else {
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? 'Failed to delete conversation',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      Helpers.showCustomSnackBar('Error deleting conversation', type: SnackBarType.error);
    }
  }

  // ──────────────────────── USER LOOKUP & START NEW CHAT ──────────────────────

  Future<Map<String, dynamic>?> lookupUserByIdOrQr(String rawInput) async {
    final input = rawInput.trim();
    if (input.isEmpty) {
      Helpers.showCustomSnackBar('Please enter a valid User ID or scan a QR code', type: SnackBarType.warning);
      return null;
    }

    try {
      isSearchingUser.value = true;
      foundUserProfile.value = null;

      final response = await _apiClient.getData(ApiConstants.userLookup(input));

      if (response.statusCode == 200 && response.data?['data'] != null) {
        final userData = Map<String, dynamic>.from(response.data['data'] as Map);
        foundUserProfile.value = userData;
        return userData;
      } else {
        Helpers.showError(
          response.data?['message'] ?? 'No user found with the provided ID or QR',
        );
        return null;
      }
    } catch (_) {
      Helpers.showError('User lookup failed. Check ID format.');
      return null;
    } finally {
      isSearchingUser.value = false;
    }
  }

  Future<void> openOrCreateChatWithUser(Map<String, dynamic> targetUser) async {
    final targetId = targetUser['_id']?.toString() ?? targetUser['id']?.toString() ?? '';
    if (targetId.isEmpty) return;

    if (targetId == currentUserId) {
      Helpers.showError('You cannot message your own profile');
      return;
    }

    try {
      isSearchingUser.value = true;
      final response = await _apiClient.postData(
        ApiConstants.conversations,
        {'participantId': targetId},
      );

      if (response.statusCode == 200 && response.data?['data'] != null) {
        final conv = Map<String, dynamic>.from(response.data['data'] as Map);
        final convId = conv['_id']?.toString() ?? '';

        activeConversationId.value = convId;
        activeChatPartner.value = targetUser;

        // Refresh conversation list in background
        fetchConversations();

        // Navigate to Chat Details & start live polling
        await fetchMessages(convId);
        startMessagePolling();
        Get.toNamed(AppRoutes.attorneyChatDetails);
      } else {
        Helpers.showError(response.data?['message'] ?? 'Failed to open conversation');
      }
    } catch (_) {
      Helpers.showError('Failed to start conversation');
    } finally {
      isSearchingUser.value = false;
    }
  }

  void openExistingConversation(Map<String, dynamic> conversation) {
    final convId = conversation['_id']?.toString() ?? '';
    if (convId.isEmpty) return;

    activeConversationId.value = convId;
    activeChatPartner.value = getOtherParticipant(conversation);

    fetchMessages(convId);
    startMessagePolling();
    Get.toNamed(AppRoutes.attorneyChatDetails);
  }

  // ──────────────────────── CHAT DETAILS & MESSAGING ──────────────────────────

  void startMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (activeConversationId.value.isNotEmpty) {
        _pollMessagesSilently(activeConversationId.value);
      }
    });
  }

  void stopMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = null;
  }

  Future<void> _pollMessagesSilently(String convId) async {
    if (convId.isEmpty) return;
    try {
      final response = await _apiClient.getData(ApiConstants.messagesByConversation(convId));
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'];
        List items = [];
        if (rawData is List) {
          items = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          items = rawData['data'] as List;
        }

        final incomingList = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        // Check if there are changes compared to current messages
        bool hasChanges = incomingList.length != chatMessages.length;
        if (!hasChanges && incomingList.isNotEmpty && chatMessages.isNotEmpty) {
          final lastIncoming = incomingList.last;
          final lastCurrent = chatMessages.last;
          if (lastIncoming['_id'] != lastCurrent['_id'] ||
              lastIncoming['text'] != lastCurrent['text'] ||
              lastIncoming['isDeleted'] != lastCurrent['isDeleted'] ||
              lastIncoming['isEdited'] != lastCurrent['isEdited']) {
            hasChanges = true;
          }
        }

        if (hasChanges) {
          chatMessages.assignAll(incomingList);
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  Future<void> fetchMessages(String convId) async {
    if (convId.isEmpty) return;
    try {
      isLoadingMessages.value = true;
      final response = await _apiClient.getData(ApiConstants.messagesByConversation(convId));

      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'];
        List items = [];
        if (rawData is List) {
          items = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          items = rawData['data'] as List;
        }

        chatMessages.assignAll(
          items.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );

        // Mark messages read
        _apiClient.patchData(ApiConstants.markMessagesAsRead(convId), {});

        _scrollToBottom();
      }
    } catch (_) {
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty && editingMessage.value == null) return;

    // If currently editing, submit edit instead
    if (editingMessage.value != null) {
      await submitEditedMessage();
      return;
    }

    if (activeConversationId.value.isEmpty) return;

    // 🚀 Instant Optimistic UI: display immediately
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = _authService.currentUser.value;
    final optimisticMsg = <String, dynamic>{
      '_id': tempId,
      'conversationId': activeConversationId.value,
      'sender': {
        '_id': currentUserId,
        'name': currentUser?.name ?? 'Me',
        'role': currentUserRole,
        'image': currentUser?.image,
      },
      'receiver': activeChatPartner.value,
      'text': text,
      'messageType': 'text',
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
      'isOptimistic': true,
      'status': 'sending',
    };

    messageController.clear();
    chatMessages.add(optimisticMsg);
    _scrollToBottom();
    HapticFeedback.lightImpact();

    try {
      isSendingMessage.value = true;
      final response = await _apiClient.postData(
        ApiConstants.messages,
        {
          'conversationId': activeConversationId.value,
          'text': text,
          'messageType': 'text',
        },
      );

      if (response.statusCode == 201 && response.data?['data'] != null) {
        final newMsg = Map<String, dynamic>.from(response.data['data'] as Map);
        final idx = chatMessages.indexWhere((m) => m['_id'] == tempId);
        if (idx != -1) {
          chatMessages[idx] = newMsg;
          chatMessages.refresh();
        } else {
          chatMessages.add(newMsg);
        }
        _scrollToBottom();
        fetchConversations();
      } else {
        final idx = chatMessages.indexWhere((m) => m['_id'] == tempId);
        if (idx != -1) chatMessages.removeAt(idx);
        Helpers.showError(response.data?['message'] ?? 'Failed to send message');
      }
    } catch (_) {
      final idx = chatMessages.indexWhere((m) => m['_id'] == tempId);
      if (idx != -1) chatMessages.removeAt(idx);
      Helpers.showError('Failed to send message');
    } finally {
      isSendingMessage.value = false;
    }
  }

  // ──────────────────────── FILE & IMAGE ATTACHMENT ──────────────────────────

  Future<void> pickAndSendImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      await _uploadAttachment(file, 'image');
    } catch (e) {
      Helpers.showError('Could not select photo: $e');
    }
  }

  Future<void> pickAndSendDocument() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isEmpty || files.first.path == null) {
        return;
      }

      final file = File(files.first.path!);
      await _uploadAttachment(file, 'file');
    } catch (e) {
      Helpers.showError('Could not select file: $e');
    }
  }

  Future<void> _uploadAttachment(File file, String messageType) async {
    if (activeConversationId.value.isEmpty) return;

    final tempId = 'temp_file_${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = _authService.currentUser.value;
    final fileName = file.path.split(Platform.pathSeparator).last;
    final optimisticMsg = <String, dynamic>{
      '_id': tempId,
      'conversationId': activeConversationId.value,
      'sender': {
        '_id': currentUserId,
        'name': currentUser?.name ?? 'Me',
        'role': currentUserRole,
        'image': currentUser?.image,
      },
      'receiver': activeChatPartner.value,
      'text': messageType == 'image' ? '📷 Photo' : '📎 Document: $fileName',
      'attachment': file.path,
      'messageType': messageType,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
      'isOptimistic': true,
      'status': 'uploading',
    };

    chatMessages.add(optimisticMsg);
    _scrollToBottom();

    try {
      isSendingMessage.value = true;
      HapticFeedback.lightImpact();

      final payloadJson = jsonEncode({
        'conversationId': activeConversationId.value,
        'messageType': messageType,
      });

      final fieldName = messageType == 'image' ? 'image' : 'doc';

      final response = await _apiClient.postMultipartData(
        ApiConstants.messages,
        {'data': payloadJson},
        multipartBody: [MultipartBody(fieldName, file)],
      );

      if (response.statusCode == 201 && response.data?['data'] != null) {
        final newMsg = Map<String, dynamic>.from(response.data['data'] as Map);
        final idx = chatMessages.indexWhere((m) => m['_id'] == tempId);
        if (idx != -1) {
          chatMessages[idx] = newMsg;
          chatMessages.refresh();
        } else {
          chatMessages.add(newMsg);
        }
        _scrollToBottom();
        fetchConversations();
      } else {
        final idx = chatMessages.indexWhere((m) => m['_id'] == tempId);
        if (idx != -1) chatMessages.removeAt(idx);
        Helpers.showError(response.data?['message'] ?? 'Failed to upload attachment');
      }
    } catch (_) {
      final idx = chatMessages.indexWhere((m) => m['_id'] == tempId);
      if (idx != -1) chatMessages.removeAt(idx);
      Helpers.showError('Attachment upload failed');
    } finally {
      isSendingMessage.value = false;
    }
  }

  // ──────────────────────── DOWNLOAD ATTACHMENT (Image / Document) ────────────

  Future<void> downloadAttachment({
    required String attachmentPath,
    String? customFileName,
    bool isImage = false,
  }) async {
    if (attachmentPath.isEmpty) return;

    final fullUrl = ApiConstants.getFileUrl(attachmentPath);
    if (downloadingUrls.contains(fullUrl)) {
      Helpers.showCustomSnackBar('Download is already in progress...', type: SnackBarType.info);
      return;
    }

    downloadingUrls.add(fullUrl);
    downloadProgress[fullUrl] = 0.0;
    HapticFeedback.lightImpact();

    String fileName = customFileName ??
        attachmentPath.split('/').last.split(Platform.pathSeparator).last;
    if (fileName.isEmpty || fileName.length < 3) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      fileName = isImage ? 'govia_img_$timestamp.jpg' : 'govia_file_$timestamp';
    }

    if (isImage &&
        !fileName.toLowerCase().endsWith('.jpg') &&
        !fileName.toLowerCase().endsWith('.png') &&
        !fileName.toLowerCase().endsWith('.jpeg') &&
        !fileName.toLowerCase().endsWith('.webp')) {
      fileName = '$fileName.jpg';
    }

    Helpers.showCustomSnackBar(
      'Downloading $fileName...',
      title: 'Downloading',
      type: SnackBarType.info,
    );

    try {
      if (Platform.isAndroid) {
        try {
          await Permission.storage.request();
        } catch (_) {}
      }

      Directory? targetDir;
      if (Platform.isAndroid) {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          targetDir = publicDownload;
        } else {
          try {
            targetDir = await getDownloadsDirectory();
          } catch (_) {}
          targetDir ??= await getExternalStorageDirectory();
        }
      } else {
        try {
          targetDir = await getDownloadsDirectory();
        } catch (_) {}
        targetDir ??= await getApplicationDocumentsDirectory();
      }

      targetDir ??= await getApplicationDocumentsDirectory();

      String savePath = '${targetDir.path}/$fileName';
      int counter = 1;
      final dotIdx = fileName.lastIndexOf('.');
      final base = dotIdx != -1 ? fileName.substring(0, dotIdx) : fileName;
      final ext = dotIdx != -1 ? fileName.substring(dotIdx) : '';

      while (await File(savePath).exists()) {
        savePath = '${targetDir.path}/${base}_$counter$ext';
        counter++;
      }

      final dio = Dio();
      try {
        await dio.download(
          fullUrl,
          savePath,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              downloadProgress[fullUrl] = received / total;
            }
          },
        );
      } catch (_) {
        final fallbackDir = await getApplicationDocumentsDirectory();
        savePath = '${fallbackDir.path}/$fileName';
        await dio.download(
          fullUrl,
          savePath,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              downloadProgress[fullUrl] = received / total;
            }
          },
        );
      }

      final downloadedFile = File(savePath);
      if (await downloadedFile.exists()) {
        HapticFeedback.mediumImpact();
        final actualName = savePath.split(Platform.pathSeparator).last;
        final folderName = targetDir.path.split('/').last;

        Get.snackbar(
          'Download Complete',
          '$actualName saved to $folderName',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF059669),
          colorText: Colors.white,
          icon: const Icon(Icons.download_done_rounded, color: Colors.white, size: 28),
          duration: const Duration(seconds: 4),
          mainButton: TextButton(
            onPressed: () async {
              try {
                final uri = Uri.parse(fullUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (_) {}
            },
            child: const Text('OPEN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      } else {
        throw Exception('Could not verify downloaded file');
      }
    } catch (e) {
      Helpers.showError('Download error: $e. Opening directly...');
      try {
        final uri = Uri.parse(fullUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    } finally {
      downloadingUrls.remove(fullUrl);
      downloadProgress.remove(fullUrl);
    }
  }

  // ──────────────────────── EDIT MESSAGE (WhatsApp Style) ─────────────────────

  void startEditing(Map<String, dynamic> message) {
    editingMessage.value = message;
    messageController.text = message['text']?.toString() ?? '';
  }

  void cancelEditing() {
    editingMessage.value = null;
    messageController.clear();
  }

  Future<void> submitEditedMessage() async {
    final msg = editingMessage.value;
    if (msg == null) return;

    final msgId = msg['_id']?.toString() ?? '';
    final newText = messageController.text.trim();

    if (newText.isEmpty) {
      Helpers.showError('Message cannot be empty');
      return;
    }

    try {
      isSendingMessage.value = true;
      final response = await _apiClient.patchData(
        ApiConstants.editMessage(msgId),
        {'text': newText},
      );

      if (response.statusCode == 200 && response.data?['data'] != null) {
        final idx = chatMessages.indexWhere((m) => (m['_id']?.toString() ?? '') == msgId);
        if (idx != -1) {
          chatMessages[idx]['text'] = newText;
          chatMessages[idx]['isEdited'] = true;
          chatMessages.refresh();
        }
        cancelEditing();
        fetchConversations();
      } else {
        Helpers.showError(response.data?['message'] ?? 'Failed to edit message');
      }
    } catch (_) {
      Helpers.showError('Failed to edit message');
    } finally {
      isSendingMessage.value = false;
    }
  }

  // ──────────────────────── DELETE MESSAGE (WhatsApp Style) ───────────────────

  Future<void> deleteMessage(String messageId) async {
    try {
      HapticFeedback.lightImpact();
      final response = await _apiClient.deleteData(ApiConstants.deleteMessage(messageId));

      if (response.statusCode == 200) {
        final idx = chatMessages.indexWhere((m) => (m['_id']?.toString() ?? '') == messageId);
        if (idx != -1) {
          chatMessages[idx]['isDeleted'] = true;
          chatMessages[idx]['text'] = 'This message was deleted';
          chatMessages[idx]['attachment'] = null;
          chatMessages.refresh();
        }
        fetchConversations();
      } else {
        Helpers.showError(response.data?['message'] ?? 'Failed to delete message');
      }
    } catch (_) {
      Helpers.showError('Failed to delete message');
    }
  }

  // ──────────────────────── FIVERR-STYLE MEETINGS IN CHAT ─────────────────────

  Future<void> scheduleMeetingInChat({
    required String topic,
    required DateTime startTime,
    required int durationMinutes,
    String? agenda,
  }) async {
    if (activeConversationId.value.isEmpty) return;

    try {
      isSendingMessage.value = true;
      HapticFeedback.lightImpact();

      final response = await _apiClient.postData(
        ApiConstants.createMeetingInChat,
        {
          'conversationId': activeConversationId.value,
          'topic': topic,
          'meetingType': 'SCHEDULED',
          'startTime': startTime.toUtc().toIso8601String(),
          'durationMinutes': durationMinutes,
          'agenda': agenda ??
              (isPartnerMentalHealthProfessional || isCurrentUserDoctor
                  ? 'Clinical consultation & mental health support'
                  : 'Legal consultation & case discussion'),
        },
      );

      if (response.statusCode == 201) {
        Helpers.showSuccess('Meeting scheduled successfully in chat!');
        fetchMessages(activeConversationId.value);
        fetchConversations();
      } else {
        Helpers.showError(response.data?['message'] ?? 'Failed to schedule meeting');
      }
    } catch (_) {
      Helpers.showError('Failed to schedule meeting');
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> startInstantMeetingInChat({String? topic}) async {
    if (activeConversationId.value.isEmpty) return;

    try {
      isSendingMessage.value = true;
      HapticFeedback.lightImpact();

      final response = await _apiClient.postData(
        ApiConstants.createMeetingInChat,
        {
          'conversationId': activeConversationId.value,
          'topic': topic ?? 'Instant Consultation / Incident Meeting',
          'meetingType': 'INSTANT',
        },
      );

      if (response.statusCode == 201) {
        Helpers.showSuccess('Instant meeting initiated in chat!');
        await fetchMessages(activeConversationId.value);
        fetchConversations();

        // Optionally auto-join
        final meetingData = response.data?['data'];
        if (meetingData != null && meetingData is Map) {
          joinMeetingFromChat(Map<String, dynamic>.from(meetingData));
        }
      } else {
        Helpers.showError(response.data?['message'] ?? 'Failed to create instant meeting');
      }
    } catch (_) {
      Helpers.showError('Failed to create instant meeting');
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> joinMeetingFromChat(Map<String, dynamic> meetingData) async {
    HapticFeedback.mediumImpact();

    final status = meetingData['status']?.toString().toUpperCase() ?? 'ACTIVE';
    final meetingType = meetingData['meetingType']?.toString().toUpperCase() ?? 'SCHEDULED';
    final startTimeRaw = meetingData['startTime'];
    final durationMinutes = int.tryParse(meetingData['durationMinutes']?.toString() ?? '30') ?? 30;
    final topic = meetingData['topic']?.toString() ?? 'Consultation Meeting';
    final meetingId = meetingData['_id']?.toString() ??
        meetingData['id']?.toString() ??
        meetingData['meetingId']?.toString() ??
        '';

    // If meeting is completed or recording is ready
    if (status == 'COMPLETED' || status == 'CANCELLED' || meetingData['endedAt'] != null) {
      showMeetingEndedDialog(meetingData);
      return;
    }

    // If meeting is scheduled, validate join window
    if (meetingType == 'SCHEDULED' && startTimeRaw != null) {
      try {
        final startTime = DateTime.parse(startTimeRaw.toString()).toLocal();
        final now = DateTime.now();

        // Allowed window starts 10 minutes before startTime
        final windowStart = startTime.subtract(const Duration(minutes: 10));
        // Allowed window ends when duration expires
        final windowEnd = startTime.add(Duration(minutes: durationMinutes));

        if (now.isBefore(windowStart)) {
          final diff = startTime.difference(now);
          final hours = diff.inHours;
          final minutes = diff.inMinutes % 60;
          final formattedStartTime = DateFormat('EEE, MMM d, yyyy • h:mm a').format(startTime);

          String timeRemainingStr = '';
          if (hours > 0) {
            timeRemainingStr = '$hours hr${hours > 1 ? 's' : ''} $minutes min${minutes > 1 ? 's' : ''}';
          } else {
            timeRemainingStr = '$minutes min${minutes > 1 ? 's' : ''}';
          }

          showMeetingCountdownDialog(
            topic: topic,
            scheduledTimeStr: formattedStartTime,
            durationMinutes: durationMinutes,
            timeRemainingStr: timeRemainingStr,
          );
          return;
        }

        if (now.isAfter(windowEnd)) {
          Helpers.showCustomSnackBar(
            'This scheduled meeting session has expired.',
            type: SnackBarType.warning,
          );
          return;
        }
      } catch (e) {
        debugPrint('Error parsing scheduled meeting time: $e');
      }
    }

    // Verify with backend that meeting is still open
    if (meetingId.isNotEmpty) {
      final meetingRepo = Get.isRegistered<MeetingRepository>()
          ? Get.find<MeetingRepository>()
          : MeetingRepository(apiClient: Get.find<ApiClient>());
      final joined = await meetingRepo.joinMeeting(meetingId);
      if (joined == null) {
        Helpers.showWarning('This meeting has ended and is no longer available to join.');
        return;
      }
    }

    // Join meeting
    final role = currentUserRole.toUpperCase();
    if (role == 'ATTORNEY' || role == 'POLICE' || role == 'BAIL_BONDSMAN') {
      Get.toNamed(AppRoutes.attorneyLiveCall, arguments: {'meeting': meetingData});
    } else if (role == 'DOCTOR' || role == 'MENTAL_HEALTH_PROFESSIONAL') {
      Get.toNamed(AppRoutes.doctorLiveCall, arguments: {'meeting': meetingData});
    } else {
      Get.toNamed(AppRoutes.citizenLiveCall, arguments: {'meeting': meetingData});
    }
  }

  void showMeetingCountdownDialog({
    required String topic,
    required String scheduledTimeStr,
    required int durationMinutes,
    required String timeRemainingStr,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.alarm_rounded,
                  color: Color(0xFF1550A6),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Meeting Not Started Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                topic,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            scheduledTimeStr,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timelapse_rounded, size: 15, color: Color(0xFF1550A6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Starts in: $timeRemainingStr',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1550A6)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can join 10 minutes prior to the scheduled time.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1550A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showMeetingEndedDialog(Map<String, dynamic> meetingData) {
    final recordingUrl = meetingData['recordingUrl']?.toString() ?? '';
    final topic = meetingData['topic']?.toString() ?? 'Consultation Meeting';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF16A34A),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Meeting Completed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                topic,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (recordingUrl.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.videocam_rounded, color: Color(0xFF1550A6), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cloud recording is ready to watch',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      playOrCopyRecording(recordingUrl);
                    },
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                    label: const Text('Watch Recording', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1550A6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Recording processing in cloud. It will be available shortly.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void playOrCopyRecording(String recordingUrl) {
    if (recordingUrl.trim().isEmpty) {
      Helpers.showError('Recording URL is not available yet');
      return;
    }
    HapticFeedback.mediumImpact();
    GoviaVideoPlayerView.open(
      url: recordingUrl,
      title: 'Consultation Recording',
      subtitle: 'Encrypted Incident Evidence',
    );
  }

  Future<void> updateMeetingScheduleInChat({
    required String meetingId,
    required String topic,
    required DateTime startTime,
    required int durationMinutes,
    String? agenda,
  }) async {
    try {
      HapticFeedback.lightImpact();
      final response = await _apiClient.patchData(
        ApiConstants.meetingDetails(meetingId),
        {
          'topic': topic,
          'startTime': startTime.toUtc().toIso8601String(),
          'durationMinutes': durationMinutes,
          if (agenda != null && agenda.isNotEmpty) 'agenda': agenda,
        },
      );

      if (response.statusCode == 200) {
        Helpers.showCustomSnackBar('Meeting updated successfully', type: SnackBarType.success);
        fetchMessages(activeConversationId.value);
        fetchConversations();
      } else {
        Helpers.showError(response.data?['message'] ?? 'Failed to update meeting');
      }
    } catch (_) {
      Helpers.showError('Failed to update meeting');
    }
  }

  Future<void> deleteMeetingInChat(String meetingId) async {
    try {
      HapticFeedback.mediumImpact();
      final response = await _apiClient.deleteData(ApiConstants.meetingDetails(meetingId));

      if (response.statusCode == 200) {
        Helpers.showCustomSnackBar('Meeting deleted successfully', type: SnackBarType.success);
        fetchMessages(activeConversationId.value);
        fetchConversations();
      } else {
        Helpers.showError(response.data?['message'] ?? 'Failed to delete meeting');
      }
    } catch (_) {
      Helpers.showError('Failed to delete meeting');
    }
  }

  Future<void> endMeetingInChat(String meetingId) async {
    try {
      HapticFeedback.mediumImpact();
      final response = await _apiClient.patchData(ApiConstants.endMeeting(meetingId), {});

      if (response.statusCode == 200) {
        Helpers.showCustomSnackBar('Meeting concluded for all participants', type: SnackBarType.success);
        fetchMessages(activeConversationId.value);
        fetchConversations();
      } else {
        Helpers.showError(response.data?['message'] ?? 'Failed to end meeting');
      }
    } catch (_) {
      Helpers.showError('Failed to end meeting');
    }
  }

  // ──────────────────────── UTILITY HELPERS ───────────────────────────────────

  void copyMessageText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    Get.rawSnackbar(
      messageText: const Text(
        'Message copied to clipboard',
        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      backgroundColor: const Color(0xFF0F172A),
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String formatTimestamp(dynamic rawDate) {
    if (rawDate == null) return '';
    try {
      final date = rawDate is DateTime ? rawDate : DateTime.parse(rawDate.toString()).toLocal();
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return DateFormat('h:mm a').format(date);
      }
      if (now.difference(date).inDays < 7) {
        return DateFormat('EEE, h:mm a').format(date);
      }
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (_) {
      return '';
    }
  }
}
