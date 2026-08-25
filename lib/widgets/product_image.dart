import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  /// Parse image_url which can be:
  /// - null/empty
  /// - a single URL string (http...)
  /// - a base64 data URL (data:image/...)
  /// - a JSON array: '["data:image/jpeg;base64,...","data:image/jpeg;base64,..."]'
  static List<String> parseImageUrls(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return [];

    // Try parsing as JSON array first
    if (imageUrl.trimLeft().startsWith('[')) {
      try {
        final parsed = json.decode(imageUrl);
        if (parsed is List && parsed.isNotEmpty) {
          return parsed.cast<String>();
        }
      } catch (_) {}
    }

    // Single data URL
    if (imageUrl.startsWith('data:')) {
      return [imageUrl];
    }

    // Single network URL
    if (imageUrl.startsWith('http')) {
      return [imageUrl];
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final urls = parseImageUrls(imageUrl);

    if (urls.isEmpty) {
      return _placeholder();
    }

    // Show first image only for card/thumbnail
    return _buildImage(urls.first);
  }

  Widget _buildImage(String url) {
    // Base64 data URL
    if (url.startsWith('data:')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (c, e, s) => _placeholder(),
        );
      } catch (e) {
        return _placeholder();
      }
    }

    // Network image
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (c, e, s) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF3A3A3D),
      child: const Center(
        child: Icon(Icons.sports_motorsports, size: 50, color: Colors.white38),
      ),
    );
  }
}
