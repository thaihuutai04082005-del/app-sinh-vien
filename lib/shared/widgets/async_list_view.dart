import 'dart:math';

import 'package:flutter/material.dart';

/// Khung danh sách có đủ 3 trạng thái bắt buộc (mục 7.4): đang tải, rỗng, lỗi.
/// Kéo xuống để tải lại.
class AsyncListView<T> extends StatelessWidget {
  const AsyncListView({
    required this.future,
    required this.onRefresh,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyText,
    this.gridMaxExtent,
    this.gridFooterHeight = 0,
    super.key,
  });

  final Future<List<T>> future;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final IconData emptyIcon;
  final String emptyText;

  /// Có giá trị thì hiển thị dạng lưới, mỗi ô rộng tối đa bằng giá trị này.
  final double? gridMaxExtent;

  /// Ô lưới cao = chiều rộng ô (ảnh vuông) + phần chữ bên dưới.
  final double gridFooterHeight;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _Message(
            icon: Icons.cloud_off_outlined,
            text: '${snapshot.error}',
            action: FilledButton.tonal(
              onPressed: onRefresh,
              child: const Text('Thử lại'),
            ),
          );
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              children: [
                const SizedBox(height: 120),
                _Message(icon: emptyIcon, text: emptyText),
              ],
            ),
          );
        }
        const padding = EdgeInsets.fromLTRB(16, 8, 16, 96);
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: gridMaxExtent == null
              ? ListView.separated(
                  padding: padding,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => itemBuilder(context, items[i]),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 12.0;
                    final width = constraints.maxWidth - padding.horizontal;
                    final columns = max(
                      2,
                      ((width + spacing) / (gridMaxExtent! + spacing)).ceil(),
                    );
                    final tile = (width - spacing * (columns - 1)) / columns;
                    return GridView.builder(
                      padding: padding,
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        mainAxisExtent: tile + gridFooterHeight,
                      ),
                      itemBuilder: (context, i) =>
                          itemBuilder(context, items[i]),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}
