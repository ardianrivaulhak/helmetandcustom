import 'package:flutter/material.dart';
import '../../models/coffee.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/product_image.dart';
import '../detail/detail_screen.dart';
import '../reviews/reviews_screen.dart';
import '../admin/add_edit_product_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  List<Helmet> _helmets = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts({int page = 1}) async {
    setState(() => _isLoading = true);
    final result = await ApiService.getProducts(page: page, limit: 8);
    setState(() {
      _helmets = result['products'] as List<Helmet>;
      _currentPage = result['page'] as int;
      _totalPages = result['totalPages'] as int;
      _isLoading = false;
    });
  }

  Future<void> _deleteProduct(Helmet helmet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2D),
        title: const Text('Hapus Produk', style: TextStyle(color: Colors.white)),
        content: Text('Yakin ingin menghapus "${helmet.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && helmet.id != null) {
      final success = await ApiService.deleteProduct(helmet.id!);
      if (success) _loadProducts(page: _currentPage);
    }
  }

  void _logout() {
    AuthService.logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search helmets...',
                            hintStyle: TextStyle(color: Colors.white54),
                            prefixIcon: Icon(Icons.search, color: Color(0xFF1565C0)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    if (AuthService.isAdmin) ...[
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () async {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (c) => const AddEditProductScreen()));
                            if (result == true) _loadProducts(page: _currentPage);
                          },
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                      child: IconButton(icon: const Icon(Icons.logout, color: Colors.white54), onPressed: _logout),
                    ),
                  ],
                ),
              ),

              // Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                    : _helmets.isEmpty
                        ? const Center(child: Text('Belum ada produk.', style: TextStyle(color: Colors.white, fontSize: 16)))
                        : RefreshIndicator(
                            onRefresh: () => _loadProducts(page: _currentPage),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                int crossAxisCount;
                                double childAspectRatio;
                                if (width > 1200) { crossAxisCount = 5; childAspectRatio = 0.65; }
                                else if (width > 900) { crossAxisCount = 4; childAspectRatio = 0.65; }
                                else if (width > 600) { crossAxisCount = 3; childAspectRatio = 0.65; }
                                else { crossAxisCount = 2; childAspectRatio = 0.6; }

                                return GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: childAspectRatio,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _helmets.length,
                                  itemBuilder: (context, index) => _buildHelmetCard(_helmets[index]),
                                );
                              },
                            ),
                          ),
              ),

              // Pagination
              if (!_isLoading && _totalPages > 1)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: _currentPage > 1 ? () => _loadProducts(page: _currentPage - 1) : null,
                      ),
                      ...List.generate(_totalPages, (i) {
                        final page = i + 1;
                        final isActive = page == _currentPage;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => _loadProducts(page: page),
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
                        onPressed: _currentPage < _totalPages ? () => _loadProducts(page: _currentPage + 1) : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ReviewsScreen()));
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        backgroundColor: const Color(0xFF2A2A2D),
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.rate_review), label: 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildHelmetCard(Helmet helmet) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailScreen(helmet: helmet))),
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(imageUrl: helmet.imageUrl, fit: BoxFit.cover),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(helmet.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                    if (AuthService.isAdmin)
                      Positioned(top: 8, left: 8, child: Row(children: [
                        _miniBtn(Icons.edit, const Color(0xFF1565C0), () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (c) => AddEditProductScreen(helmet: helmet)));
                          if (result == true) _loadProducts(page: _currentPage);
                        }),
                        const SizedBox(width: 4),
                        _miniBtn(Icons.delete, Colors.red, () => _deleteProduct(helmet)),
                      ])),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(helmet.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Expanded(child: Text(helmet.description, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Flexible(child: Text(formatCurrency(helmet.price), style: const TextStyle(color: Color(0xFF1565C0), fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.chat, color: Colors.white, size: 18)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: Colors.white, size: 16)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
