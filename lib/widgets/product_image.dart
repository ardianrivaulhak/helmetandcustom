import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  /// - a single URL string
  /// - a base64 data URL
  /// - a JSON array of URLs: '["url1","url2","url3"]'
  static List<String> parseImageUrls(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return [];
    final url = ApiService.getImageUrl(imageUrl);
    if (url.isEmpty) return [];

    // Try parsing as JSON array
    if (url.startsWith('[') || imageUrl.startsWith('[')) {
      try {
        final raw = imageUrl.startsWith('[') ? imageUrl : url;
        final parsed = json.decode(raw);
        if (parsed is List) {
          return parsed.cast<String>();
        }
      } catch (_) {}
    }

    return [url];
  }

  @override
  Widget build(BuildContext context) {
    final urls = parseImageUrls(imageUrl);

    if (urls.isEmpty) {
      return _placeholder();
    }

    // Show first image for card/thumbnail usage
    return _buildImage(urls.first);
  }

  Widget _buildImage(String url) {
    // Base64 image
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
