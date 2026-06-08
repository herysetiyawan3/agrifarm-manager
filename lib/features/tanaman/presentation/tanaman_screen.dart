import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart';
import '../../database_repository.dart';

class TanamanScreen extends ConsumerStatefulWidget {
  const TanamanScreen({super.key});

  @override
  ConsumerState<TanamanScreen> createState() => _TanamanScreenState();
}

class _TanamanScreenState extends ConsumerState<TanamanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _varietyController = TextEditingController();
  final _ageController = TextEditingController();
  final _waterController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _resetForm() {
    _nameController.clear();
    _varietyController.clear();
    _ageController.clear();
    _waterController.clear();
    _descriptionController.clear();
  }

  void _showFormDialog([Tanaman? tanaman]) {
    if (tanaman != null) {
      _nameController.text = tanaman.name;
      _varietyController.text = tanaman.variety;
      _ageController.text = tanaman.harvestAgeDays.toString();
      _waterController.text = tanaman.waterRequirement;
      _descriptionController.text = tanaman.description;
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
                    tanaman == null ? 'Tambah Tanaman Baru' : 'Edit Data Tanaman',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama Tanaman (Komoditas)', prefixIcon: Icon(Icons.grass_outlined)),
                    validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _varietyController,
                    decoration: const InputDecoration(labelText: 'Varietas Tanaman (e.g. Hikapel, Action)', prefixIcon: Icon(Icons.category_outlined)),
                    validator: (value) => value == null || value.isEmpty ? 'Varietas wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Umur Panen (Hari Setelah Tanam)', prefixIcon: Icon(Icons.timer_outlined)),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Umur panen wajib diisi';
                      if (int.tryParse(value) == null) return 'Harus angka';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _waterController,
                    decoration: const InputDecoration(labelText: 'Kebutuhan Air (e.g. Tinggi, Sedang, Rendah)', prefixIcon: Icon(Icons.water_drop_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Keterangan Lain', prefixIcon: Icon(Icons.info_outline)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      
                      final repo = ref.read(databaseRepositoryProvider);
                      final data = Tanaman(
                        id: tanaman?.id ?? '',
                        name: _nameController.text.trim(),
                        variety: _varietyController.text.trim(),
                        harvestAgeDays: int.tryParse(_ageController.text) ?? 60,
                        waterRequirement: _waterController.text.trim(),
                        description: _descriptionController.text.trim(),
                      );

                      if (tanaman == null) {
                        await repo.addCrop(data);
                      } else {
                        await repo.updateCrop(data);
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data tanaman berhasil disimpan!'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan Tanaman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteTanaman(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tanaman?'),
        content: const Text('Data tanaman ini akan dihapus dari katalog master.'),
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
      await ref.read(databaseRepositoryProvider).deleteCrop(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanaman berhasil dihapus.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _addSampleData() async {
    final repo = ref.read(databaseRepositoryProvider);
    final samples = [
      Tanaman(id: '', name: 'Melon', variety: 'Golden Melon', harvestAgeDays: 75, waterRequirement: 'Tinggi', description: 'Melon kuning manis premium'),
      Tanaman(id: '', name: 'Semangka', variety: 'Inul Merah', harvestAgeDays: 65, waterRequirement: 'Sedang', description: 'Semangka merah tanpa biji'),
      Tanaman(id: '', name: 'Cabai', variety: 'Rawit Setan', harvestAgeDays: 90, waterRequirement: 'Sedang', description: 'Cabai rawit merah pedas tinggi'),
      Tanaman(id: '', name: 'Tomat', variety: 'Servo F1', harvestAgeDays: 80, waterRequirement: 'Sedang', description: 'Tomat sayur tahan virus gemini'),
    ];

    for (var s in samples) {
      await repo.addCrop(s);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data contoh berhasil ditambahkan!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cropsState = ref.watch(watchCropsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Tanaman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Tambah Data Contoh',
            onPressed: _addSampleData,
          )
        ],
      ),
      body: cropsState.when(
        data: (crops) {
          if (crops.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Katalog tanaman masih kosong.', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _addSampleData,
                      child: const Text('Masukkan Data Contoh (Melon, Cabai, dll.)'),
                    )
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: crops.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final crop = crops[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[100],
                    child: Icon(Icons.grass, color: Colors.teal[800]),
                  ),
                  title: Text('${crop.name} - ${crop.variety}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Estimasi Panen: ${crop.harvestAgeDays} HST | Kebutuhan Air: ${crop.waterRequirement}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () => _showFormDialog(crop),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _deleteTanaman(crop.id),
                      ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
