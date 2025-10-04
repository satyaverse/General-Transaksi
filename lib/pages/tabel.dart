import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_selector/file_selector.dart';
import '../db.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final dbHelper = DBHelper();
  List<Map<String, dynamic>> _laporan = [];

  final DateFormat displayFormat = DateFormat("dd/MM/yyyy HH:mm");

  @override
  void initState() {
    super.initState();
    _loadLaporan();
  }

  Future<void> _loadLaporan() async {
    final data = await dbHelper.getTransactionsWithItems();

    final now = DateTime.now();
    final bulanIni = data.where((trx) {
      try {
        final trxDate = DateTime.parse(trx['date'].toString());
        return trxDate.year == now.year && trxDate.month == now.month;
      } catch (_) {
        return false;
      }
    }).toList();

    setState(() {
      _laporan = bulanIni;
    });
  }

  // ============================
  // EXPORT EXCEL
  // ============================
  Future<void> _exportExcel() async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Laporan');
    final sheet = excel['Laporan'];

    // Header
    sheet.appendRow([
      TextCellValue("Tanggal"),
      TextCellValue("Kasir"),
      TextCellValue("Pembeli"),
      TextCellValue("Status"),
      TextCellValue("Total"),
      TextCellValue("Dibayar"),
      TextCellValue("Detail Barang"),
    ]);

    num totalSemua = 0;
    num totalDibayar = 0;

    for (var trx in _laporan) {
      String tanggal;
      try {
        tanggal = displayFormat.format(DateTime.parse(trx['date'].toString()));
      } catch (_) {
        tanggal = trx['date'].toString();
      }

      final items = (trx['items'] as List<Map<String, dynamic>>)
          .map((e) => "${e['name']} (x${e['qty']}) ${e['price']}")
          .join(", ");

      sheet.appendRow([
        TextCellValue(tanggal),
        TextCellValue(trx['kasir'].toString()),
        TextCellValue(trx['buyer_name']?.toString() ?? "-"),
        TextCellValue(trx['status'].toString()),
        TextCellValue(trx['total'].toString()),
        TextCellValue(trx['dibayar'].toString()),
        TextCellValue(items),
      ]);

      totalSemua += num.tryParse(trx['total'].toString()) ?? 0;
      totalDibayar += num.tryParse(trx['dibayar'].toString()) ?? 0;
    }

    sheet.appendRow([TextCellValue("")]);

    sheet.appendRow([
      TextCellValue("TOTAL"),
      TextCellValue(""),
      TextCellValue(""),
      TextCellValue(""),
      TextCellValue(totalSemua.toString()),
      TextCellValue(totalDibayar.toString()),
      TextCellValue(""),
    ]);

    final location = await getSaveLocation(
    acceptedTypeGroups: [
      XTypeGroup(label: 'Excel', extensions: ['xlsx']),
    ],
    suggestedName: "laporan_transaksi.xlsx",
  );

    if (location == null) return; // user batal

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(location.path);
      await file.writeAsBytes(fileBytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excel tersimpan di: ${location.path}")),
      );
    }
  }

  // ============================
  // EXPORT PDF
  // ============================
  Future<void> _exportPDF() async {
  final pdf = pw.Document();

  // Hitung total semua transaksi
  final grandTotal = _laporan.fold<num>(0, (sum, trx) => sum + (trx['total'] ?? 0));
  final grandDibayar = _laporan.fold<num>(0, (sum, trx) => sum + (trx['dibayar'] ?? 0));

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Center(
          child: pw.Text(
            "LAPORAN TRANSAKSI (${DateFormat("MMMM yyyy").format(DateTime.now())})",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
            5: const pw.FlexColumnWidth(2),
            6: const pw.FlexColumnWidth(4),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Tanggal")),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Kasir")),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Pembeli")),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Status")),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Total")),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Dibayar")),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Detail Barang")),
              ],
            ),
            // Data
            ..._laporan.map((trx) {
              String tanggal;
              try {
                tanggal = displayFormat.format(DateTime.parse(trx['date'].toString()));
              } catch (_) {
                tanggal = trx['date'].toString();
              }

              final items = (trx['items'] as List<Map<String, dynamic>>)
                  .map((e) => "${e['name']} (x${e['qty']}) Rp. ${e['price']}")
                  .join("\n");

              return pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(tanggal, style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(trx['kasir'].toString(), style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(trx['buyer_name']?.toString() ?? "-", style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(trx['status'].toString(), style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("Rp. ${trx['total']}", style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("Rp. ${trx['dibayar']}", style: const pw.TextStyle(fontSize: 8))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(items, style: const pw.TextStyle(fontSize: 8))),
                ],
              );
            }),
            // Baris total
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text("TOTAL",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                ),
                pw.SizedBox(),
                pw.SizedBox(),
                pw.SizedBox(),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text("Rp. $grandTotal",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text("Rp. $grandDibayar",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                ),
                pw.SizedBox(),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  // 🔥 Ganti getSavePath -> getSaveLocation
  final location = await getSaveLocation(
    acceptedTypeGroups: [XTypeGroup(label: 'PDF', extensions: ['pdf'])],
    suggestedName: "laporan_transaksi.pdf",
  );

  if (location == null) return; // user batal

  final file = File(location.path); // pakai location.path
  await file.writeAsBytes(await pdf.save());

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("PDF tersimpan di: ${location.path}")),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Transaksi",
            style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: "Export ke Excel",
            icon: const Icon(Icons.table_view),
            onPressed: _laporan.isEmpty ? null : _exportExcel,
          ),
          IconButton(
            tooltip: "Export ke PDF",
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _laporan.isEmpty ? null : _exportPDF,
          ),
        ],
      ),
      body: _laporan.isEmpty
          ? const Center(child: Text("Belum ada transaksi"))
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(Colors.brown[700]),
                        dataRowMaxHeight: double.infinity,
                        columns: const [
                          DataColumn(
                              label: Text("Tanggal",
                                  style: TextStyle(color: Colors.white))),
                          DataColumn(
                              label: Text("Kasir",
                                  style: TextStyle(color: Colors.white))),
                          DataColumn(
                              label: Text("Pembeli",
                                  style: TextStyle(color: Colors.white))),
                          DataColumn(
                              label: Text("Status",
                                  style: TextStyle(color: Colors.white))),
                          DataColumn(
                              label: Text("Total",
                                  style: TextStyle(color: Colors.white))),
                          DataColumn(
                              label: Text("Dibayar",
                                  style: TextStyle(color: Colors.white))),
                          DataColumn(
                              label: Text("Detail Barang",
                                  style: TextStyle(color: Colors.white))),
                        ],
                        rows: _laporan.map((trx) {
                          final items = trx['items'] as List<Map<String, dynamic>>;
                          final itemList = items
                              .map((e) =>
                                  "${e['name']} (x${e['qty']}) Rp. ${e['price']}")
                              .join("\n");

                          String tanggal;
                          try {
                            tanggal = displayFormat
                                .format(DateTime.parse(trx['date'].toString()));
                          } catch (_) {
                            tanggal = trx['date'].toString();
                          }

                          return DataRow(
                            cells: [
                              DataCell(Text(tanggal)),
                              DataCell(Text(trx['kasir'].toString())),
                              DataCell(Text(trx['buyer_name']?.toString() ?? "-")),
                              DataCell(Text(trx['status'].toString())),
                              DataCell(Text("Rp. ${trx['total']}")),
                              DataCell(Text("Rp. ${trx['dibayar']}")),
                              DataCell(
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 200),
                                  child: Text(itemList, softWrap: true),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

