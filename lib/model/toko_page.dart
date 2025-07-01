import 'package:flutter/material.dart';
import 'package:dapur_anita/model/produk.dart';
import 'package:dapur_anita/konstanta.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TokoPage extends StatefulWidget {
  const TokoPage({super.key});

  @override
  State<TokoPage> createState() => _TokoPageState();
}

class _TokoPageState extends State<TokoPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.amber[400],
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[400],
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              // Retry loading data
              if (_tabController.index == 0) {
                fetchProduk();
              } else {
                fetchKategori();
              }
            },
            child: const Text('Coba Lagi'),
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
        automaticallyImplyLeading: false,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.amber[400]!, width: 1),
          ),
          child: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              border: InputBorder.none,
              hintText: 'Cari di Toko',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.amber[400]),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Produk'),
            Tab(text: 'Kategori Produk'),
          ],
          labelColor: Colors.amber[400],
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: Colors.amber[400],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProdukTab(),
          _buildKategoriTab(),
        ],
      ),
    );
  }

  Widget _buildProdukTab() {
    return FutureBuilder<List<ProdukResponModel>>(
      future: fetchProduk(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
            ),
          );
        } else if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.amber[400],
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum Ada Produk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Produk akan ditampilkan di sini',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var produk = snapshot.data![index];
            return Card(
              color: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber[400]!.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      color: Colors.grey[800],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image,
                        color: Colors.amber[400],
                        size: 40,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produk.namaProduk.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rp ${produk.hargaProduk}",
                          style: TextStyle(
                            color: Colors.amber[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Stok: ${produk.stok}",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKategoriTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchKategori(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
            ),
          );
        } else if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  color: Colors.amber[400],
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum Ada Kategori',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kategori akan ditampilkan di sini',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var kategori = snapshot.data![index];
            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber[400]!.withOpacity(0.5)),
              ),
              child: ListTile(
                title: Text(
                  kategori['nama_kategori'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.amber[400],
                ),
                onTap: () {
                  // Handle kategori tap
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<ProdukResponModel>> fetchProduk() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/getProduk'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Produk Response Status: ${response.statusCode}');
      print('Produk Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => ProdukResponModel.fromJson(e)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Gagal memuat produk: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchKategori() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/kategori'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Kategori Response Status: ${response.statusCode}');
      print('Kategori Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      throw Exception('Gagal memuat kategori: $e');
    }
  }
} 