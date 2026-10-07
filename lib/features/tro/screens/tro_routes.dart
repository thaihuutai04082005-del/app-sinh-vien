import 'package:flutter/material.dart';

import '../widgets/tro_theme.dart';

/// Route của module Tìm trọ: bọc màn hình trong giao diện riêng (mục 2.19) để mọi
/// màn hình mở từ module đều xanh biển – trắng, không đổi theme của phần còn lại.
Route<T> troRoute<T>(WidgetBuilder builder, {bool webFont = true}) =>
    MaterialPageRoute<T>(
      builder: (context) => Theme(
        data: TroTheme.data(webFont: webFont),
        child: Builder(builder: builder),
      ),
    );
