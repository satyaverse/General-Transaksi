import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../db.dart';

class AddBarangPage extends StatefulWidget {
  final Map<String, dynamic>? existingItem; // <<< TAMBAH INI

  const AddBarangPage({super.key, this.existingItem}); // <<< TAMBAH INI

  @override
  State<AddBarangPage> createState() => _AddBarangPageState();
}

class _AddBarangPageState extends State<AddBarangPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();

    // kalau ada existingItem (mode edit), isi field otomatis
    if (widget.existingItem != null) {
      _namaController.text = widget.existingItem!["name"] ?? "";
      _hargaController.text = widget.existingItem!["price"]?.toString() ?? "";
      if (widget.existingItem!["image"] != null &&
          widget.existingItem!["image"].toString().isNotEmpty) {
        _imageFile = File(widget.existingItem!["image"]);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(picked.path);
      final savedImage =
          await File(picked.path).copy('${appDir.path}/$fileName');

      setState(() {
        _imageFile = savedImage;
      });
    }
  }

  void _saveData() async {
    final nama = _namaController.text.trim();
    final harga = int.tryParse(_hargaController.text.trim()) ?? 0;

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama harus diisi")),
      );
      return;
    }

    if (widget.existingItem == null) {
      // === MODE TAMBAH BARU ===
      await DBHelper().insertItem({
        "name": nama,
        "price": harga,
        "image": _imageFile?.path,
      });
    } else {
      // === MODE EDIT ===
      await DBHelper().updateItem({
        "id": widget.existingItem!["id"],
        "name": nama,
        "price": harga,
        "image": _imageFile?.path,
      });
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // judul dinamis tergantung mode
        title: Text(widget.existingItem == null ? "Tambah Produk" : "Edit Produk"),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _namaController,
                  decoration: InputDecoration(
                    labelText: "Nama Produk",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Harga",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _imageFile != null
                  ? Image.file(_imageFile!, height: 120)
                  : const Text("Belum ada gambar"),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Pilih Gambar"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveData,
                child: Text(widget.existingItem == null ? "Simpan" : "Update"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
