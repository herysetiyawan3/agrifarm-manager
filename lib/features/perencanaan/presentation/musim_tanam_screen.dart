import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../../core/utils/formatters.dart';

class MusimTanamScreen extends ConsumerStatefulWidget {
  const MusimTanamScreen({super.key});

  @override
  ConsumerState<MusimTanamScreen> createState() => _MusimTanamScreenState();
}

class _MusimTanamScreenState extends ConsumerState<MusimTanamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _varietyController = TextEditingController();
  final _areaController = TextEditingController();
  final _seedsController = TextEditingController();

  String? _selectedFieldId;
  String? _selectedCropId;
  DateTime _seedingDate = DateTime.now();
  DateTime _plantingDate = DateTime.now();
  String _selectedStatus = 'Perencanaan';

  final List<String> _statuses = ['Perencanaan', 'Berjalan', 'Selesai'];

  void _resetForm() {
    _nameController.clear();
    _varietyController.clear();
    _areaController.clear();
    _seedsController.clear();
    setState(() {
      _selectedFieldId = null;
      _selectedCropId = null;
      _seedingDate = DateTime.now();
      _plantingDate = DateTime.now();
      _selectedStatus = 'Perencanaan';
    });
  }

  void _showFormDialog(List<Lahan> fields, List<Tanaman> crops, [MusimTanam? season]) {
    if (season != null) {
      _nameController.text = season.name;
      _varietyController.text = season.variety;
      final field = fields.firstWhere((f) => f.id == season.fieldId, orElse: () => fields.first);
      final pct = field.area > 0 ? (season.plantingArea / field.area * 100.0) : 0.0;
      _areaController.text = pct == pct.toInt() ? pct.toInt().toString() : pct.toStringAsFixed(1);
      _seedsController.text = season.seedsCount.toString();
      _selectedFieldId = season.fieldId;
      _selectedCropId = season.cropId;
      _seedingDate = season.seedingDate;
      _plantingDate = season.plantingDate;
      _selectedStatus = season.status;
    } else {
      _resetForm();
      _areaController.text = '100';
      if (fields.isNotEmpty) _selectedFieldId = fields.first.id;
      if (crops.isNotEmpty) {
        _selectedCropId = crops.first.id;
        _varietyController.text = crops.first.variety;
      }
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
                        season == null ? 'Buat Musim Tanam Baru' : 'Edit Musim Tanam',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nama Musim Tanam (e.g. Melon G1 2026)', prefixIcon: Icon(Icons.spa_outlined)),
                        validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedFieldId,
                        decoration: const InputDecoration(labelText: 'Pilih Lahan', prefixIcon: Icon(Icons.landscape_outlined)),
                        items: fields.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedFieldId = val),
                        validator: (value) => value == null ? 'Lahan wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCropId,
                        decoration: const InputDecoration(labelText: 'Pilih Tanaman', prefixIcon: Icon(Icons.grass_outlined)),
                        items: crops.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final crop = crops.firstWhere((c) => c.id == val);
                            setDialogState(() {
                              _selectedCropId = val;
                              _varietyController.text = crop.variety;
                            });
                          }
                        },
                        validator: (value) => value == null ? 'Tanaman wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _varietyController,
                        decoration: const InputDecoration(labelText: 'Varietas Tanaman', prefixIcon: Icon(Icons.label_outlined)),
                      ),
                      const SizedBox(height: 12),
                      // Slider for Percentage Luas Tanam
                      Builder(
                        builder: (context) {
                          final selectedField = fields.firstWhere(
                            (f) => f.id == _selectedFieldId,
                            orElse: () => fields.isNotEmpty ? fields.first : Lahan(id: '', name: '', area: 0, unit: 'm²', locationGps: '', address: '', soilType: '', status: '', waterSource: '', notes: ''),
                          );
                          double percentValue = double.tryParse(_areaController.text) ?? 100.0;
                          percentValue = percentValue.roundToDouble().clamp(1.0, 100.0);
                          final absoluteArea = (percentValue / 100.0) * selectedField.area;
                          final areaStr = absoluteArea == absoluteArea.toInt() ? absoluteArea.toInt().toString() : absoluteArea.toStringAsFixed(1);
                          final totalAreaStr = selectedField.area == selectedField.area.toInt() ? selectedField.area.toInt().toString() : selectedField.area.toStringAsFixed(1);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Luas Tanam (%):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                                  Text(
                                    '${percentValue.toInt()}% ($areaStr ${selectedField.unit} / $totalAreaStr ${selectedField.unit})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                              Slider(
                                value: percentValue,
                                min: 1.0,
                                max: 100.0,
                                divisions: 99,
                                label: '${percentValue.toInt()}%',
                                activeColor: Colors.green[800],
                                inactiveColor: Colors.green[100],
                                onChanged: (newVal) {
                                  setDialogState(() {
                                    _areaController.text = newVal.toInt().toString();
                                  });
                                },
                              ),
                            ],
                          );
                        }
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _seedsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Jumlah Bibit (Pohon)', prefixIcon: Icon(Icons.pin)),
                        validator: (value) => value == null || value.isEmpty ? 'Bibit wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text('Semai: ${Formatters.formatDate(_seedingDate)}'),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _seedingDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setDialogState(() {
                                    _seedingDate = date;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text('Tanam: ${Formatters.formatDate(_plantingDate)}'),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _plantingDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setDialogState(() {
                                    _plantingDate = date;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status Musim', prefixIcon: Icon(Icons.check_circle_outline)),
                        items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedStatus = val!),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          final repo = ref.read(databaseRepositoryProvider);
                          final selectedField = fields.firstWhere((f) => f.id == _selectedFieldId);
                          final percent = double.tryParse(_areaController.text) ?? 0.0;
                          final calculatedArea = (percent / 100.0) * selectedField.area;

                          final data = MusimTanam(
                            id: season?.id ?? '',
                            name: _nameController.text.trim(),
                            fieldId: _selectedFieldId!,
                            cropId: _selectedCropId!,
                            variety: _varietyController.text.trim(),
                            plantingArea: calculatedArea,
                            seedsCount: int.tryParse(_seedsController.text) ?? 0,
                            seedingDate: _seedingDate,
                            plantingDate: _plantingDate,
                            status: _selectedStatus,
                          );

                          if (season == null) {
                            await repo.addSeason(data);
                          } else {
                            await repo.updateSeason(data);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Musim tanam berhasil disimpan!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan Perencanaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _deleteSeason(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Musim Tanam?'),
        content: const Text('Semua jadwal pemupukan, penyemprotan, dan log hama pada musim ini akan ikut terhapus.'),
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
      await ref.read(databaseRepositoryProvider).deleteSeason(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Musim tanam berhasil dihapus.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldsState = ref.watch(watchFieldsProvider);
    final cropsState = ref.watch(watchCropsProvider);
    final seasonsState = ref.watch(watchSeasonsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Siklus / Musim Tanam')),
      body: seasonsState.when(
        data: (seasons) {
          final fields = fieldsState.value ?? [];
          final crops = cropsState.value ?? [];

          if (seasons.isEmpty) {
            return const Center(child: Text('Belum ada musim tanam. Tekan + untuk membuat perencanaan baru.'));
          }

          return ListView.builder(
            itemCount: seasons.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final season = seasons[index];
              final field = fields.firstWhere((f) => f.id == season.fieldId,
                  orElse: () => Lahan(id: '', name: 'Lahan tidak dikenal', area: 0, unit: '', locationGps: '', address: '', soilType: '', status: '', waterSource: '', notes: ''));
              final crop = crops.firstWhere((c) => c.id == season.cropId,
                  orElse: () => Tanaman(id: '', name: 'Tanaman tidak dikenal', variety: '', harvestAgeDays: 60, waterRequirement: '', description: ''));

              final hst = Formatters.calculateHST(season.plantingDate);
              final expectedHarvest = season.plantingDate.add(Duration(days: crop.harvestAgeDays));

              Color statusColor = Colors.blue;
              if (season.status == 'Berjalan') statusColor = Colors.green;
              if (season.status == 'Selesai') statusColor = Colors.grey;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              season.status,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            'HST: $hst Hari',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        season.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text('Komoditas: ${crop.name} (${season.variety})', style: const TextStyle(fontSize: 13)),
                      Builder(
                        builder: (context) {
                          final pct = field.area > 0 ? (season.plantingArea / field.area * 100.0) : 0.0;
                          final pctStr = pct == pct.toInt() ? pct.toInt().toString() : pct.toStringAsFixed(1);
                          return Text(
                            'Lahan: ${field.name} ($pctStr% dari ${field.area} ${field.unit})',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          );
                        }
                      ),
                      Text('Jumlah Bibit: ${season.seedsCount} Pohon', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tanggal Tanam: ${Formatters.formatDate(season.plantingDate)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              Text('Estimasi Panen: ${Formatters.formatDate(expectedHarvest)}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _showFormDialog(fields, crops, season),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _deleteSeason(season.id),
                              ),
                            ],
                          )
                        ],
                      )
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
        onPressed: () {
          final fields = fieldsState.value ?? [];
          final crops = cropsState.value ?? [];
          if (fields.isEmpty || crops.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lahan dan Tanaman wajib diisi terlebih dahulu sebelum membuat musim tanam!'), backgroundColor: Colors.red),
            );
            return;
          }
          _showFormDialog(fields, crops);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
