import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/coffee.dart';

class ApiService {
  // API URL - production
  static const String baseUrl = 'https://helmetandcustom.vercel.app/api';

  // GET semua produk (dengan pagination)
  static Future<Map<String, dynamic>> getProducts({int page = 1, int limit = 8}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products?page=$page&limit=$limit'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> products = data['data'] ?? [];
        return {
          'products': products.map((json) => Helmet.fromJson(json)).toList(),
          'page': data['page'] ?? 1,
          'totalPages': data['totalPages'] ?? 1,
          'total': data['total'] ?? 0,
        };
      }
      return {'products': <Helmet>[], 'page': 1, 'totalPages': 1, 'total': 0};
    } catch (e) {
      print('Error fetching products: $e');
      return {'products': <Helmet>[], 'page': 1, 'totalPages': 1, 'total': 0};
    }
  }

  // POST tambah produk
  static Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    double rating = 4.5,
    String? imagePath,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/products'));
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['category'] = category;
      request.fields['rating'] = rating.toString();

      if (kIsWeb && imageBytes != null && imageFileName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFileName,
        ));
      } else if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      final response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  // PUT update produk
  static Future<bool> updateProduct({
    required int id,
    required String name,
    required String description,
    required double price,
    required String category,
    double rating = 4.5,
    String? imagePath,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/products/$id'));
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['category'] = category;
      request.fields['rating'] = rating.toString();

      if (kIsWeb && imageBytes != null && imageFileName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFileName,
        ));
      } else if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // DELETE hapus produk
  static Future<bool> deleteProduct(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/products/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // URL lengkap untuk gambar
  static String getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    return 'https://helmetandcustom.vercel.app/uploads/$imageUrl';
  }
}
