import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/image_gallery.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../../auth/models/xac_thuc.dart';
import '../../auth/screens/xac_nhan_danh_tinh_screen.dart';
import '../models/tai_xe.dart';
import '../services/xe_dich_vu.dart';

/// Đăng ký / sửa hồ sơ tài xế (mục 3.3): loại xe, biển số, ảnh xe, bằng lái, khu vực,
/// bảng giá. Cần đã xác thực danh tính; admin Xe dọn trọ duyệt xong mới hiện cho sinh viên.
/// Lưu xong pop về trạng thái duyệt ('pending' | 'approved').
class DangKyTaiXeScreen extends StatefulWidget {
  const DangKyTaiXeScreen({required this.dv, this.hoSo, super.key});

  final XeDichVu dv;
  final TaiXe? hoSo;

  @override
  State<DangKyTaiXeScreen> createState() => _DangKyTaiXeScreenState();
}

class _DangKyTaiXeScreenState extends State<DangKyTaiXeScreen> {
  final _formKey = GlobalKey<FormState>();
  late String? _vehicleType = widget.hoSo?.vehicleType;
  late final _plate = TextEditingController(text: widget.hoSo?.licensePlate);
  late final _area = TextEditingController(text: widget.hoSo?.area);
  late final _price = TextEditingController(text: widget.hoSo?.priceReference);
  late final _giaChuyen = _soCtrl(widget.hoSo?.priceTrip);
  late final _giaKm = _soCtrl(widget.hoSo?.pricePerKm);
  late final _giaGio = _soCtrl(widget.hoSo?.priceHourly);

  static TextEditingController _soCtrl(num? v) =>
      TextEditingController(text: v?.round().toString() ?? '');

  static int? _so(TextEditingController c) => int.tryParse(c.text.trim());
  late final _desc = TextEditingController(text: widget.hoSo?.description);
  late final _xacThuc = widget.dv.xacThuc.cuaToi(widget.dv.uid);
  List<String> _anhXe = const [];
  List<String> _bangLai = const [];
  bool _dangTaiXe = false;
  bool _dangTaiBang = false;
  bool _thieuAnh = false;
  bool _saving = false;
  String? _error;

  bool get _sua => widget.hoSo != null;

  @override
  void dispose() {
    _plate.dispose();
    _area.dispose();
    _price.dispose();
    _giaChuyen.dispose();
    _giaKm.dispose();
    _giaGio.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final hopLe = _formKey.currentState!.validate();
    // Khi sửa: không chọn ảnh mới thì giữ ảnh cũ.
    final anhXe = _anhXe.isEmpty && _sua ? widget.hoSo!.vehiclePhotos : _anhXe;
    final coGia = [_giaChuyen, _giaKm, _giaGio].any((c) => _so(c) != null);
    setState(() {
      _thieuAnh = anhXe.isEmpty || (!_sua && _bangLai.isEmpty);
      _saving = hopLe && !_thieuAnh && coGia;
      _error = coGia
          ? null
          : 'Nhập ít nhất một mức giá: theo chuyến, theo km hoặc theo giờ.';
    });
    if (!_saving) return;
    try {
      final bangLai = _bangLai.isEmpty && _sua
          ? await widget.dv.xe.giayTo(widget.dv.uid)
          : _bangLai;
      final approval = await widget.dv.xe.luuHoSoTaiXe(
        HoSoTaiXeNhap(
          vehicleType: _vehicleType!,
          licensePlate: _plate.text.trim(),
          vehiclePhotos: anhXe,
          licensePhotos: bangLai,
          area: _area.text.trim(),
          priceReference: _price.text.trim(),
          priceTrip: _so(_giaChuyen),
          pricePerKm: _so(_giaKm),
          priceHourly: _so(_giaGio),
          description: _desc.text.trim(),
        ),
      );
      if (mounted) Navigator.of(context).pop(approval);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sua ? 'Sửa hồ sơ tài xế' : 'Đăng ký làm tài xế'),
      ),
      body: StreamBuilder<XacThuc>(
        stream: _xacThuc,
        builder: (context, snap) {
          if (!snap.hasData && !snap.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          final xt = snap.data ?? const XacThuc();
          return xt.daXacThucDanhTinh ? _form(context) : _canDanhTinh(xt);
        },
      ),
    );
  }

  Widget _canDanhTinh(XacThuc xt) {
    final choDuyet = xt.danhTinh == 'cho_duyet';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              choDuyet
                  ? 'CCCD của bạn đang chờ admin duyệt. Duyệt xong bạn quay lại đây để đăng ký.'
                  : 'Tài xế vào tận phòng và chở đồ của sinh viên, nên cần xác thực '
                        'danh tính (CCCD) trước khi đăng ký.',
              textAlign: TextAlign.center,
            ),
            if (xt.danhTinh == 'tu_choi' && xt.lyDoTuChoi != null) ...[
              const SizedBox(height: 8),
              Text(
                'Lần trước bị từ chối: ${xt.lyDoTuChoi}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (!choDuyet) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        XacNhanDanhTinhScreen(service: widget.dv.xacThuc),
                  ),
                ),
                child: const Text('Xác thực danh tính'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final cu = widget.hoSo;
    final colors = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (cu?.approval == 'rejected' && cu?.rejectReason != null)
            Card(
              color: colors.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Hồ sơ bị từ chối'),
                subtitle: Text(cu!.rejectReason!),
              ),
            ),
          Text(
            _sua
                ? 'Đổi loại xe, biển số, ảnh xe hoặc bằng lái thì hồ sơ phải được duyệt lại.'
                : 'Admin Xe dọn trọ sẽ xem biển số, ảnh xe và bằng lái. '
                      'Được duyệt thì bạn mới hiện trong danh sách tìm xe.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _vehicleType,
            decoration: const InputDecoration(labelText: 'Loại xe'),
            items: [
              for (final e in TaiXe.loaiXeLabels.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _vehicleType = v),
            validator: (v) => v == null ? 'Chọn loại xe' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Biển số xe',
              hintText: 'VD: 59C1-234.56',
            ),
            validator: (v) {
              final s = (v ?? '').toUpperCase().replaceAll(' ', '');
              return RegExp(r'^\d{2}[A-Z]{1,2}-?\d{0,2}-?[\d.]{4,6}$')
                      .hasMatch(s)
                  ? null
                  : 'Biển số không hợp lệ';
            },
          ),
          const SizedBox(height: 18),
          if (cu != null && _anhXe.isEmpty) ...[
            Text(
              'Ảnh xe hiện tại (tải ảnh mới để thay)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _Thumbs(urls: cu.vehiclePhotos),
            const SizedBox(height: 10),
          ],
          ImageUploadField(
            storage: widget.dv.storage,
            folder: 'xe_anh',
            label: 'Ảnh xe',
            helperText: 'Chụp rõ thùng xe và biển số.',
            maxImages: 4,
            pickImages: widget.dv.pickImages,
            onChanged: (urls, dangTai) => setState(() {
              _anhXe = urls;
              _dangTaiXe = dangTai;
            }),
          ),
          const SizedBox(height: 18),
          ImageUploadField(
            storage: widget.dv.storage,
            folder: 'xe_rieng',
            label: _sua ? 'Bằng lái (tải lên để thay)' : 'Bằng lái xe',
            helperText: 'Mặt trước và mặt sau. Chỉ admin Xe dọn trọ xem, không hiện cho sinh viên.',
            maxImages: 2,
            pickImages: widget.dv.pickImages,
            onChanged: (urls, dangTai) => setState(() {
              _bangLai = urls;
              _dangTaiBang = dangTai;
            }),
          ),
          if (_thieuAnh)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Cần ít nhất 1 ảnh xe và 1 ảnh bằng lái.',
                style: TextStyle(color: colors.error),
              ),
            ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _area,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Khu vực hoạt động',
              hintText: 'VD: Thủ Đức, Quận 9, Bình Thạnh',
            ),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Nhập khu vực' : null,
          ),
          const SizedBox(height: 6),
          Text(
            'Bảng giá tham khảo (nhập ít nhất một mức)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final (ctrl, nhan, donVi, min) in [
            (_giaChuyen, 'Theo chuyến (từ)', 'đ/chuyến', 10000),
            (_giaKm, 'Theo km', 'đ/km', 1000),
            (_giaGio, 'Theo giờ (chỉ khuân vác)', 'đ/giờ', 10000),
          ]) ...[
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: nhan, suffixText: donVi),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return (v ?? '').trim().isNotEmpty && (n == null || n < min)
                    ? 'Tối thiểu ${formatPrice(min)}'
                    : null;
              },
            ),
            const SizedBox(height: 10),
          ],
          TextFormField(
            controller: _price,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Ghi chú giá (không bắt buộc)',
              hintText: 'VD: dưới 5km tính 1 chuyến, tầng cao +20k',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _desc,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Giới thiệu (không bắt buộc)',
              hintText: 'Có phụ bốc xếp, nhận tháo lắp giường tủ...',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving || _dangTaiXe || _dangTaiBang ? null : _submit,
            child: Text(
              _dangTaiXe || _dangTaiBang
                  ? 'Đang tải ảnh...'
                  : _saving
                  ? 'Đang gửi...'
                  : _sua
                  ? 'Lưu hồ sơ'
                  : 'Gửi hồ sơ để duyệt',
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbs extends StatelessWidget {
  const _Thumbs({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(dimension: 72, child: NetworkPhoto(urls[i])),
        ),
      ),
    );
  }
}
