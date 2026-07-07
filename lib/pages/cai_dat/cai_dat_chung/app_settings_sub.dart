import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/app_config.dart';
import 'package:http/http.dart' as http;

class AppSettingsSubPage extends StatefulWidget {
  const AppSettingsSubPage({super.key});

  @override
  State<AppSettingsSubPage> createState() => _AppSettingsSubPageState();
}

class _AppSettingsSubPageState extends State<AppSettingsSubPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  // ============== PHẦN MỚI: QUÉT MẠNG LAN ==============
  bool _isScanning = false;
  double _scanProgress = 0;
  final List<String> _foundHosts = [];

  @override
  void initState() {
    super.initState();
    _ipController.text = AppConfig().serverIp;
    _portController.text = AppConfig().serverPort;
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _saveSettings(Color activeThemeColor) {
    AppConfig().updateConfig(_ipController.text, _portController.text);
    AppSnackbar.show(
      context,
      'Đã lưu cấu hình máy chủ: ${AppConfig().baseUrl}',
      backgroundColor: activeThemeColor,
      icon: Icons.check_circle_rounded,
    );
  }

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

  Future<bool> _probeHost(String ip, String port) async {
    try {
      final uri = Uri.parse('http://$ip:$port/');
      final response = await http
          .get(uri)
          .timeout(const Duration(milliseconds: 400));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

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
      _showSnackBarSimple(
        'Không xác định được mạng LAN hiện tại của thiết bị',
        Colors.redAccent,
      );
      return;
    }

    const int totalHosts = 254;
    const int batchSize = 32;
    int completed = 0;

    for (int start = 1; start <= totalHosts; start += batchSize) {
      final end = (start + batchSize - 1).clamp(1, totalHosts);
      final batch = <Future<void>>[];

      for (int i = start; i <= end; i++) {
        final ip = '$prefix$i';
        batch.add(
          _probeHost(ip, port).then((ok) {
            completed++;
            if (mounted) setState(() => _scanProgress = completed / totalHosts);
            if (ok && mounted) setState(() => _foundHosts.add(ip));
          }),
        );
      }

      await Future.wait(batch);
      if (!mounted) return;
    }

    if (mounted) {
      setState(() => _isScanning = false);
      if (_foundHosts.isEmpty) {
        _showSnackBarSimple(
          'Không tìm thấy máy chủ POS nào trong mạng LAN',
          Colors.orange,
        );
      }
    }
  }

  void _showSnackBarSimple(String message, Color color) {
    AppSnackbar.show(
      context,
      message,
      backgroundColor: color,
      icon: color == Colors.redAccent
          ? Icons.error_outline_rounded
          : color == Colors.orange
          ? Icons.warning_amber_rounded
          : Icons.info_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicThemeColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dns_rounded, color: dynamicThemeColor, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Cấu hình Kết nối Máy chủ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Thiết lập thông số mạng địa phương (IP và Cổng kết nối) để ứng dụng POS kết nối đồng bộ dữ liệu tới hệ thống máy chủ cơ sở dữ liệu SQL Server Backend.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const Divider(height: 32, color: Color(0xFFF1F5F9)),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Địa chỉ IP / Tên máy chủ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ipController,
                    decoration: _inputDecoration(
                      'VD: 192.168.1.15 hoặc MAYCHUPOS',
                      dynamicThemeColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cổng kết nối (Port)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _portController,
                    decoration: _inputDecoration(
                      'Ví dụ: 5000',
                      dynamicThemeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ============== KHỐI QUÉT MẠNG LAN MỚI ==============
        Container(
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
                    child: Text(
                      'Tự động dò tìm máy chủ POS đang chạy trong cùng mạng LAN.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
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
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dynamicThemeColor,
                      side: BorderSide(color: dynamicThemeColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isScanning) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _scanProgress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: dynamicThemeColor,
                  ),
                ),
              ],
              if (_foundHosts.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Máy chủ tìm thấy:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
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
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? dynamicThemeColor : Colors.white,
                          border: Border.all(
                            color: selected
                                ? dynamicThemeColor
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
        ),

        const Spacer(),
        const Divider(height: 24, color: Color(0xFFF1F5F9)),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _ipController.text = AppConfig().serverIp;
                  _portController.text = AppConfig().serverPort;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Hủy thay đổi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _saveSettings(dynamicThemeColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: dynamicThemeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Lưu cấu hình',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, Color focusColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: focusColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
