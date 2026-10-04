import 'dart:ui';

import 'package:flutter/material.dart';

/// Ảnh từ URL, có nền chờ và báo lỗi thay vì vỡ giao diện.
class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto(this.url, {this.fit = BoxFit.cover, super.key});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Image.network(
      url,
      fit: fit,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : ColoredBox(
              color: colors.surfaceContainerHighest,
              child: const Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
      errorBuilder: (_, _, _) => ColoredBox(
        color: colors.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined, color: colors.outline),
      ),
    );
  }
}

/// Ảnh hiện trọn vẹn (không cắt, không kéo giãn), phần trống phía sau là
/// chính ảnh đó làm mờ — ảnh ngang hay dọc đều đẹp trong khung cố định.
class FramedPhoto extends StatelessWidget {
  const FramedPhoto(this.url, {super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: NetworkPhoto(url),
          ),
          const ColoredBox(color: Color(0x33000000)),
          NetworkPhoto(url, fit: BoxFit.contain),
        ],
      ),
    );
  }
}

/// Khung ảnh vuốt ngang + mũi tên + dải ảnh nhỏ bên dưới;
/// chạm ảnh để xem toàn màn hình, phóng to được.
class ImageGallery extends StatefulWidget {
  const ImageGallery({required this.urls, this.aspectRatio = 1, super.key});

  final List<String> urls;
  final double aspectRatio;

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  void _openFullscreen(int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullscreenGallery(urls: widget.urls, initial: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return const SizedBox.shrink();
    final count = widget.urls.length;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: count,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => _openFullscreen(index),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.zoomIn,
                      child: FramedPhoto(widget.urls[index]),
                    ),
                  ),
                ),
                if (count > 1) ...[
                  if (_page > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _ArrowButton(
                        icon: Icons.chevron_left,
                        onTap: () => _goTo(_page - 1),
                      ),
                    ),
                  if (_page < count - 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: _ArrowButton(
                        icon: Icons.chevron_right,
                        onTap: () => _goTo(_page + 1),
                      ),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          '${_page + 1}/$count',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: count,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _goTo(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      width: 2,
                      color: index == _page
                          ? colors.primary
                          : Colors.transparent,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Opacity(
                      opacity: index == _page ? 1 : 0.6,
                      child: NetworkPhoto(widget.urls[index]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: IconButton.filled(
        onPressed: onTap,
        style: IconButton.styleFrom(backgroundColor: Colors.black45),
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _FullscreenGallery extends StatelessWidget {
  const _FullscreenGallery({required this.urls, required this.initial});

  final List<String> urls;
  final int initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: urls.length,
        itemBuilder: (context, index) => InteractiveViewer(
          maxScale: 4,
          child: Center(child: NetworkPhoto(urls[index], fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
