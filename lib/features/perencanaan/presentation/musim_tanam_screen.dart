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
  final _seedsController = TextEditingController();

  List<String> _selectedFieldIds = [];
  String? _selectedCropId;
  DateTime _seedingDate = DateTime.now();
  DateTime _plantingDate = DateTime.now();
  String _selectedStatus = 'Perencanaan';
  String _jenisTanam = 'Tanam Satu Komoditas';

  String _searchQuery = '';
  String _selectedStatusFilter = 'Semua';

  @override
  void dispose() {
    _nameController.dispose();
    _varietyController.dispose();
    _seedsController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _varietyController.clear();
    _seedsController.clear();
    setState(() {
      _selectedFieldIds = [];
      _selectedCropId = null;
      _seedingDate = DateTime.now();
      _plantingDate = DateTime.now();
      _selectedStatus = 'Perencanaan';
      _jenisTanam = 'Tanam Satu Komoditas';
    });
  }

  void _showFormDialog(
    List<Lahan> fields,
    List<Tanaman> crops,
    List<MusimTanam> seasons, [
    MusimTanam? season,
  ]) {
    if (season != null) {
      _nameController.text = season.name;
      _varietyController.text = season.variety;
      _seedsController.text = season.seedsCount.toString();
      _selectedFieldIds = season.fieldId
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _selectedCropId = season.cropId;
      _seedingDate = season.seedingDate;
      _plantingDate = season.plantingDate;
      _selectedStatus = season.status;
      _jenisTanam = season.jenisTanam;
    } else {
      _resetForm();
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
            final totalLahan = _selectedFieldIds.length;
            final totalArea = fields
                .where((f) => _selectedFieldIds.contains(f.id))
                .fold<double>(0.0, (sum, f) => sum + f.area);
            final totalAreaStr = totalArea == totalArea.toInt()
                ? totalArea.toInt().toString()
                : totalArea.toStringAsFixed(1);
            final totalPlants = int.tryParse(_seedsController.text) ?? 0;

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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Musim Tanam',
                          hintText: 'e.g. Melon G1 2026',
                          prefixIcon: Icon(Icons.spa_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCropId,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Tanaman',
                          prefixIcon: Icon(Icons.grass_outlined),
                        ),
                        items: crops
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final crop = crops.firstWhere((c) => c.id == val);
                            setDialogState(() {
                              _selectedCropId = val;
                              _varietyController.text = crop.variety;
                            });
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Tanaman wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _varietyController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Varietas (Otomatis)',
                          prefixIcon: Icon(Icons.label_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _jenisTanam,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Tanam',
                          prefixIcon: Icon(Icons.merge_type_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Tanam Satu Komoditas',
                            child: Text('Tanam Satu Komoditas'),
                          ),
                          DropdownMenuItem(
                            value: 'Tanam Campuran',
                            child: Text('Tanam Campuran'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              _jenisTanam = val;
                              _selectedFieldIds = [];
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pilih Lahan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: fields.length,
                          itemBuilder: (context, index) {
                            final lahan = fields[index];
                            final isChecked = _selectedFieldIds.contains(lahan.id);
                            return CheckboxListTile(
                              title: Text(
                                lahan.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${lahan.area.toStringAsFixed(0)} ${lahan.unit}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: isChecked,
                              activeColor: Colors.green,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) async {
                                if (val == true) {
                                  final activeSeasons = seasons.where((s) {
                                    if (s.id == season?.id) return false;
                                    if (s.status == 'Selesai') return false;
                                    final ids = s.fieldId
                                        .split(',')
                                        .map((e) => e.trim())
                                        .toList();
                                    return ids.contains(lahan.id);
                                  }).toList();

                                  if (activeSeasons.isNotEmpty) {
                                    if (_jenisTanam == 'Tanam Satu Komoditas') {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Lahan Sedang Digunakan'),
                                          content: Text(
                                            'Lahan ${lahan.name} masih digunakan oleh Musim ${activeSeasons.first.name}.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    } else {
                                      final proceed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Konfirmasi Lahan Campuran'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Lahan "${lahan.name}" sedang digunakan oleh:',
                                              ),
                                              const SizedBox(height: 8),
                                              ...activeSeasons.map((s) => Text(
                                                    '• ${s.name}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  )),
                                              const SizedBox(height: 12),
                                              const Text('Apakah Anda ingin melanjutkan?'),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Batal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Lanjutkan'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (proceed != true) return;
                                    }
                                  }

                                  setDialogState(() {
                                    _selectedFieldIds.add(lahan.id);
                                  });
                                } else {
                                  setDialogState(() {
                                    _selectedFieldIds.remove(lahan.id);
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _seedsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Tanaman',
                          prefixIcon: Icon(Icons.pin),
                        ),
                        onChanged: (val) {
                          setDialogState(() {});
                        },
                        validator: (value) => value == null || value.isEmpty
                            ? 'Jumlah tanaman wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                'Semai: ${Formatters.formatLongDate(_seedingDate)}',
                              ),
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
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                'Tanam: ${Formatters.formatLongDate(_plantingDate)}',
                              ),
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
                        decoration: const InputDecoration(
                          labelText: 'Status Musim',
                          prefixIcon: Icon(Icons.check_circle_outline),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Perencanaan', child: Text('Perencanaan')),
                          DropdownMenuItem(value: 'Berjalan', child: Text('Berjalan')),
                          DropdownMenuItem(
                            value: 'Panen Sebagian',
                            child: Text('Panen Sebagian'),
                          ),
                          DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                        ],
                        onChanged: (val) => setDialogState(() => _selectedStatus = val!),
                      ),
                      // Ringkasan Otomatis
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan Otomatis',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Lahan:',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      Text(
                                        '$totalLahan Lahan',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Luas:',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      Text(
                                        '$totalAreaStr m²',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Jumlah Tanaman:',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      Text(
                                        '$totalPlants',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          if (_selectedFieldIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pilih minimal satu lahan!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final repo = ref.read(databaseRepositoryProvider);

                          final data = MusimTanam(
                            id: season?.id ?? '',
                            name: _nameController.text.trim(),
                            fieldId: _selectedFieldIds.join(','),
                            cropId: _selectedCropId!,
                            variety: _varietyController.text.trim(),
                            plantingArea: totalArea,
                            seedsCount: int.tryParse(_seedsController.text) ?? 0,
                            seedingDate: _seedingDate,
                            plantingDate: _plantingDate,
                            status: _selectedStatus,
                            jenisTanam: _jenisTanam,
                          );

                          if (season == null) {
                            await repo.addSeason(data);
                          } else {
                            await repo.updateSeason(data);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Musim tanam berhasil disimpan!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Simpan Perencanaan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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

  void _showDetailDialog(
    MusimTanam season,
    Tanaman crop,
    List<Lahan> selectedFields,
  ) {
    final expectedHarvest = season.plantingDate.add(Duration(days: crop.harvestAgeDays));
    final hst = Formatters.calculateHST(season.plantingDate);

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final expensesState = ref.watch(watchExpensesProvider);
            return expensesState.when(
              data: (expenses) {
                final seasonExpenses = expenses.where((e) => e.seasonId == season.id).toList();

                double costPupuk = 0.0;
                double costPestisida = 0.0;
                double costTenagaKerja = 0.0;
                double costLainnya = 0.0;

                for (var exp in seasonExpenses) {
                  if (exp.category == 'Pupuk') {
                    costPupuk += exp.amount;
                  } else if (exp.category == 'Pestisida') {
                    costPestisida += exp.amount;
                  } else if (exp.category == 'Upah') {
                    costTenagaKerja += exp.amount;
                  } else {
                    costLainnya += exp.amount;
                  }
                }
                double totalModal = costPupuk + costPestisida + costTenagaKerja + costLainnya;

                return AlertDialog(
                  title: Text(
                    season.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDetailItem('Tanaman', crop.name),
                        _buildDetailItem('Varietas', season.variety),
                        _buildDetailItem('Jenis Tanam', season.jenisTanam),
                        _buildDetailItem('Status Musim', season.status),
                        _buildDetailItem('Hari Setelah Tanam (HST)', '$hst Hari'),
                        _buildDetailItem('Jumlah Tanaman', '${season.seedsCount}'),
                        _buildDetailItem(
                          'Tanggal Semai',
                          Formatters.formatLongDate(season.seedingDate),
                        ),
                        _buildDetailItem(
                          'Tanggal Tanam',
                          Formatters.formatLongDate(season.plantingDate),
                        ),
                        _buildDetailItem('Estimasi Panen', Formatters.formatLongDate(expectedHarvest)),
                        const Divider(),
                        const Text(
                          'Daftar Lahan:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        ...selectedFields.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text('• ${f.name} (${f.area.toStringAsFixed(0)} ${f.unit})'),
                            )),
                        const Divider(),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade800, const Color(0xFF022C22)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.dashboard_outlined, color: Colors.white70, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'DASHBOARD MUSIM TANAM',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildDashboardCostItem('Biaya Pupuk', costPupuk),
                              _buildDashboardCostItem('Biaya Pestisida', costPestisida),
                              _buildDashboardCostItem('Biaya Tenaga Kerja', costTenagaKerja),
                              _buildDashboardCostItem('Biaya Lainnya/Operasional', costLainnya),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6.0),
                                child: Divider(color: Colors.white30, height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Modal Berjalan:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatRupiah(totalModal),
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Gagal memuat biaya: $err')),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardCostItem(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            Formatters.formatRupiah(amount),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCompleteSeason(MusimTanam season) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Status Musim'),
        content: const Text(
          'Musim tanam ini sudah selesai. Ubah status menjadi Selesai?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ubah'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedSeason = MusimTanam(
        id: season.id,
        name: season.name,
        fieldId: season.fieldId,
        cropId: season.cropId,
        variety: season.variety,
        plantingArea: season.plantingArea,
        seedsCount: season.seedsCount,
        seedingDate: season.seedingDate,
        plantingDate: season.plantingDate,
        status: 'Selesai',
        jenisTanam: season.jenisTanam,
      );
      await ref.read(databaseRepositoryProvider).updateSeason(updatedSeason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status musim berhasil diubah menjadi Selesai.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _deleteSeason(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Musim Tanam?'),
        content: const Text(
          'Semua jadwal pemupukan, penyemprotan, dan log hama pada musim ini akan ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
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
          const SnackBar(
            content: Text('Musim tanam berhasil dihapus.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Perencanaan':
        color = Colors.grey;
        break;
      case 'Berjalan':
        color = Colors.green;
        break;
      case 'Panen Sebagian':
        color = Colors.amber.shade700;
        break;
      case 'Selesai':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldsState = ref.watch(watchFieldsProvider);
    final cropsState = ref.watch(watchCropsProvider);
    final seasonsState = ref.watch(watchSeasonsProvider);
    final harvestsState = ref.watch(watchHarvestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Siklus / Musim Tanam')),
      body: seasonsState.when(
        data: (seasons) {
          final fields = fieldsState.value ?? [];
          final crops = cropsState.value ?? [];
          final harvests = harvestsState.value ?? [];

          // Logika Filter & Pencarian
          final filteredSeasons = seasons.where((season) {
            // 1. Filter Status
            if (_selectedStatusFilter != 'Semua' &&
                season.status != _selectedStatusFilter) {
              return false;
            }
            // 2. Pencarian
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final nameMatches = season.name.toLowerCase().contains(query);

              final crop = crops.firstWhere(
                (c) => c.id == season.cropId,
                orElse: () => Tanaman(
                  id: '',
                  name: '',
                  variety: '',
                  harvestAgeDays: 60,
                  waterRequirement: '',
                  description: '',
                ),
              );
              final cropMatches = crop.name.toLowerCase().contains(query);
              final varietyMatches = season.variety.toLowerCase().contains(query);

              return nameMatches || cropMatches || varietyMatches;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari musim tanam...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              // Filter Status Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    'Semua',
                    'Perencanaan',
                    'Berjalan',
                    'Panen Sebagian',
                    'Selesai'
                  ].map((status) {
                    final isSelected = _selectedStatusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: Colors.green.shade100,
                        checkmarkColor: Colors.green,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.green.shade900 : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatusFilter = status;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: filteredSeasons.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada musim tanam yang cocok.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredSeasons.length,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemBuilder: (context, index) {
                          final season = filteredSeasons[index];

                          // Split comma-separated fieldId
                          final selectedFieldIds = season.fieldId
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          final selectedFields = fields
                              .where((f) => selectedFieldIds.contains(f.id))
                              .toList();
                          final lahanCount = selectedFields.length;

                          final crop = crops.firstWhere(
                            (c) => c.id == season.cropId,
                            orElse: () => Tanaman(
                              id: '',
                              name: 'Tanaman tidak dikenal',
                              variety: '',
                              harvestAgeDays: 60,
                              waterRequirement: '',
                              description: '',
                            ),
                          );

                          final totalArea = selectedFields.fold<double>(
                            0.0,
                            (sum, f) => sum + f.area,
                          );
                          final totalAreaStr = totalArea == totalArea.toInt()
                              ? totalArea.toInt().toString()
                              : totalArea.toStringAsFixed(1);

                          // Check if all harvests for this season are complete
                          final seasonHarvests =
                              harvests.where((h) => h.seasonId == season.id).toList();
                          final allHarvestsDone = seasonHarvests.isNotEmpty &&
                              seasonHarvests.every((h) => h.statusPeriode == 'Selesai');

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          season.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _buildStatusBadge(season.status),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow('Tanaman', '${crop.name} - ${season.variety}'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Jenis Tanam', season.jenisTanam),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Lahan', '$lahanCount Lahan'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Total Luas', '$totalAreaStr m²'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Jumlah Tanaman', '${season.seedsCount}'),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Tanggal Tanam',
                                    Formatters.formatLongDate(season.plantingDate),
                                  ),

                                  // Suggestion Banner if all harvests are complete and status is not Selesai
                                  if (allHarvestsDone && season.status != 'Selesai')
                                    Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Musim tanam ini sudah selesai. Ubah status menjadi Selesai?',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => _confirmCompleteSeason(season),
                                            child: const Text(
                                              'Ubah',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.info_outline, size: 16),
                                        label: const Text('Detail'),
                                        onPressed: () => _showDetailDialog(
                                          season,
                                          crop,
                                          selectedFields,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        label: const Text('Ubah'),
                                        onPressed: () => _showFormDialog(
                                          fields,
                                          crops,
                                          seasons,
                                          season,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (season.status != 'Selesai') ...[
                                        TextButton.icon(
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                            size: 16,
                                          ),
                                          label: const Text('Selesaikan'),
                                          onPressed: () => _confirmCompleteSeason(season),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      TextButton.icon(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          'Hapus',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () => _deleteSeason(season.id),
                                      ),
                                    ],
                                  )
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
      floatingActionButton: seasonsState.when(
        data: (seasons) => FloatingActionButton(
          onPressed: () {
            final fields = fieldsState.value ?? [];
            final crops = cropsState.value ?? [];
            if (fields.isEmpty || crops.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Lahan dan Tanaman wajib diisi terlebih dahulu sebelum membuat musim tanam!',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            _showFormDialog(fields, crops, seasons);
          },
          child: const Icon(Icons.add),
        ),
        loading: () => const FloatingActionButton(
          onPressed: null,
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (err, _) => const FloatingActionButton(
          onPressed: null,
          child: Icon(Icons.error),
        ),
      ),
    );
  }
}
