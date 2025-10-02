import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db.dart';
// import '../widgets/drawer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> topItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopItems();
  }

  Future<void> _loadTopItems() async {
    setState(() => isLoading = true);

    // Ambil data transaksi dari DB
    final transactions = await DBHelper().getTransactionsWithItems();

    // Hitung jumlah qty tiap item
    final Map<String, int> itemCounts = {};
    for (var trx in transactions) {
      final items = trx['items'] as List<Map<String, dynamic>>;
      for (var item in items) {
        final name = item['name'] as String;
        final qty = item['qty'] as int;
        itemCounts[name] = (itemCounts[name] ?? 0) + qty;
      }
    }

    // Sort descending berdasarkan jumlah terjual
    final sorted = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Simpan hanya 10 item teratas
    topItems = sorted.take(10).map((e) => {
          'name': e.key,
          'qty': e.value,
        }).toList();

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // cari nilai tertinggi untuk maxY
    final double maxY = topItems.isNotEmpty
        ? topItems.map((e) => e['qty'] as int).reduce((a, b) => a > b ? a : b).toDouble() * 1.1
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Produk Populer"),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
      ),
      // drawer: const AppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : topItems.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada data penjualan",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BarChart(
                    BarChartData(
                      maxY: maxY.toDouble(),
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            interval: maxY / 4,
                            getTitlesWidget: (value, meta) {
                              // tampilkan hanya 0, tengah, dan maxY
                              final checkpoints = [
                                0,
                                (maxY / 4).round(),
                                (maxY / 2).round(),
                                (3 * maxY / 4).round(),
                                maxY.round(),
                              ];

                              if (checkpoints.contains(value.round())) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 14),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= topItems.length) {
                                return const SizedBox();
                              }
                              return Transform.rotate(
                                angle: -0.8, // ~45 derajat
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    topItems[index]['name'],
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),

                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipMargin: 8,
                          tooltipPadding: const EdgeInsets.all(8),
                          getTooltipColor: (group) => Colors.white, // background tooltip
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final itemName = topItems[group.x.toInt()]['name'];
                            final qty = rod.toY.toInt();
                            return BarTooltipItem(
                              "$itemName\n$qty",
                              const TextStyle(
                                color: Colors.brown,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),



                      barGroups: topItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final qty = entry.value['qty'] as int;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: qty.toDouble(),
                              color: Colors.brown,
                              borderRadius: BorderRadius.circular(4),
                            )
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
    );
  }
}
