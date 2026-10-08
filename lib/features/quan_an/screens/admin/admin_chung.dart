import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/image_gallery.dart';
import '../../widgets/quan_an_theme.dart';

/// Thành phần dùng chung của các màn hình admin Quán ăn (QA-AD-01 … QA-AD-05).

/// Bề rộng tối đa của nội dung trên màn hình rộng (máy tính).
const double adminRongToiDa = 960;

/// Canh giữa nội dung và giới hạn bề rộng để màn rộng không bị kéo giãn.
class AdminNoiDung extends StatelessWidget {
  const AdminNoiDung({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: adminRongToiDa),
      child: child,
    ),
  );
}

/// Danh sách cuộn một cột có giới hạn bề rộng (thay cho `ListView` thường).
class AdminTrang extends StatelessWidget {
  const AdminTrang({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: QuanAnSpacing.screen),
    children: [
      for (final c in children)
        AdminNoiDung(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              QuanAnSpacing.screen,
              0,
              QuanAnSpacing.screen,
              QuanAnSpacing.cardGap,
            ),
            child: c,
          ),
        ),
    ],
  );
}

/// Một khối thông tin có tiêu đề (thẻ trắng viền xanh nhạt).
class AdminMuc extends StatelessWidget {
  const AdminMuc({
    required this.tieuDe,
    required this.children,
    this.bieuTuong,
    super.key,
  });

  final String tieuDe;
  final IconData? bieuTuong;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(QuanAnSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (bieuTuong != null) ...[
                Icon(bieuTuong, size: 20, color: QuanAnColors.primary),
                const SizedBox(width: QuanAnSpacing.sm),
              ],
              Expanded(child: Text(tieuDe, style: QuanAnText.h3)),
            ],
          ),
          const SizedBox(height: QuanAnSpacing.md),
          ...children,
        ],
      ),
    ),
  );
}

/// Dòng "nhãn: giá trị" — nhãn cố định bề rộng, giá trị tự xuống dòng.
class AdminDong extends StatelessWidget {
  const AdminDong(this.nhan, this.giaTri, {this.mau, super.key});

  final String nhan;
  final String giaTri;
  final Color? mau;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: QuanAnSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 124, child: Text(nhan, style: QuanAnText.bodySmall)),
        Expanded(
          child: Text(
            giaTri.isEmpty ? '—' : giaTri,
            style: QuanAnText.body.copyWith(color: mau),
          ),
        ),
      ],
    ),
  );
}

/// Hàng ảnh nhỏ; bấm để xem to. Rỗng thì hiện [khiRong].
class AdminAnh extends StatelessWidget {
  const AdminAnh(this.urls, {this.kichThuoc = 96, this.khiRong, super.key});

  final List<String> urls;
  final double kichThuoc;
  final String? khiRong;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return khiRong == null
          ? const SizedBox.shrink()
          : Text(khiRong!, style: QuanAnText.bodySmall);
    }
    return Wrap(
      spacing: QuanAnSpacing.sm,
      runSpacing: QuanAnSpacing.sm,
      children: [
        for (final u in urls)
          Semantics(
            button: true,
            label: 'Xem ảnh lớn',
            child: InkWell(
              borderRadius: BorderRadius.circular(QuanAnRadius.button),
              onTap: () => moAnhLon(context, u),
              child: SizedBox(
                width: kichThuoc,
                height: kichThuoc,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(QuanAnRadius.button),
                  child: NetworkPhoto(u),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Xem ảnh to (kéo / phóng được).
Future<void> moAnhLon(BuildContext context, String url) => showDialog<void>(
  context: context,
  builder: (ctx) => Theme(
    data: Theme.of(context),
    child: Dialog(
      insetPadding: const EdgeInsets.all(QuanAnSpacing.lg),
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 640, maxWidth: 900),
            child: InteractiveViewer(
              child: NetworkPhoto(url, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: 'Đóng',
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    ),
  ),
);

/// Một lựa chọn trong [AdminLuaChonNhom].
class AdminLuaChon<T> {
  const AdminLuaChon(
    this.gia,
    this.nhan, {
    this.moTa,
    this.bieuTuong,
    this.nguyHiem = false,
    this.khoa = false,
  });

  final T gia;
  final String nhan;
  final String? moTa;
  final IconData? bieuTuong;

  /// Hành động nguy hiểm: tô đỏ.
  final bool nguyHiem;

  /// Không chọn được (mờ).
  final bool khoa;
}

/// Nhóm lựa chọn một trong nhiều (thay cho radio, mỗi dòng cao ≥ 56).
class AdminLuaChonNhom<T> extends StatelessWidget {
  const AdminLuaChonNhom({
    required this.cacLuaChon,
    required this.giaTri,
    required this.onChanged,
    super.key,
  });

  final List<AdminLuaChon<T>> cacLuaChon;
  final T? giaTri;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final l in cacLuaChon)
        Padding(
          padding: const EdgeInsets.only(bottom: QuanAnSpacing.sm),
          child: _Dong<T>(
            luaChon: l,
            chon: l.gia == giaTri,
            onTap: l.khoa ? null : () => onChanged(l.gia),
          ),
        ),
    ],
  );
}

class _Dong<T> extends StatelessWidget {
  const _Dong({required this.luaChon, required this.chon, required this.onTap});

  final AdminLuaChon<T> luaChon;
  final bool chon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mau = luaChon.nguyHiem ? QuanAnColors.danger : QuanAnColors.primary;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: chon,
      enabled: onTap != null,
      label: luaChon.nhan,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(QuanAnRadius.button),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: QuanAnSpacing.md,
              vertical: QuanAnSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: chon ? mau.withValues(alpha: 0.08) : QuanAnColors.white,
              borderRadius: BorderRadius.circular(QuanAnRadius.button),
              border: Border.all(
                color: chon ? mau : QuanAnColors.border,
                width: chon ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  chon ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: chon ? mau : QuanAnColors.textSecondary,
                ),
                const SizedBox(width: QuanAnSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        luaChon.nhan,
                        style: QuanAnText.label.copyWith(
                          color: luaChon.nguyHiem ? QuanAnColors.danger : null,
                        ),
                      ),
                      if (luaChon.moTa != null)
                        Text(luaChon.moTa!, style: QuanAnText.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ô nhập lý do quyết định (bắt buộc, ghi nhật ký) kèm gợi ý bấm chọn nhanh.
class AdminLyDoField extends StatelessWidget {
  const AdminLyDoField({
    required this.controller,
    this.goiY = const [],
    this.nhan = 'Lý do quyết định (bắt buộc, ghi nhật ký)',
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final List<String> goiY;
  final String nhan;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (goiY.isNotEmpty) ...[
        Wrap(
          spacing: QuanAnSpacing.sm,
          runSpacing: QuanAnSpacing.xs,
          children: [
            for (final g in goiY)
              ActionChip(
                label: Text(g),
                onPressed: () {
                  controller.text = g;
                  controller.selection = TextSelection.collapsed(
                    offset: g.length,
                  );
                  onChanged?.call();
                },
              ),
          ],
        ),
        const SizedBox(height: QuanAnSpacing.sm),
      ],
      TextField(
        controller: controller,
        maxLines: 3,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => onChanged?.call(),
        decoration: InputDecoration(labelText: nhan),
      ),
    ],
  );
}

/// Hộp thoại hỏi lý do (bắt buộc). Trả về lý do đã cắt khoảng trắng, hoặc null nếu hủy.
Future<String?> hoiLyDo(
  BuildContext context, {
  required String tieuDe,
  String? noiDung,
  List<String> goiY = const [],
  String nutXacNhan = 'Xác nhận',
  bool nguyHiem = false,
}) => showDialog<String>(
  context: context,
  builder: (_) => Theme(
    data: Theme.of(context),
    child: _HoiLyDo(
      tieuDe: tieuDe,
      noiDung: noiDung,
      goiY: goiY,
      nutXacNhan: nutXacNhan,
      nguyHiem: nguyHiem,
    ),
  ),
);

class _HoiLyDo extends StatefulWidget {
  const _HoiLyDo({
    required this.tieuDe,
    required this.noiDung,
    required this.goiY,
    required this.nutXacNhan,
    required this.nguyHiem,
  });

  final String tieuDe;
  final String? noiDung;
  final List<String> goiY;
  final String nutXacNhan;
  final bool nguyHiem;

  @override
  State<_HoiLyDo> createState() => _HoiLyDoState();
}

class _HoiLyDoState extends State<_HoiLyDo> {
  final _o = TextEditingController();

  @override
  void dispose() {
    _o.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.tieuDe),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.noiDung != null) ...[
              Text(widget.noiDung!, style: QuanAnText.body),
              const SizedBox(height: QuanAnSpacing.md),
            ],
            AdminLyDoField(
              controller: _o,
              goiY: widget.goiY,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Quay lại'),
      ),
      FilledButton(
        style: widget.nguyHiem
            ? FilledButton.styleFrom(backgroundColor: QuanAnColors.danger)
            : null,
        onPressed: _o.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, _o.text.trim()),
        child: Text(widget.nutXacNhan),
      ),
    ],
  );
}

/// Đọc mốc thời gian từ dữ liệu thô (Timestamp, DateTime hoặc mili-giây).
DateTime? thoiGianTuDuLieu(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  return null;
}

/// Danh sách chuỗi từ dữ liệu thô.
List<String> danhSachChuoi(Object? v) => [
  if (v is List)
    for (final x in v)
      if (x is String) x,
];
