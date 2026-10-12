import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Chạy app với Firebase Emulator (máy mình, không đụng dữ liệu thật):
///   flutter run -d chrome --dart-define=EMULATOR=true
/// Bật emulator trước: firebase emulators:start --only auth,firestore,functions,storage
const dungEmulator = bool.fromEnvironment('EMULATOR');

Future<void> ketNoiEmulator({String host = '127.0.0.1'}) async {
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
}
