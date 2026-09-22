import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';

class GoviaAiController extends GetxController {
  late TextEditingController messageController;
  late ScrollController scrollController;

  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isProcessing = false.obs;
  final RxBool isLoadingChats = false.obs;
  final RxnString currentChatId = RxnString();
  final RxList<Map<String, dynamic>> chatList = <Map<String, dynamic>>[].obs;
  final RxList<String> suggestedPrompts = <String>[].obs;
  final RxString userRole = 'CITIZEN'.obs;

  ApiClient get _apiClient => Get.find<ApiClient>();
  AuthService get _authService => Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    messageController = TextEditingController();
    scrollController = ScrollController();

    // Determine current user role
    final role = _authService.currentUser.value?.role ?? 'CITIZEN';
    userRole.value = role.toUpperCase();

    _setupRoleSuggestions(userRole.value);
    _initWelcomeMessage();
    fetchChatList();
  }

  void _setupRoleSuggestions(String role) {
    switch (role) {
      case 'POLICE':
        suggestedPrompts.assignAll([
          'What are the exceptions to vehicle search warrants?',
          'When must Miranda warnings be administered during detention?',
          'Reasonable suspicion vs probable cause standard in traffic stops',
          'Search incident to lawful arrest guidelines',
        ]);
        break;
      case 'ATTORNEY':
        suggestedPrompts.assignAll([
          'Motion to suppress evidence under 4th Amendment',
          'Challenging warrantless roadside inventory searches',
          'Statutory defenses for operating vehicle under influence',
          'Arguments for commercial bail bond reduction hearing',
        ]);
        break;
      case 'MENTAL_HEALTH_PROFESSIONAL':
        suggestedPrompts.assignAll([
          'Statutory requirements for 72-hour involuntary psychiatric hold',
          'HIPAA emergency disclosure rules when imminent harm is present',
          'Legal rights of patients during crisis evaluation',
          'Coordinating crisis response with local law enforcement',
        ]);
        break;
      case 'BAIL_BONDSMAN':
        suggestedPrompts.assignAll([
          'Surety bond forfeiture defense standards and deadlines',
          'Statutory rules for fugitive recovery and extradition',
          'Procedures for lawful surrender of defendant by surety',
          'Indemnity contract enforceability requirements',
        ]);
        break;
      case 'CITIZEN':
      default:
        suggestedPrompts.assignAll([
          'What are my rights if pulled over by police at night?',
          'Can police search my vehicle without my consent?',
          'How do I clearly invoke my right to remain silent?',
          'How does the bail bond process work after an arrest?',
        ]);
        break;
    }
  }

  void _initWelcomeMessage() {
    messages.assignAll([
      {
        'text': 'Hello! I am your **GoVia AI Legal Assistant**.\n\nAsk me anything about your constitutional rights, police encounters, traffic stops, court procedures, bail bonds, or US statutes.\n\n*Tap any of the quick suggestions below or type your question.*',
        'isUser': false,
        'time': _formatCurrentTime(),
        'status': 'Delivered',
      }
    ]);
  }

  Future<void> fetchChatList() async {
    try {
      isLoadingChats.value = true;
      final response = await _apiClient.getData(ApiConstants.aiChats);
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        chatList.assignAll(list.map((c) => Map<String, dynamic>.from(c as Map)).toList());
      }
    } catch (e) {
      Helpers.debug('Error fetching AI chats: $e');
    } finally {
      isLoadingChats.value = false;
    }
  }

  Future<void> loadChat(String chatId) async {
    try {
      Helpers.showLoadingDialog(message: 'Loading conversation...');
      final response = await _apiClient.getData(ApiConstants.aiChatHistory(chatId));
      Helpers.hideLoadingDialog();

      if (response.statusCode == 200 && response.data != null) {
        final chatData = response.data['data'] as Map<String, dynamic>?;
        if (chatData != null) {
          currentChatId.value = chatData['_id']?.toString();
          final rawMessages = chatData['messages'] as List<dynamic>? ?? [];
          
          final loaded = <Map<String, dynamic>>[];
          for (final m in rawMessages) {
            final isUser = m['role'] == 'user';
            loaded.add({
              'text': m['content'] ?? '',
              'isUser': isUser,
              'time': _formatCurrentTime(),
              'status': 'Delivered',
            });
          }
          if (loaded.isNotEmpty) {
            messages.assignAll(loaded);
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      Helpers.hideLoadingDialog();
      Helpers.showError('Failed to load conversation');
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final response = await _apiClient.deleteData(ApiConstants.deleteAiChat(chatId));
      if (response.statusCode == 200) {
        chatList.removeWhere((c) => c['_id'] == chatId);
        if (currentChatId.value == chatId) {
          startNewChat();
        }
        Helpers.showSuccess('Conversation removed');
      }
    } catch (e) {
      Helpers.showError('Failed to delete conversation');
    }
  }

  void startNewChat() {
    currentChatId.value = null;
    _initWelcomeMessage();
    messageController.clear();
    _scrollToBottom();
  }

  void sendSuggestedPrompt(String prompt) {
    messageController.text = prompt;
    sendMessage();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isProcessing.value) return;

    // Add user message
    messages.add({
      'text': text,
      'isUser': true,
      'time': _formatCurrentTime(),
      'status': 'Sent',
    });
    messageController.clear();
    _scrollToBottom();

    isProcessing.value = true;

    try {
      final payload = {
        'prompt': text,
        if (currentChatId.value != null && currentChatId.value!.isNotEmpty)
          'chatId': currentChatId.value,
      };

      final response = await _apiClient.postData(
        ApiConstants.aiAssistant,
        payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final aiText = data?['message'] as String? ?? 'No response received.';
        final newChatId = data?['chatId']?.toString();

        if (newChatId != null && newChatId.isNotEmpty) {
          currentChatId.value = newChatId;
        }

        messages.add({
          'text': aiText,
          'isUser': false,
          'time': _formatCurrentTime(),
          'status': 'Delivered',
        });

        // Silently update chat list in background
        fetchChatList();
      } else {
        final errMsg = response.data?['message'] ?? 'Failed to get response from AI assistant.';
        messages.add({
          'text': '⚠️ $errMsg Please try again.',
          'isUser': false,
          'time': _formatCurrentTime(),
          'status': 'Error',
        });
      }
    } catch (e) {
      messages.add({
        'text': '⚠️ An error occurred while communicating with GoVia AI. Please check your internet connection and try again.',
        'isUser': false,
        'time': _formatCurrentTime(),
        'status': 'Error',
      });
    } finally {
      isProcessing.value = false;
      _scrollToBottom();
    }
  }

  void copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Helpers.showSuccess('Copied to clipboard');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatCurrentTime() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
