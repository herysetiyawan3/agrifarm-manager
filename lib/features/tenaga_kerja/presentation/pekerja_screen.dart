import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../../core/utils/formatters.dart';

class PekerjaScreen extends ConsumerStatefulWidget {
  const PekerjaScreen({super.key});

  @override
  ConsumerState<PekerjaScreen> createState() => _PekerjaScreenState();
}

class WorkerStats {
  final double totalDaysWorked;
  final double totalWage;
  final String lastActivity;
  final DateTime? lastDate;

  WorkerStats({
    required this.totalDaysWorked,
    required this.totalWage,
    required this.lastActivity,
    this.lastDate,
  });
}

class _PekerjaScreenState extends ConsumerState<PekerjaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Search and filters
  String _workerSearchQuery = '';
  String _activitySearchQuery = '';
  String _selectedFilterActivity = 'Semua Aktivitas';

  // Worker Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _wageController = TextEditingController();

  // Activity Log Form State
  String? _selectedSeasonId;
  String? _selectedFieldId;
  String _selectedActivityType = 'Pengolahan Lahan';
  DateTime _activityDate = DateTime.now();
  final _notesController = TextEditingController();
  final Set<String> _selectedWorkerIds = {};

  final List<String> _activityTypes = [
    'Pengolahan Lahan',
    'Penanaman',
    'Pemupukan',
    'Penyemprotan',
    'Penyiangan',
    'Pengairan',
    'Panen',
    'Sortasi',
    'Pengangkutan',
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
    _nameController.dispose();
    _phoneController.dispose();
    _wageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _resetWorkerForm() {
    _nameController.clear();
    _phoneController.clear();
    _wageController.clear();
  }

  void _resetActivityForm() {
    _notesController.clear();
    _selectedWorkerIds.clear();
    setState(() {
      _selectedSeasonId = null;
      _selectedFieldId = null;
      _selectedActivityType = 'Pengolahan Lahan';
      _activityDate = DateTime.now();
    });
  }

  WorkerStats getWorkerStats(String workerId, List<AktivitasPekerja> activities) {
    final workerActs = activities.where((act) => act.workerId == workerId).toList();
    if (workerActs.isEmpty) {
      return WorkerStats(
        totalDaysWorked: 0.0,
        totalWage: 0.0,
        lastActivity: '-',
        lastDate: null,
      );
    }
    // Sort descending by date
    workerActs.sort((a, b) => b.date.compareTo(a.date));
    final totalDays = workerActs.fold<double>(0.0, (sum, act) => sum + act.daysWorked);
    final totalWage = workerActs.fold<double>(0.0, (sum, act) => sum + act.totalWage);
    return WorkerStats(
      totalDaysWorked: totalDays,
      totalWage: totalWage,
      lastActivity: workerActs.first.activityType,
      lastDate: workerActs.first.date,
    );
  }

  void _showWorkerDialog([TenagaKerja? worker]) {
    if (worker != null) {
      _nameController.text = worker.name;
      _phoneController.text = worker.phone;
      _wageController.text = worker.dailyWage == worker.dailyWage.toInt() ? worker.dailyWage.toInt().toString() : worker.dailyWage.toString();
    } else {
      _resetWorkerForm();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(worker == null ? 'Tambah Pekerja Baru' : 'Edit Data Pekerja'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pekerja',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp (Opsional)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _wageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Upah Harian (Rp)',
                      prefixIcon: Icon(Icons.payments),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Upah harian wajib diisi' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                
                final repo = ref.read(databaseRepositoryProvider);
                final data = TenagaKerja(
                  id: worker?.id ?? '',
                  name: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                  address: worker?.address ?? '',
                  dailyWage: double.tryParse(_wageController.text) ?? 0.0,
                );

                if (worker == null) {
                  await repo.addWorker(data);
                } else {
                  await repo.updateWorker(data);
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data pekerja berhasil disimpan!'), backgroundColor: Colors.green));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showWorkerDetailDialog(TenagaKerja worker, List<AktivitasPekerja> activities) {
    final stats = getWorkerStats(worker.id, activities);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text('Nomor WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text(worker.phone.isNotEmpty ? worker.phone : '-', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.payments, color: Colors.green),
                  title: const Text('Upah Harian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text(Formatters.formatRupiah(worker.dailyWage), style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month, color: Colors.green),
                  title: const Text('Total Hari Kerja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text('${stats.totalDaysWorked.toInt()} Hari', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.monetization_on, color: Colors.green),
                  title: const Text('Total Upah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text(Formatters.formatRupiah(stats.totalWage), style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.work_history, color: Colors.green),
                  title: const Text('Aktivitas Terakhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text(stats.lastActivity, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.today, color: Colors.green),
                  title: const Text('Tanggal Terakhir Bekerja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text(stats.lastDate != null ? Formatters.formatLongDate(stats.lastDate!) : '-', style: const TextStyle(fontSize: 16, color: Colors.black87)),
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
    );
  }

  void _showActivityDialog(
    List<TenagaKerja> workers,
    List<MusimTanam> seasons,
    List<Lahan> fields,
    [List<AktivitasPekerja>? oldGroupActs]
  ) {
    if (oldGroupActs != null && oldGroupActs.isNotEmpty) {
      final first = oldGroupActs.first;
      _selectedSeasonId = first.seasonId;
      _selectedFieldId = first.fieldId;
      _selectedActivityType = first.activityType;
      _activityDate = first.date;
      _notesController.text = first.description;
      _selectedWorkerIds.clear();
      for (var act in oldGroupActs) {
        _selectedWorkerIds.add(act.workerId);
      }
    } else {
      _resetActivityForm();
      if (seasons.isNotEmpty) {
        _selectedSeasonId = seasons.first.id;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final activeSeasons = seasons.where((s) => s.status != 'Selesai' || s.id == _selectedSeasonId).toList();
            
            MusimTanam? selectedSeason;
            if (_selectedSeasonId != null && activeSeasons.isNotEmpty) {
              selectedSeason = activeSeasons.firstWhere((s) => s.id == _selectedSeasonId, orElse: () => activeSeasons.first);
            }

            List<Lahan> seasonFields = [];
            if (selectedSeason != null) {
              final fieldIds = selectedSeason.fieldId.split(',').map((e) => e.trim()).toList();
              seasonFields = fields.where((f) => fieldIds.contains(f.id) || fieldIds.contains(f.name)).toList();
            }

            final dropdownFields = seasonFields.isNotEmpty ? seasonFields : fields;

            if (_selectedFieldId == null || !dropdownFields.any((f) => f.id == _selectedFieldId)) {
              _selectedFieldId = dropdownFields.isNotEmpty ? dropdownFields.first.id : null;
            }

            final totalCost = _selectedWorkerIds.map((id) {
              final w = workers.firstWhere((element) => element.id == id, orElse: () => TenagaKerja(id: '', name: '', phone: '', address: ''));
              return w.dailyWage;
            }).fold<double>(0.0, (sum, wage) => sum + wage);

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 20, right: 20),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        oldGroupActs == null ? 'Catat Aktivitas Tenaga Kerja' : 'Edit Aktivitas Tenaga Kerja',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: _selectedSeasonId,
                        decoration: const InputDecoration(labelText: 'Musim Tanam', prefixIcon: Icon(Icons.spa)),
                        items: activeSeasons.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            _selectedSeasonId = val;
                            _selectedFieldId = null;
                          });
                        },
                        validator: (value) => value == null ? 'Musim tanam wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _selectedFieldId,
                        decoration: const InputDecoration(labelText: 'Lahan', prefixIcon: Icon(Icons.location_on)),
                        items: dropdownFields.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            _selectedFieldId = val;
                          });
                        },
                        validator: (value) => value == null ? 'Lahan wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _selectedActivityType,
                        decoration: const InputDecoration(labelText: 'Jenis Aktivitas', prefixIcon: Icon(Icons.work_outline)),
                        items: _activityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedActivityType = val!),
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
                            setDialogState(() => _activityDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text('Pilih Pekerja:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: workers.length,
                          itemBuilder: (context, idx) {
                            final w = workers[idx];
                            final isSelected = _selectedWorkerIds.contains(w.id);
                            return CheckboxListTile(
                              title: Text(w.name),
                              subtitle: Text('Upah: ${Formatters.formatRupiah(w.dailyWage)}/Hari'),
                              value: isSelected,
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    _selectedWorkerIds.add(w.id);
                                  } else {
                                    _selectedWorkerIds.remove(w.id);
                                  }
                                });
                              },
                              activeColor: Colors.green[800],
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Keterangan (Opsional)', prefixIcon: Icon(Icons.notes)),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Biaya (Otomatis):', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              Formatters.formatRupiah(totalCost),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          if (_selectedWorkerIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal satu pekerja!'), backgroundColor: Colors.red));
                            return;
                          }
                          if (_selectedSeasonId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Musim Tanam!'), backgroundColor: Colors.red));
                            return;
                          }
                          if (_selectedFieldId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Lahan!'), backgroundColor: Colors.red));
                            return;
                          }

                          final repo = ref.read(databaseRepositoryProvider);
                          
                          // 1. If editing, delete old group acts first
                          if (oldGroupActs != null) {
                            for (var act in oldGroupActs) {
                              await repo.deleteWorkerActivity(act.id, act);
                            }
                          }

                          // 2. Generate group ID
                          final groupId = oldGroupActs?.first.groupId ?? 'group_${DateTime.now().millisecondsSinceEpoch}';

                          // 3. Save acts
                          for (var id in _selectedWorkerIds) {
                            final w = workers.firstWhere((element) => element.id == id);
                            final act = AktivitasPekerja(
                              id: '',
                              workerId: w.id,
                              workerName: w.name,
                              activityType: _selectedActivityType,
                              date: _activityDate,
                              dailyWage: w.dailyWage,
                              daysWorked: 1.0,
                              totalWage: w.dailyWage,
                              seasonId: _selectedSeasonId!,
                              fieldId: _selectedFieldId!,
                              description: _notesController.text.trim(),
                              groupId: groupId,
                            );
                            await repo.addWorkerActivity(act);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(oldGroupActs == null ? 'Aktivitas kerja berhasil disimpan!' : 'Aktivitas kerja berhasil diperbarui!'),
                              backgroundColor: Colors.green,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Simpan Aktivitas Tenaga Kerja', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showActivityDetailDialog(
    List<AktivitasPekerja> groupActs,
    List<MusimTanam> seasons,
    List<Lahan> fields,
  ) {
    if (groupActs.isEmpty) return;
    final first = groupActs.first;

    final season = seasons.firstWhere((s) => s.id == first.seasonId, orElse: () => MusimTanam(id: '', name: 'Musim Tanam', fieldId: '', cropId: '', variety: '', plantingArea: 0, seedsCount: 0, seedingDate: DateTime.now(), plantingDate: DateTime.now(), status: ''));
    final field = fields.firstWhere((f) => f.id == first.fieldId, orElse: () => Lahan(id: '', name: '-', area: 0, unit: '', locationGps: '', address: '', soilType: '', status: '', waterSource: '', notes: ''));

    final totalCost = groupActs.fold<double>(0.0, (sum, act) => sum + act.totalWage);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rincian Riwayat Kerja', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.today, color: Colors.brown),
                  title: const Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text(Formatters.formatLongDate(first.date), style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.work_outline, color: Colors.brown),
                  title: const Text('Aktivitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text(first.activityType, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.spa, color: Colors.brown),
                  title: const Text('Musim Tanam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text(season.name, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on, color: Colors.brown),
                  title: const Text('Lahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text(field.name, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ),
                const Divider(),
                const Text('Daftar Pekerja:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                ...groupActs.map((act) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record, size: 8, color: Colors.brown),
                      const SizedBox(width: 8),
                      Text(act.workerName, style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      Text(Formatters.formatRupiah(act.dailyWage), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                )),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.monetization_on, color: Colors.green),
                  title: const Text('Total Biaya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text(Formatters.formatRupiah(totalCost), style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notes, color: Colors.brown),
                  title: const Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  subtitle: Text(first.description.isNotEmpty ? first.description : '-', style: const TextStyle(fontSize: 14, color: Colors.black87)),
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
    );
  }

  void _deleteActivityGroup(List<AktivitasPekerja> groupActs) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Tenaga Kerja?'),
        content: Text('Apakah Anda yakin ingin menghapus catatan upah untuk ${groupActs.length} pekerja di kelompok ini? Pencatatan di pengeluaran buku kas juga akan dihapus.'),
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
      final repo = ref.read(databaseRepositoryProvider);
      for (var act in groupActs) {
        await repo.deleteWorkerActivity(act.id, act);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log aktivitas kelompok berhasil dihapus.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _deleteWorker(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pekerja?'),
        content: const Text('Seluruh catatan profil pekerja akan dihapus. Log aktivitas sebelumnya tetap tersimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(databaseRepositoryProvider).deleteWorker(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workersState = ref.watch(watchWorkersProvider);
    final activitiesState = ref.watch(watchWorkerActivitiesProvider);
    final seasonsState = ref.watch(watchSeasonsProvider);
    final fieldsState = ref.watch(watchFieldsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenaga Kerja'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Daftar Pekerja'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat Tenaga Kerja'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: DAFTAR PEKERJA
          workersState.when(
            data: (workers) {
              final activities = activitiesState.value ?? [];
              final filteredWorkers = workers.where((w) {
                return w.name.toLowerCase().contains(_workerSearchQuery.toLowerCase().trim());
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dashboard Card at the top
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Card(
                      color: Colors.brown[50],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Pekerja', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text('${workers.length} Orang', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown[900])),
                              ],
                            ),
                            Icon(Icons.people, color: Colors.brown[800], size: 36),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Search box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Cari pekerja...',
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _workerSearchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: filteredWorkers.isEmpty
                        ? const Center(child: Text('Belum ada data pekerja.'))
                        : ListView.builder(
                            itemCount: filteredWorkers.length,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            itemBuilder: (context, index) {
                              final w = filteredWorkers[index];
                              final stats = getWorkerStats(w.id, activities);

                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: InkWell(
                                  onTap: () => _showWorkerDetailDialog(w, activities),
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.brown[100],
                                      child: Icon(Icons.person, color: Colors.brown[800]),
                                    ),
                                    title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Upah: ${Formatters.formatRupiah(w.dailyWage)}/Hari\nKehadiran: ${stats.totalDaysWorked.toInt()} Hari Kerja',
                                        style: const TextStyle(height: 1.3),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showWorkerDialog(w),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteWorker(w.id),
                                        ),
                                      ],
                                    ),
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

          // TAB 2: RIWAYAT TENAGA KERJA
          activitiesState.when(
            data: (activities) {
              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              final todayEnd = todayStart.add(const Duration(days: 1));
              final thisMonthStart = DateTime(now.year, now.month, 1);

              // 1. Dashboard calculations
              final actsToday = activities.where((act) => act.date.isAfter(todayStart.subtract(const Duration(seconds: 1))) && act.date.isBefore(todayEnd)).toList();
              
              final Set<String> groupIdsToday = {};
              for (var act in actsToday) {
                final key = act.groupId.isNotEmpty ? act.groupId : "${act.date.millisecondsSinceEpoch}_${act.activityType}";
                groupIdsToday.add(key);
              }
              final int aktivitasHariIniCount = groupIdsToday.length;
              final double biayaHariIni = actsToday.fold<double>(0.0, (sum, act) => sum + act.totalWage);

              final actsThisMonth = activities.where((act) => act.date.isAfter(thisMonthStart.subtract(const Duration(seconds: 1)))).toList();
              final double biayaBulanIni = actsThisMonth.fold<double>(0.0, (sum, act) => sum + act.totalWage);
              final double totalHariKerjaBulanIni = actsThisMonth.fold<double>(0.0, (sum, act) => sum + act.daysWorked);

              // 2. Filter activities before grouping
              final query = _activitySearchQuery.toLowerCase().trim();
              final filteredActs = activities.where((act) {
                if (_selectedFilterActivity != 'Semua Aktivitas' && act.activityType != _selectedFilterActivity) {
                  return false;
                }
                if (query.isNotEmpty && !act.workerName.toLowerCase().contains(query)) {
                  return false;
                }
                return true;
              }).toList();

              // 3. Group filtered activities
              final Map<String, List<AktivitasPekerja>> grouped = {};
              for (var act in filteredActs) {
                final key = act.groupId.isNotEmpty
                    ? act.groupId
                    : "${act.date.millisecondsSinceEpoch}_${act.activityType}_${act.seasonId}_${act.description}";
                grouped.putIfAbsent(key, () => []).add(act);
              }

              final sortedGroupKeys = grouped.keys.toList()
                ..sort((a, b) {
                  return grouped[b]!.first.date.compareTo(grouped[a]!.first.date);
                });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dashboard
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Card(
                      color: Colors.green[50],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.2,
                          children: [
                            _buildDashboardStat('Aktivitas Hari Ini', '$aktivitasHariIniCount Aktivitas', Colors.green),
                            _buildDashboardStat('Biaya Hari Ini', Formatters.formatRupiah(biayaHariIni), Colors.teal),
                            _buildDashboardStat('Biaya Bulan Ini', Formatters.formatRupiah(biayaBulanIni), Colors.orange),
                            _buildDashboardStat('Kerja Bulan Ini', '${totalHariKerjaBulanIni.toInt()} Hari Kerja', Colors.blue),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Search Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Cari pekerja...',
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _activitySearchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Row(
                      children: ['Semua Aktivitas', ..._activityTypes].map((cat) {
                        final isSelected = _selectedFilterActivity == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(cat, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            selectedColor: Colors.green[800],
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedFilterActivity = cat;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: sortedGroupKeys.isEmpty
                        ? const Center(child: Text('Belum ada riwayat aktivitas kerja.'))
                        : ListView.builder(
                            itemCount: sortedGroupKeys.length,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            itemBuilder: (context, index) {
                              final groupKey = sortedGroupKeys[index];
                              final groupActs = grouped[groupKey]!;
                              final first = groupActs.first;

                              final totalGroupWage = groupActs.fold<double>(0.0, (sum, act) => sum + act.totalWage);

                              final seasonName = seasonsState.value?.firstWhere((s) => s.id == first.seasonId, orElse: () => MusimTanam(id: '', name: 'Umum', fieldId: '', cropId: '', variety: '', plantingArea: 0, seedsCount: 0, seedingDate: DateTime.now(), plantingDate: DateTime.now(), status: '')).name ?? 'Umum';

                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: InkWell(
                                  onTap: () => _showActivityDetailDialog(groupActs, seasonsState.value ?? [], fieldsState.value ?? []),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              Formatters.formatLongDate(first.date),
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              Formatters.formatRupiah(totalGroupWage),
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Aktivitas: ${first.activityType}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Musim Tanam: $seasonName',
                                          style: TextStyle(color: Colors.grey[800], fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.brown[50],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Jumlah Pekerja: ${groupActs.length} Orang',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown[800]),
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _showActivityDialog(
                                                workersState.value ?? [],
                                                seasonsState.value ?? [],
                                                fieldsState.value ?? [],
                                                groupActs,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _deleteActivityGroup(groupActs),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
        onPressed: () {
          final workers = workersState.value ?? [];
          final seasons = seasonsState.value ?? [];
          final fields = fieldsState.value ?? [];

          if (_tabController.index == 0) {
            _showWorkerDialog();
          } else {
            if (workers.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daftar pekerja masih kosong. Harap tambahkan pekerja terlebih dahulu!'), backgroundColor: Colors.red));
              return;
            }
            if (seasons.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siklus/Musim Tanam masih kosong. Harap tambahkan musim tanam terlebih dahulu!'), backgroundColor: Colors.red));
              return;
            }
            _showActivityDialog(workers, seasons, fields);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardStat(String label, String value, Color color) {
    Color displayColor = color;
    if (color is MaterialColor) {
      displayColor = color[900] ?? color;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: displayColor)),
      ],
    );
  }
}
