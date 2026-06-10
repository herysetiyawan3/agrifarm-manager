import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../../core/utils/formatters.dart';

class StokPembelianScreen extends ConsumerStatefulWidget {
  const StokPembelianScreen({super.key});

  @override
  ConsumerState<StokPembelianScreen> createState() => _StokPembelianScreenState();
}

class _StokPembelianScreenState extends ConsumerState<StokPembelianScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();

  String _selectedCategory = 'Pupuk';
  DateTime _purchaseDate = DateTime.now();

  String _stokSearchQuery = '';
  String _searchQuery = '';

  final List<String> _categories = [
    'Pupuk',
    'Pestisida',
    'Fungisida',
    'Herbisida',
    'Benih',
    'Mulsa',
    'Peralatan',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  String _extractUnitLocal(String text, double quantity) {
    final qtyStr = quantity == quantity.toInt() ? quantity.toInt().toString() : quantity.toString();
    if (text.startsWith(qtyStr)) {
      return text.substring(qtyStr.length).trim();
    }
    final firstSpace = text.indexOf(' ');
    if (firstSpace != -1) {
      final firstPart = text.substring(0, firstSpace);
      if (double.tryParse(firstPart) != null) {
        return text.substring(firstSpace + 1).trim();
      }
    }
    return text.trim();
  }

  void _resetForm() {
    _itemNameController.clear();
    _priceController.clear();
    _quantityController.clear();
    _unitController.clear();
    setState(() {
      _selectedCategory = 'Pupuk';
      _purchaseDate = DateTime.now();
    });
  }

  void _showPurchaseDialog([Pembelian? oldPurchase]) {
    if (oldPurchase != null) {
      _itemNameController.text = oldPurchase.itemName;
      _selectedCategory = oldPurchase.category;
      _priceController.text = oldPurchase.totalPrice == oldPurchase.totalPrice.toInt()
          ? oldPurchase.totalPrice.toInt().toString()
          : oldPurchase.totalPrice.toString();
      _quantityController.text = oldPurchase.quantity == oldPurchase.quantity.toInt()
          ? oldPurchase.quantity.toInt().toString()
          : oldPurchase.quantity.toString();
      _unitController.text = _extractUnitLocal(oldPurchase.jumlah, oldPurchase.quantity);
      _purchaseDate = oldPurchase.purchaseDate;
    } else {
      _resetForm();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        oldPurchase == null ? 'Catat Pembelian Baru' : 'Edit Data Pembelian',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _itemNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Barang/Merek',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Nama barang wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Jumlah',
                                prefixIcon: Icon(Icons.production_quantity_limits),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _unitController,
                              decoration: const InputDecoration(
                                labelText: 'Satuan',
                                hintText: 'e.g. Karung',
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Harga (Rp)',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Total harga wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Tanggal Pembelian: ${Formatters.formatLongDate(_purchaseDate)}'),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _purchaseDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _purchaseDate = date;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          final totalPrice = double.tryParse(_priceController.text) ?? 0.0;
                          final qty = double.tryParse(_quantityController.text) ?? 0.0;
                          final unit = _unitController.text.trim();
                          final qtyStr = qty == qty.toInt() ? qty.toInt().toString() : qty.toString();
                          final jumlahStr = "$qtyStr $unit";
                          final unitPrice = qty > 0 ? (totalPrice / qty) : totalPrice;

                          final purchase = Pembelian(
                            id: oldPurchase?.id ?? '',
                            itemName: _itemNameController.text.trim(),
                            category: _selectedCategory,
                            shop: oldPurchase?.shop ?? '',
                            supplier: oldPurchase?.supplier ?? '',
                            purchaseDate: _purchaseDate,
                            unitPrice: unitPrice,
                            quantity: qty,
                            totalPrice: totalPrice,
                            receiptPhotoUrl: oldPurchase?.receiptPhotoUrl ?? '',
                            jumlah: jumlahStr,
                          );

                          final repo = ref.read(databaseRepositoryProvider);
                          if (oldPurchase == null) {
                            await repo.addPurchase(purchase);
                          } else {
                            await repo.updatePurchase(oldPurchase, purchase);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pembelian & Stok berhasil disimpan!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan Pembelian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deletePurchase(String id, Pembelian p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pembelian?'),
        content: const Text('Tindakan ini juga akan mengurangi stok barang di inventaris.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(databaseRepositoryProvider).deletePurchase(id, p);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data pembelian berhasil dihapus.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pupuk':
        return Colors.green;
      case 'Pestisida':
        return Colors.blue;
      case 'Fungisida':
        return Colors.orange;
      case 'Benih':
      case 'Bibit':
        return Colors.purple;
      case 'Peralatan':
        return Colors.grey;
      case 'Herbisida':
        return Colors.red;
      case 'Mulsa':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stokState = ref.watch(watchStokProvider);
    final purchaseState = ref.watch(watchPurchasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok & Pembelian'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(icon: Icon(Icons.storage), text: 'Stok Barang'),
            Tab(icon: Icon(Icons.history_edu), text: 'Riwayat Beli'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: STOK BARANG
          stokState.when(
            data: (stocks) {
              final query = _stokSearchQuery.toLowerCase();
              final filteredStocks = stocks.where((s) {
                if (query.isEmpty) return true;
                return s.itemName.toLowerCase().contains(query);
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Cari barang...',
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _stokSearchQuery = val;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredStocks.isEmpty
                        ? const Center(child: Text('Stok kosong atau barang tidak ditemukan.'))
                        : ListView.builder(
                            itemCount: filteredStocks.length,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemBuilder: (context, index) {
                              final stok = filteredStocks[index];

                              return Card(
                                elevation: 2,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: _getCategoryColor(stok.category).withOpacity(0.1),
                                        child: Icon(Icons.inventory_2_outlined, color: _getCategoryColor(stok.category)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              stok.itemName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Kategori: ${stok.category}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                            const SizedBox(height: 2),
                                            Builder(
                                              builder: (context) {
                                                final displayStock = stok.currentStock == stok.currentStock.toInt()
                                                    ? stok.currentStock.toInt().toString()
                                                    : stok.currentStock.toString();
                                                return Text(
                                                  'Stok Saat Ini: $displayStock ${stok.unit}',
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          String status = 'Tersedia';
                                          Color color = Colors.green;
                                          if (stok.currentStock <= 0) {
                                            status = 'Habis';
                                            color = Colors.red;
                                          } else if (stok.currentStock <= 5) {
                                            status = 'Menipis';
                                            color = Colors.orange;
                                          }
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: color.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),

          // TAB 2: RIWAYAT PEMBELIAN
          purchaseState.when(
            data: (purchases) {
              final now = DateTime.now();
              final currentMonthPurchases = purchases.where((p) =>
                  p.purchaseDate.year == now.year && p.purchaseDate.month == now.month).toList();
              final totalTx = currentMonthPurchases.length;
              final totalExpense = currentMonthPurchases.fold<double>(0.0, (sum, p) => sum + p.totalPrice);

              final summaryCard = Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
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
                          Icon(Icons.calendar_month, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'PEMBELIAN BULAN INI',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Transaksi', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('$totalTx', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.formatRupiah(totalExpense),
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );

              final query = _searchQuery.toLowerCase();
              final filteredPurchases = purchases.where((p) {
                if (query.isEmpty) return true;
                return p.itemName.toLowerCase().contains(query);
              }).toList();

              return Column(
                children: [
                  summaryCard,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Cari barang...',
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: ref.watch(purchasesFilterProvider),
                              icon: const Icon(Icons.sort),
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(purchasesFilterProvider.notifier).state = val;
                                }
                              },
                              items: const [
                                DropdownMenuItem(value: 'date_desc', child: Text('Terbaru')),
                                DropdownMenuItem(value: 'date_asc', child: Text('Terlama')),
                                DropdownMenuItem(value: 'price_desc', child: Text('Harga Tertinggi')),
                                DropdownMenuItem(value: 'price_asc', child: Text('Harga Terendah')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredPurchases.isEmpty
                        ? const Center(child: Text('Belum ada riwayat pembelian yang cocok.'))
                        : ListView.builder(
                            itemCount: filteredPurchases.length,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemBuilder: (context, index) {
                              final p = filteredPurchases[index];

                              return Card(
                                elevation: 2,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            p.itemName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getCategoryColor(p.category).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              p.category,
                                              style: TextStyle(
                                                color: _getCategoryColor(p.category),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        Formatters.formatLongDate(p.purchaseDate),
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                      const Divider(height: 16),
                                      Text(
                                        'Jumlah: ${p.jumlah}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total Harga: ${Formatters.formatRupiah(p.totalPrice)}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.edit, size: 14, color: Colors.blue),
                                            label: const Text('Ubah', style: TextStyle(color: Colors.blue, fontSize: 12)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.blue),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            ),
                                            onPressed: () => _showPurchaseDialog(p),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                                            label: const Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 12)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.red),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            ),
                                            onPressed: () => _deletePurchase(p.id, p),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPurchaseDialog(),
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
