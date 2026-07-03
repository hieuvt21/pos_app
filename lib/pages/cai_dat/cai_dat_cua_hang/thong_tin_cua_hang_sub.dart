import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_storage.dart';
import 'package:window_manager/window_manager.dart';
// Lưu ý: Bạn cần thêm thư viện file_picker vào file pubspec.yaml bằng lệnh: flutter pub add file_picker
import 'package:file_picker/file_picker.dart';

class ThongTinCuaHangSubPage extends StatefulWidget {
  const ThongTinCuaHangSubPage({super.key});

  @override
  State<ThongTinCuaHangSubPage> createState() => _ThongTinCuaHangSubPageState();
}

class _ThongTinCuaHangSubPageState extends State<ThongTinCuaHangSubPage> {
  // Controllers cho cấu hình App
  final _appNameController = TextEditingController();
  final _widgetTitleController = TextEditingController();
  String _selectedWidgetIcon = "storefront_rounded";

  // Controllers cho cấu hình Cửa hàng
  final _shopNameController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopEmailController = TextEditingController();
  final _shopLogoController = TextEditingController();
  final _shopTaxCodeController = TextEditingController();
  final _shopWebsiteController = TextEditingController();
  final _invoiceFooterController = TextEditingController();

  // Đề xuất giới hạn ký tự tối đa cho tiêu đề Widget để không vỡ thanh Sidebar rộng 240px
  final int _maxWidgetTitleLength = 18;

  // Bản đồ Icon mẫu đa dạng theo các ngành nghề phổ biến khác nhau
  final Map<String, Map<String, dynamic>> _industryIcons = {
    'storefront_rounded': {
      'icon': Icons.storefront_rounded,
      'label': 'Tạp hóa / POS',
    },
    'restaurant_rounded': {
      'icon': Icons.restaurant_rounded,
      'label': 'Ẩm thực / F&B',
    },
    'coffee_rounded': {
      'icon': Icons.coffee_rounded,
      'label': 'Cà phê / Trà sữa',
    },
    'checkroom_rounded': {
      'icon': Icons.checkroom_rounded,
      'label': 'Thời trang / May mặc',
    },
    'spa_rounded': {
      'icon': Icons.spa_rounded,
      'label': 'Spa / Mỹ phẩm / Làm đẹp',
    },
    'local_pharmacy_rounded': {
      'icon': Icons.local_pharmacy_rounded,
      'label': 'Y tế / Nhà thuốc',
    },
    'computer_rounded': {
      'icon': Icons.computer_rounded,
      'label': 'Máy tính / Linh kiện',
    },
    'build_rounded': {
      'icon': Icons.build_rounded,
      'label': 'Sửa chữa / Cơ khí',
    },
    'fitness_center_rounded': {
      'icon': Icons.fitness_center_rounded,
      'label': 'Phòng Gym / Thể thao',
    },
    'star_rounded': {'icon': Icons.star_rounded, 'label': 'Khác / Thương hiệu'},
  };

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu từ local storage lên biểu mẫu form
    _appNameController.text = AppStorage.getAppName();
    _widgetTitleController.text = AppStorage.getWidgetTitle();
    _selectedWidgetIcon = AppStorage.getWidgetIcon();

    _shopNameController.text = AppStorage.getShopName();
    _shopPhoneController.text = AppStorage.getShopPhone();
    _shopAddressController.text = AppStorage.getShopAddress();
    _shopEmailController.text = AppStorage.getShopEmail();
    _shopLogoController.text = AppStorage.getShopLogo();
    _shopTaxCodeController.text = AppStorage.getShopTaxCode();
    _shopWebsiteController.text = AppStorage.getShopWebsite();
    _invoiceFooterController.text = AppStorage.getInvoiceFooter();
  }

  // Hàm chọn logo trực tiếp từ máy tính (Desktop Windows/Mac)
  Future<void> _pickLogoImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'webp'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _shopLogoController.text = result.files.single.path!;
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi chọn file: $e");
    }
  }

  Future<void> _saveConfig() async {
    // Ràng buộc giới hạn độ dài ký tự của tiêu đề Widget trước khi lưu
    String widgetTitle = _widgetTitleController.text.trim();
    if (widgetTitle.length > _maxWidgetTitleLength) {
      widgetTitle = widgetTitle.substring(0, _maxWidgetTitleLength);
    }

    // Lưu trữ cấu hình App xuống vùng nhớ local
    await AppStorage.saveAppName(_appNameController.text.trim());
    await AppStorage.saveWidgetTitle(widgetTitle);
    await AppStorage.saveWidgetIcon(_selectedWidgetIcon);

    // Lưu trữ cấu hình thông tin cửa hàng phục vụ in hóa đơn
    await AppStorage.saveShopName(_shopNameController.text.trim());
    await AppStorage.saveShopPhone(_shopPhoneController.text.trim());
    await AppStorage.saveShopAddress(_shopAddressController.text.trim());
    await AppStorage.saveShopEmail(_shopEmailController.text.trim());
    await AppStorage.saveShopLogo(_shopLogoController.text.trim());
    await AppStorage.saveShopTaxCode(_shopTaxCodeController.text.trim());
    await AppStorage.saveShopWebsite(_shopWebsiteController.text.trim());
    await AppStorage.saveInvoiceFooter(_invoiceFooterController.text.trim());

    // Cập nhật lập tức tiêu đề thanh Window vật lý phía trên ứng dụng
    await windowManager.setTitle(_appNameController.text.trim());

    if (!mounted) return;
    final dynamicThemeColor = Theme.of(context).colorScheme.primary;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã cập nhật dữ liệu hệ thống thành công!'),
        backgroundColor: dynamicThemeColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header nút hành động lưu cấu hình
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'THÔNG TIN CỬA HÀNG & ỨNG DỤNG',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _saveConfig,
                icon: const Icon(
                  Icons.save_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Lưu cấu hình',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Expanded(
            child: ListView(
              children: [
                // === PHẦN 1: TÙY CHỌN ỨNG DỤNG (APP) ===
                _buildSectionHeader('1. TÙY CHỌN HIỂN THỊ APP'),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Tên ứng dụng',
                        _appNameController,
                        Icons.desktop_windows_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Tiêu đề Widget Sidebar (Tối đa $_maxWidgetTitleLength ký tự)',
                        _widgetTitleController,
                        Icons.line_weight_rounded,
                        maxLength: _maxWidgetTitleLength,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Icon Sidebar:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _industryIcons.entries.map((entry) {
                    bool isSelected = _selectedWidgetIcon == entry.key;
                    return Tooltip(
                      message: entry.value['label'],
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              entry.value['icon'],
                              size: 18,
                              color: isSelected ? Colors.white : primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.value['label'],
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        backgroundColor: Colors.grey[100],
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedWidgetIcon = entry.key);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // === PHẦN 2: THÔNG TIN CHI TIẾT CỬA HÀNG ===
                _buildSectionHeader('2. THÔNG TIN CỬA HÀNG'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Tên cửa hàng',
                        _shopNameController,
                        Icons.store_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Số điện thoại',
                        _shopPhoneController,
                        Icons.phone_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Địa chỉ',
                  _shopAddressController,
                  Icons.location_on_rounded,
                ),
                const SizedBox(height: 16),

                // Khu vực xử lý LOGO cửa hàng nâng cao
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logo',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _shopLogoController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'Chưa có logo nào được chọn...',
                              prefixIcon: const Icon(
                                Icons.image_rounded,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.folder_open_rounded,
                                  color: primaryColor,
                                ),
                                onPressed: _pickLogoImage,
                                tooltip: 'Tải ảnh logo lên',
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
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
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '💡 Đề xuất kích thước: 150x150 px (Tỷ lệ vuông 1:1, ảnh nền trong suốt PNG để in hóa đơn đẹp nhất).',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Widget Preview nhỏ hiển thị logo đã chọn kiểm tra trực quan
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child:
                          _shopLogoController.text.isNotEmpty &&
                              File(_shopLogoController.text).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_shopLogoController.text),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.store_mall_directory_rounded,
                              color: Colors.grey,
                              size: 30,
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Email',
                        _shopEmailController,
                        Icons.email_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Mã số thuế',
                        _shopTaxCodeController,
                        Icons.badge_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Website',
                  _shopWebsiteController,
                  Icons.language_rounded,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Thông tin chân hóa đơn khi in',
                  _invoiceFooterController,
                  Icons.short_text_rounded,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          buildCounter: maxLength != null
              ? (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) =>
                    null // Ẩn bộ đếm chữ mặc định nhìn rối mắt
              : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFEA580C),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
