import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    this.shape = .rectangle,
  });

  const LoadingShimmer.light({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = .rectangle,
  }) : baseColor = _lightBaseColor,
       highlightColor = _lightHighlightColor;

  const LoadingShimmer.dark({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = .rectangle,
  }) : baseColor = _darkBaseColor,
       highlightColor = _darkHighlightColor;

  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final BoxShape shape;

  static const _defaultBaseColor = Color(0xFFE0E0E0);
  static const _defaultHighlightColor = Color(0xFFF5F5F5);

  static const _lightBaseColor = Color(0xFFE5E7EB);
  static const _lightHighlightColor = Color(0xFFF3F4F6);

  static const _darkBaseColor = Color(0xFF2A2A2A);
  static const _darkHighlightColor = Color(0xFF3A3A3A);

  @override
  Widget build(BuildContext context) {
    final bColor = baseColor ?? _defaultBaseColor;
    final hColor = highlightColor ?? _defaultHighlightColor;

    Widget child = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bColor,
        shape: shape,
        borderRadius: shape == .rectangle ? borderRadius : null,
      ),
    );

    if (shape == .rectangle && borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return Shimmer.fromColors(
      baseColor: bColor,
      highlightColor: hColor,
      child: child,
    );
  }
}
