import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../models/coffee.dart';
import '../../services/api_service.dart';

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
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _pickedImageBytes = bytes;
      });
    }
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
        imagePath: (!kIsWeb && _pickedImage != null) ? _pickedImage!.path : null,
        imageBytes: (kIsWeb && _pickedImageBytes != null) ? _pickedImageBytes : null,
        imageFileName: _pickedImage?.name,
      );
    } else {
      success = await ApiService.addProduct(
        name: _nameController.text,
        description: _descController.text,
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        rating: double.tryParse(_ratingController.text) ?? 4.5,
        address: _addressController.text,
        imagePath: (!kIsWeb && _pickedImage != null) ? _pickedImage!.path : null,
        imageBytes: (kIsWeb && _pickedImageBytes != null) ? _pickedImageBytes : null,
        imageFileName: _pickedImage?.name,
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
                  // Image Picker - responsive
                  _buildLabel('Foto Produk'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final height = width * 0.6; // aspect ratio 5:3
                        return Container(
                          width: double.infinity,
                          height: height,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2D),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildImagePreview(),
                          ),
                        );
                      },
                    ),
                  ),
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

  Widget _buildImagePreview() {
    // Gambar baru dipilih
    if (_pickedImageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            _pickedImageBytes!,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
          _buildChangeLabel(),
        ],
      );
    }

    // Gambar lama dari server (edit mode)
    if (_isEditing && widget.helmet!.imageUrl != null) {
      final url = ApiService.getImageUrl(widget.helmet!.imageUrl);
      if (url.isNotEmpty) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, st) => _buildPlaceholder(),
            ),
            _buildChangeLabel(),
          ],
        );
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildChangeLabel() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Tap untuk ganti',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 50, color: Colors.white38),
        SizedBox(height: 8),
        Text(
          'Tap untuk pilih foto',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      ],
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
