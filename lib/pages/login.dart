import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db.dart';
import '../main.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _db = DBHelper();

  Future<void> _login() async {
  if (_formKey.currentState!.validate()) {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final user = await _db.login(username, password); // ambil data user

    if (user != null) {
      // update lastLogin sekarang
      await _db.updateUser({
        "id": user["id"],
        "lastLogin": DateTime.now().toIso8601String(),
      });

      // simpan username & imagePath ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("username", user["username"]);
      await prefs.setString("imagePath", user["imagePath"] ?? "");
      await prefs.setString("permissions", user["permissions"] ?? "");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username atau password salah"),
          backgroundColor: Colors.brown,
        ),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text("Login")),
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              "assets/bg.png", // ganti sesuai path gambar kamu
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            top: 40,   
            left: 20,  
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "General Transaksi",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[200],
                    
                  ),
                ),
                SizedBox(height: 5), // jarak antar teks
                Text(
                  "v1.0.0",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.brown[200],
                    
                  ),
                ),
              ],
            ),
          ),


          // Konten form login
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: "Username",
                          filled: true,
                          fillColor: Colors.white70,
                          errorStyle: TextStyle( // ⬅️ ubah style pesan error
                            color: Colors.brown[200], // ganti warna sesuai tema kamu
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Username wajib diisi" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          filled: true,
                          fillColor: Colors.white70,
                          errorStyle: TextStyle( // ⬅️ ubah style pesan error
                            color: Colors.brown[200], // ganti warna sesuai tema kamu
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Password wajib diisi" : null,
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: _login,
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[200],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20, 
            right: 20,   
            child: Text(
              "Tamalogia © 2025",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.amber,
                
              ),
            ),
          ),
        ],
      ),
    );
  }

}
