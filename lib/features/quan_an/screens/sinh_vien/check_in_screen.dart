import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/formatters.dart';
import '../../models/quan_an.dart';
import '../../models/quan_an_config.dart';
import '../../models/quan_an_filter.dart';
import '../../services/quan_an_api.dart' show ApiException;
import '../../services/quan_an_dich_vu.dart';
import '../../widgets/quan_an_async.dart';
import '../../widgets/quan_an_media_field.dart';
import '../../widgets/quan_an_status_badge.dart';
import '../../widgets/quan_an_theme.dart';
import '../../widgets/trang_thai_mo_cua_badge.dart';

/// Kết quả lấy vị trí: tọa độ hoặc lý do không lấy được (bằng chữ).
typedef _ViTri = ({double lat, double lng})?;

const _camNghiToiDa = 200;

/// QA-SV-11 Check-in tại quán (mục 3.4 Bước 3): lấy GPS, hiện khoảng cách tới quán, kèm ảnh và
/// cảm nghĩ (đều tùy chọn). Điều kiện (đủ gần, trong giờ mở cửa, 1 lần / ngày) do hệ thống
/// kiểm tra; màn hình báo lại lý do bằng chữ. Dùng được cả trên máy tính (trình duyệt có định vị).
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({required this.dv, required this.quan, super.key});

  final QuanAnDichVu dv;
  final QuanAn quan;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  QuanAnConfig _cfg = const QuanAnConfig();
  _ViTri _viTri;
  bool _dangLayViTri = false;
  String? _loiViTri;
  bool _daCheckInHomNay = false;
  List<String> _anh = const [];
  final _camNghi = TextEditingController();
  bool _congKhai = false;
  bool _dangGui = false;
  String? _loi;

  QuanAn get _q => widget.quan;

  @override
  void initState() {
    super.initState();
    _napCauHinh();
    _kiemTraDaCheckIn();
    _layViTri();
  }

  @override
  void dispose() {
    _camNghi.dispose();
    super.dispose();
  }

  Future<void> _napCauHinh() async {
    try {
      final c = await widget.dv.donMon.cauHinh();
      if (mounted) setState(() => _cfg = c);
    } catch (_) {}
  }

  Future<void> _kiemTraDaCheckIn() async {
    if (widget.dv.uid.isEmpty) return;
    try {
      final da = await widget.dv.checkIn.daCheckInHomNay(widget.dv.uid, _q.id);
      if (mounted) setState(() => _daCheckInHomNay = da);
    } catch (_) {
      // Không đọc được thì để hệ thống quyết khi bấm Check-in.
    }
  }

  Future<void> _layViTri() async {
    setState(() {
      _dangLayViTri = true;
      _loiViTri = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Hãy bật định vị (GPS) của thiết bị rồi thử lại.';
      }
      var quyen = await Geolocator.checkPermission();
      if (quyen == LocationPermission.denied) {
        quyen = await Geolocator.requestPermission();
      }
      if (quyen == LocationPermission.denied ||
          quyen == LocationPermission.deniedForever) {
        throw 'Ứng dụng chưa được cấp quyền định vị. Hãy cho phép vị trí trong cài đặt rồi thử lại.';
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() {
        _viTri = (lat: p.latitude, lng: p.longitude);
        _dangLayViTri = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _viTri = null;
        _dangLayViTri = false;
        _loiViTri = e is String
            ? e
            : 'Không lấy được vị trí của bạn, vui lòng thử lại.';
      });
    }
  }

  double? get _khoangCach {
    final v = _q.viTri, p = _viTri;
    if (v == null || p == null) return null;
    return khoangCachMet(p.lat, p.lng, v.latitude, v.longitude);
  }

  Future<void> _checkIn() async {
    final p = _viTri;
    if (p == null) return;
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    try {
      final kc = await widget.dv.checkIn.checkIn(
        quanId: _q.id,
        lat: p.lat,
        lng: p.lng,
        anh: _anh.isEmpty ? null : _anh.first,
        camNghi: _camNghi.text,
        congKhai: _congKhai,
      );
      if (!mounted) return;
      final m = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      m.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.lightGreenAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  kc == null
                      ? 'Check-in thành công tại ${_q.ten}'
                      : 'Check-in thành công · cách quán ${formatKhoangCach(kc.toDouble())}',
                ),
              ),
            ],
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _loi = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _loi = 'Có lỗi xảy ra, vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  Widget _khoiViTri() {
    if (_dangLayViTri) {
      return const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: QuanAnSpacing.md),
          Expanded(child: Text('Đang lấy vị trí của bạn...')),
        ],
      );
    }
    if (_viTri == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loiViTri ?? 'Chưa có vị trí của bạn.',
            style: const TextStyle(color: QuanAnColors.danger),
          ),
          const SizedBox(height: QuanAnSpacing.sm),
          OutlinedButton.icon(
            onPressed: _layViTri,
            icon: const Icon(Icons.my_location),
            label: const Text('Lấy lại vị trí'),
          ),
        ],
      );
    }
    final kc = _khoangCach;
    final gan = kc != null && kc <= _cfg.checkInMet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              gan ? Icons.check_circle : Icons.warning_amber_rounded,
              color: gan ? QuanAnColors.success : QuanAnColors.warning,
            ),
            const SizedBox(width: QuanAnSpacing.sm),
            Expanded(
              child: Text(
                kc == null
                    ? 'Quán chưa có vị trí trên bản đồ, chưa check-in được.'
                    : (gan
                          ? 'Bạn cách quán ${formatKhoangCach(kc)} — đủ gần để check-in.'
                          : 'Bạn cách quán ${formatKhoangCach(kc)}. Cần ở trong vòng ${_cfg.checkInMet} m quanh quán.'),
                style: QuanAnText.body,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _layViTri,
          icon: const Icon(Icons.refresh),
          label: const Text('Cập nhật vị trí'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = _q.moCua(DateTime.now(), cfg: _cfg);
    final dangNhap = widget.dv.uid.isNotEmpty;
    final khongTheCheckIn = !dangNhap || _daCheckInHomNay || _q.viTri == null;
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in tại quán')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(QuanAnSpacing.screen),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_q.ten, style: QuanAnText.h1),
                const SizedBox(height: QuanAnSpacing.xs),
                Text(_q.diaChi, style: QuanAnText.bodySmall),
                const SizedBox(height: QuanAnSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TrangThaiMoCuaBadge(tinhTrang: tt),
                ),
                if (!tt.trangThai.dangMo)
                  const Padding(
                    padding: EdgeInsets.only(top: QuanAnSpacing.sm),
                    child: Text(
                      'Quán đang ngoài giờ mở cửa nên chưa check-in được.',
                      style: TextStyle(color: QuanAnColors.warning),
                    ),
                  ),
                const SizedBox(height: QuanAnSpacing.lg),
                if (!dangNhap)
                  const QuanAnStatusBadge(
                    kind: QuanAnBadgeKind.canhBao,
                    label: 'Vui lòng đăng nhập để check-in.',
                  )
                else if (_daCheckInHomNay)
                  const QuanAnStatusBadge(
                    kind: QuanAnBadgeKind.chung,
                    label: 'Hôm nay bạn đã check-in ở quán này rồi (mỗi quán 1 lần/ngày).',
                  ),
                if (dangNhap && !_daCheckInHomNay) ...[
                  const Text('Vị trí của bạn', style: QuanAnText.h3),
                  const SizedBox(height: QuanAnSpacing.sm),
                  _khoiViTri(),
                  const SizedBox(height: QuanAnSpacing.lg),
                  QuanAnMediaField(
                    storage: widget.dv.storage,
                    folder: 'quan_an_check_in',
                    nhan: 'Ảnh (tùy chọn)',
                    toiDa: 1,
                    giaTri: _anh,
                    onChanged: (v) => setState(() => _anh = v),
                    pickImages: widget.dv.pickImages,
                  ),
                  const SizedBox(height: QuanAnSpacing.lg),
                  TextField(
                    controller: _camNghi,
                    maxLength: _camNghiToiDa,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Cảm nghĩ ngắn (tùy chọn)',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hiện công khai'),
                    subtitle: const Text('Cho người khác thấy ảnh và cảm nghĩ này.'),
                    value: _congKhai,
                    onChanged: (v) => setState(() => _congKhai = v),
                  ),
                  const SizedBox(height: QuanAnSpacing.sm),
                  const Text(
                    'Check-in cho đánh giá của bạn nhãn "📍 Check-in tại quán" và được tính vào mục "Sinh viên hay ăn".',
                    style: QuanAnText.bodySmall,
                  ),
                ],
                if (_loi != null)
                  Padding(
                    padding: const EdgeInsets.only(top: QuanAnSpacing.md),
                    child: Text(
                      _loi!,
                      style: const TextStyle(
                        color: QuanAnColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: QuanAnSpacing.xl),
                FilledButton.icon(
                  onPressed: khongTheCheckIn || _viTri == null || _dangGui
                      ? null
                      : _checkIn,
                  icon: _dangGui
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: QuanAnColors.white,
                          ),
                        )
                      : const Icon(Icons.place),
                  label: Text(_dangGui ? 'Đang check-in...' : 'Check-in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
