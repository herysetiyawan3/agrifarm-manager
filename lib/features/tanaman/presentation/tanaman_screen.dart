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

  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'a-z', 'z-a', 'age_asc', 'age_desc'

  @override
  void dispose() {
    _nameController.dispose();
    _varietyController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _varietyController.clear();
    _ageController.clear();
  }

  void _showFormDialog([Tanaman? tanaman]) {
    if (tanaman != null) {
      _nameController.text = tanaman.name;
      _varietyController.text = tanaman.variety;
      _ageController.text = tanaman.harvestAgeDays.toString();
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
                    decoration: const InputDecoration(
                      labelText: 'Nama Tanaman',
                      prefixIcon: Icon(Icons.grass_outlined),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Nama Tanaman wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _varietyController,
                    decoration: const InputDecoration(
                      labelText: 'Varietas',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Varietas wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Umur Panen (HST)',
                      prefixIcon: Icon(Icons.timer_outlined),
                      suffixText: 'HST',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Umur Panen wajib diisi';
                      final val = int.tryParse(value);
                      if (val == null) return 'Umur Panen hanya boleh angka';
                      if (val < 1) return 'Umur Panen minimal 1 HST';
                      return null;
                    },
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
                        waterRequirement: tanaman?.waterRequirement ?? '',
                        description: tanaman?.description ?? '',
                      );

                      if (tanaman == null) {
                        await repo.addCrop(data);
                      } else {
                        await repo.updateCrop(data);
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data tanaman berhasil disimpan!'),
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

          final query = _searchQuery.toLowerCase();
          final filteredCrops = crops.where((crop) {
            if (query.isEmpty) return true;
            return crop.name.toLowerCase().contains(query) ||
                crop.variety.toLowerCase().contains(query);
          }).toList();

          switch (_selectedFilter) {
            case 'a-z':
              filteredCrops.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              break;
            case 'z-a':
              filteredCrops.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
              break;
            case 'age_asc':
              filteredCrops.sort((a, b) => a.harvestAgeDays.compareTo(b.harvestAgeDays));
              break;
            case 'age_desc':
              filteredCrops.sort((a, b) => b.harvestAgeDays.compareTo(a.harvestAgeDays));
              break;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Cari tanaman atau varietas...',
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
                          value: _selectedFilter,
                          icon: const Icon(Icons.filter_list),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedFilter = val;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Semua Tanaman')),
                            DropdownMenuItem(value: 'a-z', child: Text('Nama A-Z')),
                            DropdownMenuItem(value: 'z-a', child: Text('Nama Z-A')),
                            DropdownMenuItem(value: 'age_asc', child: Text('Umur Tercepat')),
                            DropdownMenuItem(value: 'age_desc', child: Text('Umur Terlama')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredCrops.isEmpty
                    ? const Center(child: Text('Tidak ada tanaman yang cocok.'))
                    : ListView.builder(
                        itemCount: filteredCrops.length,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemBuilder: (context, index) {
                          final crop = filteredCrops[index];
                          return Card(
                            elevation: 2,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.teal[50],
                                child: Icon(Icons.grass, color: Colors.teal[800]),
                              ),
                              title: Text(crop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Varietas: ${crop.variety}\nUmur Panen: ${crop.harvestAgeDays} HST',
                                  style: TextStyle(color: Colors.grey[600], height: 1.3),
                                ),
                              ),
                              isThreeLine: true,
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
