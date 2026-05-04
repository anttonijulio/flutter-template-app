import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:template_app/core/constants/assets.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.imageUrl, this.size = 40, this.fit = .cover});

  final String? imageUrl;
  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    final content = hasImage
        ? CachedNetworkImage(
            imageUrl: imageUrl!,
            width: size,
            height: size,
            fit: fit,
            memCacheWidth: size.toInt(),
            memCacheHeight: size.toInt(),
            placeholder: (_, _) => _placeholder(),
            errorWidget: (_, _, _) => _fallback(),
          )
        : _fallback();

    return ClipOval(child: content);
  }

  Widget _placeholder() {
    return SizedBox(
      width: size,
      height: size,
      child: const ColoredBox(color: Color(0xFFE5E7EB)),
    );
  }

  Widget _fallback() {
    return Image.asset(
      Assets.imagesAvatarPlaceholder,
      width: size,
      height: size,
      fit: fit,
    );
  }
}
