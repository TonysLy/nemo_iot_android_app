import 'package:flutter/material.dart';

import '../utils/themes.dart';

// MARK: - 水平线
class HorizontalLineWidget extends StatelessWidget {
  final double width;
  final Color color;
  final EdgeInsets margin;

  const HorizontalLineWidget({
    super.key,
    this.width = 0.5,
    this.color = Themes.defaultLineColor,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      color: color,
      height: width,
    );
  }
}

// MARK: - 垂直钱
class VerticalLineWidget extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final EdgeInsets margin;

  const VerticalLineWidget({
    super.key,
    required this.height,
    this.width = 1,
    this.color = Themes.defaultLineColor,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      color: color,
      width: width,
      height: height,
    );
  }
}
