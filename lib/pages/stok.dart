import 'dart:io';
import 'package:flutter/material.dart';
import '../drawer.dart';
import '../db.dart';
import 'itempage.dart';

class Stok extends StatefulWidget {
  const Stok({super.key});

  @override
  State<Stok> createState() => _StokPageState();
}

class _StokPageState extends State<Stok> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  String searchQuery = "";

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();

    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final db = DBHelper();
    final data = await db.getItems();
    final List<Map<String, dynamic>> withStok = [];

    for (var item in data) {
      final stok = await db.getStok(item["id"]);
      withStok.add({...item, "stok": stok});
    }

    if (!mounted) return;
    setState(() {
      items = withStok;
      filteredItems = withStok;
    });
  }

  void filterItems(String query) {
    List<Map<String, dynamic>> results = [];
    if (query.isEmpty) {
      results = items;
    } else {
      results = items.where((item) {
        final nameLower = item['name'].toString().toLowerCase();
        final queryLower = query.toLowerCase();
        return nameLower.contains(queryLower);
      }).toList();
    }

    setState(() {
      filteredItems = results;
    });
  }

  Future<void> _showActionDialog(int id, String name, int stokSekarang) async {
    final item = filteredItems.firstWhere((e) => e["id"] == id);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name,textAlign: TextAlign.center,),
          content: Text("Stok saat ini: $stokSekarang",textAlign: TextAlign.center,),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.add, color: Colors.green),
              label: const Text("Tambah"),
              onPressed: () {
                Navigator.of(context).pop();
                _showInputDialog(id, name, true);
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.remove, color: Colors.orange),
              label: const Text("Kurangi"),
              onPressed: () {
                Navigator.of(context).pop();
                _showInputDialog(id, name, false);
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.edit, color: Colors.blue),
              label: const Text("Edit"),
              onPressed: () {
                Navigator.of(context).pop();
                _showEditDialog(item);
              },
            ),
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showInputDialog(int id, String name, bool isTambah) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("${isTambah ? 'Tambah' : 'Kurangi'} Stok - $name"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText:
                  "Jumlah yang ingin ${isTambah ? 'ditambah' : 'dikurangi'}",
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Simpan"),
              onPressed: () async {
                int jumlah = int.tryParse(controller.text) ?? 0;
                final db = DBHelper();
                final messenger = ScaffoldMessenger.of(context); // ✅ simpan messenger sebelum await
                final navigator = Navigator.of(context); // ✅ simpan navigator sebelum await

                if (jumlah > 0) {
                  final currentStok = await db.getStok(id);

                  if (!mounted) return;

                  if (isTambah) {
                    await db.tambahStok(id, jumlah);
                  } else {
                    if (jumlah > currentStok) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("Stok tidak mencukupi untuk dikurangi"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    await db.kurangiStok(id, jumlah);
                  }
                }

                if (!mounted) return;
                navigator.pop();
                _loadItems();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final stokController =
        TextEditingController(text: item["stok"].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Stok - ${item["name"]}"),
          content: TextField(
            controller: stokController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Jumlah Stok"),
          ),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Simpan"),
              onPressed: () async {
                final navigator = Navigator.of(context); // ✅ simpan sebelum await
                int newStok = int.tryParse(stokController.text) ?? 0;

                await DBHelper().updateStok(item["id"], newStok);

                if (!mounted) return;
                navigator.pop();
                _loadItems();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildMenuItem(
      int id, String name, int price, int stok, String? imagePath) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _showActionDialog(id, name, stok),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
              child: (imagePath != null &&
                      imagePath.isNotEmpty &&
                      File(imagePath).existsSync())
                  ? Image.file(
                      File(imagePath),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.fastfood,
                          size: 40, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text("Stok: $stok",
                      style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenuGrid() {
    if (filteredItems.isEmpty) {
      return const Center(child: Text("Belum ada data"));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return buildMenuItem(
          item["id"],
          item["name"],
          item["price"] ?? 0,
          item["stok"] ?? 0,
          item["image"],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stok Produk"),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ItemPage(),
                ),
              );
            },
            icon: const Icon(Icons.double_arrow, color: Colors.white),
            label: const Text(
              "Produk",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: OrientationBuilder(
        builder: (context, orientation) {
          Widget content = Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Cari produk...",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: searchQuery.isNotEmpty
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            onPressed: searchQuery.isNotEmpty
                                ? () {
                                    _searchController.clear();
                                    filterItems("");
                                  }
                                : null,
                          ),
                        ),
                        onChanged: filterItems,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: buildMenuGrid()),
            ],
          );

          if (orientation == Orientation.landscape) {
            return Row(
              children: [
                Expanded(child: content),
              ],
            );
          } else {
            return content;
          }
        },
      ),
    );
  }
}
