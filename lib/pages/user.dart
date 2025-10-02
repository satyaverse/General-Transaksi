import 'dart:io';
import '../drawer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../db.dart';
import 'package:intl/intl.dart';



class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _db = DBHelper();
  final ImagePicker _picker = ImagePicker();

  String? _pickedImagePath;
  List<String> _selectedMenus = [];

  final List<String> menuOptions = [
    "Transaksi",
    "Riwayat",
    "Produk",
    "Laporan",
    "Stok",
    "User",
  ];

  // Pilih gambar
  Future<void> _pickImage(VoidCallback refreshDialog) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImagePath = picked.path;
      });
      refreshDialog();
    }
  }

  // Widget input dengan batas lebar
  Widget _buildTextField(TextEditingController controller,
      {required String label, bool obscure = false}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          obscureText: obscure,
        ),
      ),
    );
  }

  // Tambah user
  Future<void> _addUser() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    _pickedImagePath = null;
    _selectedMenus = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                "Tambah Pengguna",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kiri: Foto, Username, Password
                    Flexible(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _pickImage(() => setStateDialog(() {})),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: _pickedImagePath != null
                                  ? FileImage(File(_pickedImagePath!))
                                  : null,
                              child: _pickedImagePath == null
                                  ? const Icon(Icons.camera_alt, size: 30)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(usernameController, label: "Username"),
                          const SizedBox(height: 8),
                          _buildTextField(passwordController,
                              label: "Password", obscure: true),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Kanan: Hak Akses
                    
                    Flexible(
                      flex: 3,
                      child: SizedBox(
                        width: 250,
                        height: 200,
                        child: ListView(
                          shrinkWrap: true,
                          children: menuOptions.map((menu) {
                            return CheckboxListTile(
                              dense: true,
                              title: Text(menu),
                              value: _selectedMenus.contains(menu),
                              onChanged: (val) {
                                setStateDialog(() {
                                  if (val == true) {
                                    _selectedMenus.add(menu);
                                  } else {
                                    _selectedMenus.remove(menu);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final username = usernameController.text.trim();
                    final password = passwordController.text.trim();

                    if (username.isEmpty || password.isEmpty) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Username & password wajib diisi")),
                      );
                      return;
                    }

                    final nav = Navigator.of(dialogContext);

                    await _db.insertUser({
                      "username": username,
                      "password": password,
                      "imagePath": _pickedImagePath,
                      "isHidden": 0,
                      "permissions": _selectedMenus.join(","),
                    });

                    if (!mounted) return;
                    setState(() {});
                    nav.pop();
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Edit user
  Future<void> _editUser(Map<String, dynamic> user) async {
    final usernameController =
        TextEditingController(text: user["username"] ?? "");
    final passwordController =
        TextEditingController(text: user["password"] ?? "");
    _pickedImagePath = user["imagePath"];
    _selectedMenus = (user["permissions"] as String?)?.split(",") ?? [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Center(
                child: const Text(
                  "Edit Pengguna",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kiri: Foto, Username, Password
                    Flexible(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _pickImage(() => setStateDialog(() {})),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: _pickedImagePath != null
                                  ? FileImage(File(_pickedImagePath!))
                                  : null,
                              child: _pickedImagePath == null
                                  ? const Icon(Icons.camera_alt, size: 30)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(usernameController, label: "Username"),
                          const SizedBox(height: 8),
                          _buildTextField(passwordController,
                              label: "Password", obscure: true),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Kanan: Hak Akses
                    
                    Flexible(
                      flex: 3,
                      child: SizedBox(
                        width: 250,
                        height: 200,
                        child: ListView(
                          shrinkWrap: true,
                          children: menuOptions.map((menu) {
                            return CheckboxListTile(
                              dense: true,
                              title: Text(menu),
                              value: _selectedMenus.contains(menu),
                              onChanged: (val) {
                                setStateDialog(() {
                                  if (val == true) {
                                    _selectedMenus.add(menu);
                                  } else {
                                    _selectedMenus.remove(menu);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final username = usernameController.text.trim();
                    final password = passwordController.text.trim();

                    if (username.isEmpty || password.isEmpty) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Username & password wajib diisi")),
                      );
                      return;
                    }

                    final nav = Navigator.of(dialogContext);

                    await _db.updateUser({
                      "id": user["id"],
                      "username": username,
                      "password": password,
                      "imagePath": _pickedImagePath ?? user["imagePath"],
                      "permissions": _selectedMenus.join(","),
                    });

                    if (!mounted) return;
                    setState(() {});
                    nav.pop();
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Hapus user
  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Yakin menghapus?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteUser(id);
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daftar Pengguna"),
        backgroundColor: Colors.brown[100],
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _db.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text("Tidak ada data Pengguna"));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: user["imagePath"] != null
                      ? CircleAvatar(
                          backgroundImage: FileImage(File(user["imagePath"])),
                        )
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user["username"] ?? ""),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ID: ${user["id"]}"),
                      if (user["lastLogin"] != null) ...[
                        Builder(
                          builder: (context) {
                            final date = DateTime.tryParse(user["lastLogin"]);
                            if (date != null) {
                              final formatted = DateFormat("dd MMM yyyy, HH:mm").format(date);
                              return Text("Last Login: $formatted");
                            } else {
                              return const Text("Last Login: -");
                            }
                          },
                        ),
                      ],

                    ],
                  ),
                  onTap: () {
                    showDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        // Title: Avatar + Username
                        title: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: user["imagePath"] != null
                                  ? FileImage(File(user["imagePath"]))
                                  : null,
                              child: user["imagePath"] == null
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "${user["username"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

     
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Misal: Text("Detail User") atau form field bisa ditaruh di sini
                            ],
                          ),
                        ),

                
                        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _editUser(user);
                                },
                                child: const Text("Edit"),
                              ),
                              const SizedBox(width: 16),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _deleteUser(user["id"]);
                                },
                                child: const Text("Hapus"),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );

                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: _addUser,
              backgroundColor: Colors.brown[100],
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 5),
            const Text(
              "Tambah User",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

    );
  }
}
