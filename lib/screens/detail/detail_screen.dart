import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../models/coffee.dart';
import '../../services/auth_service.dart';
import '../../widgets/product_image.dart';
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
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadLikeStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadLikeStatus() async {
    if (widget.helmet.id == null) return;
    try {
      final countRes = await http.get(Uri.parse('https://helmetandcustom.vercel.app/api/likes/product/${widget.helmet.id}'));
      if (countRes.statusCode == 200) {
        setState(() => _likeCount = json.decode(countRes.body)['total'] ?? 0);
      }
      if (AuthService.userId != null) {
        final checkRes = await http.get(Uri.parse('https://helmetandcustom.vercel.app/api/likes/check/${widget.helmet.id}/${AuthService.userId}'));
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
        Uri.parse('https://helmetandcustom.vercel.app/api/likes/toggle'),
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
    final imageUrls = ProductImage.parseImageUrls(widget.helmet.imageUrl);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: isDesktop ? _buildDesktopLayout(imageUrls) : _buildMobileLayout(imageUrls),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls, {double? height}) {
    if (imageUrls.isEmpty) {
      return Container(
        height: height ?? 300,
        color: const Color(0xFF3A3A3D),
        child: const Center(child: Icon(Icons.sports_motorsports, size: 80, color: Colors.white38)),
      );
    }

    if (imageUrls.length == 1) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: _buildSingleImage(imageUrls.first),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: height ?? 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              return _buildSingleImage(imageUrls[index]);
            },
          ),
        ),
        // Dot indicators
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imageUrls.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentImageIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentImageIndex == index ? const Color(0xFF1565C0) : Colors.white54,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleImage(String url) {
    if (url.startsWith('data:')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (c, e, s) => Container(
            color: const Color(0xFF3A3A3D),
            child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white38)),
          ),
        );
      } catch (e) {
        return Container(
          color: const Color(0xFF3A3A3D),
          child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white38)),
        );
      }
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (c, e, s) => Container(
        color: const Color(0xFF3A3A3D),
        child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white38)),
      ),
    );
  }

  // Desktop: gambar di kiri, detail di kanan
  Widget _buildDesktopLayout(List<String> imageUrls) {
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
                child: _buildImageCarousel(imageUrls, height: double.infinity),
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
  Widget _buildMobileLayout(List<String> imageUrls) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Image carousel
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: _buildImageCarousel(imageUrls),
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
        if (widget.helmet.address != null && widget.helmet.address!.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Lokasi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final query = Uri.encodeComponent(widget.helmet.address!);
              final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.helmet.address!, style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 14, decoration: TextDecoration.underline))),
                  const Icon(Icons.open_in_new, color: Colors.white38, size: 16),
                ],
              ),
            ),
          ),
        ],
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

}
