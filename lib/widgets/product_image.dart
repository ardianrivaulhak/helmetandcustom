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

  @override
  Widget build(BuildContext context) {
    final url = ApiService.getImageUrl(imageUrl);
    
    if (url.isEmpty) {
      return _placeholder();
    }

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
