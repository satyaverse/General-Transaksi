import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/itempage.dart';
import 'pages/kasirpage.dart';
import 'pages/riwayat.dart';
import 'pages/report.dart';
import 'pages/stok.dart';
import 'pages/user.dart';
import 'pages/login.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? username;
  String? imagePath;
  String? permissions;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username") ?? "Guest";
      imagePath = prefs.getString("imagePath");
      permissions = prefs.getString("permissions");
    });
  }

  /// Cek apakah user boleh akses menu tertentu
  bool _canAccess(String menu) {
    if (permissions == null || permissions!.isEmpty) return true; // default: semua
    final allowed = permissions!.split(",").map((e) => e.trim()).toList();
    return allowed.contains(menu);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.brown[800]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 40,
                  backgroundImage: (imagePath != null && imagePath!.isNotEmpty)
                      ? FileImage(File(imagePath!))
                      : null,
                  child: (imagePath == null || imagePath!.isEmpty)
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  username ?? "Loading...",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (_canAccess("Transaksi"))
            ListTile(
              leading: const Icon(Icons.shopping_cart_checkout_outlined),
              title: const Text("Transaksi"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Kasir()),
                );
              },
            ),

          if (_canAccess("Riwayat"))
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Riwayat"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Riwayat()),
                );
              },
            ),

          if (_canAccess("Produk"))
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text("Produk"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ItemPage()),
                );
              },
            ),

          if (_canAccess("Stok"))
            ListTile(
              leading: const Icon(Icons.inventory_outlined),
              title: const Text("Stok"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Stok()),
                );
              },
            ),

          if (_canAccess("Laporan"))
            ListTile(
              leading: const Icon(Icons.timeline),
              title: const Text("Laporan"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportPage()),
                );
              },
            ),  

          if (_canAccess("User"))
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Pengguna"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UsersPage()),
                );
              },
            ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Keluar"),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
