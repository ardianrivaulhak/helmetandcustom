import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
        
        // Handle both paginated and non-paginated response
        List<dynamic> reviewList;
        if (decoded is List) {
          // Old format: array langsung
          reviewList = decoded;
          setState(() {
            _reviews = reviewList.cast<Map<String, dynamic>>();
            _currentPage = 1;
            _totalPages = 1;
          });
        } else {
          // New format: {data: [...], page, totalPages}
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
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
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) return;
                          await _submitReview(commentController.text.trim(), selectedRating);
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

  Future<void> _submitReview(String comment, int rating) async {
    try {
      final response = await http.post(
        Uri.parse('https://helmetandcustom.vercel.app/api/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': AuthService.userId,
          'user_name': AuthService.userName,
          'comment': comment,
          'rating': rating,
        }),
      );
      if (response.statusCode == 201) {
        _loadReviews(page: 1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review berhasil ditambahkan!'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF2A2A2D), borderRadius: BorderRadius.circular(16)),
      child: _buildReviewContent(name, date, rating, productName, comment),
    );
  }

  Widget _buildReviewContent(String name, String date, int rating, String? productName, String comment) {
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
      ],
    );
  }
}
