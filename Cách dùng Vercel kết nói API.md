Dưới đây là mã nguồn mẫu chi tiết giúp ứng dụng Flutter Mobile thực hiện gửi yêu cầu GET (Lấy dữ liệu) và POST (Gửi/Thêm dữ liệu) lên API Node.js đang chạy trên Vercel.

Bước 1: Khai báo thư viện http trong Flutter
Mở file pubspec.yaml trong dự án Flutter của bạn và thêm thư viện http:

YAML
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0  # Thêm dòng này
Sau đó chạy lệnh flutter pub get ở Terminal để tải gói về.

Bước 2: Viết mã nguồn Service kết nối API (api_service.dart)
Tạo một file mới tên là api_service.dart để chứa các hàm gọi API:

Dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Thay thế bằng Domain thực tế mà Vercel cấp cho Server Node.js của bạn
  static const String baseUrl = 'https://test-server-vercel.vercel.app';

  // -------------------------------------------------------------
  // 1. HÀM GET REQUEST: Lấy danh sách hoặc thông tin kiểm tra
  // -------------------------------------------------------------
  static Future<Map<String, dynamic>?> checkServerStatus() async {
    final url = Uri.parse('$baseUrl/');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Chuyển chuỗi JSON nhận được từ Vercel thành Map trong Dart
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Lỗi từ Server: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối HTTP GET: $e');
      return null;
    }
  }

  // -------------------------------------------------------------
  // 2. HÀM POST REQUEST: Gửi dữ liệu sinh viên lên Server
  // -------------------------------------------------------------
  static Future<bool> createStudent(String name, String studentId) async {
    final url = Uri.parse('$baseUrl/api/students');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        // Chuyển Map Dart thành chuỗi JSON để gửi đi
        body: jsonEncode({
          'name': name,
          'studentId': studentId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Thêm sinh viên thành công!');
        return true;
      } else {
        print('Thất bại: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Lỗi kết nối HTTP POST: $e');
      return false;
    }
  }
}
Bước 3: Sử dụng trên Giao diện Flutter (main.dart)
Ví dụ tích hợp các hàm gọi API vào một màn hình Flutter đơn giản:

Dart
import 'package:flutter/material.dart';
import 'api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _serverMessage = 'Chưa kiểm tra';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  // Hàm gọi API GET
  void _testServer() async {
    setState(() => _serverMessage = 'Đang tải...');
    final result = await ApiService.checkServerStatus();
    
    if (result != null) {
      setState(() {
        _serverMessage = result['message'] ?? 'Thành công';
      });
    } else {
      setState(() {
        _serverMessage = 'Không thể kết nối tới Server Vercel';
      });
    }
  }

  // Hàm gọi API POST
  void _submitData() async {
    final name = _nameController.text;
    final id = _idController.text;

    if (name.isEmpty || id.isEmpty) return;

    bool isSuccess = await ApiService.createStudent(name, id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSuccess ? 'Gửi thành công!' : 'Thất bại!'),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter & Vercel API Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Phần 1: Test GET
            ElevatedButton(
              onPressed: _testServer,
              child: const Text('Kiểm tra Server Vercel (GET)'),
            ),
            const SizedBox(height: 10),
            Text('Kết quả: $_serverMessage', style: const TextStyle(fontWeight: FontWeight.bold)),
            
            const Divider(height: 40),

            // Phần 2: Test POST
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên sinh viên'),
            ),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'Mã số sinh viên'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _submitData,
              child: const Text('Thêm Sinh Viên (POST)'),
            ),
          ],
        ),
      ),
    );
  }
}
Lưu ý quan trọng khi chạy App trên Android:
Nếu bạn chạy ứng dụng Android, hãy đảm bảo file android/app/src/main/AndroidManifest.xml đã được cấp quyền truy cập Internet:

XML
<uses-permission android:name="android.permission.INTERNET"/>
