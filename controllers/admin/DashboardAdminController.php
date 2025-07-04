<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Order;
use App\Models\Product;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use App\Models\ProdukModel;

class DashboardAdminController extends Controller
{


    public function index()
    {
        $pesanan = Pesanan::join('produk','produk.id_produk','=','pesanan.id_produk')
        ->join('alamat_user','alamat_user.id_user','=','pesanan.id_user')
        ->select('pesanan.*','alamat_user.alamat_lengkap','alamat_user.nama_penerima','alamat_user.no_telp','alamat_user.nama_prov','alamat_user.nama_kota','alamat_user.no_telp','produk.nama_produk','produk.harga_produk','produk.foto_produk','produk.berat')
        ->where('pesanan.status', 3)
        ->orWhere('pesanan.status', 4)
        ->get();
        return view('admin.dashboard.dashboard',compact(['pesanan']));
    }

    public function getDashboardData()
    {
        try {
            // Get total users (excluding admin)
            $totalUsers = User::where('type', '!=', 'admin')->count();

            // Get current month's data
            $startOfMonth = Carbon::now()->startOfMonth();
            $endOfMonth = Carbon::now()->endOfMonth();

            // Get total transactions for current month
            $totalTransactions = Pesanan::whereBetween('created_at', [$startOfMonth, $endOfMonth])->count();

            // Get total revenue (all time)
            $totalRevenue = Pesanan::where('status', 4)->sum('harga_total_bayar');

            // Get products sold this month
            $productsSold = Pesanan::whereBetween('created_at', [$startOfMonth, $endOfMonth])
                ->where('status', 4)
                ->sum('quantity');

            return response()->json([
                'total_users' => $totalUsers,
                'total_transactions' => $totalTransactions,
                'total_revenue' => $totalRevenue,
                'products_sold' => $productsSold
            ]);
        } catch (\Exception $e) {
            \Log::error('Dashboard Error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error mengambil data dashboard: ' . $e->getMessage()
            ], 500);
        }
    }
}


