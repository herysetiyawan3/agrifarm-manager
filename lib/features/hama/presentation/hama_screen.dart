import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/formatters.dart';

class HamaScreen extends ConsumerStatefulWidget {
  const HamaScreen({super.key});

  @override
  ConsumerState<HamaScreen> createState() => _HamaScreenState();
}

class _HamaScreenState extends ConsumerState<HamaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _solutionController = TextEditingController();

  String? _selectedSeasonId;
  String _selectedSeverity = 'Ringan';
  DateTime _date = DateTime.now();
  String _localPhotoPath = '';
  bool _isSaving = false;

  final List<String> _severities = ['Ringan', 'Sedang', 'Berat'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _solutionController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _solutionController.clear();
    setState(() {
      _selectedSeverity = 'Ringan';
      _date = DateTime.now();
      _localPhotoPath = '';
      _isSaving = false;
    });
  }

  void _showFormDialog(List<MusimTanam> seasons, [HamaPenyakit? oldPest]) {
    if (oldPest != null) {
      _nameController.text = oldPest.name;
      _descriptionController.text = oldPest.description;
      _solutionController.text = oldPest.solution;
      _selectedSeasonId = oldPest.seasonId;
      _selectedSeverity = oldPest.severity;
      _date = oldPest.date;
    } else {
      _resetForm();
      if (seasons.isNotEmpty) _selectedSeasonId = seasons.first.id;
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
                      Text(oldPest == null ? 'Catat Temuan Hama' : 'Edit Catatan Hama', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedSeasonId,
                        decoration: const InputDecoration(labelText: 'Pilih Musim Tanam', prefixIcon: Icon(Icons.spa)),
                        items: seasons.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedSeasonId = val),
                        validator: (value) => value == null ? 'Musim tanam wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nama Hama/Penyakit (e.g. Lalat Buah, Embun Tepung)', prefixIcon: Icon(Icons.bug_report)),
                        validator: (value) => value == null || value.isEmpty ? 'Nama hama/penyakit wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedSeverity,
                        decoration: const InputDecoration(labelText: 'Tingkat Serangan', prefixIcon: Icon(Icons.warning_amber_outlined)),
                        items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedSeverity = val!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Gejala/Deskripsi Kerusakan', prefixIcon: Icon(Icons.description_outlined)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _solutionController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Solusi/Penanganan (Tindakan)', prefixIcon: Icon(Icons.healing_outlined)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_localPhotoPath.isEmpty ? 'Ambil / Upload Foto Hama' : 'Foto Terpilih (Ganti)'),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
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
                                  String photoUrl = oldPest?.photoUrl ?? '';
                                  if (_localPhotoPath.isNotEmpty) {
                                    photoUrl = await StorageService.uploadImage(
                                      localPath: _localPhotoPath,
                                      folder: 'pests',
                                      fileName: 'pest_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                    );
                                  }

                                  final repo = ref.read(databaseRepositoryProvider);
                                  final data = HamaPenyakit(
                                    id: oldPest?.id ?? '',
                                    date: _date,
                                    seasonId: _selectedSeasonId!,
                                    name: _nameController.text.trim(),
                                    severity: _selectedSeverity,
                                    description: _descriptionController.text.trim(),
                                    solution: _solutionController.text.trim(),
                                    photoUrl: photoUrl,
                                  );

                                  if (oldPest == null) {
                                    await repo.addPest(data);
                                  } else {
                                    await repo.updatePest(data);
                                  }

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan Hama berhasil disimpan!'), backgroundColor: Colors.green));
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
                                  }
                                } finally {
                                  setDialogState(() => _isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Simpan Laporan Hama', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _deletePest(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan Hama?'),
        content: const Text('Laporan ini akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(databaseRepositoryProvider).deletePest(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan hama berhasil dihapus.'), backgroundColor: Colors.orange));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pestState = ref.watch(watchPestsProvider);
    final seasonsState = ref.watch(watchSeasonsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Hama & Penyakit')),
      body: pestState.when(
        data: (pests) {
          final seasons = seasonsState.value ?? [];

          if (pests.isEmpty) {
            return const Center(child: Text('Belum ada catatan temuan hama/penyakit.'));
          }

          return ListView.builder(
            itemCount: pests.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final pest = pests[index];
              final season = seasons.firstWhere((s) => s.id == pest.seasonId, orElse: () => MusimTanam(id: '', name: 'Musim tidak dikenal', fieldId: '', cropId: '', variety: '', plantingArea: 0, seedsCount: 0, seedingDate: DateTime.now(), plantingDate: DateTime.now(), status: ''));

              Color severityColor = Colors.green;
              if (pest.severity == 'Sedang') severityColor = Colors.orange;
              if (pest.severity == 'Berat') severityColor = Colors.red;

              return Card(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: severityColor.withOpacity(0.15),
                    child: Icon(Icons.bug_report, color: severityColor),
                  ),
                  title: Text(pest.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Musim: ${season.name} | Tanggal: ${Formatters.formatDate(pest.date)}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Text('Tingkat Serangan: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(pest.severity, style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Deskripsi: ${pest.description}', style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('Solusi Penanganan: ${pest.solution}', style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          if (pest.photoUrl.isNotEmpty) ...[
                            const Text('Foto Kerusakan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 6),
                            Image.network(pest.photoUrl, height: 160, fit: BoxFit.cover),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showFormDialog(seasons, pest),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePest(pest.id),
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
      floatingActionButton: seasonsState.value?.isNotEmpty == true
          ? FloatingActionButton(
              onPressed: () => _showFormDialog(seasonsState.value!),
              child: const Icon(Icons.add_a_photo_outlined),
            )
          : null,
    );
  }
}
