import 'package:flutter/material.dart';

import '../models/gio_mo_cua.dart';
import 'quan_an_theme.dart';

/// Bộ chọn giờ mở cửa theo từng ngày trong tuần (mục 3.2): mỗi ngày tối đa [toiDaCa] ca
/// hoặc nghỉ. Ca qua nửa đêm (ví dụ 18:00–02:00) thuộc NGÀY BẮT ĐẦU ca.
///
/// Dùng ở form đăng quán (phần 2) và màn "Giờ mở cửa". Màn hình giữ [lich] và nhận bản mới
/// qua [onChanged]; không tự lưu.
class LichGioMoCuaEditor extends StatelessWidget {
  const LichGioMoCuaEditor({
    required this.lich,
    required this.onChanged,
    this.toiDaCa = 2,
    super.key,
  });

  final LichMoCua lich;
  final ValueChanged<LichMoCua> onChanged;
  final int toiDaCa;

  /// Giờ mặc định khi bật một ngày / thêm ca.
  static const caMacDinh = CaMoCua(tu: 7 * 60, den: 21 * 60);

  /// Lỗi của lịch (rỗng = hợp lệ): quá số ca, ca có giờ mở = giờ đóng, hai ca chồng nhau,
  /// cả tuần đều nghỉ.
  static List<String> kiemTra(LichMoCua lich, {int toiDaCa = 2}) {
    final l = <String>[];
    var coNgayMo = false;
    for (var d = 1; d <= 7; d++) {
      final cas = lich[d] ?? const <CaMoCua>[];
      if (cas.isNotEmpty) coNgayMo = true;
      if (cas.length > toiDaCa) {
        l.add('${tenThu(d)}: tối đa $toiDaCa ca mỗi ngày.');
      }
      for (final c in cas) {
        if (c.tu == c.den) {
          l.add('${tenThu(d)}: giờ mở và giờ đóng không được trùng nhau.');
        }
      }
      for (var i = 0; i < cas.length; i++) {
        for (var j = i + 1; j < cas.length; j++) {
          if (_chong(cas[i], cas[j])) {
            l.add('${tenThu(d)}: hai ca ${cas[i]} và ${cas[j]} chồng nhau.');
          }
        }
      }
    }
    if (!coNgayMo) l.add('Chọn ít nhất một ngày mở cửa trong tuần.');
    return l;
  }

  static bool _chong(CaMoCua a, CaMoCua b) {
    final ad = a.quaNuaDem ? a.den + 1440 : a.den;
    final bd = b.quaNuaDem ? b.den + 1440 : b.den;
    return a.tu < bd && b.tu < ad;
  }

  void _doi(int ngay, List<CaMoCua> ca) {
    final moi = {
      for (final e in lich.entries) e.key: List<CaMoCua>.of(e.value),
    };
    moi[ngay] = ca;
    onChanged(moi);
  }

  Future<int?> _chonGio(BuildContext context, int phut, String tieuDe) async {
    final g = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: phut ~/ 60, minute: phut % 60),
      helpText: tieuDe,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    return g == null ? null : g.hour * 60 + g.minute;
  }

  void _apDungChoCaTuan() {
    final mau = lich[1] ?? const <CaMoCua>[];
    onChanged({for (var d = 1; d <= 7; d++) d: List<CaMoCua>.of(mau)});
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _apDungChoCaTuan,
          icon: const Icon(Icons.content_copy_rounded, size: 18),
          label: const Text('Dùng giờ Thứ hai cho cả tuần'),
        ),
      ),
      for (var d = 1; d <= 7; d++) ...[
        _NgayMoCua(
          ngay: d,
          ca: lich[d] ?? const [],
          toiDaCa: toiDaCa,
          onDoi: (ca) => _doi(d, ca),
          chonGio: _chonGio,
        ),
        const SizedBox(height: QuanAnSpacing.sm),
      ],
      Text(
        'Ca qua nửa đêm (ví dụ 18:00–02:00) tính vào ngày bắt đầu ca.',
        style: QuanAnText.bodySmall,
      ),
    ],
  );
}

class _NgayMoCua extends StatelessWidget {
  const _NgayMoCua({
    required this.ngay,
    required this.ca,
    required this.toiDaCa,
    required this.onDoi,
    required this.chonGio,
  });

  final int ngay;
  final List<CaMoCua> ca;
  final int toiDaCa;
  final ValueChanged<List<CaMoCua>> onDoi;
  final Future<int?> Function(BuildContext, int, String) chonGio;

  bool get _mo => ca.isNotEmpty;

  void _suaCa(int i, CaMoCua moi) {
    final ds = List<CaMoCua>.of(ca);
    ds[i] = moi;
    onDoi(ds);
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QuanAnSpacing.md,
        vertical: QuanAnSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tenThu(ngay), style: QuanAnText.label)),
              Text(
                _mo ? 'Mở cửa' : 'Nghỉ',
                style: QuanAnText.bodySmall.copyWith(
                  color: _mo
                      ? QuanAnColors.success
                      : QuanAnColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: QuanAnSpacing.sm),
              Switch(
                value: _mo,
                onChanged: (v) =>
                    onDoi(v ? const [LichGioMoCuaEditor.caMacDinh] : const []),
              ),
            ],
          ),
          for (var i = 0; i < ca.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: QuanAnSpacing.xs),
              child: Wrap(
                spacing: QuanAnSpacing.sm,
                runSpacing: QuanAnSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Ca ${i + 1}', style: QuanAnText.bodySmall),
                  OutlinedButton(
                    onPressed: () async {
                      final g = await chonGio(context, ca[i].tu, 'Giờ mở cửa');
                      if (g != null) {
                        _suaCa(i, CaMoCua(tu: g, den: ca[i].den));
                      }
                    },
                    child: Text('Mở ${phutHienThi(ca[i].tu)}'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final g = await chonGio(
                        context,
                        ca[i].den,
                        'Giờ đóng cửa',
                      );
                      if (g != null) {
                        _suaCa(i, CaMoCua(tu: ca[i].tu, den: g));
                      }
                    },
                    child: Text('Đóng ${phutHienThi(ca[i].den)}'),
                  ),
                  IconButton(
                    tooltip: 'Xóa ca ${i + 1}',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => onDoi([
                      for (var k = 0; k < ca.length; k++)
                        if (k != i) ca[k],
                    ]),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  if (ca[i].quaNuaDem)
                    const Text(
                      'qua nửa đêm',
                      style: TextStyle(
                        color: QuanAnColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          if (_mo && ca.length < toiDaCa)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  final cuoi = ca.last;
                  final tu = cuoi.quaNuaDem
                      ? cuoi.den
                      : (cuoi.den + 60 < 1380 ? cuoi.den + 60 : 1320);
                  final den = tu + 180 < 1440 ? tu + 180 : 1439;
                  onDoi([...ca, CaMoCua(tu: tu, den: den)]);
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm ca'),
              ),
            ),
        ],
      ),
    ),
  );
}
