import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/app_config.dart';

class ZaloOaSubPage extends StatefulWidget {
  const ZaloOaSubPage({super.key});

  @override
  State<ZaloOaSubPage> createState() => _ZaloOaSubPageState();
}

class _ZaloOaSubPageState extends State<ZaloOaSubPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCheckingConnection = false;
  bool _isSendingTest = false;

  Map<String, dynamic>? _config;
  List<dynamic> _logs = [];

  // ===== FORM CẤU HÌNH =====
  final _appIdController = TextEditingController();
  final _appSecretController = TextEditingController();
  final _oaIdController = TextEditingController();
  final _refreshTokenController = TextEditingController();

  bool _enableAppointmentReminder = false;
  final _appointmentTemplateController = TextEditingController();

  bool _enableOrderNotification = false;
  final _orderTemplateController = TextEditingController();

  bool _enableTierUpgrade = false;
  final _tierTemplateController = TextEditingController();

  // ===== FORM GỬI TIN THỬ (ZNS - cần Template) =====
  final _testPhoneController = TextEditingController();
  final _testTemplateIdController = TextEditingController();
  final _testTemplateDataController = TextEditingController(); // JSON key:value

  // ===== FORM GỬI THỬ NHANH (OA thường - KHÔNG cần Template) =====
  bool _isLoadingFollowers = false;
  bool _isSendingOaTest = false;
  List<dynamic> _followers = [];
  String? _selectedFollowerUserId;
  bool _useManualUserId = false;
  final _manualUserIdController = TextEditingController();
  final _oaTestTextController = TextEditingController(
    text: 'Đây là tin nhắn thử nghiệm từ App POS.',
  );

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _appSecretController.dispose();
    _oaIdController.dispose();
    _refreshTokenController.dispose();
    _appointmentTemplateController.dispose();
    _orderTemplateController.dispose();
    _tierTemplateController.dispose();
    _testPhoneController.dispose();
    _testTemplateIdController.dispose();
    _testTemplateDataController.dispose();
    _oaTestTextController.dispose();
    _manualUserIdController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchConfig(), _fetchLogs()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchConfig() async {
    try {
      final res = await http.get(
        Uri.parse(AppConfig().buildUrl('api/zalooa/config')),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _config = data;
          _appIdController.text = data['appId'] ?? '';
          _oaIdController.text = data['oaId'] ?? '';
          // AppSecret & Token không bao giờ trả về đầy đủ từ server vì lý do bảo mật
          _appSecretController.text = '';
          _refreshTokenController.text = '';

          _enableAppointmentReminder =
              data['enableAppointmentReminder'] ?? false;
          _appointmentTemplateController.text =
              data['appointmentReminderTemplateId'] ?? '';

          _enableOrderNotification = data['enableOrderNotification'] ?? false;
          _orderTemplateController.text =
              data['orderNotificationTemplateId'] ?? '';

          _enableTierUpgrade = data['enableTierUpgradeNotification'] ?? false;
          _tierTemplateController.text = data['tierUpgradeTemplateId'] ?? '';
        });
      }
    } catch (e) {
      _showSnack('Lỗi tải cấu hình Zalo OA: $e', isError: true);
    }
  }

  Future<void> _fetchLogs() async {
    try {
      final res = await http.get(
        Uri.parse(AppConfig().buildUrl('api/zalooa/logs?take=50')),
      );
      if (res.statusCode == 200) {
        setState(() => _logs = jsonDecode(res.body));
      }
    } catch (_) {
      // Không chặn UI nếu lỗi tải log
    }
  }

  Future<void> _saveConfig() async {
    if (_appIdController.text.trim().isEmpty ||
        _oaIdController.text.trim().isEmpty) {
      _showSnack('Vui lòng nhập đầy đủ App ID và OA ID', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final body = {
        "appId": _appIdController.text.trim(),
        "appSecret": _appSecretController.text.trim().isEmpty
            ? null
            : _appSecretController.text.trim(),
        "oaId": _oaIdController.text.trim(),
        "refreshToken": _refreshTokenController.text.trim().isEmpty
            ? null
            : _refreshTokenController.text.trim(),
        "enableAppointmentReminder": _enableAppointmentReminder,
        "appointmentReminderTemplateId": _appointmentTemplateController.text
            .trim(),
        "enableOrderNotification": _enableOrderNotification,
        "orderNotificationTemplateId": _orderTemplateController.text.trim(),
        "enableTierUpgradeNotification": _enableTierUpgrade,
        "tierUpgradeTemplateId": _tierTemplateController.text.trim(),
      };

      final res = await http.put(
        Uri.parse(AppConfig().buildUrl('api/zalooa/config')),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        _showSnack('Đã lưu cấu hình Zalo OA!', isError: false);
        await _fetchConfig();
      } else {
        throw Exception(jsonDecode(res.body)['message']);
      }
    } catch (e) {
      _showSnack(
        'Lỗi lưu cấu hình: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _checkConnection() async {
    setState(() => _isCheckingConnection = true);
    try {
      final res = await http.post(
        Uri.parse(AppConfig().buildUrl('api/zalooa/refresh-token')),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _showSnack(data['message'] ?? 'Kết nối thành công!', isError: false);
        await _fetchConfig();
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      _showSnack(
        'Kết nối thất bại: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isCheckingConnection = false);
    }
  }

  Future<void> _sendTestMessage() async {
    if (_testPhoneController.text.trim().isEmpty ||
        _testTemplateIdController.text.trim().isEmpty) {
      _showSnack('Vui lòng nhập số điện thoại và Template ID', isError: true);
      return;
    }

    Map<String, String> templateData = {};
    if (_testTemplateDataController.text.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(_testTemplateDataController.text.trim());
        templateData = Map<String, String>.from(
          decoded.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      } catch (_) {
        _showSnack('Dữ liệu Template (JSON) không hợp lệ', isError: true);
        return;
      }
    }

    setState(() => _isSendingTest = true);
    try {
      final res = await http.post(
        Uri.parse(AppConfig().buildUrl('api/zalooa/send-test')),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": _testPhoneController.text.trim(),
          "templateId": _testTemplateIdController.text.trim(),
          "templateData": templateData,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _showSnack(data['message'] ?? 'Đã gửi tin thử!', isError: false);
        await _fetchLogs();
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      _showSnack(
        'Gửi thất bại: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSendingTest = false);
    }
  }

  Future<void> _fetchFollowers() async {
    setState(() => _isLoadingFollowers = true);
    try {
      final res = await http.get(
        Uri.parse(AppConfig().buildUrl('api/zalooa/followers?count=30')),
      );
      if (res.statusCode == 200) {
        setState(() {
          _followers = jsonDecode(res.body);
          if (_followers.isNotEmpty) {
            _selectedFollowerUserId = _followers.first['userId'];
          }
        });
        if (_followers.isEmpty) {
          _showSnack(
            'Chưa có ai quan tâm (follow) OA của bạn. Hãy tự follow OA bằng Zalo cá nhân rồi thử lại.',
            isError: false,
          );
        }
      } else {
        throw Exception(jsonDecode(res.body)['message']);
      }
    } catch (e) {
      _showSnack(
        'Lỗi tải danh sách follower: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoadingFollowers = false);
    }
  }

  Future<void> _sendOaTestMessage() async {
    final userId = _useManualUserId
        ? _manualUserIdController.text.trim()
        : _selectedFollowerUserId;

    if (userId == null ||
        userId.isEmpty ||
        _oaTestTextController.text.trim().isEmpty) {
      _showSnack(
        'Vui lòng chọn/nhập người nhận và nhập nội dung',
        isError: true,
      );
      return;
    }

    setState(() => _isSendingOaTest = true);
    try {
      final res = await http.post(
        Uri.parse(AppConfig().buildUrl('api/zalooa/send-test-oa-message')),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "text": _oaTestTextController.text.trim(),
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _showSnack(data['message'] ?? 'Đã gửi tin thử!', isError: false);
        await _fetchLogs();
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      _showSnack(
        'Gửi thất bại: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSendingOaTest = false);
    }
  }

  // Thông báo dùng màu theo theme hệ thống khi thành công, đỏ khi lỗi, và
  // hiển thị kiểu mặc định (khít đáy màn hình) đồng nhất với các trang khác
  // trong app (quy ước áp dụng từ nay về sau).
  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    final color = isError
        ? Colors.redAccent
        : Theme.of(context).colorScheme.primary;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(themeColor),
              const SizedBox(height: 8),
              Text(
                'Kết nối Zalo Official Account để tự động gửi thông báo/nhắc lịch cho khách hàng qua Zalo ZNS.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const Divider(height: 32, color: Color(0xFFF1F5F9)),

              _buildConnectionStatusBanner(themeColor),
              const SizedBox(height: 24),

              _buildSectionTitle('1. THÔNG TIN ỨNG DỤNG ZALO'),
              const SizedBox(height: 12),
              _buildCredentialsForm(themeColor),

              const SizedBox(height: 32),
              _buildSectionTitle('2. TÍNH NĂNG TỰ ĐỘNG'),
              const SizedBox(height: 12),
              _buildFeatureToggles(themeColor),

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveConfig,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isSaving ? 'Đang lưu...' : 'Lưu cấu hình',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('3. GỬI THỬ NHANH (KHÔNG CẦN TEMPLATE)'),
              const SizedBox(height: 12),
              _buildOaQuickTestPanel(themeColor),

              const SizedBox(height: 32),
              _buildSectionTitle(
                '4. GỬI TIN THỬ ZNS (THEO SỐ ĐIỆN THOẠI + TEMPLATE)',
              ),
              const SizedBox(height: 12),
              _buildTestSendPanel(themeColor),

              const SizedBox(height: 32),
              _buildSectionTitle('5. LỊCH SỬ GỬI TIN GẦN ĐÂY'),
              const SizedBox(height: 12),
              _buildLogsTable(),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color themeColor) {
    return Row(
      children: [
        Icon(Icons.chat_bubble_rounded, color: themeColor, size: 22),
        const SizedBox(width: 10),
        const Text(
          'Kết nối Zalo Official Account (OA)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusBanner(Color themeColor) {
    final bool hasValidToken = _config?['hasValidToken'] == true;
    final bool isConfigured = _config?['isConfigured'] == true;
    final String? lastError = _config?['lastRefreshError'];
    final String? expiredAtRaw = _config?['tokenExpiredAt'];

    Color bgColor;
    Color fgColor;
    IconData icon;
    String statusText;

    if (!isConfigured) {
      bgColor = const Color(0xFFF1F5F9);
      fgColor = const Color(0xFF64748B);
      icon = Icons.info_outline_rounded;
      statusText = 'Chưa cấu hình Zalo OA';
    } else if (hasValidToken) {
      bgColor = const Color(0xFFD1FAE5);
      fgColor = const Color(0xFF065F46);
      icon = Icons.check_circle_rounded;
      statusText = 'Đã kết nối Zalo OA thành công';
    } else {
      bgColor = const Color(0xFFFEE2E2);
      fgColor = const Color(0xFFB91C1C);
      icon = Icons.error_outline_rounded;
      statusText = 'Chưa kết nối / Token đã hết hạn';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: fgColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                    fontSize: 13.5,
                  ),
                ),
                if (expiredAtRaw != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Token hết hạn: $expiredAtRaw (giờ UTC)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: fgColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                if (lastError != null && lastError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Lỗi gần nhất: $lastError',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: fgColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _isCheckingConnection ? null : _checkConnection,
            icon: _isCheckingConnection
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fgColor,
                    ),
                  )
                : Icon(Icons.refresh_rounded, size: 16, color: fgColor),
            label: Text(
              _isCheckingConnection ? 'Đang kiểm tra...' : 'Kiểm tra kết nối',
              style: TextStyle(
                fontSize: 12.5,
                color: fgColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(side: BorderSide(color: fgColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsForm(Color themeColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'App ID (*)',
                _appIdController,
                Icons.tag_rounded,
                themeColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'OA ID (*)',
                _oaIdController,
                Icons.storefront_rounded,
                themeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                'App Secret (để trống nếu không đổi)',
                _appSecretController,
                Icons.key_rounded,
                themeColor,
                obscure: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'Refresh Token (chỉ nhập khi kết nối lần đầu / đổi mới)',
                _refreshTokenController,
                Icons.vpn_key_rounded,
                themeColor,
                obscure: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'App Secret & Refresh Token lấy tại developers.zalo.me khi tạo App liên kết với OA. '
          'Xem chi tiết trong tệp HUONG_DAN_MERGE.md phần "Lấy Refresh Token lần đầu".',
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureToggles(Color themeColor) {
    return Column(
      children: [
        _buildFeatureRow(
          themeColor: themeColor,
          icon: Icons.event_available_rounded,
          title: 'Tự động nhắc lịch hẹn',
          subtitle:
              'Gửi ZNS nhắc khách hàng vào ngày có lịch hẹn (cần module Lịch hẹn).',
          value: _enableAppointmentReminder,
          onChanged: (v) => setState(() => _enableAppointmentReminder = v),
          templateController: _appointmentTemplateController,
        ),
        const SizedBox(height: 12),
        _buildFeatureRow(
          themeColor: themeColor,
          icon: Icons.receipt_long_rounded,
          title: 'Thông báo đơn hàng',
          subtitle: 'Gửi ZNS xác nhận đơn / cập nhật trạng thái đơn hàng.',
          value: _enableOrderNotification,
          onChanged: (v) => setState(() => _enableOrderNotification = v),
          templateController: _orderTemplateController,
        ),
        const SizedBox(height: 12),
        _buildFeatureRow(
          themeColor: themeColor,
          icon: Icons.stars_rounded,
          title: 'Thông báo lên hạng thành viên',
          subtitle: 'Gửi ZNS khi khách hàng đạt hạng thành viên mới.',
          value: _enableTierUpgrade,
          onChanged: (v) => setState(() => _enableTierUpgrade = v),
          templateController: _tierTemplateController,
        ),
      ],
    );
  }

  Widget _buildFeatureRow({
    required Color themeColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required TextEditingController templateController,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: themeColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                activeThumbColor: themeColor,
                onChanged: onChanged,
              ),
            ],
          ),
          if (value) ...[
            const SizedBox(height: 10),
            TextField(
              controller: templateController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Nhập ZNS Template ID (đã được Zalo duyệt)',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12.5,
                ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: themeColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOaQuickTestPanel(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: themeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Zalo chỉ cho gửi tin theo số điện thoại (ZNS) khi Template đã được duyệt. '
                  'Trong lúc chờ duyệt, bạn có thể test đường truyền bằng cách: (1) dùng Zalo cá nhân '
                  'follow OA của bạn, (2) bấm "Lấy danh sách người quan tâm" bên dưới, (3) chọn tên '
                  'mình và gửi thử.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.switch_account_rounded,
                size: 15,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Nhập User ID thủ công (nếu API lấy danh sách bị chặn quyền)',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const Spacer(),
              Switch(
                value: _useManualUserId,
                activeThumbColor: themeColor,
                onChanged: (v) => setState(() => _useManualUserId = v),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_useManualUserId)
            _buildTextField(
              'Zalo User ID',
              _manualUserIdController,
              Icons.badge_rounded,
              themeColor,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _followers.isEmpty
                      ? Text(
                          'Chưa tải danh sách người quan tâm OA.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: _selectedFollowerUserId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: themeColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          items: _followers.map<DropdownMenuItem<String>>((f) {
                            final name = f['displayName'] ?? '(Không tên)';
                            final id = f['userId'] as String;
                            return DropdownMenuItem(
                              value: id,
                              child: Text(
                                '$name  •  $id',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedFollowerUserId = v),
                        ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isLoadingFollowers ? null : _fetchFollowers,
                  icon: _isLoadingFollowers
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: themeColor,
                          ),
                        )
                      : Icon(Icons.group_rounded, size: 16, color: themeColor),
                  label: Text(
                    _followers.isEmpty
                        ? 'Lấy danh sách người quan tâm'
                        : 'Tải lại',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: themeColor),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          _buildTextField(
            'Nội dung tin nhắn',
            _oaTestTextController,
            Icons.message_rounded,
            themeColor,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed:
                  (_isSendingOaTest ||
                      (!_useManualUserId && _followers.isEmpty))
                  ? null
                  : _sendOaTestMessage,
              icon: _isSendingOaTest
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
              label: Text(
                _isSendingOaTest ? 'Đang gửi...' : 'Gửi thử ngay',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSendPanel(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Số điện thoại nhận thử',
                  _testPhoneController,
                  Icons.phone_rounded,
                  themeColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Template ID',
                  _testTemplateIdController,
                  Icons.description_rounded,
                  themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Dữ liệu Template (JSON), VD: {"customer_name":"Anh Nam","time":"15:00"}',
            _testTemplateDataController,
            Icons.data_object_rounded,
            themeColor,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSendingTest ? null : _sendTestMessage,
              icon: _isSendingTest
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
              label: Text(
                _isSendingTest ? 'Đang gửi...' : 'Gửi tin thử',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTable() {
    if (_logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Chưa có lịch sử gửi tin nào.',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            color: const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'SĐT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'LOẠI TIN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Text(
                    'GHI CHÚ / LỖI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'THỜI GIAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'TRẠNG THÁI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_logs.length, (index) {
            final log = _logs[index];
            final bool isSuccess = log['status'] == 'Success';
            final bool isFailed = log['status'] == 'Failed';

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      log['phone'] ?? '',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      log['messageType'] ?? '',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),

                  Expanded(
                    flex: 3,
                    child: Text(
                      log['errorMessage'] ?? log['zaloMsgId'] ?? '-',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      (log['createdAt'] ?? '')
                          .toString()
                          .replaceFirst('T', ' ')
                          .split('.')
                          .first,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? const Color(0xFFD1FAE5)
                            : (isFailed
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        log['status'] ?? '',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isSuccess
                              ? const Color(0xFF065F46)
                              : (isFailed
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color themeColor, {
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: themeColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
