import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../models/coffee.dart';
import '../../services/api_service.dart';
import '../../widgets/product_image.dart';

class AddEditProductScreen extends StatefulWidget {
  final Helmet? helmet;

  const AddEditProductScreen({super.key, this.helmet});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _ratingController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCategory = 'Half-face';
  bool _isLoading = false;

  // Multiple images support (max 3)
  List<XFile> _pickedImages = [];
  List<Uint8List> _pickedImagesBytes = [];

  final List<String> _categories = ['Half-face', 'Open-face', 'Full-face'];

  bool get _isEditing => widget.helmet != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.helmet!.name;
      _descController.text = widget.helmet!.description;
      _priceController.text = widget.helmet!.price.toStringAsFixed(0);
      _ratingController.text = widget.helmet!.rating.toString();
      _selectedCategory = widget.helmet!.category;
      if (widget.helmet!.address != null) _addressController.text = widget.helmet!.address!;
    }
  }

  Future<void> _pickSingleImage() async {
    if (_pickedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 3 foto'), backgroundColor: Colors.orange),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 60,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImages.add(picked);
        _pickedImagesBytes.add(bytes);
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    final remaining = 3 - _pickedImages.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 3 foto'), backgroundColor: Colors.orange),
      );
      return;
    }
    final picker = ImagePicker();
    try {
      final picked = await picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
      );
      if (picked.isNotEmpty) {
        final toAdd = picked.take(remaining).toList();
        for (final img in toAdd) {
          final bytes = await img.readAsBytes();
          _pickedImages.add(img);
          _pickedImagesBytes.add(bytes);
        }
        setState(() {});
      }
    } catch (e) {
      // Fallback to single pick
      await _pickSingleImage();
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
      _pickedImagesBytes.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool success;
    if (_isEditing) {
      success = await ApiService.updateProduct(
        id: widget.helmet!.id!,
        name: _nameController.text,
        description: _descController.text,
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        rating: double.tryParse(_ratingController.text) ?? 4.5,
        address: _addressController.text,
        imageBytesList: _pickedImagesBytes.isNotEmpty ? _pickedImagesBytes : null,
        imageFileNames: _pickedImages.isNotEmpty ? _pickedImages.map((e) => e.name).toList() : null,
        imagePath: (!kIsWeb && _pickedImages.isNotEmpty) ? _pickedImages.first.path : null,
      );
    } else {
      success = await ApiService.addProduct(
        name: _nameController.text,
        description: _descController.text,
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        rating: double.tryParse(_ratingController.text) ?? 4.5,
        address: _addressController.text,
        imageBytesList: _pickedImagesBytes.isNotEmpty ? _pickedImagesBytes : null,
        imageFileNames: _pickedImages.isNotEmpty ? _pickedImages.map((e) => e.name).toList() : null,
        imagePath: (!kIsWeb && _pickedImages.isNotEmpty) ? _pickedImages.first.path : null,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Produk berhasil diupdate!' : 'Produk berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan produk. Pastikan server berjalan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(_isEditing ? 'Edit Produk' : 'Tambah Produk'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Picker - multiple (max 3)
                  _buildLabel('Foto Produk (max 3)'),
                  const SizedBox(height: 8),
                  _buildMultiImagePicker(),
                  const SizedBox(height: 20),

                  // Nama
                  _buildLabel('Nama Produk'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Contoh: Helm Bogo Hijau',
                    validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),

                  // Deskripsi
                  _buildLabel('Deskripsi'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _descController,
                    hint: 'Deskripsi produk. Ukuran Allsize...',
                    maxLines: 4,
                    validator: (v) => v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),

                  // Harga
                  _buildLabel('Harga (Rp)'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _priceController,
                    hint: 'Contoh: 150000',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Harga wajib diisi';
                      if (double.tryParse(v) == null) return 'Masukkan angka yang valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Kategori
                  _buildLabel('Kategori'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: const Color(0xFF2A2A2D),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(border: InputBorder.none),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rating
                  _buildLabel('Rating (1-5)'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _ratingController,
                    hint: 'Contoh: 4.5',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  // Alamat
                  _buildLabel('Alamat (opsional)'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _addressController,
                    hint: 'Contoh: Jl. Merdeka No. 10, Bandung',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isEditing ? 'Update Produk' : 'Tambah Produk',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show picked images
        if (_pickedImagesBytes.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pickedImagesBytes.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                        image: DecorationImage(
                          image: MemoryImage(_pickedImagesBytes[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // Show existing images (edit mode) when no new images picked
        if (_pickedImagesBytes.isEmpty && _isEditing && widget.helmet!.imageUrl != null)
          _buildExistingImages(),

        const SizedBox(height: 12),

        // Counter
        Text(
          '${_pickedImagesBytes.length}/3 foto dipilih',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 8),

        // Buttons
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pickedImages.length < 3 ? _pickSingleImage : null,
              icon: const Icon(Icons.add_photo_alternate, color: Colors.white70),
              label: const Text('Tambah Foto', style: TextStyle(color: Colors.white70)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 8),
            if (_pickedImages.length < 3)
              OutlinedButton.icon(
                onPressed: _pickMultipleImages,
                icon: const Icon(Icons.photo_library, color: Colors.white70, size: 18),
                label: const Text('Pilih Banyak', style: TextStyle(color: Colors.white70, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildExistingImages() {
    final urls = ProductImage.parseImageUrls(widget.helmet!.imageUrl);
    if (urls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (context, index) {
          final imgUrl = urls[index];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imgUrl.startsWith('data:')
                  ? Image.memory(
                      base64Decode(imgUrl.split(',').last),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image, color: Colors.white38),
                    )
                  : Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image, color: Colors.white38),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF2A2A2D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _ratingController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
