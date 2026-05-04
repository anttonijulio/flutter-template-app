import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:template_app/core/constants/assets.dart';

class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit,
    this.borderRadius,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (imageUrl.isEmpty) {
      content = _fallback();
    } else {
      content = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        placeholder: (_, _) => _placeholder(),
        errorWidget: (_, _, _) => _fallback(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }

    return content;
  }

  Widget _placeholder() {
    return const ColoredBox(color: Colors.grey);
  }

  Widget _fallback() {
    return Image.asset(
      Assets.imagesPlaceholder,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
