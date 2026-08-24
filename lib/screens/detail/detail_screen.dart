import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/coffee.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatefulWidget {
  final Helmet helmet;
  const DetailScreen({super.key, required this.helmet});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  Future<void> _loadLikeStatus() async {
    if (widget.helmet.id == null) return;
    try {
      final countRes = await http.get(Uri.parse('http://localhost:3000/api/likes/product/${widget.helmet.id}'));
      if (countRes.statusCode == 200) {
        setState(() => _likeCount = json.decode(countRes.body)['total'] ?? 0);
      }
      if (AuthService.userId != null) {
        final checkRes = await http.get(Uri.parse('http://localhost:3000/api/likes/check/${widget.helmet.id}/${AuthService.userId}'));
        if (checkRes.statusCode == 200) {
          setState(() => _isLiked = json.decode(checkRes.body)['liked'] ?? false);
        }
      }
    } catch (e) {}
  }

  Future<void> _toggleLike() async {
    if (!AuthService.isLoggedIn || AuthService.userId == null) return;
    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/api/likes/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'product_id': widget.helmet.id, 'user_id': AuthService.userId}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _isLiked = data['liked'];
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    } catch (e) {}
  }

  void _orderViaWhatsApp() async {
    final helmet = widget.helmet;
    final message = 'Halo, saya ingin memesan:\n'
        '🪖 ${helmet.name}\n'
        '📏 Ukuran: Allsize\n'
        '💰 Harga: Rp ${helmet.price.toStringAsFixed(0)}\n\n'
        'Apakah stok masih tersedia?';
    final uri = Uri.parse('https://wa.me/6281997635073?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiService.getImageUrl(widget.helmet.imageUrl);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: isDesktop ? _buildDesktopLayout(imageUrl) : _buildMobileLayout(imageUrl),
          ),
        ),
      ),
    );
  }

  // Desktop: gambar di kiri, detail di kanan
  Widget _buildDesktopLayout(String imageUrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image side
        Expanded(
          flex: 1,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _imagePlaceholder())
                    : _imagePlaceholder(),
              ),
              _buildTopButtons(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Detail side
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildDetailContent(),
          ),
        ),
      ],
    );
  }

  // Mobile: gambar di atas, detail di bawah
  Widget _buildMobileLayout(String imageUrl) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Image
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _imagePlaceholder())
                    : _imagePlaceholder(),
              ),
              _buildTopButtons(),
            ],
          ),
          // Detail
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2D).withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: _buildDetailContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            GestureDetector(
              onTap: _toggleLike,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : Colors.white, size: 22),
                  const SizedBox(width: 4),
                  Text('$_likeCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.helmet.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(widget.helmet.category, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 12),
        Text('Rp ${widget.helmet.price.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF1565C0), fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text(widget.helmet.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF1565C0).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: const Text('📏 Ukuran: Allsize', style: TextStyle(color: Color(0xFF42A5F5), fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 20),
        const Text('Deskripsi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(widget.helmet.description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _orderViaWhatsApp,
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text('Pesan via WhatsApp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(color: const Color(0xFF3A3A3D), child: const Center(child: Icon(Icons.sports_motorsports, size: 80, color: Colors.white38)));
  }
}
