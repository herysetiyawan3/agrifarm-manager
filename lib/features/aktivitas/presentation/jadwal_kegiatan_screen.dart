import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../../core/utils/formatters.dart';

class JadwalKegiatanScreen extends ConsumerStatefulWidget {
  const JadwalKegiatanScreen({super.key});

  @override
  ConsumerState<JadwalKegiatanScreen> createState() => _JadwalKegiatanScreenState();
}

class _JadwalKegiatanScreenState extends ConsumerState<JadwalKegiatanScreen> {
  final _formKey = GlobalKey<FormState>();

  // Dialog Form Controllers
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedSeasonId;
  String _selectedActivityType = 'Pemupukan';
  DateTime _activityDate = DateTime.now();
  String _activityStatus = 'Direncanakan';
  List<String> _selectedFieldIds = [];

  // Dropdown states
  String? _selectedStockProduct;
  String? _selectedWorker;
  bool _manualProductInput = false;

  final List<String> _activityTypes = [
    'Pemupukan',
    'Penyemprotan',
    'Pengairan',
    'Penyiangan',
    'Pemasangan Mulsa',
    'Tenaga Kerja',
    'Lainnya'
  ];

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _productController.clear();
    _quantityController.clear();
    _unitController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedActivityType = 'Pemupukan';
      _activityDate = DateTime.now();
      _activityStatus = 'Direncanakan';
      _selectedFieldIds = [];
      _selectedStockProduct = null;
      _selectedWorker = null;
      _manualProductInput = false;
    });
  }

  void _showActivityDialog(
    List<MusimTanam> seasons,
    List<Lahan> fields,
    List<Stok> inventory,
    List<TenagaKerja> workers, [
    AktivitasLapangan? oldAct,
  ]) {
    final currentSeasonId = _selectedSeasonId ?? (seasons.isNotEmpty ? seasons.first.id : null);
    if (currentSeasonId == null) return;

    final selectedSeason = seasons.firstWhere((s) => s.id == currentSeasonId);
    final seasonFieldIds = selectedSeason.fieldId
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final seasonFields = fields.where((f) => seasonFieldIds.contains(f.id)).toList();

    if (oldAct != null) {
      _selectedActivityType = oldAct.activityType;
      _quantityController.text = oldAct.quantity == oldAct.quantity.toInt()
          ? oldAct.quantity.toInt().toString()
          : oldAct.quantity.toString();
      _unitController.text = oldAct.unit;
      _descriptionController.text = oldAct.description;
      _activityDate = oldAct.date;
      _activityStatus = oldAct.status;
      _selectedFieldIds = oldAct.fieldIds
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (oldAct.activityType == 'Tenaga Kerja') {
        _selectedWorker = workers.any((w) => w.name == oldAct.product) ? oldAct.product : null;
        _productController.text = oldAct.product;
      } else if (['Pemupukan', 'Penyemprotan', 'Pemasangan Mulsa']
          .contains(oldAct.activityType)) {
        _selectedStockProduct = inventory.any((s) => s.itemName == oldAct.product)
            ? oldAct.product
            : null;
        _productController.text = oldAct.product;
        _manualProductInput = _selectedStockProduct == null;
      } else {
        _productController.text = oldAct.product;
        _manualProductInput = true;
      }
    } else {
      _resetForm();
      // By default check all fields in the season
      _selectedFieldIds = List.from(seasonFieldIds);
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
            // Filter inventory by category
            List<Stok> filteredInventory = [];
            if (_selectedActivityType == 'Pemupukan') {
              filteredInventory = inventory.where((s) => s.category == 'Pupuk').toList();
            } else if (_selectedActivityType == 'Penyemprotan') {
              filteredInventory = inventory
                  .where((s) => ['Pestisida', 'Fungisida', 'Herbisida'].contains(s.category))
                  .toList();
            } else if (_selectedActivityType == 'Pemasangan Mulsa') {
              filteredInventory = inventory.where((s) => s.category == 'Mulsa').toList();
            }

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
                        oldAct == null ? 'Catat Aktivitas Lapangan' : 'Edit Aktivitas Lapangan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedActivityType,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Aktivitas',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        items: _activityTypes
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              _selectedActivityType = val;
                              _selectedStockProduct = null;
                              _selectedWorker = null;
                              _manualProductInput = !['Pemupukan', 'Penyemprotan', 'Pemasangan Mulsa', 'Tenaga Kerja'].contains(val);
                              _productController.clear();
                              
                              if (val == 'Tenaga Kerja') {
                                _unitController.text = 'Hari';
                                if (workers.isNotEmpty) {
                                  _selectedWorker = workers.first.name;
                                  _productController.text = workers.first.name;
                                }
                              } else {
                                _unitController.clear();
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Product Selector
                      if (_selectedActivityType == 'Tenaga Kerja') ...[
                        DropdownButtonFormField<String>(
                          value: _selectedWorker,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Pekerja',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: workers
                              .map((w) => DropdownMenuItem(value: w.name, child: Text(w.name)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                _selectedWorker = val;
                                _productController.text = val;
                              });
                            }
                          },
                          validator: (value) => value == null ? 'Pekerja wajib dipilih' : null,
                        ),
                      ] else if (['Pemupukan', 'Penyemprotan', 'Pemasangan Mulsa']
                          .contains(_selectedActivityType)) ...[
                        if (!_manualProductInput && filteredInventory.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedStockProduct,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Produk dari Stok',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            items: [
                              ...filteredInventory.map((s) => DropdownMenuItem(
                                    value: s.itemName,
                                    child: Text(
                                        '${s.itemName} (Stok: ${s.currentStock.toStringAsFixed(0)} ${s.unit})'),
                                  )),
                              const DropdownMenuItem(
                                value: '__manual__',
                                child: Text('+ Ketik Manual (Barang Baru)'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val == '__manual__') {
                                setDialogState(() {
                                  _manualProductInput = true;
                                  _selectedStockProduct = null;
                                  _productController.clear();
                                  _unitController.clear();
                                });
                              } else if (val != null) {
                                final stockItem = inventory.firstWhere((s) => s.itemName == val);
                                setDialogState(() {
                                  _selectedStockProduct = val;
                                  _productController.text = val;
                                  _unitController.text = stockItem.unit;
                                });
                              }
                            },
                            validator: (value) => value == null ? 'Produk wajib dipilih' : null,
                          ),
                        ] else ...[
                          TextFormField(
                            controller: _productController,
                            decoration: InputDecoration(
                              labelText: 'Nama Produk / Barang',
                              prefixIcon: const Icon(Icons.label_outlined),
                              suffixIcon: filteredInventory.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.list),
                                      onPressed: () {
                                        setDialogState(() {
                                          _manualProductInput = false;
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Nama produk wajib diisi' : null,
                          ),
                        ]
                      ] else ...[
                        TextFormField(
                          controller: _productController,
                          decoration: const InputDecoration(
                            labelText: 'Alat / Bahan (Opsional)',
                            prefixIcon: Icon(Icons.label_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Dosis & Satuan Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: _selectedActivityType == 'Tenaga Kerja'
                                    ? 'Durasi Kerja'
                                    : 'Dosis / Jumlah',
                                prefixIcon: const Icon(Icons.scale_outlined),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _unitController,
                              decoration: const InputDecoration(
                                labelText: 'Satuan',
                                hintText: 'e.g. Kg, Ml, Hari',
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Multi Lahan Selector
                      const Text(
                        'Pilih Lahan yang Terlibat',
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
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView(
                          shrinkWrap: true,
                          children: seasonFields.map((lahan) {
                            final isChecked = _selectedFieldIds.contains(lahan.id);
                            return CheckboxListTile(
                              title: Text(lahan.name, style: const TextStyle(fontSize: 14)),
                              value: isChecked,
                              activeColor: Colors.green,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    _selectedFieldIds.add(lahan.id);
                                  } else {
                                    _selectedFieldIds.remove(lahan.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan Tambahan',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),

                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Tanggal: ${Formatters.formatLongDate(_activityDate)}'),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _activityDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _activityDate = date;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _activityStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status Aktivitas',
                          prefixIcon: Icon(Icons.check_circle_outline),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Direncanakan', child: Text('Direncanakan')),
                          DropdownMenuItem(value: 'Dilaksanakan', child: Text('Dilaksanakan')),
                          DropdownMenuItem(value: 'Dibatalkan', child: Text('Dibatalkan')),
                        ],
                        onChanged: (val) => setDialogState(() => _activityStatus = val!),
                      ),
                      const SizedBox(height: 24),
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
                          final activity = AktivitasLapangan(
                            id: oldAct?.id ?? '',
                            seasonId: currentSeasonId,
                            fieldIds: _selectedFieldIds.join(','),
                            activityType: _selectedActivityType,
                            product: _productController.text.trim(),
                            quantity: double.tryParse(_quantityController.text) ?? 0.0,
                            unit: _unitController.text.trim(),
                            date: _activityDate,
                            description: _descriptionController.text.trim(),
                            status: _activityStatus,
                          );

                          if (oldAct == null) {
                            if (_activityStatus == 'Dilaksanakan') {
                              // Save as direncanakan first, then execute to deduct stock and cost properly
                              final tempAct = AktivitasLapangan(
                                id: '',
                                seasonId: activity.seasonId,
                                fieldIds: activity.fieldIds,
                                activityType: activity.activityType,
                                product: activity.product,
                                quantity: activity.quantity,
                                unit: activity.unit,
                                date: activity.date,
                                description: activity.description,
                                status: 'Direncanakan',
                              );
                              final docId = await repo.addActivity(tempAct);
                              
                              final actToExecute = AktivitasLapangan(
                                id: docId,
                                seasonId: tempAct.seasonId,
                                fieldIds: tempAct.fieldIds,
                                activityType: tempAct.activityType,
                                product: tempAct.product,
                                quantity: tempAct.quantity,
                                unit: tempAct.unit,
                                date: tempAct.date,
                                description: tempAct.description,
                                status: tempAct.status,
                              );
                              await repo.executeActivity(actToExecute);
                            } else {
                              await repo.addActivity(activity);
                            }
                          } else {
                            if (oldAct.status != 'Dilaksanakan' && _activityStatus == 'Dilaksanakan') {
                              await repo.executeActivity(activity);
                            } else {
                              await repo.updateActivity(activity);
                            }
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Aktivitas lapangan berhasil disimpan!'),
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
                        child: const Text('Simpan Aktivitas', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _laksanakanActivity(AktivitasLapangan act) async {
    await ref.read(databaseRepositoryProvider).executeActivity(act);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivitas dilaksanakan. Stok berkurang & Biaya tercatat!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteActivity(AktivitasLapangan act) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Aktivitas?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus aktivitas ${act.activityType} - ${act.product}? '
          'Jika sudah dilaksanakan, stok akan dikembalikan dan catatan biaya akan dihapus.',
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
      await ref.read(databaseRepositoryProvider).deleteActivity(act);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktivitas berhasil dihapus.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasonsState = ref.watch(watchSeasonsProvider);
    final fieldsState = ref.watch(watchFieldsProvider);
    final inventoryState = ref.watch(watchStokProvider);
    final workersState = ref.watch(watchWorkersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas Lapangan'),
      ),
      body: seasonsState.when(
        data: (seasons) {
          if (seasons.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada musim tanam. Harap buat musim tanam terlebih dahulu.',
              ),
            );
          }

          final activeSeasons = seasons;
          final currentSeasonId = _selectedSeasonId ?? activeSeasons.first.id;
          final selectedSeason = activeSeasons.firstWhere(
            (s) => s.id == currentSeasonId,
            orElse: () => activeSeasons.first,
          );

          final isCompleted = selectedSeason.status == 'Selesai';

          return Column(
            children: [
              // Season Selector
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: DropdownButtonFormField<String>(
                  value: selectedSeason.id,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Musim Tanam',
                    prefixIcon: Icon(Icons.spa_outlined),
                  ),
                  items: activeSeasons
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                                '${s.name} ${s.status == 'Selesai' ? '(Selesai)' : ''}'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSeasonId = val;
                    });
                  },
                ),
              ),

              // Activities List
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final activitiesState = ref.watch(watchActivitiesProvider(selectedSeason.id));
                    final fields = fieldsState.value ?? [];

                    return activitiesState.when(
                      data: (activities) {
                        if (activities.isEmpty) {
                          return const Center(
                            child: Text('Belum ada catatan aktivitas lapangan.'),
                          );
                        }

                        return ListView.builder(
                          itemCount: activities.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemBuilder: (context, index) {
                            final act = activities[index];

                            // Resolve land names
                            final fieldIds = act.fieldIds
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            final actFields = fields.where((f) => fieldIds.contains(f.id)).toList();
                            final lahanNames = actFields.isEmpty
                                ? 'Lahan tidak dikenal'
                                : actFields.map((f) => f.name).join(', ');

                            final isDone = act.status == 'Dilaksanakan';

                            // Determine Color & Icon based on activity type
                            IconData iconData = Icons.task_alt;
                            Color themeColor = Colors.grey;

                            switch (act.activityType) {
                              case 'Pemupukan':
                                iconData = Icons.grass;
                                themeColor = Colors.green;
                                break;
                              case 'Penyemprotan':
                                iconData = Icons.bug_report_outlined;
                                themeColor = Colors.orange;
                                break;
                              case 'Pengairan':
                                iconData = Icons.water_drop_outlined;
                                themeColor = Colors.blue;
                                break;
                              case 'Penyiangan':
                                iconData = Icons.cleaning_services_outlined;
                                themeColor = Colors.teal;
                                break;
                              case 'Pemasangan Mulsa':
                                iconData = Icons.layers_outlined;
                                themeColor = Colors.purple;
                                break;
                              case 'Tenaga Kerja':
                                iconData = Icons.people_outline;
                                themeColor = Colors.brown;
                                break;
                              default:
                                iconData = Icons.task_alt;
                                themeColor = Colors.grey;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: themeColor.withOpacity(0.12),
                                              child: Icon(iconData, color: themeColor),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  act.activityType,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  Formatters.formatLongDate(act.date),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        _buildStatusBadge(act.status),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (act.product.isNotEmpty) ...[
                                      Text(
                                        act.activityType == 'Tenaga Kerja' ? 'Pekerja:' : 'Produk:',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        act.product,
                                        style: const TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    Text(
                                      act.activityType == 'Tenaga Kerja' ? 'Durasi:' : 'Dosis / Jumlah:',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${act.quantity} ${act.unit}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Lahan yang Terlibat:',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      lahanNames,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    if (act.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Keterangan:',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        act.description,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (!isDone &&
                                            act.status != 'Dibatalkan' &&
                                            !isCompleted) ...[
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.check, size: 16),
                                            label: const Text('Laksanakan'),
                                            onPressed: () => _laksanakanActivity(act),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green[800],
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        if (!isCompleted) ...[
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                            onPressed: () => _showActivityDialog(
                                              seasons,
                                              fields,
                                              inventoryState.value ?? [],
                                              workersState.value ?? [],
                                              act,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _deleteActivity(act),
                                          ),
                                        ] else ...[
                                          const Text(
                                            'Musim Selesai (Data Dikunci)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ]
                                      ],
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
        data: (seasons) {
          if (seasons.isEmpty) return null;
          final currentSeasonId = _selectedSeasonId ?? seasons.first.id;
          final selectedSeason = seasons.firstWhere(
            (s) => s.id == currentSeasonId,
            orElse: () => seasons.first,
          );
          if (selectedSeason.status == 'Selesai') return null; // Kunci input baru

          return FloatingActionButton(
            onPressed: () => _showActivityDialog(
              seasons,
              fieldsState.value ?? [],
              inventoryState.value ?? [],
              workersState.value ?? [],
            ),
            child: const Icon(Icons.add_task),
          );
        },
        loading: () => null,
        error: (err, _) => null,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'Dilaksanakan') color = Colors.green;
    if (status == 'Dibatalkan') color = Colors.red;

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
}
