import 'package:flutter/material.dart';
import 'package:dapur_anita/konstanta.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dapur_anita/auth/alamat_page.dart';

class CartItem {
  final int id;
  final String name;
  final String image;
  final int price;
  final String variant;
  int quantity;
  bool isSelected;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.variant,
    required this.quantity,
    this.isSelected = true,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      name: json['nama_produk'] ?? '',
      image: json['foto_produk'] ?? '',
      price: json['harga_produk'] ?? 0,
      variant: json['berat']?.toString() ?? '',
      quantity: json['jumlah'] ?? 1,
      isSelected: true,
    );
  }
}

Future<bool> addToCart(BuildContext context, int productId, int quantity) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id');
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/keranjang'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'id_user': userId,
        'id_produk': productId,
        'jumlah': quantity,
      }),
    );

    print('Request URL: $baseUrl/api/keranjang');
    print('Request Body: ${json.encode({
      'id_user': userId,
      'id_produk': productId,
      'jumlah': quantity,
    })}');

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil menambahkan ke keranjang'),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } else {
      print('Error Response: ${response.body}');
      print('Status Code: ${response.statusCode}');
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal menambahkan ke keranjang');
    }
  } catch (e) {
    print('Exception: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }
}

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  List<CartItem> cartItems = [];
  bool selectAll = true;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');
      
      if (userId == null) {
        setState(() {
          error = "Silakan login terlebih dahulu";
          isLoading = false;
        });
        return;
      }

      print('Fetching cart items for user $userId');
      final response = await http.get(
        Uri.parse('$baseUrl/api/keranjang/$userId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          cartItems = data.map((item) => CartItem.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Gagal memuat keranjang: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching cart items: $e');
      setState(() {
        error = "Terjadi kesalahan: $e";
        isLoading = false;
      });
    }
  }

  Future<void> updateCartItemQuantity(int itemId, int quantity) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');

      if (userId == null) return;

      final response = await http.put(
        Uri.parse('$baseUrl/api/keranjang/$itemId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'quantity': quantity,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal mengupdate jumlah');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void updateQuantity(int index, bool increment) async {
    final item = cartItems[index];
    final newQuantity = increment ? item.quantity + 1 : item.quantity - 1;
    
    if (newQuantity < 1) return;

    setState(() {
      cartItems[index].quantity = newQuantity;
    });

    await updateCartItemQuantity(item.id, newQuantity);
  }

  Future<void> deleteSelectedItems() async {
    try {
      for (var item in cartItems.where((item) => item.isSelected)) {
        final response = await http.delete(
          Uri.parse('$baseUrl/api/keranjang/${item.id}'),
          headers: {
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            cartItems.removeWhere((cartItem) => cartItem.id == item.id);
          });
        } else {
          throw Exception('Gagal menghapus item');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      for (var item in cartItems) {
        item.isSelected = selectAll;
      }
    });
  }

  void toggleSelectItem(int index) {
    setState(() {
      cartItems[index].isSelected = !cartItems[index].isSelected;
      selectAll = cartItems.every((item) => item.isSelected);
    });
  }

  int get totalPrice {
    return cartItems
        .where((item) => item.isSelected)
        .fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get selectedCount {
    return cartItems.where((item) => item.isSelected).length;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Keranjang'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchCartItems,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text(
          'Keranjang',
          style: TextStyle(color: Colors.amber[400]),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.amber[400]),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton.icon(
              onPressed: deleteSelectedItems,
              icon: Icon(Icons.delete, color: Colors.red[400]),
              label: Text(
                'Hapus',
                style: TextStyle(color: Colors.red[400]),
              ),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Text(
                'Keranjang kosong',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchCartItems,
                    color: Colors.amber[400],
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Card(
                          color: const Color(0xFF2D2D2D),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.amber[400]!.withOpacity(0.5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.isSelected,
                                  onChanged: (_) => toggleSelectItem(index),
                                  activeColor: Colors.amber[400],
                                  checkColor: Colors.black,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    '$gambarUrl/produk/${item.image}',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[800],
                                        child: Icon(Icons.error, color: Colors.amber[400]),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      if (item.variant.isNotEmpty) ...[
                                        Text(
                                          item.variant,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        'Rp${item.price}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[400],
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.remove, color: Colors.amber[400]),
                                            onPressed: () => updateQuantity(index, false),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[800],
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.amber[400]!.withOpacity(0.5)),
                                            ),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.add, color: Colors.amber[400]),
                                            onPressed: () => updateQuantity(index, true),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: selectAll,
                              onChanged: (_) => toggleSelectAll(),
                              activeColor: Colors.amber[400],
                              checkColor: Colors.black,
                            ),
                            const Text(
                              'Pilih Semua',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                            Text(
                              'Rp$totalPrice',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[400],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: selectedCount > 0
                              ? () async {
                                  SharedPreferences prefs = await SharedPreferences.getInstance();
                                  final userId = prefs.getInt('id');
                                  
                                  if (userId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Silakan login terlebih dahulu'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  // Get selected items for checkout
                                  final selectedItems = cartItems.where((item) => item.isSelected).toList();
                                  
                                  // Navigate to address page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AlamatPage(
                                        cartItems: selectedItems,
                                        totalPrice: totalPrice,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[400],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Beli ($selectedCount)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
