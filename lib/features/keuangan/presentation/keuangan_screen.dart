import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/formatters.dart';

class KeuanganScreen extends ConsumerStatefulWidget {
  const KeuanganScreen({super.key});

  @override
  ConsumerState<KeuanganScreen> createState() => _KeuanganScreenState();
}

class _KeuanganScreenState extends ConsumerState<KeuanganScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Lainnya';
  DateTime _expenseDate = DateTime.now();
  String _localPhotoPath = '';
  bool _isSaving = false;

  final List<String> _categories = ['Bibit', 'Pupuk', 'Pestisida', 'Upah', 'Transportasi', 'Sewa Lahan', 'BBM', 'Listrik', 'Air', 'Lainnya'];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = 'Lainnya';
      _expenseDate = DateTime.now();
      _localPhotoPath = '';
      _isSaving = false;
    });
  }

  void _showFormDialog([Pengeluaran? oldExp]) {
    if (oldExp != null) {
      _amountController.text = oldExp.amount.toString();
      _descriptionController.text = oldExp.description;
      _selectedCategory = oldExp.category;
      _expenseDate = oldExp.date;
    } else {
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 20, right: 20),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(oldExp == null ? 'Catat Pengeluaran Baru' : 'Edit Pengeluaran', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Nominal Pengeluaran (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
                        validator: (value) => value == null || value.isEmpty ? 'Nominal wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Kategori Pengeluaran', prefixIcon: Icon(Icons.category_outlined)),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedCategory = val!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Keterangan/Deskripsi', prefixIcon: Icon(Icons.description_outlined)),
                        validator: (value) => value == null || value.isEmpty ? 'Deskripsi wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Tanggal: ${Formatters.formatDate(_expenseDate)}'),
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: _expenseDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (date != null) {
                            setDialogState(() => _expenseDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(_localPhotoPath.isEmpty ? 'Upload Foto Nota/Kuitansi' : 'Foto Terpilih (Ganti)'),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (file != null) {
                            setDialogState(() => _localPhotoPath = file.path);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setDialogState(() => _isSaving = true);

                                try {
                                  String photoUrl = oldExp?.photoUrl ?? '';
                                  if (_localPhotoPath.isNotEmpty) {
                                    photoUrl = await StorageService.uploadImage(
                                      localPath: _localPhotoPath,
                                      folder: 'expenses',
                                      fileName: 'expense_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                    );
                                  }

                                  final repo = ref.read(databaseRepositoryProvider);
                                  final data = Pengeluaran(
                                    id: oldExp?.id ?? '',
                                    date: _expenseDate,
                                    seasonId: oldExp?.seasonId ?? '',
                                    category: _selectedCategory,
                                    description: _descriptionController.text.trim(),
                                    amount: double.tryParse(_amountController.text) ?? 0.0,
                                    photoUrl: photoUrl,
                                  );

                                  if (oldExp == null) {
                                    await repo.addExpense(data);
                                  } else {
                                    await repo.updateExpense(data);
                                  }

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengeluaran berhasil dicatat!'), backgroundColor: Colors.green));
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencatat: $e'), backgroundColor: Colors.red));
                                  }
                                } finally {
                                  setDialogState(() => _isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Simpan Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _deleteExpense(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan Biaya?'),
        content: const Text('Catatan pengeluaran kas ini akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(databaseRepositoryProvider).deleteExpense(id);
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Bibit': return Icons.spa_outlined;
      case 'Pupuk': return Icons.grass_outlined;
      case 'Pestisida': return Icons.coronavirus_outlined;
      case 'Upah': return Icons.people_outline;
      case 'Transportasi': return Icons.local_shipping_outlined;
      case 'Sewa Lahan': return Icons.landscape_outlined;
      case 'BBM': return Icons.local_gas_station_outlined;
      case 'Listrik': return Icons.power_outlined;
      case 'Air': return Icons.water_drop_outlined;
      default: return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesState = ref.watch(watchExpensesProvider);
    final seasonsState = ref.watch(watchSeasonsProvider);
    final seasons = seasonsState.value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Buku Kas Pengeluaran')),
      body: expensesState.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(child: Text('Belum ada catatan pengeluaran kas.'));
          }

          double totalCash = 0.0;
          for (var exp in expenses) {
            totalCash += exp.amount;
          }

          return Column(
            children: [
              // Summary Total Card
              Card(
                color: Colors.green[800],
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pengeluaran:',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        Formatters.formatRupiah(totalCash),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Expense List
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    final isSeasonFinished = exp.seasonId.isNotEmpty &&
                        seasons.any((s) => s.id == exp.seasonId && s.status == 'Selesai');

                    return Card(
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[100],
                          child: Icon(_getCategoryIcon(exp.category), color: Colors.red[800]),
                        ),
                        title: Text(exp.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${exp.category} | ${Formatters.formatDate(exp.date)}'),
                        trailing: Text(
                          Formatters.formatRupiah(exp.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Tanggal: ${Formatters.formatLongDate(exp.date)}', style: const TextStyle(fontSize: 13)),
                                Text('Kategori: ${exp.category}', style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 12),
                                if (exp.photoUrl.isNotEmpty) ...[
                                  const Text('Bukti Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Image.network(exp.photoUrl, height: 160, fit: BoxFit.cover),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        if (isSeasonFinished) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Tidak dapat mengubah biaya pada musim tanam yang sudah Selesai.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        } else {
                                          _showFormDialog(exp);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        if (isSeasonFinished) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Tidak dapat mengubah biaya pada musim tanam yang sudah Selesai.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        } else {
                                          _deleteExpense(exp.id);
                                        }
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.post_add),
      ),
    );
  }
}
