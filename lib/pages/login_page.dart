import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/widgets/app_input_decoration.dart';
import '../core/widgets/app_snackbar.dart';
import '../services/app_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ============== PHẦN MỚI: CẤU HÌNH KẾT NỐI MÁY CHỦ ==============
  bool _isConnectionPanelOpen = false;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  bool _isScanning = false;
  double _scanProgress = 0; // 0 -> 1
  final List<String> _foundHosts = [];

  @override
  void initState() {
    super.initState();
    _ipController.text = AppConfig().serverIp;
    _portController.text = AppConfig().serverPort;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _saveConnectionConfig() {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    if (ip.isEmpty || port.isEmpty) {
      _showSnackBar(
        'Vui lòng nhập đầy đủ IP/Tên máy chủ và Cổng',
        Colors.redAccent,
      );
      return;
    }
    AppConfig().updateConfig(ip, port);
    _showSnackBar(
      'Đã áp dụng máy chủ: ${AppConfig().baseUrl}',
      const Color(0xFF10B981),
    );
  }

  // Lấy prefix subnet hiện tại của máy khách, ví dụ "192.168.1."
  Future<String?> _getLocalSubnetPrefix() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final itf in interfaces) {
        for (final addr in itf.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              ip.startsWith('172.')) {
            final parts = ip.split('.');
            if (parts.length == 4) {
              return '${parts[0]}.${parts[1]}.${parts[2]}.';
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // Quét toàn bộ dải mạng LAN (1 -> 254) tìm máy chủ đang chạy đúng cổng POS
  Future<void> _scanLanForServers() async {
    final port = _portController.text.trim().isEmpty
        ? '5000'
        : _portController.text.trim();

    setState(() {
      _isScanning = true;
      _scanProgress = 0;
      _foundHosts.clear();
    });

    final prefix = await _getLocalSubnetPrefix();
    if (prefix == null) {
      setState(() => _isScanning = false);
      _showSnackBar(
        'Không xác định được mạng LAN hiện tại của thiết bị',
        Colors.redAccent,
      );
      return;
    }

    const int totalHosts = 254;
    const int batchSize = 32; // quét song song theo từng đợt để không treo máy
    int completed = 0;

    for (int start = 1; start <= totalHosts; start += batchSize) {
      final end = (start + batchSize - 1).clamp(1, totalHosts);
      final batch = <Future<void>>[];

      for (int i = start; i <= end; i++) {
        final ip = '$prefix$i';
        batch.add(
          _probeHost(ip, port).then((ok) {
            completed++;
            if (mounted) {
              setState(() => _scanProgress = completed / totalHosts);
            }
            if (ok && mounted) {
              setState(() => _foundHosts.add(ip));
            }
          }),
        );
      }

      await Future.wait(batch);
      if (!mounted) return;
    }

    if (mounted) {
      setState(() => _isScanning = false);
      if (_foundHosts.isEmpty) {
        _showSnackBar(
          'Không tìm thấy máy chủ POS nào trong mạng LAN',
          Colors.orange,
        );
      }
    }
  }

  // Thử kết nối nhanh tới 1 IP, coi là "máy chủ POS" nếu trả lời được trong thời gian ngắn
  Future<bool> _probeHost(String ip, String port) async {
    try {
      final uri = Uri.parse('http://$ip:$port/');
      final response = await http
          .get(uri)
          .timeout(const Duration(milliseconds: 400));
      // Server gốc của bạn (Program.cs) trả về chuỗi text khi gọi GET "/"
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleLogin() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar(
        'Vui lòng nhập đầy đủ tài khoản và mật khẩu',
        Colors.redAccent,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String loginUrl = AppConfig().buildUrl('api/auth/login');

      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"tenDangNhap": username, "matKhau": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['token'];
        String hoTen = data['user']['hoTen'];
        String userId = data['user']['id'].toString();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_name', hoTen);
        await prefs.setString('user_id', userId);

        _showSnackBar(
          'Đăng nhập thành công! Chào $hoTen',
          const Color(0xFF10B981),
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(
          errorData['message'] ?? 'Đăng nhập thất bại',
          Colors.redAccent,
        );
      }
    } catch (e) {
      _showSnackBar('Không thể kết nối đến máy chủ: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    AppSnackbar.show(
      context,
      message,
      backgroundColor: backgroundColor,
      icon: backgroundColor == Colors.orange
          ? Icons.warning_amber_rounded
          : backgroundColor == Colors.redAccent
          ? Icons.error_outline_rounded
          : Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'HỆ THỐNG POS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Đăng nhập tài khoản để tiếp tục',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Tên đăng nhập',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _usernameController,
                  decoration: _inputDecoration(
                    'Nhập tài khoản...',
                    Icons.person,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Mật khẩu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('Nhập mật khẩu...', Icons.lock)
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF94A3B8),
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ĐĂNG NHẬP',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 8),
                _buildConnectionPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============== UI PHẦN "KẾT NỐI" CÓ THỂ ẨN/MỞ ==============
  Widget _buildConnectionPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () =>
              setState(() => _isConnectionPanelOpen = !_isConnectionPanelOpen),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.dns_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Kết nối',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  AppConfig().baseUrl,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(width: 6),
                Icon(
                  _isConnectionPanelOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isConnectionPanelOpen
              ? _buildConnectionForm()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildConnectionForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 4),
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
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IP / Tên máy chủ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _ipController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _connInputDecoration(
                        'VD: 192.168.1.15 hoặc MAYCHUPOS',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cổng',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _portController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _connInputDecoration('5000'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isScanning ? null : _scanLanForServers,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find_rounded, size: 16),
                  label: Text(
                    _isScanning ? 'Đang quét...' : 'Quét mạng LAN',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveConnectionConfig,
                  icon: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Áp dụng',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          if (_isScanning) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _scanProgress,
                minHeight: 4,
                backgroundColor: const Color(0xFFE2E8F0),
                color: const Color(0xFFEA580C),
              ),
            ),
          ],
          if (_foundHosts.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Máy chủ tìm thấy:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _foundHosts.map((ip) {
                final selected = _ipController.text.trim() == ip;
                return InkWell(
                  onTap: () => setState(() => _ipController.text = ip),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFEA580C) : Colors.white,
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFEA580C)
                            : const Color(0xFFE2E8F0),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dns_rounded,
                          size: 13,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          ip,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _connInputDecoration(String hint) {
    return appInputDecoration(
      hint: hint,
      focusColor: const Color(0xFFEA580C),
      dense: true,
      filled: true,
      fillColor: Colors.white,
    ).copyWith(
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return appInputDecoration(
      hint: hint,
      focusColor: const Color(0xFFEA580C),
      icon: icon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
    ).copyWith(
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }
}
