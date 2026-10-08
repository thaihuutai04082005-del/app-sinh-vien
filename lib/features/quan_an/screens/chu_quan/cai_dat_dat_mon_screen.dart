import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/formatters.dart';
import '../../../auth/services/xac_thuc_service.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/chu_quan_chung.dart';
import '../../widgets/quan_an_theme.dart';

/// QA-CQ-10 Cài đặt đặt món (chỉ hộ kinh doanh): bật đặt món, đến lấy / quán tự giao, bán kính,
/// phí giao, đơn tối thiểu, thời gian chuẩn bị, tiền mặt. Sửa bất cứ lúc nào, hiện ngay, không cần duyệt.
class CaiDatDatMonScreen extends StatefulWidget {
  const CaiDatDatMonScreen({required this.dv, required this.quan, super.key});

  final QuanAnDichVu dv;
  final QuanAn quan;

  @override
  State<CaiDatDatMonScreen> createState() => _CaiDatDatMonScreenState();
}

class _CaiDatDatMonScreenState extends State<CaiDatDatMonScreen> {
  /// Thời gian chuẩn bị tối đa (phút); chưa có trong cấu hình hệ thống.
  static const _chuanBiToiDa = 240;

  QuanAnConfig _cfg = const QuanAnConfig();
  late CaiDatDatMon _d = widget.quan.datMon;
  late final _phiGiao = TextEditingController(text: _chuoiSo(_d.phiGiao));
  late final _phiMoiKm = TextEditingController(text: _chuoiSo(_d.phiMoiKm));
  late final _donToiThieu = TextEditingController(
    text: _chuoiSo(_d.donToiThieu),
  );
  late final _chuanBi = TextEditingController(text: '${_d.chuanBiPhut}');
  List<String> _loi = const [];
  bool _dangLuu = false;

  static String _chuoiSo(num v) => v <= 0 ? '' : '${v.round()}';

  @override
  void initState() {
    super.initState();
    widget.dv.donMon
        .cauHinh()
        .then((c) {
          if (mounted) setState(() => _cfg = c);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _phiGiao.dispose();
    _phiMoiKm.dispose();
    _donToiThieu.dispose();
    _chuanBi.dispose();
    super.dispose();
  }

  int _so(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  CaiDatDatMon get _hienTai => _d.copyWith(
    phiGiao: _so(_phiGiao),
    phiMoiKm: _so(_phiMoiKm),
    donToiThieu: _so(_donToiThieu),
    chuanBiPhut: _so(_chuanBi),
  );

  List<String> _kiemTra(CaiDatDatMon d) {
    final l = <String>[];
    if (d.bat && !d.coCachNhan) {
      l.add('Chọn ít nhất một cách nhận món: Đến lấy hoặc Quán tự giao.');
    }
    if (d.giaoTanNoi &&
        (d.banKinhKm < _cfg.banKinhGiaoToiThieuKm ||
            d.banKinhKm > _cfg.banKinhGiaoToiDaKm)) {
      l.add(
        'Bán kính giao từ ${_cfg.banKinhGiaoToiThieuKm} đến ${_cfg.banKinhGiaoToiDaKm} km.',
      );
    }
    if (d.chuanBiPhut < 1 || d.chuanBiPhut > _chuanBiToiDa) {
      l.add('Thời gian chuẩn bị từ 1 đến $_chuanBiToiDa phút.');
    }
    return l;
  }

  Future<void> _luu() async {
    final d = _hienTai;
    final loi = _kiemTra(d);
    setState(() => _loi = loi);
    if (loi.isNotEmpty) return;
    setState(() => _dangLuu = true);
    try {
      await widget.dv.quan.thaoTac('caiDatDatMon', {
        'quanId': widget.quan.id,
        'datMon': d.toMap(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu cài đặt đặt món')));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loi = [e.message]);
    } catch (_) {
      if (mounted) {
        setState(() => _loi = const ['Có lỗi xảy ra, vui lòng thử lại.']);
      }
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  Widget _oSo(
    TextEditingController c,
    String nhan, {
    String? goiY,
    String? hau,
  }) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: nhan,
      helperText: goiY,
      helperMaxLines: 3,
      suffixText: hau,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final q = widget.quan;
    if (!q.laHoKinhDoanh) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cài đặt đặt món')),
        body: const Padding(
          padding: EdgeInsets.all(QuanAnSpacing.screen),
          child: TrangRong(
            rongToiDa: 640,
            child: HopThongBao.canhBao(
              noiDung: 'Chỉ quán hộ kinh doanh mới nhận đặt món qua app. Quán bán lẻ có thể nâng cấp ở mục "Sửa thông tin".',
            ),
          ),
        ),
      );
    }
    final d = _d;
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt đặt món')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(QuanAnSpacing.screen),
              child: TrangRong(
                rongToiDa: 640,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const HopThongBao(
                      noiDung: 'Sửa lúc nào cũng được và hiện ngay, không cần duyệt. Đơn đã đặt vẫn giữ cài đặt lúc khách đặt.',
                    ),
                    const SizedBox(height: QuanAnSpacing.cardGap),
                    KhoiThongTin(
                      tieuDe: 'Nhận đặt món qua app',
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: d.bat,
                        onChanged: (v) =>
                            setState(() => _d = d.copyWith(bat: v)),
                        title: const Text('Bật đặt món'),
                        subtitle: const Text(
                          'Tắt thì khách chỉ xem menu, không đặt món được.',
                        ),
                      ),
                    ),
                    const SizedBox(height: QuanAnSpacing.cardGap),
                    KhoiThongTin(
                      tieuDe: 'Cách nhận món',
                      phu: 'Chọn ít nhất một cách.',
                      child: Column(
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: d.denLay,
                            onChanged: (v) => setState(
                              () => _d = d.copyWith(denLay: v ?? false),
                            ),
                            title: const Text('Đến lấy'),
                            subtitle: const Text(
                              'Khách tới quán nhận, đọc mã nhận món.',
                            ),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: d.giaoTanNoi,
                            onChanged: (v) => setState(
                              () => _d = d.copyWith(giaoTanNoi: v ?? false),
                            ),
                            title: const Text('Quán tự giao'),
                            subtitle: const Text(
                              'Quán tự giao tận nơi, chụp ảnh khi giao.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (d.giaoTanNoi) ...[
                      const SizedBox(height: QuanAnSpacing.cardGap),
                      KhoiThongTin(
                        tieuDe: 'Giao hàng',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bán kính giao tối đa: ${d.banKinhKm.round()} km',
                              style: QuanAnText.label,
                            ),
                            Slider(
                              min: _cfg.banKinhGiaoToiThieuKm.toDouble(),
                              max: _cfg.banKinhGiaoToiDaKm.toDouble(),
                              divisions:
                                  (_cfg.banKinhGiaoToiDaKm -
                                          _cfg.banKinhGiaoToiThieuKm)
                                      .clamp(1, 100),
                              value: d.banKinhKm
                                  .clamp(
                                    _cfg.banKinhGiaoToiThieuKm,
                                    _cfg.banKinhGiaoToiDaKm,
                                  )
                                  .toDouble(),
                              label: '${d.banKinhKm.round()} km',
                              onChanged: (v) => setState(
                                () => _d = d.copyWith(banKinhKm: v.round()),
                              ),
                            ),
                            Text(
                              'Từ ${_cfg.banKinhGiaoToiThieuKm} đến ${_cfg.banKinhGiaoToiDaKm} km.',
                              style: QuanAnText.bodySmall,
                            ),
                            const SizedBox(height: QuanAnSpacing.lg),
                            const Text(
                              'Cách tính phí giao',
                              style: QuanAnText.label,
                            ),
                            RadioGroup<String>(
                              groupValue: d.phiGiaoKieu,
                              onChanged: (v) => setState(
                                () => _d = d.copyWith(
                                  phiGiaoKieu: v ?? 'co_dinh',
                                ),
                              ),
                              child: const Column(
                                children: [
                                  RadioListTile<String>(
                                    contentPadding: EdgeInsets.zero,
                                    value: 'co_dinh',
                                    title: Text('Phí cố định mỗi đơn'),
                                  ),
                                  RadioListTile<String>(
                                    contentPadding: EdgeInsets.zero,
                                    value: 'theo_km',
                                    title: Text('Phí theo km'),
                                  ),
                                ],
                              ),
                            ),
                            if (d.theoKm)
                              _oSo(
                                _phiMoiKm,
                                'Phí mỗi km',
                                hau: 'đ/km',
                                goiY: 'Để trống hoặc 0 là miễn phí giao.',
                              )
                            else
                              _oSo(
                                _phiGiao,
                                'Phí giao',
                                hau: 'đ',
                                goiY: 'Để trống hoặc 0 là miễn phí giao.',
                              ),
                            const SizedBox(height: QuanAnSpacing.md),
                            _oSo(
                              _donToiThieu,
                              'Đơn tối thiểu để giao',
                              hau: 'đ',
                              goiY: 'Tính trên tiền món, chưa gồm phí giao. Để trống là không yêu cầu.',
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: QuanAnSpacing.cardGap),
                    KhoiThongTin(
                      tieuDe: 'Chuẩn bị món',
                      child: _oSo(
                        _chuanBi,
                        'Thời gian chuẩn bị trung bình',
                        hau: 'phút',
                        goiY:
                            'Từ 1 đến $_chuanBiToiDa phút. Dùng để tính giờ dự kiến khách nhận món.',
                      ),
                    ),
                    const SizedBox(height: QuanAnSpacing.cardGap),
                    KhoiThongTin(
                      tieuDe: 'Tiền mặt',
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: d.tienMat,
                        onChanged: (v) =>
                            setState(() => _d = d.copyWith(tienMat: v)),
                        title: const Text('Nhận tiền mặt khi nhận hàng'),
                        subtitle: Text(
                          'Chỉ áp dụng cho đơn dưới ${formatPrice(_cfg.tienMatDuoi)}. '
                          'Khách hay bỏ đơn tiền mặt có thể bị tạm dừng quyền này.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ThanhDuoiForm(
            loi: _loi,
            child: FilledButton(
              onPressed: _dangLuu ? null : _luu,
              child: Text(_dangLuu ? 'Đang lưu...' : 'Lưu cài đặt'),
            ),
          ),
        ],
      ),
    );
  }
}
