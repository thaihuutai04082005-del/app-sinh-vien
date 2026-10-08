import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/don_mon.dart';
import '../../models/thanh_toan.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_states.dart';
import '../../widgets/quan_an_theme.dart';

/// Một dòng doanh thu: một ngày hoặc một tuần (thứ hai – chủ nhật, giờ Việt Nam).
class DongDoanhThu {
  const DongDoanhThu({
    required this.tu,
    required this.den,
    required this.soDon,
    required this.quaApp,
    required this.tienMat,
  });

  /// Ngày đầu / ngày cuối của kỳ (UTC, chỉ dùng phần ngày).
  final DateTime tu;
  final DateTime den;
  final int soDon;
  final num quaApp;
  final num tienMat;

  num get tong => quaApp + tienMat;

  String get nhan {
    String ngay(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return tu == den ? '${ngay(tu)}/${tu.year}' : '${ngay(tu)} – ${ngay(den)}';
  }
}

/// Gom các đơn HOÀN TẤT (`completed`) theo ngày hoặc tuần, mới nhất trước.
/// Đơn tiền mặt tách riêng vì không đi qua app. Mốc thời gian: lúc đơn kết thúc
/// (thiếu thì lúc cập nhật cuối, rồi lúc tạo), theo giờ Việt Nam.
List<DongDoanhThu> tongHopDoanhThu(
  Iterable<DonMon> don, {
  required bool theoTuan,
}) {
  final nhom = <DateTime, List<DonMon>>{};
  for (final d in don) {
    if (d.status != 'completed') continue;
    final t = d.ketThucLuc ?? d.capNhatLuc ?? d.taoLuc;
    if (t == null) continue;
    final v = gioVietNam(t);
    final ngay = DateTime.utc(v.year, v.month, v.day);
    final khoa = theoTuan
        ? ngay.subtract(Duration(days: ngay.weekday - 1))
        : ngay;
    nhom.putIfAbsent(khoa, () => []).add(d);
  }
  final khoa = nhom.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final k in khoa)
      DongDoanhThu(
        tu: k,
        den: theoTuan ? k.add(const Duration(days: 6)) : k,
        soDon: nhom[k]!.length,
        quaApp: nhom[k]!
            .where((d) => d.traApp)
            .fold<num>(0, (s, d) => s + d.tong),
        tienMat: nhom[k]!
            .where((d) => d.laTienMat)
            .fold<num>(0, (s, d) => s + d.tong),
      ),
  ];
}

/// QA-CQ-08 Doanh thu: số đơn và tổng tiền theo ngày / tuần (từ đơn hoàn tất của chủ quán),
/// cùng tiền đang giữ / đã nhận trong ví. Đơn tiền mặt ghi rõ là không qua app.
class DoanhThuScreen extends StatefulWidget {
  const DoanhThuScreen({required this.dv, this.quanId, super.key});

  final QuanAnDichVu dv;

  /// Chỉ tính một quán; null = mọi quán của chủ quán.
  final String? quanId;

  @override
  State<DoanhThuScreen> createState() => _DoanhThuScreenState();
}

class _DoanhThuScreenState extends State<DoanhThuScreen> {
  bool _theoTuan = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Doanh thu')),
    body: QuanAnStream<List<DonMon>>(
      stream: () => widget.dv.donMon.cuaChuQuan(widget.dv.uid),
      thongBaoLoi: 'Không tải được doanh thu',
      builder: (context, tatCa) {
        final ds = [
          for (final d in tatCa)
            if (widget.quanId == null || d.quanId == widget.quanId) d,
        ];
        final ngay = tongHopDoanhThu(ds, theoTuan: false);
        final tuan = tongHopDoanhThu(ds, theoTuan: true);
        final bay = gioVietNam(DateTime.now());
        final homNay = DateTime.utc(bay.year, bay.month, bay.day);
        final tuanNay = homNay.subtract(Duration(days: homNay.weekday - 1));
        DongDoanhThu? tim(List<DongDoanhThu> l, DateTime k) {
          for (final x in l) {
            if (x.tu == k) return x;
          }
          return null;
        }

        final dong = _theoTuan ? tuan : ngay;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(QuanAnSpacing.screen),
          child: TrangRong(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TomTat(
                  homNay: tim(ngay, homNay),
                  tuanNay: tim(tuan, tuanNay),
                  vi: widget.dv.donMon.vi(widget.dv.uid),
                ),
                const SizedBox(height: QuanAnSpacing.md),
                const HopThongBao(
                  noiDung:
                      'Chỉ tính đơn đã hoàn tất. Đơn tiền mặt là tiền quán tự '
                      'thu khi giao, không đi qua app nên không có trong ví.',
                ),
                const SizedBox(height: QuanAnSpacing.lg),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Chi tiết', style: QuanAnText.h2),
                    ),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: false, label: Text('Theo ngày')),
                        ButtonSegment(value: true, label: Text('Theo tuần')),
                      ],
                      selected: {_theoTuan},
                      onSelectionChanged: (s) =>
                          setState(() => _theoTuan = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: QuanAnSpacing.md),
                if (dong.isEmpty)
                  const QuanAnEmptyState(
                    icon: Icons.bar_chart_rounded,
                    title: 'Chưa có đơn hoàn tất',
                    message: 'Doanh thu hiện khi có đơn được hoàn tất.',
                  )
                else
                  _Bang(dong: dong, theoTuan: _theoTuan),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _TomTat extends StatelessWidget {
  const _TomTat({
    required this.homNay,
    required this.tuanNay,
    required this.vi,
  });

  final DongDoanhThu? homNay;
  final DongDoanhThu? tuanNay;
  final Stream<ViChuQuan> vi;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final cot = c.maxWidth >= 720 ? 4 : 2;
      final rong = (c.maxWidth - (cot - 1) * QuanAnSpacing.md) / cot;
      Widget o(String t, String gia, [String? phu]) => SizedBox(
        width: rong,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(QuanAnSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t, style: QuanAnText.bodySmall),
                const SizedBox(height: QuanAnSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    gia,
                    style: QuanAnText.h2.copyWith(color: QuanAnColors.primary),
                  ),
                ),
                if (phu != null) Text(phu, style: QuanAnText.bodySmall),
              ],
            ),
          ),
        ),
      );
      return StreamBuilder<ViChuQuan>(
        stream: vi,
        builder: (context, s) => Wrap(
          spacing: QuanAnSpacing.md,
          runSpacing: QuanAnSpacing.md,
          children: [
            o(
              'Hôm nay',
              formatPrice(homNay?.tong ?? 0),
              '${homNay?.soDon ?? 0} đơn',
            ),
            o(
              'Tuần này',
              formatPrice(tuanNay?.tong ?? 0),
              '${tuanNay?.soDon ?? 0} đơn',
            ),
            o(
              'Tiền app đang giữ',
              s.hasData ? formatPrice(s.data!.dangGiu) : '—',
            ),
            o('Đã nhận', s.hasData ? formatPrice(s.data!.daNhan) : '—'),
          ],
        ),
      );
    },
  );
}

class _Bang extends StatelessWidget {
  const _Bang({required this.dong, required this.theoTuan});

  final List<DongDoanhThu> dong;
  final bool theoTuan;

  @override
  Widget build(BuildContext context) => Card(
    child: LayoutBuilder(
      builder: (context, c) {
        final rong = c.maxWidth >= 600;
        final tongDon = dong.fold<int>(0, (s, d) => s + d.soDon);
        final tongApp = dong.fold<num>(0, (s, d) => s + d.quaApp);
        final tongMat = dong.fold<num>(0, (s, d) => s + d.tienMat);
        Widget hang({
          required String ky,
          required String don,
          required String app,
          required String mat,
          required String tong,
          bool dam = false,
        }) {
          final kieu = (dam ? QuanAnText.label : QuanAnText.body);
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: QuanAnSpacing.lg,
              vertical: QuanAnSpacing.md,
            ),
            child: rong
                ? Row(
                    children: [
                      Expanded(flex: 3, child: Text(ky, style: kieu)),
                      Expanded(
                        flex: 2,
                        child: Text(
                          don,
                          style: kieu,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          app,
                          style: kieu,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          mat,
                          style: kieu,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          tong,
                          style: kieu.copyWith(color: QuanAnColors.primary),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ky, style: kieu),
                            Text(
                              '$don · app $app · tiền mặt $mat',
                              style: QuanAnText.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: QuanAnSpacing.sm),
                      Text(
                        tong,
                        style: kieu.copyWith(color: QuanAnColors.primary),
                      ),
                    ],
                  ),
          );
        }

        return Column(
          children: [
            if (rong)
              Container(
                color: QuanAnColors.primaryLight,
                child: hang(
                  ky: theoTuan ? 'Tuần' : 'Ngày',
                  don: 'Số đơn',
                  app: 'Qua app',
                  mat: 'Tiền mặt (không qua app)',
                  tong: 'Tổng',
                  dam: true,
                ),
              ),
            for (final d in dong) ...[
              hang(
                ky: d.nhan,
                don: '${d.soDon} đơn',
                app: formatPrice(d.quaApp),
                mat: formatPrice(d.tienMat),
                tong: formatPrice(d.tong),
              ),
              const Divider(),
            ],
            hang(
              ky: 'Cộng tất cả',
              don: '$tongDon đơn',
              app: formatPrice(tongApp),
              mat: formatPrice(tongMat),
              tong: formatPrice(tongApp + tongMat),
              dam: true,
            ),
          ],
        );
      },
    ),
  );
}
