import 'package:flutter/material.dart';
import 'package:recolle/core/theme/app_colors.dart';

/// 表示に必要な解像度だけデコードし、取得中はプレースホルダーを出すネットワーク画像。
class DecodedNetworkImage extends StatelessWidget {
  const DecodedNetworkImage({
    super.key,
    required this.url,
    required this.logicalWidth,
    required this.logicalHeight,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String url;
  final double logicalWidth;
  final double logicalHeight;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return ColoredBox(color: AppColors.surfaceLight);
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (logicalWidth * dpr).round().clamp(1, 1 << 15);
    final cacheH = (logicalHeight * dpr).round().clamp(1, 1 << 15);

    return Image.network(
      url,
      fit: fit,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return ColoredBox(
          color: AppColors.surfaceLight,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
      errorBuilder: errorBuilder,
    );
  }
}
