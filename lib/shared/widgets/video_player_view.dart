import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Phát video từ URL: bấm để phát/dừng, thanh tua, giữ đúng tỉ lệ khung hình.
class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({required this.url, this.maxHeight = 480, super.key});

  final String url;
  final double maxHeight;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.initialize().then(
      (_) => mounted ? setState(() {}) : null,
      onError: (_) => mounted ? setState(() => _failed = true) : null,
    );
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onUpdate)
      ..dispose();
    super.dispose();
  }

  void _toggle() {
    final value = _controller.value;
    if (value.isPlaying) {
      _controller.pause();
    } else {
      if (value.position >= value.duration) _controller.seekTo(Duration.zero);
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;
    Widget child;
    if (_failed || value.hasError) {
      child = const _Placeholder(
        icon: Icons.videocam_off_outlined,
        text: 'Không phát được video trên trình duyệt này.',
      );
    } else if (!value.isInitialized) {
      child = const _Placeholder(
        icon: Icons.play_circle_outline,
        text: 'Đang tải video...',
      );
    } else {
      child = AspectRatio(
        aspectRatio: value.aspectRatio,
        child: GestureDetector(
          onTap: _toggle,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              AnimatedOpacity(
                opacity: value.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.only(top: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.black,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 40),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
