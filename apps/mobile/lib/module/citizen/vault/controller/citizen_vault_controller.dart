import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/module/citizen/vault/model/vault_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Backwards compatibility for existing views referencing EncounterModel
class EncounterModel {
  final String id;
  final String title;
  final String dateTime;
  final String locationName;
  final String duration;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String description;

  EncounterModel({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.locationName,
    required this.duration,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.description,
  });
}

class CitizenVaultController extends GetxController {
  late final ApiClient _apiClient;

  // State
  final RxList<VaultFolderModel> folders = <VaultFolderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isActionLoading = false.obs;
  final RxString activeFilter = 'All'.obs;
  final RxString searchQuery = ''.obs;

  // ─── TABS & SHARING STATE ──────────────────────────────────────────
  final RxString selectedTab = 'Recordings'.obs; // 'Recordings', 'My Folders', 'Shared'
  final RxList<VaultFolderModel> sharedFolders = <VaultFolderModel>[].obs;
  final RxList<Map<String, dynamic>> allRecordings = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingShared = false.obs;
  final RxBool isLoadingRecordings = false.obs;

  void switchTab(String tab) {
    selectedTab.value = tab;
    if (tab == 'Recordings') {
      fetchAllRecordings(showLoader: false);
    } else if (tab == 'My Folders') {
      fetchFolders(showLoader: false);
    } else if (tab == 'Shared' || tab == 'Shared with Me') {
      fetchSharedFolders(showLoader: false);
    }
  }

  // Active folder details cache (folderId -> items list)
  final RxMap<String, List<VaultItemModel>> folderItemsCache = <String, List<VaultItemModel>>{}.obs;
  final RxBool isLoadingFolderDetails = false.obs;

  // Downloads tracking
  final RxSet<String> downloadingUrls = <String>{}.obs;
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;

  // Quick stats
  int get totalFolders => folders.length;
  int get totalEvidenceItems => folders.fold(0, (sum, f) => sum + f.itemCount);
  int get totalVideos => folders.fold(0, (sum, f) => sum + (f.counts['video'] ?? 0));
  int get totalAudios => folders.fold(0, (sum, f) => sum + (f.counts['audio'] ?? 0));
  int get totalImages => folders.fold(0, (sum, f) => sum + (f.counts['image'] ?? 0));
  int get totalDocs => folders.fold(0, (sum, f) => sum + (f.counts['doc'] ?? 0));

  // Legacy list for any views referencing filteredEncounters
  final RxList<EncounterModel> filteredEncounters = <EncounterModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    try {
      _apiClient = Get.find<ApiClient>();
    } catch (_) {
      _apiClient = Get.put(ApiClient());
    }
    fetchFolders();
    fetchSharedFolders(showLoader: false);
    fetchAllRecordings(showLoader: false);
  }

  void applyFilter(String filter) {
    activeFilter.value = filter;
  }

  void setSearchQuery(String q) {
    searchQuery.value = q.trim();
  }

  List<VaultFolderModel> get filteredSharedFolders {
    if (sharedFolders.isEmpty) return [];
    if (searchQuery.value.isEmpty) return sharedFolders.toList();
    final q = searchQuery.value.toLowerCase();
    return sharedFolders.where((f) {
      final matchesName = f.name.toLowerCase().contains(q);
      final matchesDesc = f.description.toLowerCase().contains(q);
      final matchesSharedBy = (f.sharedByName ?? '').toLowerCase().contains(q);
      return matchesName || matchesDesc || matchesSharedBy;
    }).toList();
  }

  List<Map<String, dynamic>> get filteredRecordings {
    if (allRecordings.isEmpty) return [];
    if (searchQuery.value.isEmpty) return allRecordings.toList();
    final q = searchQuery.value.toLowerCase();
    return allRecordings.where((r) {
      final title = (r['topic'] ?? r['title'] ?? '').toString().toLowerCase();
      final caller = (r['callerName'] ?? r['hostName'] ?? '').toString().toLowerCase();
      return title.contains(q) || caller.contains(q);
    }).toList();
  }

  List<VaultFolderModel> get filteredFolders {
    if (folders.isEmpty) return [];

    final list = folders.toList();
    if (searchQuery.value.isEmpty) {
      return list;
    }

    final q = searchQuery.value.toLowerCase();
    return list.where((f) {
      final matchesName = f.name.toLowerCase().contains(q);
      final matchesDesc = f.description.toLowerCase().contains(q);
      final matchesLoc = f.location.toLowerCase().contains(q);
      final matchesCat = f.categoryDisplayName.toLowerCase().contains(q);
      final matchesContained = f.containedCategories.any((c) => c.toLowerCase().contains(q));
      return matchesName || matchesDesc || matchesLoc || matchesCat || matchesContained;
    }).toList();
  }

  // ──────────────────────── FETCH FOLDERS ────────────────────────
  Future<void> fetchFolders({bool showLoader = true}) async {
    if (showLoader) isLoading.value = true;
    try {
      final response = await _apiClient.getData(ApiConstants.vaultFolders);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data['data'] ?? [];
        folders.value = list.map((json) => VaultFolderModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      Helpers.debug('Error fetching vault folders: $e');
    } finally {
      if (showLoader) isLoading.value = false;
    }
  }

  // ──────────────────────── FETCH SHARED FOLDERS ────────────────────────
  Future<void> fetchSharedFolders({bool showLoader = true}) async {
    if (showLoader) isLoadingShared.value = true;
    try {
      final response = await _apiClient.getData(ApiConstants.vaultSharedWithMe);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data['data'] ?? [];
        sharedFolders.value = list.map((json) => VaultFolderModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      Helpers.debug('Error fetching shared folders: $e');
    } finally {
      if (showLoader) isLoadingShared.value = false;
    }
  }

  // ──────────────────────── FETCH ALL RECORDINGS ────────────────────────
  Future<void> fetchAllRecordings({bool showLoader = true}) async {
    if (showLoader) isLoadingRecordings.value = true;
    try {
      final response = await _apiClient.getData(ApiConstants.vaultRecordings);
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'];
        List<Map<String, dynamic>> items = [];
        if (rawData is Map) {
          final allList = rawData['all'] as List? ?? rawData['meetings'] as List? ?? [];
          items = allList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (rawData is List) {
          items = rawData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        allRecordings.value = items;
        allRecordings.refresh();
      }
    } catch (e) {
      Helpers.debug('Error fetching recordings: $e');
    } finally {
      if (showLoader) isLoadingRecordings.value = false;
    }
  }

  // ──────────────────────── SHARE FOLDER ────────────────────────
  Future<bool> shareFolder({
    required String folderId,
    required String targetUserId,
  }) async {
    try {
      isActionLoading.value = true;
      final response = await _apiClient.postData(
        ApiConstants.vaultFolderShare(folderId),
        {'targetUserId': targetUserId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showSuccess('Folder shared successfully');
        HapticFeedback.mediumImpact();
        await fetchFolders(showLoader: false);
        return true;
      } else {
        final msg = response.data?['message'] ?? 'Failed to share folder';
        Helpers.showError(msg);
      }
    } catch (e) {
      Helpers.showError('Error sharing folder: $e');
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  // ──────────────────────── LOOKUP USER ────────────────────────
  Future<Map<String, dynamic>?> lookupUser(String identifier) async {
    try {
      final response = await _apiClient.getData(ApiConstants.userLookup(identifier));
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (_) {}
    return null;
  }

  // ──────────────────────── CREATE FOLDER ────────────────────────
  Future<VaultFolderModel?> createFolder({
    required String name,
    String? description,
    String? category,
    String? location,
    DateTime? incidentDate,
    bool showSuccessToast = true,
  }) async {
    if (name.trim().isEmpty) {
      Helpers.showError('Please enter a folder title');
      return null;
    }

    try {
      isActionLoading.value = true;
      final payload = {
        'name': name.trim(),
        'description': description?.trim() ?? '',
        'category': category ?? 'ENCOUNTER',
        'location': location?.trim() ?? '',
        'incidentDate': (incidentDate ?? DateTime.now()).toIso8601String(),
      };

      final response = await _apiClient.postData(ApiConstants.vaultFolders, payload);
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final dynamic rawData = (response.data is Map && response.data['data'] != null)
            ? response.data['data']
            : response.data;
        if (rawData is Map<String, dynamic>) {
          final newFolder = VaultFolderModel.fromJson(rawData);
          folders.removeWhere((f) => f.id == newFolder.id);
          folders.insert(0, newFolder);
          folders.refresh();
          if (showSuccessToast) {
            Helpers.showSuccess('Folder "${newFolder.name}" created successfully');
          }
          HapticFeedback.mediumImpact();
          fetchFolders(showLoader: false);
          return newFolder;
        }
      }
      final msg = response.data?['message'] ?? response.statusMessage ?? 'Failed to create folder';
      Helpers.showError(msg.toString());
    } catch (e) {
      Helpers.showError('Error creating vault folder: $e');
    } finally {
      isActionLoading.value = false;
    }
    return null;
  }

  // ──────────────────────── UPDATE FOLDER ────────────────────────
  Future<bool> updateFolder({
    required String folderId,
    required String name,
    String? description,
    String? category,
    String? location,
    DateTime? incidentDate,
  }) async {
    if (name.trim().isEmpty) {
      Helpers.showError('Please enter a folder title');
      return false;
    }

    try {
      isActionLoading.value = true;
      final Map<String, dynamic> payload = {'name': name.trim()};
      if (description != null) payload['description'] = description.trim();
      if (category != null) payload['category'] = category;
      if (location != null) payload['location'] = location.trim();
      if (incidentDate != null) payload['incidentDate'] = incidentDate.toIso8601String();

      final response = await _apiClient.patchData(ApiConstants.vaultFolderDetails(folderId), payload);
      if (response.statusCode == 200) {
        Helpers.showSuccess('Folder updated successfully');
        HapticFeedback.mediumImpact();
        await fetchFolders(showLoader: false);
        return true;
      }
    } catch (e) {
      Helpers.showError('Error updating folder: $e');
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  // ──────────────────────── DELETE FOLDER ────────────────────────
  Future<bool> deleteFolder(String folderId) async {
    try {
      isActionLoading.value = true;
      final response = await _apiClient.deleteData(ApiConstants.vaultFolderDetails(folderId));
      if (response.statusCode == 200) {
        folders.removeWhere((f) => f.id == folderId);
        folders.refresh();
        folderItemsCache.remove(folderId);
        folderItemsCache.refresh();
        Helpers.showSuccess('Folder deleted');
        HapticFeedback.mediumImpact();
        return true;
      }
    } catch (e) {
      Helpers.showError('Error deleting folder: $e');
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  // ──────────────────────── GET FOLDER DETAILS ────────────────────────
  Future<List<VaultItemModel>> fetchFolderDetails(String folderId, {bool forceRefresh = false}) async {
    if (!forceRefresh && folderItemsCache.containsKey(folderId)) {
      return folderItemsCache[folderId]!;
    }

    try {
      isLoadingFolderDetails.value = true;
      final response = await _apiClient.getData(ApiConstants.vaultFolderDetails(folderId));
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final List<dynamic> itemsList = data['items'] ?? [];
        final items = itemsList.map((json) => VaultItemModel.fromJson(json as Map<String, dynamic>)).toList();
        folderItemsCache[folderId] = items;
        folderItemsCache.refresh();
        return items;
      }
    } catch (e) {
      Helpers.debug('Error fetching folder details: $e');
    } finally {
      isLoadingFolderDetails.value = false;
    }
    return [];
  }

  // ──────────────────────── UPLOAD EVIDENCE ────────────────────────
  Future<bool> uploadEvidence({
    required String folderId,
    required File file,
    String? title,
    String? description,
    String? category,
    String? fileType,
    int? duration,
    String? importance,
    String? subCategory,
  }) async {
    try {
      isActionLoading.value = true;

      // Detect field name based on file extension
      final ext = file.path.split('.').last.toLowerCase();
      String fieldName = 'media';
      if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
        fieldName = 'image';
      } else if (['pdf', 'doc', 'docx', 'txt', 'csv'].contains(ext)) {
        fieldName = 'doc';
      }

      final payload = {
        'folderId': folderId,
        if (title != null && title.isNotEmpty) 'title': title.trim(),
        if (description != null && description.isNotEmpty) 'description': description.trim(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (fileType != null && fileType.isNotEmpty) 'fileType': fileType,
        if (duration != null && duration > 0) 'duration': duration.toString(),
        if (importance != null && importance.isNotEmpty) 'importance': importance,
        if (subCategory != null && subCategory.isNotEmpty) 'subCategory': subCategory.trim(),
      };

      final response = await _apiClient.postMultipartData(
        ApiConstants.vaultUpload,
        payload,
        multipartBody: [MultipartBody(fieldName, file)],
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showSuccess('Evidence saved to Vault');
        HapticFeedback.mediumImpact();
        await fetchFolders(showLoader: false);
        await fetchFolderDetails(folderId, forceRefresh: true);
        return true;
      } else {
        final msg = response.data?['message'] ?? 'Upload failed';
        Helpers.showError(msg);
      }
    } catch (e) {
      Helpers.showError('Error uploading evidence: $e');
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  // ──────────────────────── LINK MEETING TO VAULT ────────────────────────
  Future<bool> linkMeetingToFolder({
    required String folderId,
    required String meetingId,
    String? title,
    String? description,
  }) async {
    try {
      isActionLoading.value = true;
      final payload = {
        'folderId': folderId,
        'meetingId': meetingId,
        if (title != null && title.isNotEmpty) 'title': title.trim(),
        if (description != null && description.isNotEmpty) 'description': description.trim(),
      };

      final response = await _apiClient.postData(ApiConstants.vaultLinkMeeting, payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showSuccess('Meeting recording attached to Vault');
        HapticFeedback.mediumImpact();
        await fetchFolders(showLoader: false);
        await fetchFolderDetails(folderId, forceRefresh: true);
        await fetchAllRecordings(showLoader: false);
        return true;
      } else {
        final msg = response.data?['message'] ?? 'Failed to attach meeting';
        Helpers.showError(msg);
      }
    } catch (e) {
      Helpers.showError('Error linking meeting: $e');
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  // ──────────────────────── DELETE EVIDENCE ITEM ────────────────────────
  Future<bool> deleteEvidenceItem({required String itemId, required String folderId}) async {
    try {
      isActionLoading.value = true;
      final response = await _apiClient.deleteData(ApiConstants.vaultItem(itemId));
      if (response.statusCode == 200) {
        Helpers.showSuccess('Evidence deleted');
        if (folderItemsCache.containsKey(folderId)) {
          folderItemsCache[folderId]!.removeWhere((i) => i.id == itemId);
          folderItemsCache.refresh();
        }
        await fetchFolders(showLoader: false);
        return true;
      }
    } catch (e) {
      Helpers.showError('Error deleting evidence: $e');
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  // ──────────────────────── DOWNLOAD EVIDENCE ────────────────────────
  Future<void> downloadEvidence(VaultItemModel item) async {
    final fullUrl = item.fullUrl;
    if (fullUrl.isEmpty) {
      Helpers.showError('Download link is not available');
      return;
    }

    if (downloadingUrls.contains(fullUrl)) {
      Helpers.showCustomSnackBar('Download is already in progress...', type: SnackBarType.info);
      return;
    }

    downloadingUrls.add(fullUrl);
    downloadProgress[fullUrl] = 0.0;

    final rawFileName = item.fileUrl.split('/').last;
    final fileExt = rawFileName.contains('.') ? rawFileName.split('.').last : (item.fileType == 'VIDEO' ? 'mp4' : 'bin');
    final sanitizedTitle = (item.title.isNotEmpty ? item.title : item.displayTitle).replaceAll(RegExp(r'[^\w\s\-]'), '').trim().replaceAll(' ', '_');
    final fileName = '${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    Get.snackbar(
      'Starting Download',
      'Saving $fileName...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1550A6),
      colorText: Colors.white,
      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
      duration: const Duration(seconds: 3),
    );

    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          targetDir = publicDownload;
        } else {
          try {
            targetDir = await getDownloadsDirectory();
          } catch (_) {}
        }
      }

      targetDir ??= await getApplicationDocumentsDirectory();

      final savePath = '${targetDir.path}/$fileName';
      final dio = Dio();

      await dio.download(
        fullUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress[fullUrl] = received / total;
          }
        },
      );

      final downloadedFile = File(savePath);
      if (await downloadedFile.exists()) {
        HapticFeedback.mediumImpact();
        Get.snackbar(
          'Download Complete',
          '$fileName saved to ${targetDir.path.split('/').last}',
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
      }
    } catch (e) {
      Helpers.showError('Download failed: $e. Opening browser directly...');
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
}
