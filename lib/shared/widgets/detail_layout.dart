import 'package:flutter/material.dart';

/// Bố cục màn chi tiết: màn rộng chia 2 cột (ảnh/video trái, thông tin phải),
/// màn hẹp xếp dọc. Nội dung không bị kéo giãn quá rộng trên màn hình lớn.
class DetailLayout extends StatelessWidget {
  const DetailLayout({required this.media, required this.info, super.key});

  final Widget media;
  final Widget info;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        return SingleChildScrollView(
          padding: EdgeInsets.all(wide ? 28 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 11, child: media),
                        const SizedBox(width: 32),
                        Expanded(flex: 9, child: info),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: media,
                        ),
                        const SizedBox(height: 20),
                        info,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
