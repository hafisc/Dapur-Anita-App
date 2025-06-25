import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dapur_anita/konstanta.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dapur_anita/model/kategori.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';

class EditForm extends StatefulWidget {
  final String idBarang;

  const EditForm({super.key, required this.idBarang});

  @override
  State<EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<EditForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaProdukController = TextEditingController();
  final TextEditingController hargaProdukController = TextEditingController();
  final TextEditingController stokController = TextEditingController();
  final TextEditingController beratController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  
  KategoriModel? selectedKategori;
  List<KategoriModel> kategoriList = [];
  bool isLoading = false;
  XFile? _imageFile;
  Uint8List? _webImage;
  final picker = ImagePicker();
  String? existingImage;

  @override
  void initState() {
    super.initState();
    fetchKategori().then((_) => getData());
  }

  Future<void> fetchKategori() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/kategori'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          kategoriList = data.map((item) => KategoriModel.fromJson(item)).toList();
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      showError('Gagal memuat kategori: $e');
    }
  }

  Future<void> getData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/editApi/${widget.idBarang}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null || data['user'] == null) {
          throw Exception('Data produk tidak ditemukan');
        }
        
        final produkData = data['user'];
        setState(() {
          namaProdukController.text = produkData['nama_produk'] ?? '';
          hargaProdukController.text = produkData['harga_produk']?.toString() ?? '';
          stokController.text = produkData['stok']?.toString() ?? '';
          beratController.text = produkData['berat']?.toString() ?? '';
          deskripsiController.text = produkData['deskripsi_produk'] ?? '';
          existingImage = produkData['foto_produk'];
          
          // Set selected kategori
          if (produkData['id_kategori'] != null && kategoriList.isNotEmpty) {
            selectedKategori = kategoriList.firstWhere(
              (kategori) => kategori.idKategori == produkData['id_kategori'],
              orElse: () => kategoriList.first,
            );
          }
        });
      } else {
        throw Exception('Failed to load product data');
      }
    } catch (e) {
      print('Error: $e');
      showError('Gagal memuat data produk: ${e.toString()}');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        if (kIsWeb) {
          var bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = pickedFile;
          });
        } else {
          setState(() {
            _imageFile = pickedFile;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      showError('Gagal memilih gambar');
    }
  }

  Widget _buildImagePreview() {
    if (_imageFile == null && _webImage == null && existingImage != null) {
      return Stack(
        children: [
          Image.network(
            '$baseUrl/produk/$existingImage',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading image: $error');
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.amber[400], size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: Colors.amber[400]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap untuk memilih gambar baru',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              );
            },
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
                ),
              );
            },
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(4),
              child: const Text(
                'Tap untuk mengubah',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_imageFile == null && _webImage == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload, color: Colors.amber[400], size: 48),
          const SizedBox(height: 8),
          Text(
            'Upload Foto Produk',
            style: TextStyle(color: Colors.amber[400]),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap untuk memilih gambar',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      );
    }

    if (kIsWeb && _webImage != null) {
      return Stack(
        children: [
          Image.memory(
            _webImage!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(4),
              child: const Text(
                'Gambar baru dipilih',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!kIsWeb && _imageFile != null) {
      return Stack(
        children: [
          Image.file(
            File(_imageFile!.path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(4),
              child: const Text(
                'Gambar baru dipilih',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  Future<void> updateData() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedKategori == null) {
      showError('Silakan pilih kategori produk');
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/updateApi/${widget.idBarang}'),
      );
      
      request.fields.addAll({
        'nama_produk': namaProdukController.text,
        'kategori_produk': selectedKategori!.idKategori.toString(),
        'stok_produk': stokController.text,
        'berat_produk': beratController.text,
        'harga_produk': hargaProdukController.text,
        'deskripsi_produk': deskripsiController.text,
        'foto_lama': existingImage ?? '',
        '_method': 'PUT',
      });

      if (kIsWeb) {
        if (_webImage != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'img1',
              _webImage!,
              filename: 'product_image.jpg',
            ),
          );
        }
      } else {
        if (_imageFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'img1',
              _imageFile!.path,
            ),
          );
        }
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Berhasil!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Produk berhasil diperbarui',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[400],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context, true); // Return to previous screen with refresh flag
                      },
                      child: const Text(
                        'Kembali',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        throw Exception('Gagal memperbarui produk: ${response.statusCode}');
      }
    } catch (e) {
      showError('Gagal memperbarui produk: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: Colors.amber[400])),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text(
          'Edit Produk',
          style: TextStyle(color: Colors.amber[400]),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.amber[400]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Data Produk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              
              // Nama Produk
              TextFormField(
                controller: namaProdukController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nama Produk',
                  labelStyle: TextStyle(color: Colors.amber[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2D2D2D),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama produk tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kategori Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[400]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<KategoriModel>(
                    dropdownColor: const Color(0xFF2D2D2D),
                    isExpanded: true,
                    value: selectedKategori,
                    hint: Text(
                      kategoriList.isEmpty 
                        ? 'Loading kategori...' 
                        : 'Pilih Kategori Produk',
                      style: TextStyle(color: Colors.amber[400])
                    ),
                    items: kategoriList.map((KategoriModel kategori) {
                      return DropdownMenuItem<KategoriModel>(
                        value: kategori,
                        child: Text(
                          kategori.namaKategori ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (KategoriModel? newValue) {
                      setState(() {
                        selectedKategori = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stok dan Berat dalam satu row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: stokController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stok Produk',
                        labelStyle: TextStyle(color: Colors.amber[400]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2D2D2D),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Stok tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: beratController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Berat (gram)',
                        labelStyle: TextStyle(color: Colors.amber[400]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2D2D2D),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Berat tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Harga Produk
              TextFormField(
                controller: hargaProdukController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga Produk',
                  labelStyle: TextStyle(color: Colors.amber[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2D2D2D),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Deskripsi Produk
              TextFormField(
                controller: deskripsiController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Produk',
                  labelStyle: TextStyle(color: Colors.amber[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2D2D2D),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Upload Foto Button
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[400]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImagePreview(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : updateData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[400],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Update',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}