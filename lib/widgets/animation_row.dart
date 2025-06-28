import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AnimatedLampRow extends StatelessWidget {
  final List<String> imagePaths;
  final double imageSize;
  final double spacing;
  const AnimatedLampRow({
    super.key,
    required this.imagePaths,
    this.imageSize = 60,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: imageSize + 16,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: imagePaths.map((path) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.white,
                period: const Duration(milliseconds: 1200),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    path,
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: imageSize,
                      height: imageSize,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
