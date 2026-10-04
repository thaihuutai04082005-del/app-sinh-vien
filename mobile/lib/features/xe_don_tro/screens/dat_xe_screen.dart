import 'package:flutter/material.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../../../shared/widgets/video_upload_field.dart';
import '../models/booking_xe.dart';
import '../services/booking_xe_service.dart';
import 'booking_xe_detail_screen.dart';

/// Form đặt xe dọn trọ: điểm đi, điểm đến, thời gian và ảnh đồ đạc
/// để tài xế báo giá trọn gói (mục 3.3). Lưu xong thì pop về với [BookingXe].
class DatXeScreen extends StatefulWidget {
  const DatXeScreen({
    required this.service,
    required this.storage,
    this.pickImages,
    this.pickVideo,
    super.key,
  });

  final BookingXeService service;
  final ImageStorageService storage;
  final ImagePickerCallback? pickImages;
  final VideoPickerCallback? pickVideo;

  @override
  State<DatXeScreen> createState() => _DatXeScreenState();
}

class _DatXeScreenState extends State<DatXeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
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
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
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

    final booking = BookingXe(
      id: '',
      userId: '', // Service gán uid người gửi.
      driverId: '', // Gán khi sinh viên chọn tài xế.
      fromAddress: _fromController.text.trim(),
      toAddress: _toController.text.trim(),
      itemPhotos: _itemPhotos,
      quotedPrice: null,
      scheduledAt: _scheduledAt!,
      status: 'pending',
      videos: _videos,
    );

    setState(() => _isSaving = true);
    try {
      final created = await widget.service.guiYeuCau(booking);
      if (mounted) Navigator.of(context).pop(created);
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
            const SizedBox(height: 22),
            ImageUploadField(
              storage: widget.storage,
              folder: 'booking_xe',
              label: 'Ảnh đồ đạc',
              helperText: 'Chụp toàn bộ đồ cần chuyển để tài xế báo giá trọn gói chính xác.',
              pickImages: widget.pickImages,
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
              storage: widget.storage,
              folder: 'booking_xe',
              helperText: 'Quay một vòng phòng để tài xế thấy hết đồ cần chuyển (khoảng 30–60 giây).',
              pickVideo: widget.pickVideo,
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
