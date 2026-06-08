import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../../core/utils/formatters.dart';

class LahanScreen extends ConsumerStatefulWidget {
  const LahanScreen({super.key});

  @override
  ConsumerState<LahanScreen> createState() => _LahanScreenState();
}

class _LahanScreenState extends ConsumerState<LahanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _soilTypeController = TextEditingController();
  final _rentPriceController = TextEditingController();
  final _waterSourceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedUnit = 'm²';
  String _selectedStatus = 'Milik Sendiri';
  DateTime? _rentStartDate;
  DateTime? _rentEndDate;

  void _resetForm() {
    _nameController.clear();
    _areaController.clear();
    _locationController.clear();
    _addressController.clear();
    _soilTypeController.clear();
    _rentPriceController.clear();
    _waterSourceController.clear();
    _notesController.clear();
    setState(() {
      _selectedUnit = 'm²';
      _selectedStatus = 'Milik Sendiri';
      _rentStartDate = null;
      _rentEndDate = null;
    });
  }

  void _showFormDialog([Lahan? lahan]) {
    if (lahan != null) {
      _nameController.text = lahan.name;
      _areaController.text = lahan.area.toString();
      _locationController.text = lahan.locationGps;
      _addressController.text = lahan.address;
      _soilTypeController.text = lahan.soilType;
      _rentPriceController.text = lahan.rentPrice.toString();
      _waterSourceController.text = lahan.waterSource;
      _notesController.text = lahan.notes;
      _selectedUnit = lahan.unit;
      _selectedStatus = lahan.status;
      _rentStartDate = lahan.rentStartDate;
      _rentEndDate = lahan.rentEndDate;
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
                        lahan == null ? 'Tambah Lahan Baru' : 'Edit Data Lahan',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nama Lahan', prefixIcon: Icon(Icons.map_outlined)),
                        validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _areaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Luas Lahan', prefixIcon: Icon(Icons.aspect_ratio)),
                              validator: (value) => value == null || value.isEmpty ? 'Luas wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              items: const [
                                DropdownMenuItem(value: 'm²', child: Text('m²')),
                                DropdownMenuItem(value: 'hektar', child: Text('Hektar')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    _selectedUnit = val;
                                  });
                                }
                              },
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi GPS (Koordinat)',
                          prefixIcon: Icon(Icons.gps_fixed),
                          hintText: "Contoh: -6.2088, 106.8456",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Alamat', prefixIcon: Icon(Icons.location_on_outlined)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _soilTypeController,
                        decoration: const InputDecoration(labelText: 'Jenis Tanah (misal: Liat, Pasir)', prefixIcon: Icon(Icons.layers_outlined)),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status Kepemilikan Lahan', prefixIcon: Icon(Icons.assignment)),
                        items: const [
                          DropdownMenuItem(value: 'Milik Sendiri', child: Text('Milik Sendiri')),
                          DropdownMenuItem(value: 'Sewa', child: Text('Sewa')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              _selectedStatus = val;
                            });
                          }
                        },
                      ),
                      if (_selectedStatus == 'Sewa') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _rentPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Sewa (Rp)', prefixIcon: Icon(Icons.monetization_on_outlined)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(_rentStartDate == null ? 'Mulai Sewa' : Formatters.formatDate(_rentStartDate!)),
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      _rentStartDate = date;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(_rentEndDate == null ? 'Akhir Sewa' : Formatters.formatDate(_rentEndDate!)),
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      _rentEndDate = date;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _waterSourceController,
                        decoration: const InputDecoration(labelText: 'Sumber Air (misal: Sumur, Irigasi)', prefixIcon: Icon(Icons.water_drop_outlined)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Catatan tambahan', prefixIcon: Icon(Icons.note_alt_outlined)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          
                          final repo = ref.read(databaseRepositoryProvider);
                          final data = Lahan(
                            id: lahan?.id ?? '',
                            name: _nameController.text.trim(),
                            area: double.tryParse(_areaController.text) ?? 0.0,
                            unit: _selectedUnit,
                            locationGps: _locationController.text.trim(),
                            address: _addressController.text.trim(),
                            soilType: _soilTypeController.text.trim(),
                            status: _selectedStatus,
                            rentPrice: double.tryParse(_rentPriceController.text) ?? 0.0,
                            rentStartDate: _rentStartDate,
                            rentEndDate: _rentEndDate,
                            waterSource: _waterSourceController.text.trim(),
                            notes: _notesController.text.trim(),
                          );

                          if (lahan == null) {
                            await repo.addField(data);
                          } else {
                            await repo.updateField(data);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Data Lahan berhasil disimpan!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan Lahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _deleteLahan(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Lahan?'),
        content: const Text('Data lahan dan relasinya akan dihapus secara permanen.'),
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
      await ref.read(databaseRepositoryProvider).deleteField(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lahan berhasil dihapus.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldsState = ref.watch(watchFieldsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Lahan')),
      body: fieldsState.when(
        data: (fields) {
          if (fields.isEmpty) {
            return const Center(child: Text('Belum ada data lahan. Tekan + untuk menambahkan.'));
          }

          return ListView.builder(
            itemCount: fields.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final lahan = fields[index];
              return Card(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.landscape, color: Colors.green[800]),
                  ),
                  title: Text(lahan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Luas: ${lahan.area} ${lahan.unit} | Status: ${lahan.status}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (lahan.locationGps.isNotEmpty)
                            Text('GPS: ${lahan.locationGps}', style: const TextStyle(fontSize: 13)),
                          if (lahan.address.isNotEmpty)
                            Text('Alamat: ${lahan.address}', style: const TextStyle(fontSize: 13)),
                          if (lahan.soilType.isNotEmpty)
                            Text('Jenis Tanah: ${lahan.soilType}', style: const TextStyle(fontSize: 13)),
                          if (lahan.waterSource.isNotEmpty)
                            Text('Sumber Air: ${lahan.waterSource}', style: const TextStyle(fontSize: 13)),
                          if (lahan.status == 'Sewa') ...[
                            Text('Harga Sewa: ${Formatters.formatRupiah(lahan.rentPrice)}', style: const TextStyle(fontSize: 13)),
                            if (lahan.rentStartDate != null)
                              Text('Periode Sewa: ${Formatters.formatDate(lahan.rentStartDate!)} s/d ${Formatters.formatDate(lahan.rentEndDate!)}', style: const TextStyle(fontSize: 13)),
                          ],
                          if (lahan.notes.isNotEmpty)
                            Text('Catatan: ${lahan.notes}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showFormDialog(lahan),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteLahan(lahan.id),
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
