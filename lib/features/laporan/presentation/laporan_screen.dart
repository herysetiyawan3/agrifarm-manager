import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/file_exporter.dart';

class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key});

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSeasonId;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seasonsState = ref.watch(watchSeasonsProvider);
    final expensesState = ref.watch(watchExpensesProvider);
    final salesState = ref.watch(watchSalesProvider);
    final harvestsState = ref.watch(watchHarvestsProvider);
    final fieldsState = ref.watch(watchFieldsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Tani'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Laba Rugi'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Rekap Panen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLabaRugiTab(seasonsState, expensesState, salesState),
          _buildRekapPanenTab(harvestsState, seasonsState, fieldsState, salesState),
        ],
      ),
    );
  }

  Widget _buildLabaRugiTab(
    AsyncValue<List<MusimTanam>> seasonsState,
    AsyncValue<List<Pengeluaran>> expensesState,
    AsyncValue<List<Penjualan>> salesState,
  ) {
    return seasonsState.when(
      data: (seasons) {
        if (seasons.isEmpty) {
          return const Center(child: Text('Belum ada musim tanam untuk dianalisis.'));
        }

        final currentSeasonId = _selectedSeasonId ?? seasons.first.id;
        final activeSeason = seasons.firstWhere((s) => s.id == currentSeasonId);

        // Calculate Financials for the selected season
        final expenses = expensesState.value ?? [];
        final sales = salesState.value ?? [];

        // Categorised Expenses
        double totalExp = 0.0;
        double expBibit = 0.0;
        double expPupuk = 0.0;
        double expPest = 0.0;
        double expUpah = 0.0;
        double expSewa = 0.0;
        double expLain = 0.0;

        final seasonExpenses = expenses.where((e) {
          return e.date.isAfter(activeSeason.seedingDate) && 
                 (activeSeason.status == 'Selesai' ? e.date.isBefore(DateTime.now()) : true);
        }).toList();

        for (var e in seasonExpenses) {
          totalExp += e.amount;
          switch (e.category) {
            case 'Bibit': expBibit += e.amount; break;
            case 'Pupuk': expPupuk += e.amount; break;
            case 'Pestisida': expPest += e.amount; break;
            case 'Upah': expUpah += e.amount; break;
            case 'Sewa Lahan': expSewa += e.amount; break;
            default: expLain += e.amount; break;
          }
        }

        // Total Sales
        double totalRev = 0.0;
        final seasonSales = sales.where((s) => s.seasonId == currentSeasonId).toList();
        for (var s in seasonSales) {
          totalRev += s.totalPrice;
        }

        final netProfit = totalRev - totalExp;
        final margin = totalRev > 0 ? (netProfit / totalRev) * 100 : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Season Dropdown
              DropdownButtonFormField<String>(
                value: currentSeasonId,
                decoration: const InputDecoration(labelText: 'Pilih Siklus Tanam', prefixIcon: Icon(Icons.spa)),
                items: seasons.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSeasonId = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Laba Rugi Cards
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text('LABA BERSIH ESTIMASI', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.formatRupiah(netProfit),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: netProfit >= 0 ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: netProfit >= 0 ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Margin: ${margin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: netProfit >= 0 ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ringkasan Pemasukan & Pengeluaran Row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Pendapatan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(Formatters.formatRupiah(totalRev), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Pengeluaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(Formatters.formatRupiah(totalExp), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Rincian Biaya
              const Text('Rincian Kategori Biaya', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildBreakdownItem('Beli Bibit', expBibit, totalExp, Colors.blue),
              _buildBreakdownItem('Beli Pupuk', expPupuk, totalExp, Colors.green),
              _buildBreakdownItem('Beli Pestisida', expPest, totalExp, Colors.orange),
              _buildBreakdownItem('Upah Tenaga Kerja', expUpah, totalExp, Colors.red),
              _buildBreakdownItem('Sewa Lahan', expSewa, totalExp, Colors.purple),
              _buildBreakdownItem('Lainnya/Operasional', expLain, totalExp, Colors.grey),

              const SizedBox(height: 36),

              // Export Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        await FileExporter.exportLabaRugiPdf(
                          seasonName: activeSeason.name,
                          totalPendapatan: totalRev,
                          totalPengeluaran: totalExp,
                          labaBersih: netProfit,
                          marginKeuntungan: margin,
                          biayaKategori: {
                            'Bibit': expBibit,
                            'Pupuk': expPupuk,
                            'Pestisida': expPest,
                            'Upah Pekerja': expUpah,
                            'Sewa Lahan': expSewa,
                            'Lainnya/Operasional': expLain,
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.table_view),
                      label: const Text('Export Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        // Export Excel Purchases Sheet
                        final purchaseHeaders = ['Nama Barang', 'Kategori', 'Toko', 'Tanggal', 'Harga Satuan', 'Jumlah', 'Total Harga'];
                        final purchaseRows = seasonExpenses.map((e) => [
                          e.description,
                          e.category,
                          'AgriFarm',
                          Formatters.formatDate(e.date),
                          e.amount,
                          1,
                          e.amount
                        ]).toList();

                        await FileExporter.exportToExcel(
                          fileName: 'Laporan_Keuangan_${activeSeason.name}',
                          sheetName: 'Pengeluaran',
                          headers: purchaseHeaders,
                          rows: purchaseRows,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildRekapPanenTab(
    AsyncValue<List<Panen>> harvestsState,
    AsyncValue<List<MusimTanam>> seasonsState,
    AsyncValue<List<Lahan>> fieldsState,
    AsyncValue<List<Penjualan>> salesState,
  ) {
    return harvestsState.when(
      data: (harvests) {
        final filteredHarvests = harvests.where((h) {
          final hDate = DateTime(h.date.year, h.date.month, h.date.day);
          final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
          final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
          return !hDate.isBefore(start) && !hDate.isAfter(end);
        }).toList();

        double totalWeight = 0.0;
        int totalTrees = 0;
        double totalRevenue = 0.0;
        
        final Map<String, Map<String, dynamic>> buyerStats = {};

        for (var h in filteredHarvests) {
          totalWeight += h.weight;
          totalTrees += h.harvestedTrees ?? 0;
          totalRevenue += h.totalPrice ?? 0.0;

          final buyerName = h.buyerName ?? 'Umum';
          if (buyerStats.containsKey(buyerName)) {
            buyerStats[buyerName]!['weight'] = buyerStats[buyerName]!['weight'] + h.weight;
            buyerStats[buyerName]!['totalPrice'] = buyerStats[buyerName]!['totalPrice'] + (h.totalPrice ?? 0.0);
            buyerStats[buyerName]!['count'] = buyerStats[buyerName]!['count'] + 1;
          } else {
            buyerStats[buyerName] = {
              'weight': h.weight,
              'totalPrice': h.totalPrice ?? 0.0,
              'count': 1,
            };
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Range Selector and CSV Exporter
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Periode Rekap:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month, size: 18),
                            label: Text(
                              "${Formatters.formatDate(_startDate)} - ${Formatters.formatDate(_endDate)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _startDate = picked.start;
                                  _endDate = picked.end;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      if (filteredHarvests.isNotEmpty) ...[
                        const Divider(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Unduh CSV Detail Rekap', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final headers = [
                              'Tanggal Panen',
                              'Musim Tanam',
                              'Lahan',
                              'Jumlah Pohon Terpanen',
                              'Total Berat (Kg)',
                              'Berat Grade A (Kg)',
                              'Harga Grade A (Rp/Kg)',
                              'Berat Grade B (Kg)',
                              'Harga Grade B (Rp/Kg)',
                              'Berat Grade C (Kg)',
                              'Harga Grade C (Rp/Kg)',
                              'Nama Tengkulak / Pembeli',
                              'Total Penjualan (Rp)',
                              'Status Pembayaran',
                              'Nominal Dibayar (Rp)',
                              'Sisa Piutang (Rp)',
                              'Catatan'
                            ];

                            final List<List<dynamic>> rows = [];
                            for (var h in filteredHarvests) {
                              final season = seasonsState.value?.firstWhere(
                                (s) => s.id == h.seasonId,
                                orElse: () => MusimTanam(id: '', name: 'Musim Tanam', fieldId: '', cropId: '', variety: '', plantingArea: 0, seedsCount: 0, seedingDate: DateTime.now(), plantingDate: DateTime.now(), status: ''),
                              );
                              final seasonName = season?.name ?? 'Umum';
                              final field = fieldsState.value?.firstWhere(
                                (f) => f.id == season?.fieldId,
                                orElse: () => Lahan(id: '', name: '-', area: 0, unit: '', locationGps: '', address: '', soilType: '', status: '', waterSource: '', notes: ''),
                              );
                              final lahanName = field?.name ?? '-';

                              // Find corresponding sale if exists to get payment status & paid info
                              final salesList = salesState.value ?? [];
                              final sale = salesList.firstWhere(
                                (s) => s.seasonId == h.seasonId && s.date.day == h.date.day && s.buyerId == h.buyerId && (s.totalPrice - (h.totalPrice ?? 0.0)).abs() < 100,
                                orElse: () => Penjualan(id: '', date: h.date, buyerId: h.buyerId ?? '', buyerName: h.buyerName ?? '', seasonId: h.seasonId, seasonName: seasonName, weight: h.weight, pricePerKg: h.pricePerKg ?? 0.0, totalPrice: h.totalPrice ?? 0.0, status: 'Belum Lunas', amountPaid: 0, remainingDebt: h.totalPrice ?? 0.0),
                              );

                              rows.add([
                                Formatters.formatDate(h.date),
                                seasonName,
                                lahanName,
                                h.harvestedTrees ?? 0,
                                h.weight,
                                h.gradeAWeight,
                                h.priceGradeA ?? 0.0,
                                h.gradeBWeight,
                                h.priceGradeB ?? 0.0,
                                h.gradeCWeight,
                                h.priceGradeC ?? 0.0,
                                h.buyerName ?? 'Umum',
                                h.totalPrice ?? 0.0,
                                sale.status,
                                sale.amountPaid,
                                sale.remainingDebt,
                                h.notes
                              ]);
                            }

                            // Append total row
                            rows.add([
                              'TOTAL KESELURUHAN',
                              '',
                              '',
                              totalTrees,
                              totalWeight,
                              '',
                              '',
                              '',
                              '',
                              '',
                              '',
                              '',
                              totalRevenue,
                              '',
                              '',
                              '',
                              ''
                            ]);

                            final startStr = DateFormat('yyyyMMdd').format(_startDate);
                            final endStr = DateFormat('yyyyMMdd').format(_endDate);
                            await FileExporter.exportToCSV(
                              fileName: 'Rekap_Panen_${startStr}_s.d_$endStr',
                              headers: headers,
                              rows: rows,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Total Revenue Card (Full Width)
              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payments_outlined, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'TOTAL PENDAPATAN',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        Formatters.formatRupiah(totalRevenue),
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dari ${filteredHarvests.length} kali panen & penjualan',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Summary Cards (Row of 2)
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 3,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[800]!, Colors.blue[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.scale_outlined, color: Colors.white70, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'TOTAL BERAT',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${totalWeight.toStringAsFixed(1).replaceAll('.', ',')} Kg',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rata-rata: ${filteredHarvests.isNotEmpty ? (totalWeight / filteredHarvests.length).toStringAsFixed(1).replaceAll('.', ',') : '0'} Kg/panen',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 3,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[800]!, Colors.orange[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.nature_outlined, color: Colors.white70, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'POHON PANEN',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTreesCount(totalTrees),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalTrees > 0 ? (totalWeight / totalTrees).toStringAsFixed(2).replaceAll('.', ',') : '0'} Kg/pohon',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Buyer List Section
              const Text(
                'Distribusi ke Tengkulak / Pembeli',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (buyerStats.isEmpty)
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: Colors.grey[400], size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada data panen di periode terpilih.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: buyerStats.keys.length,
                  itemBuilder: (context, idx) {
                    final bName = buyerStats.keys.elementAt(idx);
                    final stats = buyerStats[bName]!;
                    final weight = stats['weight'] as double;
                    final price = stats['totalPrice'] as double;
                    final count = stats['count'] as int;

                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.green[50],
                          child: Icon(Icons.handshake_outlined, color: Colors.green[800]),
                        ),
                        title: Text(
                          bName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '$count kali transaksi penjualan',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${weight.toStringAsFixed(1).replaceAll('.', ',')} Kg',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatRupiah(price),
                              style: TextStyle(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  String _formatTreesCount(int count) {
    if (count >= 1000) {
      final double thousands = count / 1000;
      return "${thousands.toStringAsFixed(1).replaceAll('.', ',')} rb";
    }
    return "$count";
  }

  Widget _buildBreakdownItem(String label, double value, double total, Color color) {
    final pct = total > 0 ? (value / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text('${Formatters.formatRupiah(value)} (${(pct * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
