import 'package:app_sinh_vien/features/tro/models/nha_tro.dart';
import 'package:app_sinh_vien/features/tro/models/phong_tro.dart';
import 'package:app_sinh_vien/features/tro/models/tro_filter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

NhaTro nha(
  String id, {
  String ten = 'Nhà trọ',
  String diaChi = '',
  String loaiHinh = 'phong',
  NoiQuy? noiQuy,
  List<String> tienIch = const [],
  double lat = 10.46,
  double lng = 105.63,
  int soPhongTrong = 1,
  double? diem,
}) => NhaTro(
  id: id,
  chuTroId: 'c',
  ten: ten,
  diaChi: diaChi,
  loaiHinh: loaiHinh,
  noiQuy: noiQuy ?? const NoiQuy(gioGiac: 'tu_do', thuCung: false, oQuaDem: false, baoTruocTuan: 1),
  tienIchChung: tienIch,
  viTri: GeoPoint(lat, lng),
  trangThai: 'active',
  soLieu: SoLieuNhaTro(soPhongTrong: soPhongTrong, diem: diem),
);

PhongTro phong(String id, String nhaTroId, {num gia = 1500000, bool? coGac, List<String> tienIch = const [], String trangThai = 'available'}) =>
    PhongTro(id: id, nhaTroId: nhaTroId, chuTroId: 'c', ten: id, giaThue: gia, coGac: coGac, tienIch: tienIch, trangThai: trangThai);

NoiQuy nq({String gio = 'tu_do', String? dong, bool thuCung = false, bool oQuaDem = false, int tuan = 1}) =>
    NoiQuy(gioGiac: gio, gioDongCua: dong, thuCung: thuCung, oQuaDem: oQuaDem, baoTruocTuan: tuan);

List<String> ids(KetQuaLoc k) => [for (final x in k.danhSach) x.nhaTro.id];

void main() {
  test('bỏ dấu: "Nguyễn Huệ" ↔ "nguyen hue", ký tự đặc biệt không làm lỗi', () {
    expect(boDau('Đường Nguyễn Huệ (P.1)*'), 'duong nguyen hue p 1');
    expect(boDau('(*.'), '');
  });

  test('gõ "nguyen hue" + điểm gốc + bán kính 1 km: đúng nhà trọ trên đường Nguyễn Huệ trong 1 km', () {
    const goc = DiemGoc(lat: 10.46, lng: 105.63);
    final ds = [
      nha('gan', diaChi: '12 Nguyễn Huệ, Phường 1'),
      nha('xa', diaChi: '90 Nguyễn Huệ', lat: 10.50), // ~4,4 km
      nha('khac_duong', diaChi: '5 Lê Lợi'),
    ];
    final p = [phong('1', 'gan'), phong('2', 'xa'), phong('3', 'khac_duong')];
    final kq = locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter(tuKhoa: 'nguyen hue', banKinhMet: 1000), goc: goc);
    expect(ids(kq), ['gan']);
  });

  test('ký tự đặc biệt trong ô tìm không làm lỗi', () {
    final kq = locNhaTro(nhaTro: [nha('a')], phong: [phong('1', 'a')], filter: const TroFilter(tuKhoa: '(*.'));
    expect(ids(kq), ['a']);
  });

  test('nhà trọ chỉ hiện khi có ≥ 1 phòng "Còn trống" thỏa lọc; phòng phù hợp được giữ lại', () {
    final kq = locNhaTro(
      nhaTro: [nha('a'), nha('b')],
      phong: [phong('a1', 'a', gia: 1200000), phong('a2', 'a', gia: 2500000), phong('b1', 'b', trangThai: 'reserved')],
      filter: const TroFilter(giaDen: 2000000),
    );
    expect(ids(kq), ['a']);
    expect(kq.danhSach.single.phongPhuHop.map((p) => p.id), ['a1']);
    expect(kq.soPhong, 1);
  });

  test('lọc "Tự do 24/24": chỉ ra trọ tự do', () {
    final ds = [nha('tudo'), nha('d22', noiQuy: nq(gio: 'gioi_han', dong: '22:00'))];
    final p = [phong('1', 'tudo'), phong('2', 'd22')];
    expect(ids(locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter(tuDo24: true))), ['tudo']);
  });

  test('"Về muộn được tới ít nhất 23:00": ra trọ tự do và trọ đóng cửa 23:00, không ra trọ 22:00', () {
    final ds = [
      nha('tudo'),
      nha('d23', noiQuy: nq(gio: 'gioi_han', dong: '23:00')),
      nha('d22', noiQuy: nq(gio: 'gioi_han', dong: '22:00')),
      nha('d0030', noiQuy: nq(gio: 'gioi_han', dong: '00:30')),
    ];
    final p = [for (final n in ds) phong('p_${n.id}', n.id)];
    final kq = ids(locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter(veMuonToi: '23:00')));
    expect(kq.toSet(), {'tudo', 'd23', 'd0030'});
  });

  test('"Cho phép nuôi thú cưng" / "Cho ở qua đêm": chỉ ra trọ khai "Cho phép"', () {
    final ds = [nha('co', noiQuy: nq(thuCung: true, oQuaDem: true)), nha('khong')];
    final p = [phong('1', 'co'), phong('2', 'khong')];
    expect(ids(locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter(thuCung: true))), ['co']);
    expect(ids(locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter(oQuaDem: true))), ['co']);
  });

  test('"Báo trước tối đa 2 tuần": ra trọ 1 tuần và 2 tuần, không ra trọ 3 tuần', () {
    final ds = [nha('t1', noiQuy: nq(tuan: 1)), nha('t2', noiQuy: nq(tuan: 2)), nha('t3', noiQuy: nq(tuan: 3))];
    final p = [for (final n in ds) phong('p_${n.id}', n.id)];
    expect(ids(locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter(baoTruocToiDa: 2))).toSet(), {'t1', 't2'});
  });

  test('lọc nội quy kết hợp được với giá, bán kính, tiện ích (tiện ích phòng và tiện ích chung)', () {
    const goc = DiemGoc(lat: 10.46, lng: 105.63);
    final ds = [
      nha('dung', noiQuy: nq(thuCung: true), tienIch: ['wifi']),
      nha('khong_wifi', noiQuy: nq(thuCung: true)),
      nha('xa', noiQuy: nq(thuCung: true), tienIch: ['wifi'], lat: 10.6),
    ];
    final p = [
      phong('1', 'dung', gia: 1400000, tienIch: ['may_lanh']),
      phong('2', 'dung', gia: 1400000),
      phong('3', 'khong_wifi', tienIch: ['may_lanh']),
      phong('4', 'xa', tienIch: ['may_lanh']),
    ];
    const f = TroFilter(thuCung: true, giaDen: 1500000, banKinhMet: 2000, tienIch: {'wifi', 'may_lanh'});
    final kq = locNhaTro(nhaTro: ds, phong: p, filter: f, goc: goc);
    expect(ids(kq), ['dung']);
    expect(kq.danhSach.single.phongPhuHop.map((x) => x.id), ['1']);
  });

  test('loại phòng có gác chỉ áp khi chọn "Cho thuê phòng"', () {
    final ds = [nha('a')];
    final p = [phong('gac', 'a', coGac: true), phong('ko', 'a', coGac: false)];
    final kq = locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter(loaiHinh: 'phong', coGac: true));
    expect(kq.danhSach.single.phongPhuHop.map((x) => x.id), ['gac']);
  });

  test('tắt "Chỉ hiện nơi còn phòng": nhà trọ hết phòng hiện ở cuối', () {
    final ds = [nha('het', soPhongTrong: 0), nha('con')];
    final p = [phong('1', 'con')];
    expect(ids(locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter())), ['con']);
    final tat = locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter(chiConPhong: false));
    expect(ids(tat), ['con', 'het']);
    expect(tat.danhSach.last.hetPhong, isTrue);
  });

  test('sắp xếp gần nhất / giá thấp nhất / đánh giá cao nhất', () {
    const goc = DiemGoc(lat: 10.46, lng: 105.63);
    final ds = [nha('xa', lat: 10.47, diem: 5), nha('gan', diem: 3)];
    final p = [phong('1', 'xa', gia: 1000000), phong('2', 'gan', gia: 2000000)];
    expect(ids(locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter(), goc: goc)), ['gan', 'xa']);
    expect(ids(locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter(sapXep: SapXep.giaThap))), ['xa', 'gan']);
    expect(ids(locNhaTro(nhaTro: ds, phong: p, filter: const TroFilter(sapXep: SapXep.danhGia))), ['xa', 'gan']);
  });

  test('bộ lọc lưu và đọc lại được (app nhớ bộ lọc lần trước)', () {
    const f = TroFilter(loaiHinh: 'phong', coGac: true, banKinhMet: 1000, tienIch: {'wifi'}, veMuonToi: '23:00', baoTruocToiDa: 2, chiConPhong: false, sapXep: SapXep.giaThap);
    final lai = TroFilter.fromJson(f.toJson());
    expect(lai.toJson(), f.toJson());
    expect(lai.dangLoc, isTrue);
    expect(f.xoaLoc().dangLoc, isFalse);
  });

  test('khoảng cách đường thẳng xấp xỉ đúng', () {
    expect(khoangCachMet(10.46, 105.63, 10.47, 105.63), closeTo(1112, 5));
  });
}
