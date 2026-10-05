import 'package:cloud_firestore/cloud_firestore.dart';

/// Người dùng chung cho mọi module — collection `users` (mục 7.3).
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatarUrl = '',
    this.role = 'student',
    this.schoolEmail = '',
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;

  /// "student" | "landlord" | "shop_owner" | "driver"...
  final String role;
  final String schoolEmail;
  final DateTime? createdAt;

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        avatarUrl: map['avatarUrl'] as String? ?? '',
        role: map['role'] as String? ?? 'student',
        schoolEmail: map['schoolEmail'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  /// Khi tạo mới, `createdAt` do server đặt để thống nhất giờ.
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'role': role,
        'schoolEmail': schoolEmail,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
