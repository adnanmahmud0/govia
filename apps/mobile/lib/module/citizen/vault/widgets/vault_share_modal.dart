import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/module/citizen/vault/controller/citizen_vault_controller.dart';
import 'package:gsabino365/module/citizen/vault/model/vault_models.dart';
import 'package:gsabino365/module/shared/chat/controller/chat_controller.dart';

class VaultShareModal extends StatefulWidget {
  final VaultFolderModel folder;

  const VaultShareModal({super.key, required this.folder});

  static Future<void> show(BuildContext context, {required VaultFolderModel folder}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VaultShareModal(folder: folder),
    );
  }

  @override
  State<VaultShareModal> createState() => _VaultShareModalState();
}

class _VaultShareModalState extends State<VaultShareModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _idInputController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  late final CitizenVaultController _vaultController;
  late final ApiClient _apiClient;

  // Selected recipient state
  Map<String, dynamic>? _selectedUser;
  bool _isSearching = false;
  bool _isSharing = false;
  String _searchError = '';

  // Message list contacts
  List<Map<String, dynamic>> _contacts = [];
  bool _loadingContacts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _vaultController = Get.find<CitizenVaultController>();
    try {
      _apiClient = Get.find<ApiClient>();
    } catch (_) {
      _apiClient = Get.put(ApiClient());
    }

    _loadRecentContacts();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _tabController.index != 1) {
        _scannerController.stop();
      } else if (_tabController.index == 1 && _selectedUser == null) {
        _scannerController.start();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    _idInputController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentContacts() async {
    setState(() => _loadingContacts = true);
    try {
      // 1. Try ChatController conversations
      if (Get.isRegistered<ChatController>()) {
        final chatCtrl = Get.find<ChatController>();
        if (chatCtrl.conversations.isNotEmpty) {
          final mapped = chatCtrl.conversations.map((c) {
            final other = chatCtrl.getOtherParticipant(c);
            final otherId = other['_id']?.toString() ?? other['id']?.toString() ?? c['_id']?.toString() ?? '';
            return {
              '_id': otherId,
              'id': otherId,
              'name': other['name']?.toString() ?? 'Govia Member',
              'role': other['role']?.toString() ?? 'Citizen',
              'profilePicture': other['profilePicture']?.toString() ?? other['image']?.toString(),
              'shortHexId': other['shortHexId']?.toString() ?? '',
              'lastMessage': c['lastMessageText']?.toString() ?? '',
            };
          }).toList();
          if (mounted) {
            setState(() {
              _contacts = mapped;
              _loadingContacts = false;
            });
            return;
          }
        }
      }

      // 2. Fetch from API
      final response = await _apiClient.getData(ApiConstants.conversations);
      if (response.statusCode == 200 && response.data != null) {
        final dynamic rawList = response.data['data'] ?? [];
        if (rawList is List) {
          final list = <Map<String, dynamic>>[];
          for (final item in rawList) {
            if (item is Map) {
              final participant = item['otherParticipant'] ?? item['participant'];
              if (participant is Map) {
                list.add(Map<String, dynamic>.from(participant));
              }
            }
          }
          if (mounted) {
            setState(() {
              _contacts = list;
              _loadingContacts = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingContacts = false);
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    final raw = barcode.rawValue!.trim();
    if (raw.isEmpty) return;

    HapticFeedback.mediumImpact();
    await _scannerController.stop();

    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    // Lookup scanned payload
    final user = await _vaultController.lookupUser(raw);
    if (mounted) {
      setState(() {
        _isSearching = false;
        if (user != null) {
          _selectedUser = user;
        } else {
          // Fallback: parse JSON directly
          try {
            if (raw.startsWith('{') && raw.endsWith('}')) {
              _selectedUser = Map<String, dynamic>.from(jsonDecode(raw) as Map);
            } else {
              _searchError = 'User not found for scanned QR';
              _scannerController.start();
            }
          } catch (_) {
            _searchError = 'Invalid QR format';
            _scannerController.start();
          }
        }
      });
    }
  }

  Future<void> _handleIdSearch() async {
    final query = _idInputController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchError = 'Please enter a user ID or Short ID');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    final user = await _vaultController.lookupUser(query);
    if (mounted) {
      setState(() {
        _isSearching = false;
        if (user != null) {
          _selectedUser = user;
        } else {
          _searchError = 'No active user found with ID "$query"';
        }
      });
    }
  }

  Future<void> _confirmAndShare() async {
    if (_selectedUser == null) return;
    final targetId = _selectedUser!['_id']?.toString() ??
        _selectedUser!['id']?.toString() ??
        '';
    if (targetId.isEmpty) {
      Helpers.showError('Invalid recipient ID');
      return;
    }

    setState(() => _isSharing = true);
    final success = await _vaultController.shareFolder(
      folderId: widget.folder.id,
      targetUserId: targetId,
    );

    if (mounted) {
      setState(() => _isSharing = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Drag handle
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 12.h),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.share_rounded, color: const Color(0xFF1550A6), size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Folder',
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '"${widget.folder.name}" • View-Only Access',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFE2E8F0), height: 20),

          // If a recipient is already selected -> show Confirmation Card
          if (_selectedUser != null) ...[
            Expanded(child: _buildRecipientConfirmationView()),
          ] else ...[
            // Tab bar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF1550A6),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: EdgeInsets.all(4.r),
                tabs: const [
                  Tab(text: 'Message List'),
                  Tab(text: 'Scan QR'),
                  Tab(text: 'Enter User ID'),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMessageListTab(),
                  _buildScanQrTab(),
                  _buildEnterIdTab(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────── TAB 1: MESSAGE LIST ────────────────────────
  Widget _buildMessageListTab() {
    if (_loadingContacts) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1550A6)));
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 48.sp, color: const Color(0xFF94A3B8)),
              SizedBox(height: 12.h),
              Text(
                'No Recent Messages',
                style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              SizedBox(height: 6.h),
              Text(
                'You have no recent chat conversations. Use "Scan QR" or "Enter User ID" to share this folder.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      itemCount: _contacts.length,
      separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 1),
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        final name = contact['name']?.toString() ?? 'Govia Member';
        final role = contact['role']?.toString() ?? 'Citizen';
        final avatar = contact['profilePicture']?.toString() ?? contact['avatar']?.toString();
        final shortId = contact['shortHexId']?.toString() ?? '';

        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          leading: CircleAvatar(
            radius: 22.r,
            backgroundColor: const Color(0xFF1550A6).withValues(alpha: 0.1),
            backgroundImage: (avatar != null && avatar.isNotEmpty)
                ? NetworkImage(ApiConstants.getFileUrl(avatar)) as ImageProvider
                : const AssetImage('assets/images/user_avatar.png'),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1550A6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 9.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1550A6)),
                ),
              ),
            ],
          ),
          subtitle: Text(
            shortId.isNotEmpty ? 'ID: #$shortId' : role,
            style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF64748B)),
          ),
          trailing: ElevatedButton(
            onPressed: () {
              setState(() => _selectedUser = contact);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1550A6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Select', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  // ──────────────────────── TAB 2: SCAN QR ────────────────────────
  Widget _buildScanQrTab() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Text(
            "Point camera at recipient's Govia Digital ID QR code",
            style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
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
                  Container(
                    width: 200.w,
                    height: 200.w,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF3B82F6), width: 3.w),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  if (_isSearching)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_searchError.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              _searchError,
              style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFDC2626)),
            ),
          ],
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // ──────────────────────── TAB 3: ENTER USER ID ────────────────────────
  Widget _buildEnterIdTab() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Recipient ID',
            style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          SizedBox(height: 6.h),
          Text(
            'Input Short Hex ID (e.g. 882910AA), Assigned Number, or full user ID.',
            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idInputController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. 882910AA',
                    hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF64748B), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFF1550A6), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  ),
                  onSubmitted: (_) => _handleIdSearch(),
                ),
              ),
              SizedBox(width: 10.w),
              ElevatedButton(
                onPressed: _isSearching ? null : _handleIdSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1550A6),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: _isSearching
                    ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Find', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (_searchError.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _searchError,
                      style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────── RECIPIENT CONFIRMATION VIEW ────────────────────────
  Widget _buildRecipientConfirmationView() {
    final user = _selectedUser!;
    final name = user['name']?.toString() ?? 'Govia Member';
    final role = user['role']?.toString() ?? 'Citizen';
    final avatar = user['profilePicture']?.toString() ?? user['avatar']?.toString();
    final shortId = user['shortHexId']?.toString() ?? user['shortId']?.toString() ?? '';
    final idStr = user['_id']?.toString() ?? user['id']?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_rounded, color: Color(0xFF1550A6), size: 20),
                    SizedBox(width: 8.w),
                    Text(
                      'Recipient Confirmed',
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1550A6),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                SizedBox(height: 14.h),
                CircleAvatar(
                  radius: 32.r,
                  backgroundColor: const Color(0xFF1550A6).withValues(alpha: 0.12),
                  backgroundImage: (avatar != null && avatar.isNotEmpty)
                      ? NetworkImage(ApiConstants.getFileUrl(avatar)) as ImageProvider
                      : const AssetImage('assets/images/user_avatar.png'),
                ),
                SizedBox(height: 10.h),
                Text(
                  name,
                  style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                Text(
                  shortId.isNotEmpty ? 'ID: #$shortId' : (idStr.isNotEmpty ? 'ID: #$idStr' : ''),
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1550A6),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility_rounded, color: Color(0xFF059669), size: 16),
                      SizedBox(width: 6.w),
                      Text(
                        'View-Only Access Granted',
                        style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF065F46)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Share Action Button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _confirmAndShare,
              icon: _isSharing
                  ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.share_rounded),
              label: Text(
                _isSharing ? 'Sharing Folder...' : 'Share Folder with $name',
                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1550A6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedUser = null;
                  _searchError = '';
                });
                if (_tabController.index == 1) {
                  _scannerController.start();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('Choose Different Recipient'),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
