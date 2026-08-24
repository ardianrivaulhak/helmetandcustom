import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews({int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://helmetandcustom.vercel.app/api/reviews?page=$page&limit=5'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> reviewList;
        if (decoded is List) {
          reviewList = decoded;
          setState(() {
            _reviews = reviewList.cast<Map<String, dynamic>>();
            _currentPage = 1;
            _totalPages = 1;
          });
        } else {
          reviewList = decoded['data'] ?? [];
          setState(() {
            _reviews = reviewList.cast<Map<String, dynamic>>();
            _currentPage = decoded['page'] ?? 1;
            _totalPages = decoded['totalPages'] ?? 1;
          });
        }
      } else {
        print('Reviews API error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error loading reviews: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showAddReviewDialog() {
    final commentController = TextEditingController();
    int selectedRating = 5;
    List<XFile> selectedImages = [];
    List<Uint8List> imageBytes = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool isPickingImage = false;

          Future<void> pickImages() async {
            if (isPickingImage) return;
            isPickingImage = true;
            final picker = ImagePicker();
            final remaining = 3 - selectedImages.length;
            if (remaining <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Maksimal 3 foto'), backgroundColor: Colors.orange),
              );
              isPickingImage = false;
              return;
            }

            try {
              // Coba pickMultiImage dulu
              final picked = await picker.pickMultiImage(
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 80,
              );
              if (picked.isNotEmpty) {
                final toAdd = picked.take(remaining).toList();
                for (final img in toAdd) {
                  final bytes = await img.readAsBytes();
                  selectedImages.add(img);
                  imageBytes.add(bytes);
                }
                setDialogState(() {});
              }
            } catch (e) {
              // Fallback: pilih satu-satu
              final img = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 80,
              );
              if (img != null) {
                final bytes = await img.readAsBytes();
                selectedImages.add(img);
                imageBytes.add(bytes);
                setDialogState(() {});
              }
            }
            isPickingImage = false;
          }

          Future<void> pickSingleImage() async {
            if (isPickingImage) return;
            isPickingImage = true;
            final remaining = 3 - selectedImages.length;
            if (remaining <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Maksimal 3 foto'), backgroundColor: Colors.orange),
              );
              isPickingImage = false;
              return;
            }
            final picker = ImagePicker();
            final img = await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1024,
              maxHeight: 1024,
              imageQuality: 80,
            );
            if (img != null) {
              final bytes = await img.readAsBytes();
              selectedImages.add(img);
              imageBytes.add(bytes);
              setDialogState(() {});
            }
            isPickingImage = false;
          }

          return Dialog(
            backgroundColor: const Color(0xFF2A2A2D),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tulis Review', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text('Rating:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedRating = i + 1),
                          child: Icon(i < selectedRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    const Text('Komentar:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tulis review kamu...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF1C1C1E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Image picker section
                    Row(
                      children: [
                        const Text('Foto (max 3):', style: TextStyle(color: Colors.white70)),
                        const Spacer(),
                        Text('${selectedImages.length}/3', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Preview selected images
                    if (imageBytes.isNotEmpty)
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageBytes.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: MemoryImage(imageBytes[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedImages.removeAt(index);
                                        imageBytes.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: selectedImages.length < 3 ? pickSingleImage : null,
                          icon: const Icon(Icons.add_photo_alternate, color: Colors.white70),
                          label: const Text('Tambah Foto', style: TextStyle(color: Colors.white70)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (selectedImages.length < 3)
                          OutlinedButton.icon(
                            onPressed: pickImages,
                            icon: const Icon(Icons.photo_library, color: Colors.white70, size: 18),
                            label: const Text('Pilih Banyak', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) return;
                          await _submitReview(commentController.text.trim(), selectedRating, selectedImages);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                        child: const Text('Kirim', style: TextStyle(color: Colors.white)),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitReview(String comment, int rating, List<XFile> images) async {
    try {
      // Use multipart request to send images
      final uri = Uri.parse('https://helmetandcustom.vercel.app/api/reviews');
      final request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = AuthService.userId?.toString() ?? '';
      request.fields['user_name'] = AuthService.userName;
      request.fields['comment'] = comment;
      request.fields['rating'] = rating.toString();

      // Attach images (max 3)
      for (final img in images) {
        final bytes = await img.readAsBytes();
        final filename = img.name.isNotEmpty ? img.name : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        request.files.add(http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: filename,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        _loadReviews(page: 1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review berhasil ditambahkan!'), backgroundColor: Colors.green));
        }
      } else {
        print('Submit review error: ${response.statusCode} ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menambah review'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      print('Submit review exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menambah review'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(backgroundColor: const Color(0xFF1C1C1E), title: const Text('Review Pembeli'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _reviews.isEmpty
              ? const Center(child: Text('Belum ada review', style: TextStyle(color: Colors.white54, fontSize: 16)))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _loadReviews(page: _currentPage),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 700;
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 800),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _reviews.length,
                                  itemBuilder: (context, index) => _buildReviewCard(_reviews[index], isWide),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Pagination
                    if (_totalPages > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        color: const Color(0xFF2A2A2D),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                              onPressed: _currentPage > 1 ? () => _loadReviews(page: _currentPage - 1) : null,
                            ),
                            ...List.generate(_totalPages, (i) {
                              final page = i + 1;
                              final isActive = page == _currentPage;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () => _loadReviews(page: page),
                                  child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFF1565C0) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isActive ? const Color(0xFF1565C0) : Colors.white24),
                                    ),
                                    child: Center(child: Text('$page', style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.bold))),
                                  ),
                                ),
                              );
                            }),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: Colors.white),
                              onPressed: _currentPage < _totalPages ? () => _loadReviews(page: _currentPage + 1) : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
      floatingActionButton: AuthService.isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: _showAddReviewDialog,
              backgroundColor: const Color(0xFF1565C0),
              icon: const Icon(Icons.rate_review, color: Colors.white),
              label: const Text('Tulis Review', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, bool isWide) {
    final int rating = review['rating'] ?? 5;
    final String name = review['user_name'] ?? 'Anonim';
    final String comment = review['comment'] ?? '';
    final String? productName = review['product_name'];
    final String date = review['created_at'] ?? '';

    // Parse image_urls (stored as JSON string)
    List<String> imageUrls = [];
    if (review['image_urls'] != null && review['image_urls'].toString().isNotEmpty) {
      try {
        final parsed = json.decode(review['image_urls']);
        if (parsed is List) {
          imageUrls = parsed.cast<String>();
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF2A2A2D), borderRadius: BorderRadius.circular(16)),
      child: _buildReviewContent(name, date, rating, productName, comment, imageUrls),
    );
  }

  Widget _buildReviewContent(String name, String date, int rating, String? productName, String comment, List<String> imageUrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1565C0),
              radius: 18,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                if (date.isNotEmpty) Text(date.toString().split('T').first.split(' ').first, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
            ),
            Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 16))),
          ],
        ),
        if (productName != null && productName.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(productName, style: const TextStyle(color: Color(0xFF1565C0), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
        const SizedBox(height: 8),
        Text(comment, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
        // Display review images
        if (imageUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullImage(context, imageUrls, index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: NetworkImage(imageUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _showFullImage(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    child: Center(
                      child: Image.network(
                        imageUrls[index],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        },
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
