{{flutter_js}}
{{flutter_build_config}}

// Mỗi lần build, main.dart.js có link mới (?v=...) nên trình duyệt không thể
// dùng lại bản cũ đã lưu: deploy xong là người dùng thấy bản mới ngay.
for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) {
    build.mainJsPath += "?v=" + {{flutter_service_worker_version}};
  }
}

_flutter.loader.load();
