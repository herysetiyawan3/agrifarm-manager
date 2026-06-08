import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/profile_screen.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';

// Navigation hooks to other screens (we'll implement these screens next)
import '../../lahan/presentation/lahan_screen.dart';
import '../../tanaman/presentation/tanaman_screen.dart';
import '../../perencanaan/presentation/musim_tanam_screen.dart';
import '../../inventory/presentation/stok_pembelian_screen.dart';
import '../../aktivitas/presentation/jadwal_kegiatan_screen.dart';
import '../../hama/presentation/hama_screen.dart';
import '../../tenaga_kerja/presentation/pekerja_screen.dart';
import '../../keuangan/presentation/keuangan_screen.dart';
import '../../penjualan/presentation/panen_penjualan_screen.dart';
import '../../laporan/presentation/laporan_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final fieldsVal = ref.watch(watchFieldsProvider);
    final seasonsVal = ref.watch(watchSeasonsProvider);
    final expensesVal = ref.watch(watchExpensesProvider);
    final salesVal = ref.watch(watchSalesProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Tani', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          onPressed: () {
            ref.read(isDarkModeProvider.notifier).state = !isDark;
          },
        ),
        actions: [
          profileState.when(
            data: (profile) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  backgroundImage: profile?.photoUrl.isNotEmpty == true
                      ? NetworkImage(profile!.photoUrl)
                      : null,
                  child: profile?.photoUrl.isEmpty == true || profile == null
                      ? const Icon(Icons.person, size: 18, color: Colors.green)
                      : null,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(watchFieldsProvider);
          ref.invalidate(watchSeasonsProvider);
          ref.invalidate(watchExpensesProvider);
          ref.invalidate(watchSalesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Widget
              profileState.when(
                data: (profile) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Text(
                    'Halo, ${profile?.displayName ?? 'Petani'}! 👋',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 12),

              // Overview Stats Card Row
              _buildStatsGrid(context, fieldsVal, seasonsVal, expensesVal, salesVal),

              const SizedBox(height: 20),

              // Active Planting Season Card
              _buildActiveSeasonCard(context, seasonsVal, fieldsVal),

              const SizedBox(height: 20),

              // Financial Chart Section
              _buildChartSection(context, expensesVal, salesVal, isDark),

              const SizedBox(height: 20),

              // Module Quick Menu Grid
              _buildQuickMenuGrid(context),

              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showQuickActionDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Catat Cepat', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AsyncValue<List<Lahan>> fieldsVal,
    AsyncValue<List<MusimTanam>> seasonsVal,
    AsyncValue<List<Pengeluaran>> expensesVal,
    AsyncValue<List<Penjualan>> salesVal,
  ) {
    final fieldsCount = fieldsVal.value?.length ?? 0;
    final activeSeasons = seasonsVal.value?.where((s) => s.status == 'Berjalan').length ?? 0;
    
    double totalExp = 0.0;
    for (var exp in expensesVal.value ?? []) {
      totalExp += exp.amount;
    }

    double totalRev = 0.0;
    for (var sale in salesVal.value ?? []) {
      totalRev += sale.totalPrice;
    }

    final netProfit = totalRev - totalExp;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: [
          _buildStatItem('Lahan Aktif', '$fieldsCount Lahan', Icons.landscape, Colors.green),
          _buildStatItem('Musim Berjalan', '$activeSeasons Siklus', Icons.spa, Colors.teal),
          _buildStatItem('Total Biaya', Formatters.formatShortRupiah(totalExp), Icons.payment, Colors.red),
          _buildStatItem('Laba Bersih', Formatters.formatShortRupiah(netProfit), Icons.trending_up, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSeasonCard(BuildContext context, AsyncValue<List<MusimTanam>> seasonsVal, AsyncValue<List<Lahan>> fieldsVal) {
    final activeSeason = seasonsVal.value?.firstWhere((s) => s.status == 'Berjalan',
        orElse: () => MusimTanam(
            id: '',
            name: 'Tidak ada musim aktif',
            fieldId: '',
            cropId: '',
            variety: '',
            plantingArea: 0.0,
            seedsCount: 0,
            seedingDate: DateTime.now(),
            plantingDate: DateTime.now(),
            status: ''));

    if (activeSeason == null || activeSeason.id == '') {
      return Card(
        color: Colors.green[50],
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.info_outline, color: Colors.green, size: 32),
              SizedBox(height: 8),
              Text(
                'Belum ada musim tanam berjalan',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Text('Silakan tambahkan perencanaan tanam baru di menu bawah.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final fieldName = fieldsVal.value?.firstWhere((f) => f.id == activeSeason.fieldId, orElse: () => Lahan(id: '', name: 'Lahan Umum', area: 0, unit: '', locationGps: '', address: '', soilType: '', status: '', waterSource: '', notes: '')).name ?? 'Lahan';
    final hst = Formatters.calculateHST(activeSeason.plantingDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Musim Tanam Berjalan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[800]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'HST: $hst Hari',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activeSeason.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Varietas: ${activeSeason.variety} | Lahan: $fieldName', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              value: 0.65, // Example completion rate
              backgroundColor: Colors.grey,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Semai: ${Formatters.formatDate(activeSeason.seedingDate)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text('Tanam: ${Formatters.formatDate(activeSeason.plantingDate)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, AsyncValue<List<Pengeluaran>> expensesVal, AsyncValue<List<Penjualan>> salesVal, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perkembangan Laba Rugi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Expenses line (Red)
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 1),
                        FlSpot(1, 2.5),
                        FlSpot(2, 1.8),
                        FlSpot(3, 4.2),
                      ],
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    // Revenue line (Green)
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 0),
                        FlSpot(1, 1.2),
                        FlSpot(2, 3.5),
                        FlSpot(3, 8.0),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: Colors.green, size: 12),
                SizedBox(width: 4),
                Text('Penjualan', style: TextStyle(fontSize: 12)),
                SizedBox(width: 20),
                Icon(Icons.circle, color: Colors.red, size: 12),
                SizedBox(width: 4),
                Text('Pengeluaran', style: TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenuGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'Menu Manajemen Kebun',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildMenuItem(context, 'Lahan', Icons.landscape_outlined, Colors.green, const LahanScreen()),
              _buildMenuItem(context, 'Tanaman', Icons.grass_outlined, Colors.teal, const TanamanScreen()),
              _buildMenuItem(context, 'Siklus Tanam', Icons.calendar_today_outlined, Colors.blue, const MusimTanamScreen()),
              _buildMenuItem(context, 'Stok & Beli', Icons.shopping_basket_outlined, Colors.indigo, const StokPembelianScreen()),
              _buildMenuItem(context, 'Jadwal Tani', Icons.alarm_outlined, Colors.orange, const JadwalKegiatanScreen()),
              _buildMenuItem(context, 'Hama/Penyakit', Icons.bug_report_outlined, Colors.red, const HamaScreen()),
              _buildMenuItem(context, 'Tenaga Kerja', Icons.people_outline, Colors.brown, const PekerjaScreen()),
              _buildMenuItem(context, 'Buku Kas', Icons.account_balance_wallet_outlined, Colors.blueGrey, const KeuanganScreen()),
              _buildMenuItem(context, 'Panen & Jual', Icons.monetization_on_outlined, Colors.amber[800]!, const PanenPenjualanScreen()),
              _buildMenuItem(context, 'Laporan Keuangan', Icons.analytics_outlined, Colors.purple, const LaporanScreen()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Catat Cepat Aktivitas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.landscape, color: Colors.white)),
                title: const Text('Tambah Lahan Baru'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LahanScreen()));
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.shopping_cart, color: Colors.white)),
                title: const Text('Catat Pembelian Saprotan'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StokPembelianScreen()));
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.payment, color: Colors.white)),
                title: const Text('Catat Pengeluaran Operasional'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const KeuanganScreen()));
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.monetization_on, color: Colors.white)),
                title: const Text('Catat Hasil Panen / Penjualan'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PanenPenjualanScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
