import 'package:flutter/material.dart';

/// Màu sắc, kích thước, chuỗi cố định dùng chung toàn app.
class AppColors {
  static const Color primary = Color(0xFF1E88E5);
  static const Color accent = Color(0xFFFF7043);
  static const Color background = Color(0xFFF5F7FA);
}

class AppSizes {
  static const double padding = 16;
  static const double radius = 12;
}

class AppStrings {
  static const String appName = 'App Sinh Viên';
}

/// Tên collection Firestore (mục 7.2/7.3 của tài liệu mô hình).
/// Không tự đặt tên khác — mọi thành viên dùng chung các hằng số này.
class Collections {
  static const String users = 'users';
  static const String phongTro = 'phong_tro';
  static const String quanAn = 'quan_an';
  static const String menuItems = 'menu_items';
  static const String xeDonTro = 'xe_don_tro';
  static const String bookingXe = 'booking_xe';
  static const String products = 'products';
  static const String orders = 'orders';
  static const String vouchers = 'vouchers';
  static const String follows = 'follows';
  static const String vuiChoi = 'vui_choi';
  static const String reviews = 'reviews';
  static const String checkins = 'checkins';
  static const String chats = 'chats';
  static const String messages = 'messages';
}
