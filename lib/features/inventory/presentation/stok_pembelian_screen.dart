import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../../core/services/storage_service.dart';
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
  final _shopController = TextEditingController();
  final _supplierController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  String _selectedCategory = 'Pupuk';
  DateTime _purchaseDate = DateTime.now();
  String _receiptLocalPath = '';
  bool _isUploading = false;

  final List<String> _categories = ['Bibit', 'Pupuk', 'Pestisida', 'Mulsa', 'Tali Rambat', 'Plastik', 'Peralatan'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemNameController.dispose();
    _shopController.dispose();
    _supplierController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _receiptLocalPath = pickedFile.path;
      });
    }
  }

  void _resetForm() {
    _itemNameController.clear();
    _shopController.clear();
    _supplierController.clear();
    _priceController.clear();
    _quantityController.clear();
    setState(() {
      _selectedCategory = 'Pupuk';
      _purchaseDate = DateTime.now();
      _receiptLocalPath = '';
      _isUploading = false;
    });
  }

  void _showPurchaseDialog([Pembelian? oldPurchase]) {
    if (oldPurchase != null) {
      _itemNameController.text = oldPurchase.itemName;
      _selectedCategory = oldPurchase.category;
      _priceController.text = oldPurchase.unitPrice == oldPurchase.unitPrice.toInt() ? oldPurchase.unitPrice.toInt().toString() : oldPurchase.unitPrice.toString();
      _quantityController.text = oldPurchase.quantity == oldPurchase.quantity.toInt() ? oldPurchase.quantity.toInt().toString() : oldPurchase.quantity.toString();
      _shopController.text = oldPurchase.shop;
      _supplierController.text = oldPurchase.supplier;
      _purchaseDate = oldPurchase.purchaseDate;
      _receiptLocalPath = '';
      _isUploading = false;
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
                        decoration: const InputDecoration(labelText: 'Nama Barang/Merek', prefixIcon: Icon(Icons.shopping_bag_outlined)),
                        validator: (value) => value == null || value.isEmpty ? 'Nama barang wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.category_outlined)),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Harga Satuan (Rp)', prefixIcon: Icon(Icons.monetization_on_outlined)),
                              onTap: () {
                                if (_priceController.text == '0' || _priceController.text == '0.0') {
                                  _priceController.clear();
                                }
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Harga wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Jumlah Beli', prefixIcon: Icon(Icons.production_quantity_limits)),
                              onTap: () {
                                if (_quantityController.text == '0' || _quantityController.text == '0.0') {
                                  _quantityController.clear();
                                }
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Jumlah wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _shopController,
                              decoration: const InputDecoration(labelText: 'Nama Toko', prefixIcon: Icon(Icons.store_outlined)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _supplierController,
                              decoration: const InputDecoration(labelText: 'Supplier', prefixIcon: Icon(Icons.business_outlined)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Tanggal: ${Formatters.formatDate(_purchaseDate)}'),
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
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(_receiptLocalPath.isEmpty && (oldPurchase?.receiptPhotoUrl ?? '').isEmpty
                            ? 'Upload Struk/Nota'
                            : _receiptLocalPath.isNotEmpty
                                ? 'Nota Baru Terpilih'
                                : 'Nota Lama Terunggah (Ganti)'),
                        onPressed: () async {
                          await _pickReceiptImage();
                          setDialogState(() {});
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isUploading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                
                                setDialogState(() {
                                  _isUploading = true;
                                });

                                try {
                                  String receiptUrl = oldPurchase?.receiptPhotoUrl ?? '';
                                  if (_receiptLocalPath.isNotEmpty) {
                                    receiptUrl = await StorageService.uploadImage(
                                      localPath: _receiptLocalPath,
                                      folder: 'receipts',
                                      fileName: 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                    );
                                  }

                                  final repo = ref.read(databaseRepositoryProvider);
                                  final price = double.tryParse(_priceController.text) ?? 0.0;
                                  final qty = double.tryParse(_quantityController.text) ?? 0.0;

                                  final purchase = Pembelian(
                                    id: oldPurchase?.id ?? '',
                                    itemName: _itemNameController.text.trim(),
                                    category: _selectedCategory,
                                    shop: _shopController.text.trim(),
                                    supplier: _supplierController.text.trim(),
                                    purchaseDate: _purchaseDate,
                                    unitPrice: price,
                                    quantity: qty,
                                    totalPrice: price * qty,
                                    receiptPhotoUrl: receiptUrl,
                                  );

                                  if (oldPurchase == null) {
                                    await repo.addPurchase(purchase);
                                  } else {
                                    await repo.updatePurchase(oldPurchase, purchase);
                                  }

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Pembelian & Stok berhasil dicatat!'), backgroundColor: Colors.green),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                } finally {
                                  setDialogState(() {
                                    _isUploading = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isUploading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Simpan Pembelian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              if (stocks.isEmpty) {
                return const Center(child: Text('Stok kosong. Catat pembelian baru untuk menambah stok.'));
              }

              return ListView.builder(
                itemCount: stocks.length,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (context, index) {
                  final stok = stocks[index];
                  final isLow = stok.currentStock <= 5.0; // Warning threshold

                  return Card(
                    color: isLow ? Colors.orange[50] : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isLow ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                        child: Text(stok.unit),
                      ),
                      title: Text(stok.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Kategori: ${stok.category} | Masuk: ${stok.quantityIn} | Keluar: ${stok.quantityOut}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${stok.currentStock}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isLow ? Colors.orange[900] : Colors.green[900],
                            ),
                          ),
                          if (isLow)
                            const Text('Stok Menipis!', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),

          // TAB 2: RIWAYAT PEMBELIAN
          purchaseState.when(
            data: (purchases) {
              if (purchases.isEmpty) {
                return const Center(child: Text('Belum ada riwayat pembelian.'));
              }

              return ListView.builder(
                itemCount: purchases.length,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (context, index) {
                  final p = purchases[index];

                  return Card(
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo[100],
                        child: const Icon(Icons.shopping_bag, color: Colors.indigo),
                      ),
                      title: Text(p.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${Formatters.formatDate(p.purchaseDate)} | Total: ${Formatters.formatRupiah(p.totalPrice)}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Kategori: ${p.category}', style: const TextStyle(fontSize: 13)),
                              Text('Harga Satuan: ${Formatters.formatRupiah(p.unitPrice)} | Jumlah: ${p.quantity}', style: const TextStyle(fontSize: 13)),
                              Text('Toko: ${p.shop} | Supplier: ${p.supplier}', style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 12),
                              if (p.receiptPhotoUrl.isNotEmpty) ...[
                                const Text('Bukti Struk/Nota:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 6),
                                Image.network(p.receiptPhotoUrl, height: 160, fit: BoxFit.cover),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    label: const Text('Ubah', style: TextStyle(color: Colors.blue)),
                                    onPressed: () => _showPurchaseDialog(p),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    onPressed: () => _deletePurchase(p.id, p),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
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
