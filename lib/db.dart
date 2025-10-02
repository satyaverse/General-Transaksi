import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  initDB() async {
    String path = join(await getDatabasesPath(), "toko.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price INTEGER,
            image TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            total INTEGER,
            buyer_name TEXT,
            kasir TEXT,
            status TEXT,
            dibayar INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE transaction_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id INTEGER,
            item_id INTEGER,
            qty INTEGER,
            price INTEGER,
            FOREIGN KEY (transaction_id) REFERENCES transactions (id),
            FOREIGN KEY (item_id) REFERENCES items (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            password TEXT,
            imagePath TEXT,
            isHidden INTEGER DEFAULT 0,
            permissions TEXT,
            lastLogin TEXT
          )
        ''');

        await db.insert("users", {
          "username": "superadmin",
          "password": "asd1234",
          "isHidden": 1,
        });

        // Tabel stok
        await db.execute('''
          CREATE TABLE stok(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id INTEGER,
            jumlah INTEGER DEFAULT 0,
            FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // =======================
  // ITEMS
  // =======================
  Future<int> insertItem(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert("items", data);
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return await db.query("items");
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete("items", where: "id = ?", whereArgs: [id]);
  }

  Future<int> updateItem(Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      "items",
      data,
      where: "id = ?",
      whereArgs: [data["id"]],
    );
  }

  Future<int> clearItems() async {
    final db = await database;
    return await db.delete('items');
  }

  // =======================
  // TRANSACTIONS
  // =======================
  Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert("transactions", data);
  }

  Future<int> insertTransactionItem(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert("transaction_items", data);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return await db.query("transactions", orderBy: "date DESC");
  }

  Future<List<Map<String, dynamic>>> getTransactionsWithItems() async {
    final db = await database;
    final transactions = await db.query("transactions", orderBy: "date DESC");

    final result = <Map<String, dynamic>>[];

    for (var transaction in transactions) {
      final items = await db.rawQuery('''
        SELECT ti.*, i.name 
        FROM transaction_items ti 
        LEFT JOIN items i ON ti.item_id = i.id 
        WHERE ti.transaction_id = ?
      ''', [transaction['id']]);

      result.add({
        'id': transaction['id'],
        'date': transaction['date'],
        'total': transaction['total'],
        'buyer_name': transaction['buyer_name'],
        'kasir': transaction['kasir'],
        'status': transaction['status'],
        'dibayar': transaction['dibayar'],
        'items': items,
      });
    }

    return result;
  }

  Future<int> saveCompleteTransaction(
  List<Map<String, dynamic>> cartItems,
  int total, {
  required String buyerName,
  required String kasir,
  required String status,
  required int dibayar,
}) async {
  final db = await database;
  final now = DateTime.now().toIso8601String();

  try {
    return await db.transaction<int>((txn) async {
      // Simpan transaksi utama
      final transactionId = await txn.insert(
        'transactions',
        {
          'date': now,
          'total': total,
          'buyer_name': buyerName,
          'kasir': kasir,
          'status': status,
          'dibayar': dibayar,
        },
      );

      // Loop semua item di keranjang
      for (var item in cartItems) {
        final itemId = item['id'] as int;
        final qty = item['quantity'] as int;
        final price = item['price'] as int;

        // Ambil stok + nama barang
        final stokRes = await txn.rawQuery('''
          SELECT s.jumlah, i.name 
          FROM stok s 
          JOIN items i ON s.item_id = i.id
          WHERE s.item_id = ?
          LIMIT 1
        ''', [itemId]);

        if (stokRes.isEmpty) {
          throw Exception("Barang dengan ID $itemId tidak ditemukan di stok!");
        }

        final currentStok = stokRes.first["jumlah"] as int;
        final itemName = stokRes.first["name"] as String;

        // 🔴 Validasi stok cukup
        if (currentStok < qty) {
          throw (
            "Stok $itemName tidak mencukupi! (tersisa $currentStok, diminta $qty)",
          );
        }

        // Simpan detail transaksi
        await txn.insert(
          'transaction_items',
          {
            'transaction_id': transactionId,
            'item_id': itemId,
            'qty': qty,
            'price': price,
          },
        );

        // Update stok
        await txn.update(
          "stok",
          {"jumlah": currentStok - qty},
          where: "item_id = ?",
          whereArgs: [itemId],
        );
      }

      return transactionId;
    });
  } catch (e) {
    throw '$e';
  }
}


  // =======================
  // DELETE TRANSACTION
  // =======================
  Future<void> deleteTransaction(int id) async {
  final db = await database;
  await db.transaction((txn) async {
    // Ambil semua item di transaksi
    final items = await txn.query(
      "transaction_items",
      where: "transaction_id = ?",
      whereArgs: [id],
    );

    // Tambahkan kembali stok untuk setiap item
    for (var item in items) {
      final itemId = item['item_id'] as int;
      final qty = item['qty'] as int;

      final res = await txn.query(
        "stok",
        columns: ["jumlah"],
        where: "item_id = ?",
        whereArgs: [itemId],
        limit: 1,
      );

      final currentStok = res.first["jumlah"] as int;
      await txn.update(
        "stok",
        {"jumlah": currentStok + qty},
        where: "item_id = ?",
        whereArgs: [itemId],
      );
    }

    // Hapus detail transaksi
    await txn.delete(
      "transaction_items",
      where: "transaction_id = ?",
      whereArgs: [id],
    );

    // Hapus transaksi utama
    await txn.delete(
      "transactions",
      where: "id = ?",
      whereArgs: [id],
    );
  });
}


  // =======================
  // USERS
  // =======================
  Future<int> insertUser(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert("users", {
      "username": data["username"],
      "password": data["password"],
      "imagePath": data["imagePath"],
      "isHidden": data["isHidden"] ?? 0,
      "permissions": data["permissions"] ?? "",
    });
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query(
      "users",
      where: "isHidden = ?",
      whereArgs: [0],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete("users", where: "id = ?", whereArgs: [id]);
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
  final db = await database;
  return await db.update(
    "users",
    {
      if (user.containsKey("username")) "username": user["username"],
      if (user.containsKey("password")) "password": user["password"],
      if (user.containsKey("imagePath")) "imagePath": user["imagePath"],
      if (user.containsKey("permissions")) "permissions": user["permissions"],
      if (user.containsKey("lastLogin")) "lastLogin": user["lastLogin"],
    },
    where: "id = ?",
    whereArgs: [user["id"]],
  );
}


  Future<Map<String, dynamic>?> login(String username, String password) async {
    final db = await database;
    final res = await db.query(
      "users",
      where: "username = ? AND password = ?",
      whereArgs: [username, password],
    );
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  // ===============================
  // STOK
  // ===============================
  Future<int> getStok(int itemId) async {
    final db = await database;
    final res = await db.query(
      "stok",
      columns: ["jumlah"],
      where: "item_id = ?",
      whereArgs: [itemId],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return res.first["jumlah"] as int;
    }
    return 0;
  }

  Future<int> updateStok(int itemId, int newJumlah) async {
    final db = await database;
    final result = await db.update(
      "stok",
      {"jumlah": newJumlah},
      where: "item_id = ?",
      whereArgs: [itemId],
    );

    if (result == 0) {
      return await db.insert("stok", {
        "item_id": itemId,
        "jumlah": newJumlah,
      });
    }
    return result;
  }

  Future<int> tambahStok(int itemId, int jumlahTambah) async {
    int stokSekarang = await getStok(itemId);
    return await updateStok(itemId, stokSekarang + jumlahTambah);
  }

  Future<int> kurangiStok(int itemId, int jumlahKurang) async {
    int stokSekarang = await getStok(itemId);
    int newStok = stokSekarang - jumlahKurang;
    if (newStok < 0) newStok = 0;
    return await updateStok(itemId, newStok);
  }
}
