import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dapur_anita/konstanta.dart';
import 'package:dapur_anita/model/pesanan_page.dart';
import 'package:dapur_anita/auth/profil.dart';
import 'package:intl/intl.dart';
import 'package:dapur_anita/admin/pesanan_admin_page.dart';
import 'package:dapur_anita/admin/tambah_produk.dart';
import 'package:dapur_anita/admin/edit_form.dart';
import 'package:dapur_anita/model/produk.dart';
import 'dart:math' as num;

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic> dashboardData = {
    'total_users': 0,
    'total_transactions': 0,
    'total_revenue': 0,
    'products_sold': 0,
  };
  int _selectedIndex = 0;
  bool isLoading = true;
  String errorMessage = '';
  
  // Add GlobalKey for RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('Fetching dashboard data from: $baseUrl/api/getDashboardData');
      final response = await http.get(
        Uri.parse('$baseUrl/api/getDashboardData'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Dashboard Response Status: ${response.statusCode}');
      print('Dashboard Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          dashboardData = {
            'total_users': data['total_users'] ?? 0,
            'total_transactions': data['total_transactions'] ?? 0,
            'total_revenue': double.parse(data['total_revenue'].toString()),
            'products_sold': data['products_sold'] ?? 0,
          };
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Gagal memuat data: Error ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() {
        if (e.toString().contains('SocketException')) {
          errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda';
        } else {
          errorMessage = 'Gagal memuat data: $e';
        }
        isLoading = false;
      });
    }
  }

  String formatCurrency(dynamic amount) {
    // Convert amount to double safely
    double number;
    try {
      number = amount is double ? amount : double.parse(amount.toString());
    } catch (e) {
      number = 0;
    }
    
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }

  Widget _buildDashboardContent() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 60,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red[400]),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[400],
                foregroundColor: Colors.black,
              ),
              onPressed: fetchDashboardData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchDashboardData,
      color: Colors.amber[400],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildNewStatCard(
                  'Pengguna Terdaftar',
                  dashboardData['total_users']?.toString() ?? '0',
                  Icons.people_outline,
                ),
                _buildNewStatCard(
                  'Total Transaksi Bulan Ini',
                  dashboardData['total_transactions']?.toString() ?? '0',
                  Icons.access_time,
                ),
                _buildNewStatCard(
                  'Total Pendapatan',
                  formatCurrency(dashboardData['total_revenue']),
                  Icons.access_time,
                ),
                _buildNewStatCard(
                  'Produk Terjual Bulan Ini',
                  dashboardData['products_sold']?.toString() ?? '0',
                  Icons.grid_view,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: Colors.blue[700], size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<ProdukResponModel>> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/getProduk'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => ProdukResponModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> delete(String idBarang) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/deleteApi/$idBarang'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          // Refresh the product list
          fetchData();
        });
      } else {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardContent(),
      const PesananAdminPage(),
      Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D2D2D),
          automaticallyImplyLeading: false,
          title: Text(
            'Kelola Produk',
            style: TextStyle(color: Colors.amber[400]),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.amber[400],
          child: const Icon(Icons.add, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TambahProdukPage(),
              ),
            ).then((_) {
              // Refresh data when returning from TambahProdukPage
              setState(() {
                // This will trigger rebuild and fetch new data
              });
            });
          },
        ),
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          color: Colors.amber[400],
          onRefresh: () async {
            setState(() {
              // This will trigger rebuild and fetch new data
            });
          },
          child: FutureBuilder<List<ProdukResponModel>>(
            future: fetchData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada produk',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var produk = snapshot.data![index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        produk.namaProduk.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatCurrency(produk.hargaProduk),
                            style: TextStyle(
                              color: Colors.amber[400],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Stok: ${produk.stok}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.amber[400], size: 20),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditForm(
                                  idBarang: produk.idProduk.toString(),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF2D2D2D),
                                  title: const Text(
                                    'Hapus Produk',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Text(
                                    'Yakin ingin menghapus produk ini?',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text(
                                        'Batal',
                                        style: TextStyle(color: Colors.grey[400]),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    TextButton(
                                      child: Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red[400]),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        delete(produk.idProduk.toString());
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      const ProfilPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: _selectedIndex == 2 ? null : AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        automaticallyImplyLeading: false,
        title: Text(
          _selectedIndex == 0 ? 'Dashboard Admin' :
          _selectedIndex == 1 ? 'Kelola Pesanan' :
          _selectedIndex == 3 ? 'Profil Admin' : '',
          style: TextStyle(color: Colors.amber[400]),
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.amber[400]),
              onPressed: fetchDashboardData,
            ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2D2D2D),
        selectedItemColor: Colors.amber[400],
        unselectedItemColor: Colors.grey[400],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
} 