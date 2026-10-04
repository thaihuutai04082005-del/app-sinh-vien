// Cấu hình Firebase của project `appsinhvien-810a2` (web + Android).
// apiKey của Firebase là định danh công khai, dữ liệu được bảo vệ bằng
// firestore.rules / storage.rules chứ không phải bằng việc giấu key.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError(
      'Chưa cấu hình Firebase cho $defaultTargetPlatform. '
      'Thêm app trên Firebase Console rồi cập nhật file này.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCbXKx79XxpVCjb8UliDxioFcUxf4Hxej0',
    appId: '1:654696345455:web:bf7f94f1b7818e5b2f829a',
    messagingSenderId: '654696345455',
    projectId: 'appsinhvien-810a2',
    authDomain: 'appsinhvien-810a2.firebaseapp.com',
    storageBucket: 'appsinhvien-810a2.firebasestorage.app',
    measurementId: 'G-NRPCL7PGJL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDA0j86EumsCZgCGHpx5YEPKfsVcWyX4qg',
    appId: '1:654696345455:android:0ed21eeb44d755022f829a',
    messagingSenderId: '654696345455',
    projectId: 'appsinhvien-810a2',
    storageBucket: 'appsinhvien-810a2.firebasestorage.app',
  );
}
