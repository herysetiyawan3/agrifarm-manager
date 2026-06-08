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

class _PekerjaScreenState extends ConsumerState<PekerjaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Worker Info Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Activity Log Controllers
  final _dailyWageController = TextEditingController();
  final _daysWorkedController = TextEditingController();

  String? _selectedWorkerId;
  String _selectedActivityType = 'Pengolahan Lahan';
  DateTime _activityDate = DateTime.now();

  final List<String> _activityTypes = ['Pengolahan Lahan', 'Penanaman', 'Pemupukan', 'Penyemprotan', 'Panen', 'Lainnya'];

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
    _addressController.dispose();
    _dailyWageController.dispose();
    _daysWorkedController.dispose();
    super.dispose();
  }

  void _resetWorkerForm() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  void _resetActivityForm() {
    _dailyWageController.clear();
    _daysWorkedController.clear();
    setState(() {
      _selectedWorkerId = null;
      _selectedActivityType = 'Pengolahan Lahan';
      _activityDate = DateTime.now();
    });
  }

  void _showWorkerDialog([TenagaKerja? worker]) {
    if (worker != null) {
      _nameController.text = worker.name;
      _phoneController.text = worker.phone;
      _addressController.text = worker.address;
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                  validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nomor HP (WhatsApp)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Alamat Tinggal'),
                ),
              ],
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
                  address: _addressController.text.trim(),
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

  void _showActivityDialog(List<TenagaKerja> workers, [AktivitasPekerja? oldAct]) {
    if (oldAct != null) {
      _selectedWorkerId = oldAct.workerId;
      _selectedActivityType = oldAct.activityType;
      _dailyWageController.text = oldAct.dailyWage == oldAct.dailyWage.toInt() ? oldAct.dailyWage.toInt().toString() : oldAct.dailyWage.toString();
      _daysWorkedController.text = oldAct.daysWorked == oldAct.daysWorked.toInt() ? oldAct.daysWorked.toInt().toString() : oldAct.daysWorked.toString();
      _activityDate = oldAct.date;
    } else {
      _resetActivityForm();
      if (workers.isNotEmpty) _selectedWorkerId = workers.first.id;
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
                      Text(oldAct == null ? 'Catat Aktivitas Kerja & Gaji' : 'Edit Aktivitas Kerja & Gaji', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedWorkerId,
                        decoration: const InputDecoration(labelText: 'Pilih Pekerja', prefixIcon: Icon(Icons.person)),
                        items: workers.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedWorkerId = val),
                        validator: (value) => value == null ? 'Pekerja wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedActivityType,
                        decoration: const InputDecoration(labelText: 'Jenis Aktivitas', prefixIcon: Icon(Icons.work_outline)),
                        items: _activityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedActivityType = val!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dailyWageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Upah Harian (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
                              onTap: () {
                                if (_dailyWageController.text == '0' || _dailyWageController.text == '0.0') {
                                  _dailyWageController.clear();
                                }
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Upah wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _daysWorkedController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Jumlah Hari', prefixIcon: Icon(Icons.date_range_outlined)),
                              onTap: () {
                                if (_daysWorkedController.text == '0' || _daysWorkedController.text == '0.0') {
                                  _daysWorkedController.clear();
                                }
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Jumlah hari wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Tanggal: ${Formatters.formatDate(_activityDate)}'),
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: _activityDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (date != null) {
                            setDialogState(() => _activityDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          
                          final worker = workers.firstWhere((w) => w.id == _selectedWorkerId);
                          final daily = double.tryParse(_dailyWageController.text) ?? 0.0;
                          final days = double.tryParse(_daysWorkedController.text) ?? 0.0;

                          final data = AktivitasPekerja(
                            id: oldAct?.id ?? '',
                            workerId: _selectedWorkerId!,
                            workerName: worker.name,
                            activityType: _selectedActivityType,
                            date: _activityDate,
                            dailyWage: daily,
                            daysWorked: days,
                            totalWage: daily * days,
                          );

                          if (oldAct == null) {
                            await ref.read(databaseRepositoryProvider).addWorkerActivity(data);
                          } else {
                            await ref.read(databaseRepositoryProvider).updateWorkerActivity(oldAct, data);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log aktivitas kerja & gaji berhasil disimpan!'), backgroundColor: Colors.green));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Simpan Log Kerja', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _deleteActivity(AktivitasPekerja act) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Log Kerja?'),
        content: Text('Apakah Anda yakin ingin menghapus log kerja ${act.workerName} - ${act.activityType}? Pencatatan gaji di pengeluaran buku kas juga akan dihapus.'),
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
      await ref.read(databaseRepositoryProvider).deleteWorkerActivity(act.id, act);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log aktivitas kerja berhasil dihapus.'), backgroundColor: Colors.orange),
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
            Tab(icon: Icon(Icons.payments), text: 'Log & Upah Gaji'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: DAFTAR PEKERJA
          workersState.when(
            data: (workers) {
              if (workers.isEmpty) {
                return const Center(child: Text('Belum ada data pekerja kebun.'));
              }

              return ListView.builder(
                itemCount: workers.length,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (context, index) {
                  final w = workers[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.brown[100], child: Icon(Icons.person, color: Colors.brown[800])),
                      title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('HP: ${w.phone} | Alamat: ${w.address}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showWorkerDialog(w)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteWorker(w.id)),
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

          // TAB 2: LOG AKTIVITAS & GAJI
          activitiesState.when(
            data: (activities) {
              if (activities.isEmpty) {
                return const Center(child: Text('Belum ada log aktivitas kerja harian.'));
              }

              return ListView.builder(
                itemCount: activities.length,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (context, index) {
                  final act = activities[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.orange[100], child: Icon(Icons.engineering_outlined, color: Colors.orange[800])),
                      title: Text(act.workerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${act.activityType} (${act.daysWorked} hari) | ${Formatters.formatDate(act.date)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(Formatters.formatRupiah(act.totalWage), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showActivityDialog(workersState.value ?? [], act),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _deleteActivity(act),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final workers = workersState.value ?? [];
          if (_tabController.index == 0) {
            _showWorkerDialog();
          } else {
            if (workers.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daftar pekerja masih kosong. Harap tambahkan pekerja terlebih dahulu!'), backgroundColor: Colors.red));
              return;
            }
            _showActivityDialog(workers);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
