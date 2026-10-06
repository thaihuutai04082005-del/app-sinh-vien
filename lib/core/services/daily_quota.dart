import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

class QuotaException implements Exception {
  const QuotaException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Hạn mức chống spam cho mỗi tài khoản, đếm theo ngày (UTC) trong `quota/{uid}`.
/// Số liệu phải khớp với `firestore.rules` và `storage.rules`: rules mới là nơi
/// chặn thật, kiểm tra ở đây chỉ để báo lỗi dễ hiểu cho người dùng.
class DailyQuota {
  DailyQuota([this._firestore, this._auth]);

  static const maxPosts = 10;
  static const maxUploads = 30;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  Future<String>? _anonymousSignIn;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  static int get today =>
      DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  /// uid của tài khoản đang đăng nhập. Nếu chưa đăng nhập thì dùng tài khoản ẩn
  /// danh; nhiều lượt upload chạy song song chỉ đăng nhập ẩn danh một lần.
  /// Không lưu lại uid của tài khoản đã đăng nhập nên đổi tài khoản vẫn đúng.
  Future<String> _uid() async {
    final auth = _auth ?? FirebaseAuth.instance;
    final current = auth.currentUser;
    if (current != null) return current.uid;

    final pending = _anonymousSignIn ??= _signInAnonymously(auth);
    try {
      return await pending;
    } catch (_) {
      _anonymousSignIn = null;
      rethrow;
    }
  }

  Future<String> _signInAnonymously(FirebaseAuth auth) async {
    final user = (await auth.signInAnonymously()).user;
    if (user == null) throw const QuotaException('Không đăng nhập được.');
    return user.uid;
  }

  /// Chỉ để test: uid mà các lượt đăng/upload sẽ dùng.
  @visibleForTesting
  Future<String> uidForTest() => _uid();

  /// Giữ chỗ 1 lượt upload; trả về đường dẫn file `{folder}/{uid}/{day}_{n}.{ext}`.
  Future<String> reserveUploadPath(String folder, String ext) async {
    final uid = await _uid();
    final day = today;
    final index = await _increment(uid, day, 'uploads', maxUploads);
    return '$folder/$uid/${day}_$index.$ext';
  }

  /// Tạo document trong [collection] cùng lúc tăng bộ đếm bài đăng.
  /// [build] nhận uid của người đăng và trả về dữ liệu document.
  Future<({String id, Map<String, dynamic> data})> createPost(
    String collection,
    Map<String, dynamic> Function(String uid) build,
  ) async {
    final uid = await _uid();
    final day = today;
    final data = build(uid);
    final index = await _increment(
      uid,
      day,
      'posts',
      maxPosts,
      collection: collection,
      data: data,
    );
    return (id: _postId(uid, day, index), data: data);
  }

  Future<int> _increment(
    String uid,
    int day,
    String field,
    int max, {
    String? collection,
    Map<String, dynamic>? data,
  }) {
    final quotaRef = _db.collection(Collections.quota).doc(uid);
    return _db.runTransaction((tx) async {
      final snapshot = await tx.get(quotaRef);
      final current = snapshot.data();
      final sameDay = current != null && current['day'] == day;
      final posts = sameDay ? (current['posts'] as num).toInt() : 0;
      final uploads = sameDay ? (current['uploads'] as num).toInt() : 0;
      final next = (field == 'posts' ? posts : uploads) + 1;
      if (next > max) {
        throw QuotaException(
          field == 'posts'
              ? 'Mỗi ngày chỉ được đăng tối đa $max tin.'
              : 'Mỗi ngày chỉ được tải lên tối đa $max ảnh/video.',
        );
      }
      tx.set(quotaRef, {
        'day': day,
        'posts': field == 'posts' ? next : posts,
        'uploads': field == 'uploads' ? next : uploads,
      });
      if (collection != null) {
        tx.set(_db.collection(collection).doc(_postId(uid, day, next)), {
          ...?data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return next;
    });
  }

  /// 1 lượt đếm chỉ ứng với đúng 1 id tin (firestore.rules kiểm tra lại).
  static String _postId(String uid, int day, int index) =>
      '${uid}_${day}_$index';
}
