import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/quan_an_config.dart';
import '../../services/admin_quan_an_service.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../quan_an_routes.dart';
import 'admin_chung.dart';
import 'dinh_chi_quan_screen.dart';

const _nhanDoiTuong = {
  'quan': 'Quán',
  'mon': 'Món',
  'nguoi_dung': 'Người dùng',
  'danh_gia': 'Đánh giá',
  'tin_nhan': 'Tin nhắn',
};

/// Loại quyết định có thể kháng nghị (mục 3.15).
const _nhanQuyetDinh = {
  'khoa_dat_mon': 'Khóa đặt món',
  'khoa_dat_ban': 'Khóa đặt bàn',
  'khoa_tien_mat': 'Mất quyền tiền mặt',
  'khoa_bao_cao': 'Khóa chức năng báo cáo',
  'bom_hang': 'Lần bom hàng',
  'bo_hen_dat_ban': 'Lần bỏ hẹn đặt bàn',
  'khieu_nai_sai': 'Lần khiếu nại bị tính sai',
  'bao_cao_sai': 'Lần báo cáo sai',
  'an_quan': 'Ẩn quán',
  'dinh_chi': 'Đình chỉ quán',
  'khoa_ban': 'Khóa bán vĩnh viễn',
};

/// Quyết định có "lần vi phạm" để xóa khỏi bộ đếm.
const _quyetDinhViPham = {
  'bom_hang',
  'bo_hen_dat_ban',
  'khieu_nai_sai',
  'bao_cao_sai',
  'quan_cham_xac_nhan',
};

/// Chức năng của người dùng trong Quán ăn có thể khóa: mã → nhãn.
const _chucNangKhoa = {
  'khoaDatMon': 'Đặt món',
  'khoaDatBan': 'Đặt bàn',
  'khoaTienMat': 'Tiền mặt khi nhận',
  'khoaBaoCao': 'Báo cáo',
  'khoaDatMonApp': 'Đặt món trả trên app',
};

/// QA-AD-05 Xử lý báo cáo · kháng nghị · khóa chức năng người dùng (mục 3.10, 3.12, 3.15).
class BaoCaoKhangNghiAdminScreen extends StatefulWidget {
  const BaoCaoKhangNghiAdminScreen({
    required this.dv,
    required this.viec,
    super.key,
  });

  final QuanAnDichVu dv;
  final ViecAdminQuan viec;

  @override
  State<BaoCaoKhangNghiAdminScreen> createState() =>
      _BaoCaoKhangNghiAdminScreenState();
}

class _BaoCaoKhangNghiAdminScreenState
    extends State<BaoCaoKhangNghiAdminScreen> {
  String? _chon;
  final _lyDo = TextEditingController();
  bool _dangGui = false;

  Map<String, dynamic> get _m => widget.viec.duLieu;
  bool get _laBaoCao => widget.viec.loai == 'bao_cao';
  Map<dynamic, dynamic> get _doiTuong => (_m['doiTuong'] as Map?) ?? const {};
  Map<dynamic, dynamic> get _quyetDinh => (_m['quyetDinh'] as Map?) ?? const {};

  @override
  void dispose() {
    _lyDo.dispose();
    super.dispose();
  }

  List<AdminLuaChon<String>> get _luaChon {
    if (_laBaoCao) {
      return const [
        AdminLuaChon(
          'hop_le_an',
          'Báo cáo hợp lệ, ẩn đối tượng',
          moTa: 'Có căn cứ: đối tượng bị ẩn, giao dịch đang chạy đi tiếp theo luật.',
        ),
        AdminLuaChon(
          'hop_le',
          'Báo cáo hợp lệ, không ẩn',
          moTa: 'Ghi nhận báo cáo nhưng chưa đủ căn cứ để ẩn.',
        ),
        AdminLuaChon(
          'bac',
          'Bác báo cáo',
          moTa:
              'Báo cáo sai: khôi phục nội dung đang ẩn tạm (nếu có). Báo cáo sai nhiều lần '
              'có thể bị khóa chức năng báo cáo.',
        ),
      ];
    }
    final loai = '${_quyetDinh['loai']}';
    return [
      AdminLuaChon(
        'go_khoa',
        _hanhPhatLaLanVP(loai) ? 'Gỡ hình phạt' : 'Gỡ khóa',
        moTa: 'Chấp nhận kháng nghị: hình phạt hết hiệu lực ngay.',
      ),
      const AdminLuaChon(
        'giu_nguyen',
        'Giữ nguyên quyết định',
        moTa:
            'Không chấp nhận kháng nghị. Mỗi quyết định chỉ kháng nghị 1 lần.',
      ),
      if (_hanhPhatLaLanVP(loai))
        const AdminLuaChon(
          'xoa_vi_pham',
          'Xóa lần vi phạm khỏi bộ đếm',
          moTa: 'Lần vi phạm chuyển sang "đã gỡ", không tính vào ngưỡng khóa.',
        ),
    ];
  }

  bool _hanhPhatLaLanVP(String loai) => _quyetDinhViPham.contains(loai);

  Map<String, dynamic> _tham() {
    final lyDo = _lyDo.text.trim();
    if (_laBaoCao) {
      return {
        'id': widget.viec.id,
        'hopLe': _chon != 'bac',
        'anDoiTuong': _chon == 'hop_le_an',
        'khoiPhuc': _chon == 'bac',
        'lyDo': lyDo,
      };
    }
    return {'id': widget.viec.id, 'ketQua': _chon, 'lyDo': lyDo};
  }

  Future<void> _gui() async {
    setState(() => _dangGui = true);
    final a = widget.dv.admin;
    final ok = await chayThaoTac(
      context,
      () => _laBaoCao ? a.xuLyBaoCao(_tham()) : a.xuLyKhangNghi(_tham()),
      thanhCong: _laBaoCao ? 'Đã xử lý báo cáo' : 'Đã quyết định kháng nghị',
    );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_laBaoCao ? 'Báo cáo' : 'Kháng nghị')),
    body: AdminTrang(
      children: [
        if (_laBaoCao)
          _ChiTietBaoCao(viec: widget.viec, dv: widget.dv)
        else
          _ChiTietKhangNghi(viec: widget.viec),
        AdminMuc(
          tieuDe: 'Quyết định của admin',
          bieuTuong: Icons.gavel_outlined,
          children: [
            AdminLuaChonNhom<String>(
              cacLuaChon: _luaChon,
              giaTri: _chon,
              onChanged: (v) => setState(() => _chon = v),
            ),
            const SizedBox(height: QuanAnSpacing.sm),
            AdminLyDoField(controller: _lyDo, onChanged: () => setState(() {})),
            const SizedBox(height: QuanAnSpacing.lg),
            FilledButton(
              onPressed:
                  _chon != null && _lyDo.text.trim().isNotEmpty && !_dangGui
                  ? _gui
                  : null,
              child: const Text('Gửi quyết định'),
            ),
          ],
        ),
        if (_laBaoCao)
          AdminMuc(
            tieuDe: 'Xử lý thêm',
            bieuTuong: Icons.more_horiz,
            children: [
              Wrap(
                spacing: QuanAnSpacing.sm,
                runSpacing: QuanAnSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => moKhoaChucNang(
                      context,
                      widget.dv,
                      dinhDanh: _doiTuong['loai'] == 'nguoi_dung'
                          ? '${_doiTuong['id']}'
                          : null,
                    ),
                    icon: const Icon(Icons.person_off_outlined),
                    label: const Text('Khóa chức năng người dùng'),
                  ),
                ],
              ),
            ],
          ),
      ],
    ),
  );
}

class _ChiTietBaoCao extends StatelessWidget {
  const _ChiTietBaoCao({required this.viec, required this.dv});

  final ViecAdminQuan viec;
  final QuanAnDichVu dv;

  @override
  Widget build(BuildContext context) {
    final m = viec.duLieu;
    final dt = (m['doiTuong'] as Map?) ?? const {};
    final loai = '${dt['loai'] ?? ''}';
    final id = '${dt['id'] ?? ''}';
    final quanId = loai == 'quan' ? id : (dt['quanId'] as String?);
    return AdminMuc(
      tieuDe: lyDoBaoCaoLabels[m['lyDo']] ?? '${m['lyDo'] ?? 'Báo cáo'}',
      bieuTuong: Icons.flag_outlined,
      children: [
        Wrap(
          spacing: QuanAnSpacing.sm,
          runSpacing: QuanAnSpacing.sm,
          children: [
            if (m['uuTienCao'] == true)
              const QuanAnStatusBadge(
                kind: QuanAnBadgeKind.dongCua,
                label: 'Ưu tiên cao',
              ),
            QuanAnStatusBadge(
              kind: m['duocTinh'] == false
                  ? QuanAnBadgeKind.chung
                  : QuanAnBadgeKind.xacThuc,
              label: m['duocTinh'] == false
                  ? 'Không tính vào ngưỡng'
                  : 'Báo cáo được tính',
            ),
          ],
        ),
        const SizedBox(height: QuanAnSpacing.md),
        AdminDong('Đối tượng', '${_nhanDoiTuong[loai] ?? loai} · $id'),
        AdminDong('Ghi chú', '${m['ghiChu'] ?? ''}'),
        AdminDong('Gửi lúc', formatNgayGio(viec.luc)),
        const SizedBox(height: QuanAnSpacing.xs),
        const Text(
          'Số báo cáo chỉ là tín hiệu ưu tiên kiểm tra, không tự ẩn và không tự '
          'ghi vi phạm. Admin chỉ ẩn khi có căn cứ.',
          style: QuanAnText.bodySmall,
        ),
        if (quanId != null && quanId.isNotEmpty) ...[
          const SizedBox(height: QuanAnSpacing.md),
          Wrap(
            spacing: QuanAnSpacing.sm,
            runSpacing: QuanAnSpacing.sm,
            children: [
              OutlinedButton(
                onPressed: () => QuanAnDieuHuong.quan(context, dv, quanId),
                child: const Text('Mở trang quán'),
              ),
              OutlinedButton(
                onPressed: () => QuanAnDieuHuong.mo(
                  context,
                  (_) => DinhChiQuanScreen(dv: dv, quanId: quanId),
                ),
                child: const Text('Đình chỉ, ẩn quán…'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ChiTietKhangNghi extends StatelessWidget {
  const _ChiTietKhangNghi({required this.viec});

  final ViecAdminQuan viec;

  @override
  Widget build(BuildContext context) {
    final m = viec.duLieu;
    final qd = (m['quyetDinh'] as Map?) ?? const {};
    final loai = '${qd['loai'] ?? ''}';
    final han = thoiGianTuDuLieu(m['hanTraLoi']);
    return AdminMuc(
      tieuDe: 'Kháng nghị: ${_nhanQuyetDinh[loai] ?? loai}',
      bieuTuong: Icons.balance_outlined,
      children: [
        AdminDong('Gửi lúc', formatNgayGio(viec.luc)),
        if (han != null) AdminDong('Trả lời trước', formatNgayGio(han)),
        AdminDong('Lý do', '${m['lyDo'] ?? ''}'),
        const SizedBox(height: QuanAnSpacing.xs),
        AdminAnh(
          danhSachChuoi(m['bangChung']),
          khiRong: 'Không đính kèm bằng chứng',
        ),
        const SizedBox(height: QuanAnSpacing.md),
        const Text(
          'Đang kháng nghị thì hình phạt vẫn còn hiệu lực cho tới khi admin quyết.',
          style: QuanAnText.bodySmall,
        ),
      ],
    );
  }
}

/// Mở hộp thoại khóa chức năng của người dùng trong Quán ăn (đặt món, đặt bàn, tiền mặt, báo cáo).
/// [dinhDanh]: uid hoặc số điện thoại điền sẵn.
Future<void> moKhoaChucNang(
  BuildContext context,
  QuanAnDichVu dv, {
  String? dinhDanh,
}) => showDialog<void>(
  context: context,
  builder: (_) => Theme(
    data: Theme.of(context),
    child: _KhoaChucNangDialog(dv: dv, dinhDanh: dinhDanh),
  ),
);

class _KhoaChucNangDialog extends StatefulWidget {
  const _KhoaChucNangDialog({required this.dv, this.dinhDanh});

  final QuanAnDichVu dv;
  final String? dinhDanh;

  @override
  State<_KhoaChucNangDialog> createState() => _KhoaChucNangDialogState();
}

class _KhoaChucNangDialogState extends State<_KhoaChucNangDialog> {
  late final _dinhDanh = TextEditingController(text: widget.dinhDanh ?? '');
  final _lyDo = TextEditingController();
  String _chucNang = 'khoaDatMon';
  int _ngay = 7;
  bool _dangGui = false;
  late final Future<QuanAnConfig> _cfg = widget.dv.donMon.cauHinh().catchError(
    (_) => const QuanAnConfig(),
  );

  @override
  void dispose() {
    _dinhDanh.dispose();
    _lyDo.dispose();
    super.dispose();
  }

  bool get _hopLe =>
      _dinhDanh.text.trim().isNotEmpty &&
      _lyDo.text.trim().isNotEmpty &&
      !_dangGui;

  Future<void> _khoa() async {
    final dd = _dinhDanh.text.trim();
    final laSdt = RegExp(r'^\+?\d{9,12}$').hasMatch(dd);
    setState(() => _dangGui = true);
    final ok = await chayThaoTac(
      context,
      () => widget.dv.admin.khoaChucNang(
        uid: laSdt ? null : dd,
        sdt: laSdt ? dd : null,
        chucNang: _chucNang,
        den: DateTime.now().add(Duration(days: _ngay)),
        lyDo: _lyDo.text.trim(),
      ),
      thanhCong: 'Đã khóa ${_chucNangKhoa[_chucNang]} $_ngay ngày',
    );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Khóa chức năng người dùng'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: FutureBuilder<QuanAnConfig>(
          future: _cfg,
          initialData: const QuanAnConfig(),
          builder: (context, s) {
            final c = s.data ?? const QuanAnConfig();
            final ngay = {
              1,
              3,
              7,
              14,
              30,
              90,
              c.bomHangKhoaNgay,
              c.khoaDatBanNgay,
              c.khieuNaiSaiKhoaNgay,
              _ngay,
            }.toList()..sort();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Chỉ chặn hành động mới trong Quán ăn; giao dịch đang chạy đi tiếp. '
                  'Người dùng được kháng nghị.',
                  style: QuanAnText.bodySmall,
                ),
                const SizedBox(height: QuanAnSpacing.md),
                TextField(
                  controller: _dinhDanh,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Mã người dùng hoặc số điện thoại',
                  ),
                ),
                const SizedBox(height: QuanAnSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _chucNang,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Chức năng'),
                  items: [
                    for (final e in _chucNangKhoa.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setState(() => _chucNang = v ?? _chucNang),
                ),
                const SizedBox(height: QuanAnSpacing.md),
                DropdownButtonFormField<int>(
                  initialValue: _ngay,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Thời gian khóa',
                  ),
                  items: [
                    for (final n in ngay)
                      DropdownMenuItem(value: n, child: Text('$n ngày')),
                  ],
                  onChanged: (v) => setState(() => _ngay = v ?? _ngay),
                ),
                const SizedBox(height: QuanAnSpacing.md),
                AdminLyDoField(
                  controller: _lyDo,
                  onChanged: () => setState(() {}),
                ),
              ],
            );
          },
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Quay lại'),
      ),
      FilledButton(
        onPressed: _hopLe ? _khoa : null,
        child: const Text('Khóa chức năng'),
      ),
    ],
  );
}
