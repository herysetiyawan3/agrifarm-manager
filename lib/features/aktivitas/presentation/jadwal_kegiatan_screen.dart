import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/presentation/auth_providers.dart';

class JadwalKegiatanScreen extends ConsumerStatefulWidget {
  const JadwalKegiatanScreen({super.key});

  @override
  ConsumerState<JadwalKegiatanScreen> createState() => _JadwalKegiatanScreenState();
}

class _JadwalKegiatanScreenState extends ConsumerState<JadwalKegiatanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Dialog Form Controllers
  final _hstController = TextEditingController();
  final _productController = TextEditingController();
  final _dosageController = TextEditingController();
  final _targetController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _scheduledDate = DateTime.now();
  String _selectedUnit = 'Kg';
  String _selectedMethod = 'Kocor'; // Fertilization
  String _selectedProductType = 'Fungisida'; // Spraying

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hstController.dispose();
    _productController.dispose();
    _dosageController.dispose();
    _targetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _hstController.clear();
    _productController.clear();
    _dosageController.clear();
    _targetController.clear();
    _notesController.clear();
    setState(() {
      _scheduledDate = DateTime.now();
      _selectedUnit = 'Kg';
      _selectedMethod = 'Kocor';
      _selectedProductType = 'Fungisida';
    });
  }

  // Show dialog to add / edit Fertilization
  void _showFertilisationDialog(String seasonId, [JadwalPemupukan? oldFert]) {
    if (oldFert != null) {
      _hstController.text = oldFert.hst.toString();
      _productController.text = oldFert.fertilizerName;
      _dosageController.text = oldFert.dosage.toString();
      _selectedUnit = oldFert.unit;
      _selectedMethod = oldFert.method;
      _scheduledDate = oldFert.date;
    } else {
      _resetForm();
      _selectedUnit = 'Kg';
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
                      Text(oldFert == null ? 'Jadwalkan Pemupukan' : 'Edit Jadwal Pemupukan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _hstController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Hari Setelah Tanam (HST)', prefixIcon: Icon(Icons.timer)),
                        onTap: () {
                          if (_hstController.text == '0') {
                            _hstController.clear();
                          }
                        },
                        validator: (value) => value == null || value.isEmpty ? 'HST wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _productController,
                        decoration: const InputDecoration(labelText: 'Nama Pupuk', prefixIcon: Icon(Icons.grass_outlined)),
                        validator: (value) => value == null || value.isEmpty ? 'Nama pupuk wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _dosageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Dosis Pupuk', prefixIcon: Icon(Icons.scale)),
                              onTap: () {
                                if (_dosageController.text == '0' || _dosageController.text == '0.0') {
                                  _dosageController.clear();
                                }
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Dosis wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              items: const [
                                DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                                DropdownMenuItem(value: 'Gram', child: Text('Gram')),
                                DropdownMenuItem(value: 'Karung', child: Text('Karung')),
                              ],
                              onChanged: (val) => setDialogState(() => _selectedUnit = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedMethod,
                        decoration: const InputDecoration(labelText: 'Metode Aplikasi', prefixIcon: Icon(Icons.settings_input_component_outlined)),
                        items: const [
                          DropdownMenuItem(value: 'Kocor', child: Text('Kocor')),
                          DropdownMenuItem(value: 'Tabur', child: Text('Tabur')),
                          DropdownMenuItem(value: 'Fertigasi', child: Text('Fertigasi')),
                        ],
                        onChanged: (val) => setDialogState(() => _selectedMethod = val!),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Tanggal: ${Formatters.formatDate(_scheduledDate)}'),
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: _scheduledDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (date != null) {
                            setDialogState(() => _scheduledDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          final repo = ref.read(databaseRepositoryProvider);
                          
                          final data = JadwalPemupukan(
                            id: oldFert?.id ?? '',
                            seasonId: seasonId,
                            hst: int.tryParse(_hstController.text) ?? 0,
                            date: _scheduledDate,
                            fertilizerName: _productController.text.trim(),
                            dosage: double.tryParse(_dosageController.text) ?? 0.0,
                            unit: _selectedUnit,
                            method: _selectedMethod,
                            status: oldFert?.status ?? 'Belum Dilaksanakan',
                          );

                          if (oldFert == null) {
                            await repo.addFertilization(data);
                          } else {
                            await repo.updateFertilization(data);
                          }

                          // Schedule notification reminder (24 hours before / at 7am of the day)
                          try {
                            final reminderTime = DateTime(_scheduledDate.year, _scheduledDate.month, _scheduledDate.day, 7, 0);
                            await NotificationService().scheduleNotification(
                              id: data.hashCode,
                              title: 'Pengingat Pemupukan 🌿',
                              body: 'Jadwal pemupukan ${data.fertilizerName} hari ini untuk musim tanam Anda.',
                              scheduledTime: reminderTime,
                            );
                          } catch (e) {
                            debugPrint('Failed to schedule notification: $e');
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal pemupukan berhasil disimpan!'), backgroundColor: Colors.green));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Simpan Jadwal', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // Show dialog to add / edit Spraying
  void _showSprayingDialog(String seasonId, [JadwalPenyemprotan? oldSpray]) {
    if (oldSpray != null) {
      _hstController.text = oldSpray.hst.toString();
      _productController.text = oldSpray.productName;
      _selectedProductType = oldSpray.productType;
      _dosageController.text = oldSpray.dosage.toString();
      _targetController.text = oldSpray.targetPest;
      _notesController.text = oldSpray.notes;
      _scheduledDate = oldSpray.date;
    } else {
      _resetForm();
      _selectedProductType = 'Fungisida';
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
                      Text(oldSpray == null ? 'Jadwalkan Penyemprotan' : 'Edit Jadwal Penyemprotan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _hstController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Hari Setelah Tanam (HST)', prefixIcon: Icon(Icons.timer)),
                        onTap: () {
                          if (_hstController.text == '0') {
                            _hstController.clear();
                          }
                        },
                        validator: (value) => value == null || value.isEmpty ? 'HST wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _productController,
                        decoration: const InputDecoration(labelText: 'Nama Produk (Merek)', prefixIcon: Icon(Icons.bug_report_outlined)),
                        validator: (value) => value == null || value.isEmpty ? 'Nama produk wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedProductType,
                        decoration: const InputDecoration(labelText: 'Jenis Produk', prefixIcon: Icon(Icons.category)),
                        items: const [
                          DropdownMenuItem(value: 'Fungisida', child: Text('Fungisida')),
                          DropdownMenuItem(value: 'Insektisida', child: Text('Insektisida')),
                          DropdownMenuItem(value: 'Bakterisida', child: Text('Bakterisida')),
                          DropdownMenuItem(value: 'Herbisida', child: Text('Herbisida')),
                        ],
                        onChanged: (val) => setDialogState(() => _selectedProductType = val!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dosageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Dosis (ml / L)', prefixIcon: Icon(Icons.scale)),
                              onTap: () {
                                if (_dosageController.text == '0' || _dosageController.text == '0.0') {
                                  _dosageController.clear();
                                }
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Dosis wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _targetController,
                              decoration: const InputDecoration(labelText: 'Target Hama', prefixIcon: Icon(Icons.coronavirus)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Catatan Penyemprotan', prefixIcon: Icon(Icons.note_alt_outlined)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Tanggal: ${Formatters.formatDate(_scheduledDate)}'),
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: _scheduledDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (date != null) {
                            setDialogState(() => _scheduledDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          final repo = ref.read(databaseRepositoryProvider);
                          
                          final data = JadwalPenyemprotan(
                            id: oldSpray?.id ?? '',
                            seasonId: seasonId,
                            hst: int.tryParse(_hstController.text) ?? 0,
                            date: _scheduledDate,
                            productName: _productController.text.trim(),
                            productType: _selectedProductType,
                            dosage: double.tryParse(_dosageController.text) ?? 0.0,
                            targetPest: _targetController.text.trim(),
                            notes: _notesController.text.trim(),
                            status: oldSpray?.status ?? 'Belum Dilaksanakan',
                          );

                          if (oldSpray == null) {
                            await repo.addSpraying(data);
                          } else {
                            await repo.updateSpraying(data);
                          }

                          // Schedule notification reminder (at 7am of the day)
                          try {
                            final reminderTime = DateTime(_scheduledDate.year, _scheduledDate.month, _scheduledDate.day, 7, 0);
                            await NotificationService().scheduleNotification(
                              id: data.hashCode,
                              title: 'Pengingat Penyemprotan 🛡️',
                              body: 'Jadwal penyemprotan ${data.productName} (${data.productType}) hari ini.',
                              scheduledTime: reminderTime,
                            );
                          } catch (e) {
                            debugPrint('Failed to schedule notification: $e');
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal penyemprotan berhasil disimpan!'), backgroundColor: Colors.green));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Simpan Jadwal', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _markFertDone(JadwalPemupukan f) async {
    final updated = JadwalPemupukan(
      id: f.id,
      seasonId: f.seasonId,
      hst: f.hst,
      date: f.date,
      fertilizerName: f.fertilizerName,
      dosage: f.dosage,
      unit: f.unit,
      method: f.method,
      status: 'Selesai',
    );
    await ref.read(databaseRepositoryProvider).updateFertilization(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan Pemupukan selesai dicatat & Stok berkurang!'), backgroundColor: Colors.green),
      );
    }
  }

  void _markSprayDone(JadwalPenyemprotan s) async {
    final updated = JadwalPenyemprotan(
      id: s.id,
      seasonId: s.seasonId,
      hst: s.hst,
      date: s.date,
      productName: s.productName,
      productType: s.productType,
      dosage: s.dosage,
      targetPest: s.targetPest,
      notes: s.notes,
      status: 'Selesai',
    );
    await ref.read(databaseRepositoryProvider).updateSpraying(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan Penyemprotan selesai dicatat & Stok berkurang!'), backgroundColor: Colors.green),
      );
    }
  }

  void _deleteFert(JadwalPemupukan f) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal Pemupukan?'),
        content: Text('Apakah Anda yakin ingin menghapus jadwal pemupukan ${f.fertilizerName}? Jika jadwal sudah berstatus selesai, stok pupuk akan dikembalikan.'),
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
      await ref.read(databaseRepositoryProvider).deleteFertilization(f.id, f);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal pemupukan berhasil dihapus.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _deleteSpray(JadwalPenyemprotan s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal Penyemprotan?'),
        content: Text('Apakah Anda yakin ingin menghapus jadwal penyemprotan ${s.productName}? Jika jadwal sudah berstatus selesai, stok pestisida akan dikembalikan.'),
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
      await ref.read(databaseRepositoryProvider).deleteSpraying(s.id, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal penyemprotan berhasil dihapus.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasonsState = ref.watch(watchSeasonsProvider);
    final selectedSeasonId = ref.watch(selectedSeasonIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan Tani'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(icon: Icon(Icons.grass), text: 'Pemupukan'),
            Tab(icon: Icon(Icons.bug_report_outlined), text: 'Penyemprotan'),
          ],
        ),
      ),
      body: seasonsState.when(
        data: (seasons) {
          final runningSeasons = seasons.where((s) => s.status == 'Berjalan').toList();

          if (runningSeasons.isEmpty) {
            return const Center(child: Text('Tidak ada musim tanam aktif berjalan. Harap buat musim tanam terlebih dahulu.'));
          }

          // Auto-select first active season if none is selected or not in runningSeasons
          final currentSeasonId = (selectedSeasonId != null && runningSeasons.any((s) => s.id == selectedSeasonId))
              ? selectedSeasonId
              : runningSeasons.first.id;

          return Column(
            children: [
              // Season Selector Dropdown
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: DropdownButtonFormField<String>(
                  value: currentSeasonId,
                  decoration: const InputDecoration(labelText: 'Pilih Musim Tanam Aktif', prefixIcon: Icon(Icons.spa)),
                  items: runningSeasons.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) {
                    ref.read(selectedSeasonIdProvider.notifier).state = val;
                  },
                ),
              ),

              // Tabbed Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Pemupukan
                    _buildFertilisationList(currentSeasonId),

                    // Tab 2: Penyemprotan
                    _buildSprayingList(currentSeasonId),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: seasonsState.value?.any((s) => s.status == 'Berjalan') == true
          ? FloatingActionButton(
              onPressed: () {
                final running = seasonsState.value!.where((s) => s.status == 'Berjalan').toList();
                if (running.isEmpty) return;
                final currentSeasonId = (selectedSeasonId != null && running.any((s) => s.id == selectedSeasonId))
                    ? selectedSeasonId
                    : running.first.id;
                if (_tabController.index == 0) {
                  _showFertilisationDialog(currentSeasonId);
                } else {
                  _showSprayingDialog(currentSeasonId);
                }
              },
              child: const Icon(Icons.add_task),
            )
          : null,
    );
  }

  Widget _buildFertilisationList(String seasonId) {
    final fertsState = ref.watch(watchFertilizationsProvider(seasonId));

    return fertsState.when(
      data: (ferts) {
        if (ferts.isEmpty) {
          return const Center(child: Text('Belum ada jadwal pemupukan.'));
        }

        return ListView.builder(
          itemCount: ferts.length,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemBuilder: (context, index) {
            final f = ferts[index];
            final isDone = f.status == 'Selesai';

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDone ? Colors.grey[300] : Colors.green[100],
                  child: Icon(Icons.check_circle_outline, color: isDone ? Colors.grey : Colors.green[800]),
                ),
                title: Text('${f.fertilizerName} (${f.dosage} ${f.unit})', style: TextStyle(fontWeight: FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null)),
                subtitle: Text('Metode: ${f.method} | HST: ${f.hst} | Tanggal: ${Formatters.formatDate(f.date)}'),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'done') {
                      _markFertDone(f);
                    } else if (value == 'edit') {
                      _showFertilisationDialog(seasonId, f);
                    } else if (value == 'delete') {
                      _deleteFert(f);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isDone)
                      const PopupMenuItem(
                        value: 'done',
                        child: Row(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Tandai Selesai'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Ubah'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus'),
                        ],
                      ),
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
  }

  Widget _buildSprayingList(String seasonId) {
    final sprayState = ref.watch(watchSprayingsProvider(seasonId));

    return sprayState.when(
      data: (sprays) {
        if (sprays.isEmpty) {
          return const Center(child: Text('Belum ada jadwal penyemprotan.'));
        }

        return ListView.builder(
          itemCount: sprays.length,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemBuilder: (context, index) {
            final s = sprays[index];
            final isDone = s.status == 'Selesai';

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDone ? Colors.grey[300] : Colors.orange[100],
                  child: Icon(Icons.coronavirus, color: isDone ? Colors.grey : Colors.orange[800]),
                ),
                title: Text('${s.productName} [${s.productType}]', style: TextStyle(fontWeight: FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null)),
                subtitle: Text('Dosis: ${s.dosage} ml/L | Target: ${s.targetPest} | Tanggal: ${Formatters.formatDate(s.date)}'),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'done') {
                      _markSprayDone(s);
                    } else if (value == 'edit') {
                      _showSprayingDialog(seasonId, s);
                    } else if (value == 'delete') {
                      _deleteSpray(s);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isDone)
                      const PopupMenuItem(
                        value: 'done',
                        child: Row(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Tandai Selesai'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Ubah'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus'),
                        ],
                      ),
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
  }
}

// Additional dynamic providers for watch query referencing seasonId
final watchFertilizationsProvider = StreamProvider.family<List<JadwalPemupukan>, String>((ref, seasonId) {
  return ref.watch(databaseRepositoryProvider).watchFertilizations(seasonId);
});

final watchSprayingsProvider = StreamProvider.family<List<JadwalPenyemprotan>, String>((ref, seasonId) {
  return ref.watch(databaseRepositoryProvider).watchSprayings(seasonId);
});
