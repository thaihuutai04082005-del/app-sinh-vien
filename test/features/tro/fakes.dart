import 'dart:async';
import 'dart:typed_data';

import 'package:app_sinh_vien/core/services/image_storage_service.dart';
import 'package:app_sinh_vien/features/auth/models/xac_thuc.dart';
import 'package:app_sinh_vien/features/auth/services/xac_thuc_service.dart';
import 'package:app_sinh_vien/features/tro/models/coc_truc_tiep.dart';
import 'package:app_sinh_vien/features/tro/models/danh_gia.dart';
import 'package:app_sinh_vien/features/tro/models/dat_coc.dart';
import 'package:app_sinh_vien/features/tro/models/khang_nghi.dart';
import 'package:app_sinh_vien/features/tro/models/nha_tro.dart';
import 'package:app_sinh_vien/features/tro/models/phong_tro.dart';
import 'package:app_sinh_vien/features/tro/models/thanh_toan.dart';
import 'package:app_sinh_vien/features/tro/models/thong_bao.dart';
import 'package:app_sinh_vien/features/tro/models/tin_nhan.dart';
import 'package:app_sinh_vien/features/tro/models/tro_config.dart';
import 'package:app_sinh_vien/features/tro/services/admin_service.dart';
import 'package:app_sinh_vien/features/tro/services/bao_cao_service.dart';
import 'package:app_sinh_vien/features/tro/services/chat_service.dart';
import 'package:app_sinh_vien/features/tro/services/coc_truc_tiep_service.dart';
import 'package:app_sinh_vien/features/tro/services/danh_gia_service.dart';
import 'package:app_sinh_vien/features/tro/services/dat_coc_service.dart';
import 'package:app_sinh_vien/features/tro/services/nha_tro_service.dart';
import 'package:app_sinh_vien/features/tro/services/thong_bao_service.dart';
import 'package:app_sinh_vien/features/tro/services/tro_dich_vu.dart';

/// Bộ dịch vụ giả cho widget test của module Tìm trọ: dữ liệu trong bộ nhớ, ghi lại các lời gọi.
class TroGia {
  TroGia({
    this.uid = 'sv',
    this.xacThuc = const XacThuc(sdt: '0902000002', sdtDaXacThuc: true),
  });

  final String uid;
  XacThuc xacThuc;
  List<NhaTro> nhaTro = [];
  List<PhongTro> phong = [];
  List<DatCoc> datCoc = [];
  List<TinNhan> tinNhan = [];
  Object? loiSanh;
  final goi = <String>[];
  final thamSo = <Map<String, dynamic>>[];
  ThongTinDatCoc thongTin = const ThongTinDatCoc(conHuyMienPhi: 2);

  TroDichVu get dv => TroDichVu(
    uid: uid,
    nhaTro: _NhaTroGia(this),
    datCoc: _DatCocGia(this),
    cocTrucTiep: _CocTrucTiepGia(),
    chat: _ChatGia(this),
    danhGia: _DanhGiaGia(),
    baoCao: _BaoCaoGia(),
    thongBao: _ThongBaoGia(),
    admin: _AdminGia(),
    xacThuc: _XacThucGia(this),
    storage: _StorageGia(),
  );
}

class _StorageGia implements ImageStorageService {
  @override
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async => 'https://cdn.test/$folder/$fileName';
}

class _XacThucGia implements XacThucService {
  _XacThucGia(this.g);

  final TroGia g;

  @override
  Stream<XacThuc> cuaToi(String uid) => Stream.value(g.xacThuc);
  @override
  Stream<QuyenAdmin> quyenAdmin(String uid) => Stream.value(const QuyenAdmin());
  @override
  Future<String> guiOtp(String sdt) async =>
      'Bản thử nghiệm: mã OTP là 123456.';
  @override
  Future<void> xacNhanOtp(String ma) async {}
  @override
  Future<void> guiDanhTinh({
    required String hoTen,
    required String soCccd,
  }) async {}
  @override
  Stream<List<(String, String, String)>> danhTinhChoDuyet() =>
      Stream.value(const []);
  @override
  Future<void> duyetDanhTinh(
    String uid, {
    required bool dongY,
    String? lyDo,
  }) async {}
}

class _NhaTroGia implements NhaTroService {
  _NhaTroGia(this.g);

  final TroGia g;

  Stream<T> _hoacLoi<T>(T Function() f) =>
      g.loiSanh != null ? Stream<T>.error(g.loiSanh!) : Stream.value(f());

  @override
  Stream<List<NhaTro>> nhaTroDangHien() => _hoacLoi(() => g.nhaTro);
  @override
  Stream<List<PhongTro>> phongConTrong() =>
      _hoacLoi(() => g.phong.where((p) => p.trangThai == 'available').toList());
  @override
  Stream<NhaTro?> nhaTro(String id) =>
      Stream.value(g.nhaTro.where((n) => n.id == id).firstOrNull);
  @override
  Stream<List<PhongTro>> phongHienThi(String nhaTroId) => Stream.value(
    g.phong
        .where(
          (p) =>
              p.nhaTroId == nhaTroId &&
              ['available', 'reserved', 'rented'].contains(p.trangThai),
        )
        .toList(),
  );
  @override
  Stream<PhongTro?> phong(String id) =>
      Stream.value(g.phong.where((p) => p.id == id).firstOrNull);
  @override
  Stream<ChiSoChu> chiSoChu(String chuTroId) =>
      Stream.value(const ChiSoChu(hoTen: 'Chủ trọ A', tyLeCamKet: 100));
  @override
  Future<String?> laySdtChuTro(String nhaTroId) async => '0901000001';
  @override
  Stream<bool> daLuu(String uid, String nhaTroId) => Stream.value(false);
  @override
  Stream<List<String>> nhaTroDaLuu(String uid) => Stream.value(const []);
  @override
  Future<void> luu(String uid, String nhaTroId, {required bool luu}) async =>
      g.goi.add('luu');
  @override
  Stream<List<NhaTro>> nhaTroCuaToi(String uid) =>
      Stream.value(g.nhaTro.where((n) => n.chuTroId == uid).toList());
  @override
  Stream<List<PhongTro>> phongCuaNha(String nhaTroId) =>
      Stream.value(g.phong.where((p) => p.nhaTroId == nhaTroId).toList());
  @override
  Future<String> luuNhapNhaTro(String? id, Map<String, dynamic> duLieu) async {
    g.goi.add('luuNhapNhaTro');
    g.thamSo.add(duLieu);
    return id ?? 'nha_moi';
  }

  @override
  Future<void> luuGiayTo(String nhaTroId, List<String> giayTo) async =>
      g.goi.add('luuGiayTo');
  @override
  Future<List<String>> docGiayTo(String nhaTroId) async => const [];
  @override
  Future<String> luuNhapPhong(String? id, Map<String, dynamic> duLieu) async {
    g.goi.add('luuNhapPhong');
    g.thamSo.add(duLieu);
    return id ?? 'phong_moi';
  }

  @override
  Future<void> xoaNhap(String col, String id) async => g.goi.add('xoaNhap');
  @override
  Future<void> thaoTac(String hanhDong, Map<String, dynamic> thamSo) async {
    g.goi.add(hanhDong);
    g.thamSo.add(thamSo);
  }
}

class _DatCocGia implements DatCocService {
  _DatCocGia(this.g);

  final TroGia g;

  @override
  Future<TroConfig> cauHinh() async => const TroConfig();
  @override
  Future<ThongTinDatCoc> thongTin() async => g.thongTin;
  @override
  Future<String> taoCoc({required String phongId, required DateTime t}) async {
    g.goi.add('taoCoc');
    g.thamSo.add({'phongId': phongId, 't': t});
    return 'coc_moi';
  }

  @override
  Stream<DatCoc?> datCoc(String id) =>
      Stream.value(g.datCoc.where((d) => d.id == id).firstOrNull);
  @override
  Stream<List<DatCoc>> cuaSinhVien(String uid) =>
      Stream.value(g.datCoc.where((d) => d.sinhVienId == uid).toList());
  @override
  Stream<List<DatCoc>> cuaChuTro(String uid) =>
      Stream.value(g.datCoc.where((d) => d.chuTroId == uid).toList());
  @override
  Stream<KhoanTien?> khoanTien(String datCocId) =>
      Stream.value(const KhoanTien(trangThai: 'dang_giu', soTien: 1000000));
  @override
  Stream<ViChuTro> vi(String uid) => Stream.value(const ViChuTro());
  @override
  Future<void> xuLyHan(String datCocId) async => g.goi.add('xuLyHan');
  @override
  Future<void> thaoTac(
    String datCocId,
    int version,
    Map<String, dynamic> su,
  ) async {
    g.goi.add('thaoTac:${su['loai']}');
    g.thamSo.add({'version': version, ...su});
  }

  @override
  Future<void> thanhToan(String datCocId, String ketQua) async =>
      g.goi.add('thanhToan:$ketQua');
}

class _CocTrucTiepGia implements CocTrucTiepService {
  @override
  Stream<List<CocTrucTiep>> cuaChuTro(String uid) => Stream.value(const []);
  @override
  Stream<CocTrucTiep?> theoId(String id) => Stream.value(null);
  @override
  Stream<List<CocTrucTiep>> cuaNguoiCoc(String sdt) => Stream.value(const []);
  @override
  Future<void> xacNhan({
    required String phongId,
    required DateTime ngayNhanDuKien,
    String? sdtNguoiCoc,
  }) async {}
  @override
  Future<void> capNhat(
    String id,
    String ketQua, {
    DateTime? ngayNhanDuKien,
  }) async {}
  @override
  Future<void> toiDaThue(String id) async {}
}

class _ChatGia implements ChatService {
  _ChatGia(this.g);

  final TroGia g;

  @override
  Stream<List<CuocTroChuyen>> cuocCuaToi(String uid) => Stream.value(const []);
  @override
  Stream<CuocTroChuyen?> cuoc(String chatId) => Stream.value(
    CuocTroChuyen(
      id: chatId,
      thanhVien: chatId.split('_'),
      ten: const {'chu': 'Chủ trọ A', 'sv': 'Sinh viên B'},
    ),
  );
  @override
  Stream<List<TinNhan>> tinNhan(String chatId) => Stream.value(g.tinNhan);
  @override
  Future<String?> gui(
    String nguoiNhan, {
    String? noiDung,
    String? phongId,
    String? anh,
  }) async {
    g.goi.add(phongId != null ? 'gui_the' : 'gui');
    return noiDung != null && noiDung.toLowerCase().contains('chuyển khoản')
        ? canhBaoLuaDao
        : null;
  }

  @override
  Future<void> daXem(String chatId) async => g.goi.add('daXem');
  @override
  Future<void> chan(String chatId, {required bool chan}) async {}
}

class _DanhGiaGia implements DanhGiaService {
  @override
  Stream<List<DanhGia>> cuaNhaTro(String nhaTroId) => Stream.value(const []);
  @override
  Stream<DanhGia?> theoNguon(String loai, String id) => Stream.value(null);
  @override
  Future<void> gui({
    required String loaiNguon,
    required String idNguon,
    required Map<String, int> diem,
    required List<String> the,
    required String nhanXet,
    required List<String> anh,
  }) async {}
  @override
  Future<void> traLoi(String danhGiaId, String noiDung) async {}
}

class _BaoCaoGia implements BaoCaoService {
  @override
  Future<void> baoCao({
    required String loai,
    required String id,
    String? chatId,
    required String lyDo,
    String ghiChu = '',
    List<String> tieuChiSai = const [],
    DateTime? thoiDiemXayRa,
    String? datCocId,
  }) async {}
  @override
  Stream<List<ViPham>> viPhamCuaToi(String uid) => Stream.value(const []);
  @override
  Stream<List<KhangNghi>> khangNghiCuaToi(String uid) => Stream.value(const []);
  @override
  Stream<Map<String, DateTime?>> khoaCuaToi(String khoa) =>
      Stream.value(const {});
  @override
  Future<void> khangNghi({
    required String loai,
    required String id,
    String? col,
    required String lyDo,
    List<String> bangChung = const [],
  }) async {}
}

class _ThongBaoGia implements ThongBaoService {
  @override
  Stream<List<ThongBao>> cuaToi(String uid) => Stream.value(const []);
  @override
  Future<void> daDoc(String id) async {}
  @override
  Stream<Map<String, bool>> caiDat(String uid) => Stream.value(const {});
  @override
  Future<void> doiCaiDat(String uid, String nhom, bool bat) async {}
}

class _AdminGia implements AdminTroService {
  @override
  Stream<List<ViecAdmin>> hangCho() => Stream.value(const []);
  @override
  Future<List<String>> giayTo(String nhaTroId) async => const [];
  @override
  Future<void> goi(String hanhDong, Map<String, dynamic> thamSo) async {}
}
