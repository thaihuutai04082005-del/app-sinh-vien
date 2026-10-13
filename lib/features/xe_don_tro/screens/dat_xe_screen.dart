import 'package:flutter/material.dart';

import '../../../shared/widgets/image_source_field.dart';
import '../../../shared/widgets/video_upload_field.dart';
import '../models/booking_xe.dart';
import '../models/tai_xe.dart';
import '../services/xe_dich_vu.dart';
import '../widgets/xe_widgets.dart';

/// Form đặt xe dọn trọ gửi cho một tài xế: điểm đi, điểm đến, thời gian và ảnh
/// đồ đạc để tài xế báo giá trọn gói (mục 3.3). Gửi xong thì pop về với id đơn.
class DatXeScreen extends StatefulWidget {
  const DatXeScreen({required this.dv, required this.taiXe, super.key});

  final XeDichVu dv;
  final TaiXe taiXe;

  @override
  State<DatXeScreen> createState() => _DatXeScreenState();
}

class _DatXeScreenState extends State<DatXeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _scheduledAt;
  List<String> _itemPhotos = const [];
  bool _isUploading = false;
  List<String> _videos = const [];
  bool _isUploadingVideo = false;
  bool _showPhotoError = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 89)),
      initialDate: _scheduledAt ?? now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _showPhotoError = _itemPhotos.isEmpty);
    if (!formValid || _itemPhotos.isEmpty || _scheduledAt == null) return;

    setState(() => _isSaving = true);
    try {
      final id = await widget.dv.xe.guiYeuCau(
        YeuCauXe(
          driverId: widget.taiXe.driverId,
          fromAddress: _fromController.text.trim(),
          toAddress: _toController.text.trim(),
          scheduledAt: _scheduledAt!,
          contactPhone: _phoneController.text.trim(),
          itemPhotos: _itemPhotos,
          videos: _videos,
          note: _noteController.text.trim(),
        ),
      );
      if (mounted) Navigator.of(context).pop(id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Chưa gửi được: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt xe dọn trọ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TaiXeCard(taiXe: widget.taiXe),
            const SizedBox(height: 18),
            TextFormField(
              controller: _fromController,
              decoration: const InputDecoration(
                labelText: 'Điểm đi',
                prefixIcon: Icon(Icons.trip_origin),
              ),
              validator: _required('Nhập địa chỉ điểm đi'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _toController,
              decoration: const InputDecoration(
                labelText: 'Điểm đến',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: _required('Nhập địa chỉ điểm đến'),
            ),
            const SizedBox(height: 14),
            FormField<DateTime>(
              validator: (_) =>
                  _scheduledAt == null ? 'Chọn ngày giờ cần chuyển' : null,
              builder: (field) => InkWell(
                onTap: () async {
                  await _pickSchedule();
                  field.didChange(_scheduledAt);
                },
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày giờ chuyển',
                    prefixIcon: const Icon(Icons.event_outlined),
                    errorText: field.errorText,
                  ),
                  child: Text(
                    _scheduledAt == null
                        ? 'Chọn thời gian'
                        : formatBookingTime(_scheduledAt!),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại liên hệ',
                prefixIcon: Icon(Icons.call_outlined),
                helperText: 'Tài xế gọi số này để hẹn giờ.',
              ),
              validator: (v) {
                final s = (v ?? '').replaceAll(RegExp(r'[\s.-]'), '');
                return RegExp(r'^(0|\+84)\d{9}$').hasMatch(s)
                    ? null
                    : 'Số điện thoại không hợp lệ';
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Ghi chú cho tài xế (không bắt buộc)',
                hintText: 'Tầng mấy, có thang máy không, đồ dễ vỡ...',
              ),
            ),
            const SizedBox(height: 12),
            ImageSourceField(
              storage: widget.dv.storage,
              folder: 'booking_xe',
              label: 'Ảnh đồ đạc',
              helperText: 'Chụp toàn bộ đồ cần chuyển để tài xế báo giá trọn gói chính xác.',
              startWithLink: false,
              pickImages: widget.dv.pickImages,
              onChanged: (urls, isUploading) => setState(() {
                _itemPhotos = urls;
                _isUploading = isUploading;
                if (urls.isNotEmpty) _showPhotoError = false;
              }),
            ),
            if (_showPhotoError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Cần ít nhất 1 ảnh đồ đạc.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 22),
            VideoUploadField(
              storage: widget.dv.storage,
              folder: 'booking_xe',
              helperText: 'Quay một vòng phòng để tài xế thấy hết đồ cần chuyển (khoảng 30 giây).',
              pickVideo: widget.dv.pickVideo,
              onChanged: (urls, isUploading) => setState(() {
                _videos = urls;
                _isUploadingVideo = isUploading;
              }),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _isUploading || _isUploadingVideo || _isSaving
                  ? null
                  : _submit,
              icon: const Icon(Icons.request_quote_outlined),
              label: Text(
                _isUploading || _isUploadingVideo
                    ? 'Đang tải lên...'
                    : _isSaving
                    ? 'Đang gửi...'
                    : 'Gửi yêu cầu báo giá',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

FormFieldValidator<String> _required(String message) =>
    (value) => (value == null || value.trim().isEmpty) ? message : null;
