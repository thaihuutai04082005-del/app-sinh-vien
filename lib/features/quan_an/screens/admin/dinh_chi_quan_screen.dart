import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/quan_an.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import 'admin_chung.dart';

/// Hành động admin có thể làm với một quán.
enum _HanhDong { dinhChi, goDinhChi, an, hien, khoaBan, luaDao }

/// Hậu quả hiển thị trước khi quyết định (mục 3.14).
const _hauQuaAnDinhChi =
    'Chỉ chặn giao dịch MỚI. Đơn đang "chờ quán xác nhận" bị hủy và hoàn tiền; '
    'đơn đã nhận đi tiếp theo luật bình thường; bàn đã xác nhận bị hủy, '
    'không tính lỗi sinh viên; quán vẫn phải trả lời khiếu nại.';

const _hauQuaKhoaBan =
    'Khóa quyền đăng quán và nhận đơn trong Quán ăn, không khóa cả tài khoản. '
    'Không nhận đơn mới. Đơn cũ xử lý theo trạng thái và bằng chứng từng đơn; '
    'KHÔNG hoàn tiền chỉ vì quán bị khóa.';

const _hauQuaLuaDao =
    'Kết luận này là về quán / tài khoản, KHÔNG tự quyết kết quả từng đơn:\n'
    '• Ngừng nhận đơn mới.\n'
    '• Không tự hoàn tiền, không tự giải ngân các đơn đang chạy: đơn đang '
    '"Chờ xác nhận nhận món" được giữ tiền và gắn cờ để admin xét từng đơn '
    'theo bằng chứng của chính đơn đó.\n'
    '• Đơn đã hoàn tất hợp lệ trước đó không bị đảo ngược.\n'
    '• Đặt bàn đã xác nhận bị hủy, không tính lỗi sinh viên.\n'
    '• Gửi đề nghị khóa cả tài khoản tới admin danh tính (admin danh tính quyết).';

/// QA-AD-03 Đình chỉ quán: đình chỉ / gỡ đình chỉ, ẩn / hiện, khóa bán vĩnh viễn,
/// kết luận lừa đảo (mục 3.12, 3.14). Mọi quyết định bắt buộc ghi lý do.
class DinhChiQuanScreen extends StatelessWidget {
  const DinhChiQuanScreen({required this.dv, required this.quanId, super.key});

  final QuanAnDichVu dv;
  final String quanId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đình chỉ quán')),
    body: QuanAnStream<QuanAn?>(
      stream: () => dv.quan.quan(quanId),
      builder: (context, q) => q == null
          ? const QuanAnEmptyState(title: 'Không tìm thấy quán')
          : _NoiDung(dv: dv, quan: q),
    ),
  );
}

class _NoiDung extends StatefulWidget {
  const _NoiDung({required this.dv, required this.quan});

  final QuanAnDichVu dv;
  final QuanAn quan;

  @override
  State<_NoiDung> createState() => _NoiDungState();
}

class _NoiDungState extends State<_NoiDung> {
  _HanhDong? _chon;
  bool _hieuHauQua = false;
  final _lyDo = TextEditingController();
  bool _dangGui = false;

  QuanAn get _q => widget.quan;

  @override
  void dispose() {
    _lyDo.dispose();
    super.dispose();
  }

  List<AdminLuaChon<_HanhDong>> get _luaChon => [
    if (_q.trangThai == 'suspended')
      const AdminLuaChon(
        _HanhDong.goDinhChi,
        'Gỡ đình chỉ',
        moTa: 'Quán hoạt động trở lại, nhận giao dịch mới.',
        bieuTuong: Icons.lock_open,
      )
    else
      const AdminLuaChon(
        _HanhDong.dinhChi,
        'Đình chỉ quán',
        moTa: 'Vi phạm vệ sinh, lừa đảo, tái phạm. Quán ngừng nhận giao dịch mới.',
        bieuTuong: Icons.block,
      ),
    if (_q.trangThai == 'hidden')
      const AdminLuaChon(
        _HanhDong.hien,
        'Hiện lại quán',
        moTa: 'Quán xuất hiện lại trong sảnh.',
        bieuTuong: Icons.visibility,
      )
    else
      const AdminLuaChon(
        _HanhDong.an,
        'Ẩn quán',
        moTa: 'Quán biến mất khỏi sảnh, không nhận giao dịch mới.',
        bieuTuong: Icons.visibility_off,
      ),
    AdminLuaChon(
      _HanhDong.khoaBan,
      _q.khoaBan ? 'Đã khóa bán vĩnh viễn' : 'Khóa bán vĩnh viễn',
      moTa: 'Khóa đăng quán và nhận đơn trong Quán ăn, không khóa tài khoản.',
      bieuTuong: Icons.gpp_bad_outlined,
      nguyHiem: true,
      khoa: _q.khoaBan,
    ),
    const AdminLuaChon(
      _HanhDong.luaDao,
      'Kết luận lừa đảo / giấy tờ giả',
      moTa: 'Quyết định nặng nhất: ảnh hưởng đơn đang chạy và tài khoản chủ quán.',
      bieuTuong: Icons.report_gmailerrorred,
      nguyHiem: true,
    ),
  ];

  String _nutLabel(_HanhDong h) => switch (h) {
    _HanhDong.dinhChi => 'Đình chỉ quán',
    _HanhDong.goDinhChi => 'Gỡ đình chỉ',
    _HanhDong.an => 'Ẩn quán',
    _HanhDong.hien => 'Hiện lại quán',
    _HanhDong.khoaBan => 'Khóa bán vĩnh viễn',
    _HanhDong.luaDao => 'Kết luận lừa đảo',
  };

  bool _nguyHiem(_HanhDong h) =>
      h == _HanhDong.khoaBan || h == _HanhDong.luaDao || h == _HanhDong.dinhChi;

  bool get _duDieuKien =>
      _chon != null &&
      _lyDo.text.trim().isNotEmpty &&
      (_chon != _HanhDong.luaDao || _hieuHauQua) &&
      !_dangGui;

  Future<void> _thucHien() async {
    final h = _chon!;
    final lyDo = _lyDo.text.trim();
    final ten = _q.ten.isEmpty ? 'quán này' : '"${_q.ten}"';
    final dongY = await xacNhan(
      context,
      tieuDe: '${_nutLabel(h)}?',
      noiDung: switch (h) {
        _HanhDong.luaDao => 'Kết luận $ten lừa đảo.\n\n$_hauQuaLuaDao',
        _HanhDong.khoaBan => 'Khóa bán vĩnh viễn $ten.\n\n$_hauQuaKhoaBan',
        _HanhDong.dinhChi ||
        _HanhDong.an => '${_nutLabel(h)} $ten.\n\n$_hauQuaAnDinhChi',
        _ => '${_nutLabel(h)} $ten.',
      },
      dongY: _nutLabel(h),
      nguyHiem: _nguyHiem(h),
    );
    if (!dongY || !mounted) return;
    final a = widget.dv.admin;
    setState(() => _dangGui = true);
    final ok = await chayThaoTac(
      context,
      () => switch (h) {
        _HanhDong.dinhChi => a.dinhChi(_q.id, dinhChi: true, lyDo: lyDo),
        _HanhDong.goDinhChi => a.dinhChi(_q.id, dinhChi: false, lyDo: lyDo),
        _HanhDong.an => a.anHien(_q.id, an: true, lyDo: lyDo),
        _HanhDong.hien => a.anHien(_q.id, an: false, lyDo: lyDo),
        _HanhDong.khoaBan => a.khoaBan(_q.id, lyDo),
        _HanhDong.luaDao => a.luaDao(_q.id, lyDo),
      },
      thanhCong: 'Đã thực hiện: ${_nutLabel(h)}',
    );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final h = _chon;
    return AdminTrang(
      children: [
        AdminMuc(
          tieuDe: _q.ten.isEmpty ? 'Quán chưa đặt tên' : _q.ten,
          bieuTuong: Icons.storefront_outlined,
          children: [
            Wrap(
              spacing: QuanAnSpacing.sm,
              runSpacing: QuanAnSpacing.sm,
              children: [
                QuanAnStatusBadge(
                  kind: switch (_q.trangThai) {
                    'active' => QuanAnBadgeKind.moCua,
                    'suspended' => QuanAnBadgeKind.dongCua,
                    _ => QuanAnBadgeKind.tamNghi,
                  },
                  label: _q.trangThaiLabel,
                ),
                QuanAnStatusBadge(
                  kind: QuanAnBadgeKind.chung,
                  label: _q.loaiQuanLabel,
                ),
                if (_q.khoaBan)
                  const QuanAnStatusBadge(
                    kind: QuanAnBadgeKind.dongCua,
                    label: 'Đã khóa bán vĩnh viễn',
                  ),
              ],
            ),
            const SizedBox(height: QuanAnSpacing.md),
            AdminDong('Địa chỉ', _q.diaChi),
            AdminDong('Số điện thoại', _q.sdt),
            if (_q.anBoi != null) AdminDong('Ẩn bởi', _q.anBoi!),
            if (_q.duyetLuc != null)
              AdminDong('Duyệt lúc', formatNgayGio(_q.duyetLuc!)),
          ],
        ),
        AdminMuc(
          tieuDe: 'Chọn hành động',
          bieuTuong: Icons.gavel_outlined,
          children: [
            AdminLuaChonNhom<_HanhDong>(
              cacLuaChon: _luaChon,
              giaTri: h,
              onChanged: (v) => setState(() {
                _chon = v;
                _hieuHauQua = false;
              }),
            ),
          ],
        ),
        if (h != null) ...[
          if (h == _HanhDong.luaDao)
            const QuanAnWarningBox(message: _hauQuaLuaDao)
          else if (h == _HanhDong.khoaBan)
            const QuanAnWarningBox(message: _hauQuaKhoaBan)
          else if (h == _HanhDong.dinhChi || h == _HanhDong.an)
            const AdminMuc(
              tieuDe: 'Hậu quả với giao dịch đang chạy',
              bieuTuong: Icons.info_outline,
              children: [Text(_hauQuaAnDinhChi, style: QuanAnText.body)],
            ),
          AdminMuc(
            tieuDe: 'Lý do',
            bieuTuong: Icons.edit_note,
            children: [
              AdminLyDoField(
                controller: _lyDo,
                onChanged: () => setState(() {}),
              ),
              if (h == _HanhDong.luaDao) ...[
                const SizedBox(height: QuanAnSpacing.sm),
                CheckboxListTile(
                  value: _hieuHauQua,
                  onChanged: (v) => setState(() => _hieuHauQua = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Tôi hiểu: không tự hoàn / tự giải ngân đơn đang chạy; '
                    'từng đơn sẽ được rà soát riêng.',
                    style: QuanAnText.body,
                  ),
                ),
              ],
            ],
          ),
          FilledButton(
            style: _nguyHiem(h)
                ? FilledButton.styleFrom(backgroundColor: QuanAnColors.danger)
                : null,
            onPressed: _duDieuKien ? _thucHien : null,
            child: Text(_nutLabel(h)),
          ),
        ],
      ],
    );
  }
}
