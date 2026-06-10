import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart';
import '../../database_repository.dart';
import '../../../core/utils/formatters.dart';

class PanenPenjualanScreen extends ConsumerStatefulWidget {
  const PanenPenjualanScreen({super.key});

  @override
  ConsumerState<PanenPenjualanScreen> createState() => _PanenPenjualanScreenState();
}

class _PanenPenjualanScreenState extends ConsumerState<PanenPenjualanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Panen controllers
  final _weightController = TextEditingController();
  final _gradeAController = TextEditingController();
  final _gradeBController = TextEditingController();
  final _gradeCController = TextEditingController();
  final _notesController = TextEditingController();

  // Search state variables
  String _panenSearchQuery = '';
  String _tengkulakSearchQuery = '';
  String _salesSearchQuery = '';

  // Tengkulak controllers
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _buyerAddressController = TextEditingController();
  final _buyerRegionController = TextEditingController();
  final _buyerCommodityController = TextEditingController();

  // Penjualan controllers
  final _salesWeightController = TextEditingController();
  final _salesPriceController = TextEditingController();
  final _priceAController = TextEditingController();
  final _priceBController = TextEditingController();
  final _priceCController = TextEditingController();
  final _amountPaidController = TextEditingController();

  String? _selectedSeasonId;
  String? _selectedBuyerId;
  DateTime _date = DateTime.now();
  String _salesStatus = 'Lunas';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weightController.dispose();
    _gradeAController.dispose();
    _gradeBController.dispose();
    _gradeCController.dispose();
    _notesController.dispose();
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _buyerAddressController.dispose();
    _buyerRegionController.dispose();
    _buyerCommodityController.dispose();
    _salesWeightController.dispose();
    _salesPriceController.dispose();
    _priceAController.dispose();
    _priceBController.dispose();
    _priceCController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }


  double getAlreadyHarvestedPercentage(String seasonId, String? currentHarvestId, List<Panen> harvests) {
    double total = 0.0;
    for (var h in harvests) {
      if (h.seasonId == seasonId && h.id != currentHarvestId) {
        total += h.perkiraanPanen;
      }
    }
    return total;
  }

  void _showGradeBreakdownDialog(BuildContext context, double gA, double gB, double gC) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rincian Berat Per Grade'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Grade A'),
                trailing: Text('${gA.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} Kg'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Grade B'),
                trailing: Text('${gB.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} Kg'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Grade C'),
                trailing: Text('${gC.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} Kg'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            )
          ],
        );
      },
    );
  }

  void _showTengkulakSearchDialog(
      BuildContext context,
      List<Tengkulak> buyers,
      Function(Tengkulak) onSelected,
      Function(String) onAddNew) {
    showDialog(
      context: context,
      builder: (context) {
        String searchQ = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = searchQ.toLowerCase().trim();
            final filtered = buyers.where((b) {
              return b.name.toLowerCase().contains(query);
            }).toList();
            
            final exactMatch = buyers.any((b) => b.name.toLowerCase() == query);

            return AlertDialog(
              title: const Text('Pilih Tengkulak'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Cari nama tengkulak...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchQ = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length + (!exactMatch && searchQ.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filtered.length) {
                            return ListTile(
                              leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                              title: Text('+ Tambah Tengkulak Baru "$searchQ"', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              onTap: () {
                                Navigator.pop(context);
                                onAddNew(searchQ);
                              },
                            );
                          }
                          final buyer = filtered[index];
                          return ListTile(
                            leading: const Icon(Icons.person, color: Colors.grey),
                            title: Text(buyer.name),
                            onTap: () {
                              Navigator.pop(context);
                              onSelected(buyer);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQuickAddTengkulakDialog(
      String initialName,
      StateSetter setDialogState,
      TextEditingController controller,
      Function(String) onBuyerAdded) {
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final quickFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Tengkulak Baru'),
          content: Form(
            key: quickFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Tengkulak'),
                    validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Nomor HP (Opsional)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Alamat (Opsional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!quickFormKey.currentState!.validate()) return;
                
                final newBuyer = Tengkulak(
                  id: '',
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                  region: '',
                  commodityBought: '',
                  notes: '',
                );

                final newId = await ref.read(databaseRepositoryProvider).addBuyer(newBuyer);
                
                if (mounted) {
                  Navigator.pop(context);
                  setDialogState(() {
                    _selectedBuyerId = newId;
                    onBuyerAdded(newId);
                    controller.text = newBuyer.name;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Tengkulak baru berhasil ditambahkan!'),
                    backgroundColor: Colors.green,
                  ));
                }
              },
              child: const Text('Simpan'),
            )
          ],
        );
      },
    );
  }

  void _confirmSelesaikanMusimTanam(MusimTanam season) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Musim Tanam?'),
        content: Text('Apakah Anda yakin ingin menyelesaikan musim tanam "${season.name}"? Setelah diselesaikan, seluruh data musim tanam ini akan dikunci dan tidak dapat diubah kembali.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Musim tanam berhasil diselesaikan & dikunci!'),
                  backgroundColor: Colors.green,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonProgressSection(List<MusimTanam> seasons, List<Panen> harvests, List<Lahan> fields) {
    final activeSeasons = seasons
        .where((s) => s.status == 'Berjalan' || s.status == 'Panen Sebagian' || s.status == 'Panen Selesai')
        .toList();

    if (activeSeasons.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 175,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: activeSeasons.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final season = activeSeasons[index];
          
          final double alreadyHarvested = harvests
              .where((h) => h.seasonId == season.id)
              .fold(0.0, (sum, h) => sum + h.perkiraanPanen);
          final double sisaPanen = (100.0 - alreadyHarvested).clamp(0.0, 100.0);
          final progress = (alreadyHarvested / 100.0).clamp(0.0, 1.0);
          
          final isCompleted = sisaPanen <= 0;
          final statusText = isCompleted ? 'Panen Selesai' : 'Panen Sebagian';
          final badgeColor = isCompleted ? Colors.green[800] : Colors.orange[800];
          final badgeBg = isCompleted ? Colors.green[50] : Colors.orange[50];

          final fieldIds = season.fieldId.split(',').map((e) => e.trim()).toList();
          final seasonFieldNames = fields
              .where((f) => fieldIds.contains(f.id) || fieldIds.contains(f.name))
              .map((f) => f.name)
              .join(', ');

          return Container(
            width: 320,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              elevation: 3,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            season.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeColor!.withOpacity(0.3)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lahan: ${seasonFieldNames.isNotEmpty ? seasonFieldNames : "-"}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sudah: ${alreadyHarvested.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        Text('Sisa: ${sisaPanen.toInt()}%', style: TextStyle(fontSize: 12, color: Colors.orange[900], fontWeight: FontWeight.w500)),
                        const Text('Target: 100%', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[800]!),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isCompleted && season.status != 'Selesai')
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _confirmSelesaikanMusimTanam(season),
                          icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                          label: const Text('Selesaikan Musim Tanam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _resetPanenForm() {
    _weightController.clear();
    _gradeAController.clear();
    _gradeBController.clear();
    _gradeCController.clear();
    _notesController.clear();
    _salesPriceController.clear();
    _salesWeightController.clear();
    _priceAController.clear();
    _priceBController.clear();
    _priceCController.clear();
    _amountPaidController.clear();
    setState(() {
      _selectedSeasonId = null;
      _selectedBuyerId = null;
      _date = DateTime.now();
      _salesStatus = 'Lunas';
    });
  }

  void _resetTengkulakForm() {
    _buyerNameController.clear();
    _buyerPhoneController.clear();
    _buyerAddressController.clear();
    _buyerRegionController.clear();
    _buyerCommodityController.clear();
  }

  void _resetPenjualanForm() {
    _salesWeightController.clear();
    _salesPriceController.clear();
    _amountPaidController.clear();
    setState(() {
      _selectedSeasonId = null;
      _selectedBuyerId = null;
      _date = DateTime.now();
      _salesStatus = 'Lunas';
    });
  }

  void _showPanenDialog(
      List<MusimTanam> seasons,
      List<Lahan> fields,
      List<Tengkulak> buyers,
      List<Panen> harvests,
      List<Tanaman> crops,
      {Panen? harvest}) {
    _resetPanenForm();
    
    String? selectedSeasonId = harvest?.seasonId ?? (seasons.isNotEmpty ? seasons.first.id : null);
    String? selectedFieldId = harvest?.fieldId;
    String inputMethod = 'Pilihan Cepat';
    String? selectedBuyerId = harvest?.buyerId ?? (buyers.isNotEmpty ? buyers.first.id : null);
    DateTime date = harvest?.date ?? DateTime.now();
    double perkiraanPanen = harvest?.perkiraanPanen ?? 0.0;
    String salesStatus = 'Lunas';
    
    if (harvest != null) {
      _weightController.text = harvest.weight.toString();
      final gA = harvest.beratGradeA > 0 ? harvest.beratGradeA : harvest.gradeAWeight;
      final gB = harvest.beratGradeB > 0 ? harvest.beratGradeB : harvest.gradeBWeight;
      final gC = harvest.beratGradeC > 0 ? harvest.beratGradeC : harvest.gradeCWeight;
      _gradeAController.text = gA == gA.toInt() ? gA.toInt().toString() : gA.toString();
      _gradeBController.text = gB == gB.toInt() ? gB.toInt().toString() : gB.toString();
      _gradeCController.text = gC == gC.toInt() ? gC.toInt().toString() : gC.toString();
      _notesController.text = harvest.notes;
      _priceAController.text = harvest.priceGradeA?.toString() ?? '';
      _priceBController.text = harvest.priceGradeB?.toString() ?? '';
      _priceCController.text = harvest.priceGradeC?.toString() ?? '';
      date = harvest.date;
      perkiraanPanen = harvest.perkiraanPanen;
      
      if (perkiraanPanen == 25.0 || perkiraanPanen == 50.0 || perkiraanPanen == 75.0 || perkiraanPanen == 100.0) {
        inputMethod = 'Pilihan Cepat';
      } else {
        inputMethod = 'Persentase Manual';
      }
    } else {
      _weightController.text = '0';
      _gradeAController.text = '0';
      _gradeBController.text = '0';
      _gradeCController.text = '0';
      perkiraanPanen = 0.0;
    }

    final TextEditingController buyerSearchController = TextEditingController();
    if (selectedBuyerId != null) {
      final b = buyers.firstWhere((element) => element.id == selectedBuyerId, orElse: () => Tengkulak(id: '', name: '', phone: '', address: '', region: '', commodityBought: '', notes: ''));
      buyerSearchController.text = b.name;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedSeason = seasons.firstWhere((s) => s.id == selectedSeasonId, orElse: () => seasons.first);
            
            final alreadyHarvested = getAlreadyHarvestedPercentage(selectedSeason.id, harvest?.id, harvests);
            final sisaPanen = (100.0 - alreadyHarvested).clamp(0.0, 100.0);

            final List<double> quickOptions = [];
            if (sisaPanen >= 25.0) quickOptions.add(25.0);
            if (sisaPanen >= 50.0) quickOptions.add(50.0);
            if (sisaPanen >= 75.0) quickOptions.add(75.0);
            if (sisaPanen >= 100.0) quickOptions.add(100.0);

            final fieldIds = selectedSeason.fieldId.split(',').map((id) => id.trim()).toList();
            final seasonFields = fields.where((f) => fieldIds.contains(f.id) || fieldIds.contains(f.name)).toList();
            if (seasonFields.isEmpty) {
              seasonFields.add(Lahan(id: selectedSeason.fieldId, name: selectedSeason.fieldId, area: 0, unit: 'm²', locationGps: '', address: '', soilType: '', status: '', waterSource: '', notes: ''));
            }

            if (selectedFieldId == null || !seasonFields.any((f) => f.id == selectedFieldId)) {
              selectedFieldId = seasonFields.first.id;
            }


            final gradeA = double.tryParse(_gradeAController.text) ?? 0.0;
            final gradeB = double.tryParse(_gradeBController.text) ?? 0.0;
            final gradeC = double.tryParse(_gradeCController.text) ?? 0.0;
            final totalWeight = gradeA + gradeB + gradeC;



            final isOverLimit = perkiraanPanen > sisaPanen;
            final canSave = !isOverLimit && perkiraanPanen > 0 && totalWeight > 0 && selectedBuyerId != null;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 20, right: 20),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Catat Hasil Panen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      
                      DropdownButtonFormField<String>(
                        value: selectedSeasonId,
                        decoration: const InputDecoration(labelText: 'Musim Tanam', prefixIcon: Icon(Icons.spa)),
                        items: seasons.where((s) => s.status != 'Selesai' || s.id == selectedSeasonId).map((s) {
                          return DropdownMenuItem(value: s.id, child: Text(s.name));
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedSeasonId = val;
                            selectedFieldId = null;
                          });
                        },
                        validator: (value) => value == null ? 'Musim tanam wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: selectedFieldId,
                        decoration: const InputDecoration(labelText: 'Pilih Lahan', prefixIcon: Icon(Icons.location_on)),
                        items: seasonFields.map((f) {
                          return DropdownMenuItem(value: f.id, child: Text(f.name));
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedFieldId = val;
                          });
                        },
                        validator: (value) => value == null ? 'Lahan wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),

                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Tanggal Panen: ${Formatters.formatLongDate(date)}'),
                        onPressed: () async {
                          final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (d != null) {
                            setDialogState(() => date = d);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan Progres Panen Musim Ini',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Sudah Dipanen: ${alreadyHarvested.toInt()}%'),
                                Text('Sisa Panen: ${sisaPanen.toInt()}%', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)),
                                const Text('Target: 100%'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (alreadyHarvested + perkiraanPanen) / 100.0,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(isOverLimit ? Colors.red : Colors.green),
                              ),
                            ),
                            if (perkiraanPanen > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Rencana Input Kali Ini: +$perkiraanPanen% (Total: ${(alreadyHarvested + perkiraanPanen).toStringAsFixed(1)}%)',
                                style: TextStyle(color: isOverLimit ? Colors.red : Colors.green[800], fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('Metode Input Panen:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Pilihan Cepat', style: TextStyle(fontSize: 12)),
                              selected: inputMethod == 'Pilihan Cepat',
                              selectedColor: Colors.green[800],
                              labelStyle: TextStyle(
                                color: inputMethod == 'Pilihan Cepat' ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() {
                                    inputMethod = 'Pilihan Cepat';
                                    if (quickOptions.isNotEmpty) {
                                      perkiraanPanen = quickOptions.first;
                                    } else {
                                      perkiraanPanen = 0.0;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Persentase Manual', style: TextStyle(fontSize: 12)),
                              selected: inputMethod == 'Persentase Manual',
                              selectedColor: Colors.green[800],
                              labelStyle: TextStyle(
                                color: inputMethod == 'Persentase Manual' ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() {
                                    inputMethod = 'Persentase Manual';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (inputMethod == 'Pilihan Cepat') ...[
                        if (quickOptions.isEmpty)
                          const Text('Sisa panen kurang dari 25%. Silakan gunakan Persentase Manual.', style: TextStyle(color: Colors.orange, fontSize: 12))
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: quickOptions.map((opt) {
                              final isSelected = perkiraanPanen == opt;
                              return ChoiceChip(
                                label: Text('${opt.toInt()}%'),
                                selected: isSelected,
                                selectedColor: Colors.green[800],
                                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                                onSelected: (sel) {
                                  if (sel) {
                                    setDialogState(() {
                                      perkiraanPanen = opt;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                      ] else if (inputMethod == 'Persentase Manual') ...[
                        TextFormField(
                          initialValue: perkiraanPanen > 0 ? perkiraanPanen.toString() : '',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Persentase Panen (%)', prefixIcon: Icon(Icons.percent)),
                          onChanged: (val) {
                            setDialogState(() {
                              perkiraanPanen = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                      ],

                      if (isOverLimit) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Persentase panen melebihi sisa panen yang tersedia.\nSisa panen saat ini: ${sisaPanen.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}%',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 12),

                      const Text('Grade Panen:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gradeAController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Grade A (Kg)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                              onTap: () {
                                if (_gradeAController.text == '0') _gradeAController.clear();
                              },
                              onChanged: (val) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _gradeBController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Grade B (Kg)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                              onTap: () {
                                if (_gradeBController.text == '0') _gradeBController.clear();
                              },
                              onChanged: (val) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _gradeCController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Grade C (Kg)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                              onTap: () {
                                if (_gradeCController.text == '0') _gradeCController.clear();
                              },
                              onChanged: (val) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: () {
                          _showGradeBreakdownDialog(context, gradeA, gradeB, gradeC);
                        },
                        child: Card(
                          color: Colors.green[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.green[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Berat (Otomatis)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${totalWeight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} Kg',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[900]),
                                    ),
                                  ],
                                ),
                                Icon(Icons.info_outline, color: Colors.green[800]),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 32),

                      const Text('Tengkulak / Pembeli:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: buyerSearchController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Tengkulak',
                          prefixIcon: Icon(Icons.handshake),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        onTap: () {
                          _showTengkulakSearchDialog(
                            context,
                            buyers,
                            (Tengkulak selection) {
                              setDialogState(() {
                                selectedBuyerId = selection.id;
                                buyerSearchController.text = selection.name;
                              });
                            },
                            (String nameQ) {
                              _showQuickAddTengkulakDialog(
                                nameQ,
                                setDialogState,
                                buyerSearchController,
                                (newId) {
                                  selectedBuyerId = newId;
                                },
                              );
                            },
                          );
                        },
                        validator: (value) {
                          if (selectedBuyerId == null || selectedBuyerId!.isEmpty) {
                            return 'Tengkulak wajib dipilih';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      if (gradeA > 0) ...[
                        TextFormField(
                          controller: _priceAController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Grade A per Kg (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
                          onTap: () {
                            if (_priceAController.text == '0') _priceAController.clear();
                          },
                          validator: (value) => (value == null || value.isEmpty) ? 'Harga Grade A wajib diisi' : null,
                          onChanged: (val) => setDialogState(() {}),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (gradeB > 0) ...[
                        TextFormField(
                          controller: _priceBController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Grade B per Kg (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
                          onTap: () {
                            if (_priceBController.text == '0') _priceBController.clear();
                          },
                          validator: (value) => (value == null || value.isEmpty) ? 'Harga Grade B wajib diisi' : null,
                          onChanged: (val) => setDialogState(() {}),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (gradeC > 0) ...[
                        TextFormField(
                          controller: _priceCController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Grade C per Kg (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
                          onTap: () {
                            if (_priceCController.text == '0') _priceCController.clear();
                          },
                          validator: (value) => (value == null || value.isEmpty) ? 'Harga Grade C wajib diisi' : null,
                          onChanged: (val) => setDialogState(() {}),
                        ),
                        const SizedBox(height: 12),
                      ],

                      DropdownButtonFormField<String>(
                        value: salesStatus,
                        decoration: const InputDecoration(labelText: 'Status Pembayaran', prefixIcon: Icon(Icons.check_circle_outline)),
                        items: const [
                          DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
                          DropdownMenuItem(value: 'Belum Lunas', child: Text('Belum Lunas')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              salesStatus = val;
                              if (val == 'Lunas') _amountPaidController.clear();
                            });
                          }
                        },
                      ),
                      if (salesStatus == 'Belum Lunas') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountPaidController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Nominal yang Dibayar (Rp)', prefixIcon: Icon(Icons.price_check)),
                          onTap: () {
                            if (_amountPaidController.text == '0') _amountPaidController.clear();
                          },
                          validator: (value) => salesStatus == 'Belum Lunas' && (value == null || value.isEmpty) ? 'Nominal dibayar wajib diisi' : null,
                        ),
                      ],
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Catatan Panen', prefixIcon: Icon(Icons.note_alt_outlined)),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pendapatan:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Builder(
                              builder: (context) {
                                final priceA = double.tryParse(_priceAController.text) ?? 0.0;
                                final priceB = double.tryParse(_priceBController.text) ?? 0.0;
                                final priceC = double.tryParse(_priceCController.text) ?? 0.0;
                                final totalSales = (gradeA * priceA) + (gradeB * priceB) + (gradeC * priceC);
                                return Text(
                                  Formatters.formatRupiah(totalSales),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: canSave
                            ? () async {
                                if (!_formKey.currentState!.validate()) return;
                                
                                final buyer = buyers.firstWhere((b) => b.id == selectedBuyerId);
                                final priceA = double.tryParse(_priceAController.text) ?? 0.0;
                                final priceB = double.tryParse(_priceBController.text) ?? 0.0;
                                final priceC = double.tryParse(_priceCController.text) ?? 0.0;
                                final totalSales = (gradeA * priceA) + (gradeB * priceB) + (gradeC * priceC);
                                final averagePrice = totalWeight > 0 ? (totalSales / totalWeight) : 0.0;

                                final finalSisa = sisaPanen - perkiraanPanen;
                                final newSeasonStatus = finalSisa <= 0.0 ? 'Panen Selesai' : 'Panen Sebagian';
                                
                                final updatedSeason = MusimTanam(
                                  id: selectedSeason.id,
                                  name: selectedSeason.name,
                                  fieldId: selectedSeason.fieldId,
                                  cropId: selectedSeason.cropId,
                                  variety: selectedSeason.variety,
                                  plantingArea: selectedSeason.plantingArea,
                                  seedsCount: selectedSeason.seedsCount,
                                  seedingDate: selectedSeason.seedingDate,
                                  plantingDate: selectedSeason.plantingDate,
                                  status: newSeasonStatus,
                                  jenisTanam: selectedSeason.jenisTanam,
                                );
                                await ref.read(databaseRepositoryProvider).updateSeason(updatedSeason);

                                final selectedLahan = seasonFields.firstWhere((f) => f.id == selectedFieldId, orElse: () => seasonFields.first);

                                final data = Panen(
                                  id: harvest?.id ?? '',
                                  seasonId: selectedSeasonId!,
                                  fieldId: selectedFieldId!,
                                  fieldName: selectedLahan.name,
                                  date: date,
                                  weight: totalWeight,
                                  gradeAWeight: gradeA,
                                  gradeBWeight: gradeB,
                                  gradeCWeight: gradeC,
                                  beratGradeA: gradeA,
                                  beratGradeB: gradeB,
                                  beratGradeC: gradeC,
                                  fruitsCount: 0,
                                  notes: _notesController.text.trim(),
                                  buyerId: buyer.id,
                                  buyerName: buyer.name,
                                  pricePerKg: averagePrice,
                                  totalPrice: totalSales,
                                  perkiraanPanen: perkiraanPanen,
                                  statusPeriode: finalSisa <= 0.0 ? 'Selesai' : 'Aktif',
                                  priceGradeA: priceA > 0 ? priceA : null,
                                  priceGradeB: priceB > 0 ? priceB : null,
                                  priceGradeC: priceC > 0 ? priceC : null,
                                );

                                if (harvest != null) {
                                  await ref.read(databaseRepositoryProvider).updateHarvest(data);
                                } else {
                                  await ref.read(databaseRepositoryProvider).addHarvest(data);
                                  
                                  double paid = totalSales;
                                  if (salesStatus == 'Belum Lunas') {
                                    paid = double.tryParse(_amountPaidController.text) ?? 0.0;
                                  }
                                  
                                  final saleData = Penjualan(
                                    id: '',
                                    date: date,
                                    buyerId: buyer.id,
                                    buyerName: buyer.name,
                                    seasonId: selectedSeasonId!,
                                    seasonName: selectedSeason.name,
                                    weight: totalWeight,
                                    pricePerKg: averagePrice,
                                    totalPrice: totalSales,
                                    status: salesStatus,
                                    amountPaid: paid,
                                    remainingDebt: totalSales - paid,
                                    priceGradeA: priceA > 0 ? priceA : null,
                                    priceGradeB: priceB > 0 ? priceB : null,
                                    priceGradeC: priceC > 0 ? priceC : null,
                                  );
                                  await ref.read(databaseRepositoryProvider).addSale(saleData);
                                }

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(harvest != null ? 'Data Panen berhasil diperbarui!' : 'Data Panen & Penjualan berhasil disimpan!'),
                                    backgroundColor: Colors.green,
                                  ));
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Simpan Data Panen & Penjualan', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showTengkulakDialog({Tengkulak? buyer}) {
    _resetTengkulakForm();
    if (buyer != null) {
      _buyerNameController.text = buyer.name;
      _buyerPhoneController.text = buyer.phone;
      _buyerAddressController.text = buyer.address;
      _buyerRegionController.text = buyer.region;
      _buyerCommodityController.text = buyer.commodityBought;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(buyer != null ? 'Edit Tengkulak / Pembeli' : 'Tambah Tengkulak / Pembeli'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _buyerNameController,
                    decoration: const InputDecoration(labelText: 'Nama Pembeli'),
                    validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _buyerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Nomor WhatsApp'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _buyerAddressController,
                    decoration: const InputDecoration(labelText: 'Alamat lengkap'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _buyerRegionController,
                    decoration: const InputDecoration(labelText: 'Wilayah Distribusi (e.g. Jakarta, Solo)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _buyerCommodityController,
                    decoration: const InputDecoration(labelText: 'Komoditas Utama (e.g. Melon Golden)'),
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
                
                final data = Tengkulak(
                  id: buyer?.id ?? '',
                  name: _buyerNameController.text.trim(),
                  phone: _buyerPhoneController.text.trim(),
                  address: _buyerAddressController.text.trim(),
                  region: _buyerRegionController.text.trim(),
                  commodityBought: _buyerCommodityController.text.trim(),
                  notes: buyer?.notes ?? '',
                );

                if (buyer != null) {
                  await ref.read(databaseRepositoryProvider).updateBuyer(data);
                } else {
                  await ref.read(databaseRepositoryProvider).addBuyer(data);
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(buyer != null ? 'Data tengkulak berhasil diperbarui!' : 'Pembeli berhasil disimpan!'),
                    backgroundColor: Colors.green,
                  ));
                }
              },
              child: const Text('Simpan'),
            )
          ],
        );
      },
    );
  }

  void _showPenjualanDialog(List<MusimTanam> seasons, List<Tengkulak> buyers, List<Lahan> fields, {Penjualan? sale}) {
    _resetPenjualanForm();
    if (sale != null) {
      _selectedSeasonId = sale.seasonId;
      _selectedBuyerId = sale.buyerId;
      _salesWeightController.text = sale.weight.toString();
      _salesPriceController.text = sale.pricePerKg.toString();
      _salesStatus = sale.status;
      _amountPaidController.text = sale.amountPaid == sale.amountPaid.toInt() ? sale.amountPaid.toInt().toString() : sale.amountPaid.toString();
      _date = sale.date;
    } else {
      if (seasons.isNotEmpty) _selectedSeasonId = seasons.first.id;
      if (buyers.isNotEmpty) _selectedBuyerId = buyers.first.id;
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
                      Text(sale != null ? 'Edit Transaksi Penjualan' : 'Catat Transaksi Penjualan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedSeasonId,
                        decoration: const InputDecoration(labelText: 'Pilih Musim Tanam / Lahan', prefixIcon: Icon(Icons.spa)),
                        items: seasons.where((s) => s.status != 'Selesai' || s.id == _selectedSeasonId).map((s) {
                          final field = fields.firstWhere(
                            (f) => f.id == s.fieldId,
                            orElse: () => Lahan(id: '', name: 'Umum', area: 0, unit: 'm²', locationGps: '', address: '', soilType: '', status: '', waterSource: '', notes: ''),
                          );
                          return DropdownMenuItem(value: s.id, child: Text("${s.name} (Lahan: ${field.name})"));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => _selectedSeasonId = val),
                        validator: (value) => value == null ? 'Musim tanam wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedBuyerId,
                        decoration: const InputDecoration(labelText: 'Pilih Pembeli / Tengkulak', prefixIcon: Icon(Icons.person)),
                        items: buyers.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedBuyerId = val),
                        validator: (value) => value == null ? 'Pembeli wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _salesWeightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Berat Terjual (Kg)', prefixIcon: Icon(Icons.scale)),
                              onTap: () {
                                if (_salesWeightController.text == '0') {
                                  _salesWeightController.clear();
                                }
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Berat wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _salesPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Harga per Kg (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
                              onTap: () {
                                if (_salesPriceController.text == '0') {
                                  _salesPriceController.clear();
                                }
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Harga wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _salesStatus,
                        decoration: const InputDecoration(labelText: 'Status Pembayaran', prefixIcon: Icon(Icons.check_circle_outline)),
                        items: const [
                          DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
                          DropdownMenuItem(value: 'Belum Lunas', child: Text('Belum Lunas')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              _salesStatus = val;
                              if (val == 'Lunas') _amountPaidController.clear();
                            });
                          }
                        },
                      ),
                      if (_salesStatus == 'Belum Lunas') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountPaidController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Nominal yang Dibayar (Rp)', prefixIcon: Icon(Icons.price_check)),
                          onTap: () {
                            if (_amountPaidController.text == '0') {
                              _amountPaidController.clear();
                            }
                          },
                          validator: (value) => value == null || value.isEmpty ? 'Nominal dibayar wajib diisi' : null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Tanggal Transaksi: ${Formatters.formatDate(_date)}'),
                        onPressed: () async {
                          final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (d != null) {
                            setDialogState(() => _date = d);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          
                          final season = seasons.firstWhere((s) => s.id == _selectedSeasonId);
                          final buyer = buyers.firstWhere((b) => b.id == _selectedBuyerId);
                          final weight = double.tryParse(_salesWeightController.text) ?? 0.0;
                          final price = double.tryParse(_salesPriceController.text) ?? 0.0;
                          final total = weight * price;
                          
                          double paid = total;
                          if (_salesStatus == 'Belum Lunas') {
                            paid = double.tryParse(_amountPaidController.text) ?? 0.0;
                          }

                          final data = Penjualan(
                            id: sale?.id ?? '',
                            date: _date,
                            buyerId: _selectedBuyerId!,
                            buyerName: buyer.name,
                            seasonId: _selectedSeasonId!,
                            seasonName: season.name,
                            weight: weight,
                            pricePerKg: price,
                            totalPrice: total,
                            status: _salesStatus,
                            amountPaid: paid,
                            remainingDebt: total - paid,
                            priceGradeA: sale?.priceGradeA,
                            priceGradeB: sale?.priceGradeB,
                            priceGradeC: sale?.priceGradeC,
                          );

                          if (sale != null) {
                            await ref.read(databaseRepositoryProvider).updateSale(data);
                          } else {
                            await ref.read(databaseRepositoryProvider).addSale(data);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(sale != null ? 'Transaksi Penjualan berhasil diperbarui!' : 'Transaksi Penjualan berhasil disimpan!'),
                              backgroundColor: Colors.green,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: Text(sale != null ? 'Simpan Perubahan Penjualan' : 'Simpan Penjualan', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void _confirmDeletePanen(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan Panen'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan hasil panen ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(databaseRepositoryProvider).deleteHarvest(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan panen berhasil dihapus'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBuyer(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Tengkulak'),
        content: const Text('Apakah Anda yakin ingin menghapus data tengkulak ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(databaseRepositoryProvider).deleteBuyer(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data tengkulak berhasil dihapus'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSale(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi Penjualan'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi penjualan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(databaseRepositoryProvider).deleteSale(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi penjualan berhasil dihapus'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seasonsState = ref.watch(watchSeasonsProvider);
    final buyersState = ref.watch(watchBuyersProvider);
    final harvestsState = ref.watch(watchHarvestsProvider);
    final salesState = ref.watch(watchSalesProvider);
    final fieldsState = ref.watch(watchFieldsProvider);
    final cropsState = ref.watch(watchCropsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panen & Penjualan'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Panen'),
            Tab(icon: Icon(Icons.people_outline), text: 'Tengkulak'),
            Tab(icon: Icon(Icons.monetization_on_outlined), text: 'Penjualan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: PANEN
          harvestsState.when(
            data: (harvests) {
              final query = _panenSearchQuery.toLowerCase();
              final filteredHarvests = harvests.where((h) {
                if (query.isEmpty) return true;
                final season = seasonsState.value?.firstWhere(
                  (s) => s.id == h.seasonId,
                  orElse: () => MusimTanam(id: '', name: '', fieldId: '', cropId: '', variety: '', plantingArea: 0, seedsCount: 0, seedingDate: DateTime.now(), plantingDate: DateTime.now(), status: ''),
                );
                final field = fieldsState.value?.firstWhere(
                  (f) => f.id == season?.fieldId,
                  orElse: () => Lahan(id: '', name: '', area: 0, unit: '', locationGps: '', address: '', soilType: '', status: '', waterSource: '', notes: ''),
                );
                final lahanName = field?.name.toLowerCase() ?? '';
                final buyerName = h.buyerName?.toLowerCase() ?? '';
                final seasonName = season?.name.toLowerCase() ?? '';
                return lahanName.contains(query) || buyerName.contains(query) || seasonName.contains(query);
              }).toList();

              return Column(
                children: [
                  _buildSeasonProgressSection(seasonsState.value ?? [], harvests, fieldsState.value ?? []),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Cari Panen (Tengkulak / Lahan)...',
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _panenSearchQuery = val;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredHarvests.isEmpty
                        ? const Center(child: Text('Belum ada catatan panen yang cocok.'))
                        : ListView.builder(
                            itemCount: filteredHarvests.length,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemBuilder: (context, index) {
                              final h = filteredHarvests[index];
                              final season = seasonsState.value?.firstWhere((s) => s.id == h.seasonId, orElse: () => MusimTanam(id: '', name: 'Musim Tanam', fieldId: '', cropId: '', variety: '', plantingArea: 0, seedsCount: 0, seedingDate: DateTime.now(), plantingDate: DateTime.now(), status: ''));
                              final seasonName = season?.name ?? 'Musim Tanam';
                              final field = fieldsState.value?.firstWhere((f) => f.id == season?.fieldId, orElse: () => Lahan(id: '', name: '-', area: 0, unit: '', locationGps: '', address: '', soilType: '', status: '', waterSource: '', notes: ''));
                              final lahanName = field?.name ?? '-';
                              
                              return Card(
                                elevation: 2,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text("$seasonName (Lahan: $lahanName)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                          ),
                                          Text(Formatters.formatLongDate(h.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(width: 8),
                                          Builder(
                                            builder: (context) {
                                              final hSeason = seasonsState.value?.firstWhere(
                                                (se) => se.id == h.seasonId,
                                                orElse: () => MusimTanam(id: '', name: '', fieldId: '', cropId: '', variety: '', plantingArea: 0, seedsCount: 0, seedingDate: DateTime.now(), plantingDate: DateTime.now(), status: ''),
                                              );
                                              final hSeasonCompleted = hSeason?.status == 'Selesai';
                                              if (hSeasonCompleted) {
                                                return const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                                  child: Text('Musim Selesai', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                                                );
                                              }
                                              return PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert, size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _showPanenDialog(seasonsState.value ?? [], fieldsState.value ?? [], buyersState.value ?? [], harvestsState.value ?? [], cropsState.value ?? [], harvest: h);
                                                  } else if (value == 'delete') {
                                                    _confirmDeletePanen(h.id);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                                                ],
                                              );
                                            }
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: () => _showGradeBreakdownBottomSheet(h),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.green[200]!),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.scale, size: 14, color: Colors.green),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Total Berat: ${h.weight} Kg ⓘ',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green[900],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Progress: ${h.perkiraanPanen.toInt()}% (${h.statusPeriode})',
                                            style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          if (h.beratGradeA > 0 || (h.beratGradeA == 0 && h.beratGradeB == 0 && h.beratGradeC == 0))
                                            _buildGradeLabel('Grade A: ${h.beratGradeA} kg${h.priceGradeA != null && h.priceGradeA! > 0 ? " • ${Formatters.formatRupiah(h.priceGradeA!)}" : ""}'),
                                          if (h.beratGradeB > 0)
                                            _buildGradeLabel('Grade B: ${h.beratGradeB} kg${h.priceGradeB != null && h.priceGradeB! > 0 ? " • ${Formatters.formatRupiah(h.priceGradeB!)}" : ""}'),
                                          if (h.beratGradeC > 0)
                                            _buildGradeLabel('Grade C: ${h.beratGradeC} kg${h.priceGradeC != null && h.priceGradeC! > 0 ? " • ${Formatters.formatRupiah(h.priceGradeC!)}" : ""}'),
                                        ],
                                      ),
                                      if (h.buyerName != null && h.buyerName!.isNotEmpty) ...[
                                        const Divider(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.handshake_outlined, size: 16, color: Colors.orange[800]),
                                                const SizedBox(width: 4),
                                                Text('Terjual ke: ${h.buyerName}', style: TextStyle(color: Colors.orange[900], fontSize: 12, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                            Text(
                                              'Rp ${Formatters.formatRupiah(h.totalPrice ?? 0.0)}',
                                              style: TextStyle(color: Colors.green[800], fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (h.notes.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text('Catatan: ${h.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                                      ]
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

          // TAB 2: TENGKULAK
          buyersState.when(
            data: (buyers) {
              final query = _tengkulakSearchQuery.toLowerCase();
              final filteredBuyers = buyers.where((b) {
                if (query.isEmpty) return true;
                return b.name.toLowerCase().contains(query) ||
                    b.region.toLowerCase().contains(query) ||
                    b.commodityBought.toLowerCase().contains(query);
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Cari Tengkulak...',
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _tengkulakSearchQuery = val;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredBuyers.isEmpty
                        ? const Center(child: Text('Belum ada data tengkulak yang cocok.'))
                        : ListView.builder(
                            itemCount: filteredBuyers.length,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemBuilder: (context, index) {
                              final b = filteredBuyers[index];
                              return Card(
                                elevation: 2,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.green[50], 
                                    child: Icon(Icons.person, color: Colors.green[800])
                                  ),
                                  title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'WhatsApp: ${b.phone}\nWilayah: ${b.region} • Beli: ${b.commodityBought}',
                                      style: TextStyle(color: Colors.grey[600], height: 1.3),
                                    ),
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showTengkulakDialog(buyer: b);
                                      } else if (value == 'delete') {
                                        _confirmDeleteBuyer(b.id);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
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

          // TAB 3: PENJUALAN
          salesState.when(
            data: (sales) {
              final query = _salesSearchQuery.toLowerCase();
              final filteredSales = sales.where((s) {
                if (query.isEmpty) return true;
                final season = seasonsState.value?.firstWhere(
                  (se) => se.id == s.seasonId,
                  orElse: () => MusimTanam(id: '', name: '', fieldId: '', cropId: '', variety: '', plantingArea: 0, seedsCount: 0, seedingDate: DateTime.now(), plantingDate: DateTime.now(), status: ''),
                );
                final field = fieldsState.value?.firstWhere(
                  (f) => f.id == season?.fieldId,
                  orElse: () => Lahan(id: '', name: '', area: 0, unit: '', locationGps: '', address: '', soilType: '', status: '', waterSource: '', notes: ''),
                );
                final lahanName = field?.name.toLowerCase() ?? '';
                final buyerName = s.buyerName.toLowerCase();
                final seasonName = s.seasonName.toLowerCase();
                final docId = s.id.toLowerCase();
                return lahanName.contains(query) || buyerName.contains(query) || seasonName.contains(query) || docId.contains(query);
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Cari Penjualan (Tengkulak / Lahan / ID)...',
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _salesSearchQuery = val;
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
                              value: ref.watch(salesFilterProvider),
                              icon: const Icon(Icons.sort),
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(salesFilterProvider.notifier).state = val;
                                }
                              },
                              items: const [
                                DropdownMenuItem(value: 'date_desc', child: Text('Terbaru')),
                                DropdownMenuItem(value: 'date_asc', child: Text('Terlama')),
                                DropdownMenuItem(value: 'price_desc', child: Text('Nominal Terbesar')),
                                DropdownMenuItem(value: 'price_asc', child: Text('Nominal Terkecil')),
                                DropdownMenuItem(value: 'weight_desc', child: Text('Berat Terbesar')),
                                DropdownMenuItem(value: 'weight_asc', child: Text('Berat Terkecil')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredSales.isEmpty
                        ? const Center(child: Text('Belum ada transaksi penjualan yang cocok.'))
                        : ListView.builder(
                            itemCount: filteredSales.length,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemBuilder: (context, index) {
                              final s = filteredSales[index];
                              final isLunas = s.status == 'Lunas';

                              return Card(
                                elevation: 2,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(s.buyerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isLunas ? Colors.green[50] : Colors.red[50],
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(s.status, style: TextStyle(color: isLunas ? Colors.green[800] : Colors.red[800], fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 8),
                                              Builder(
                                                builder: (context) {
                                                  final sSeason = seasonsState.value?.firstWhere(
                                                    (se) => se.id == s.seasonId,
                                                    orElse: () => MusimTanam(id: '', name: '', fieldId: '', cropId: '', variety: '', plantingArea: 0, seedsCount: 0, seedingDate: DateTime.now(), plantingDate: DateTime.now(), status: ''),
                                                  );
                                                  final sSeasonCompleted = sSeason?.status == 'Selesai';
                                                  if (sSeasonCompleted) {
                                                    return const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                                                      child: Text('Musim Selesai', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                                                    );
                                                  }
                                                  return PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_vert, size: 20),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onSelected: (value) {
                                                      if (value == 'edit') {
                                                        _showPenjualanDialog(seasonsState.value ?? [], buyersState.value ?? [], fieldsState.value ?? [], sale: s);
                                                      } else if (value == 'delete') {
                                                        _confirmDeleteSale(s.id);
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                                                    ],
                                                  );
                                                }
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Builder(
                                        builder: (context) {
                                          final season = seasonsState.value?.firstWhere((se) => se.id == s.seasonId, orElse: () => MusimTanam(id: '', name: 'Musim', fieldId: '', cropId: '', variety: '', plantingArea: 0, seedsCount: 0, seedingDate: DateTime.now(), plantingDate: DateTime.now(), status: ''));
                                          final field = fieldsState.value?.firstWhere((f) => f.id == season?.fieldId, orElse: () => Lahan(id: '', name: '-', area: 0, unit: '', locationGps: '', address: '', soilType: '', status: '', waterSource: '', notes: ''));
                                          final lahanName = field?.name ?? '-';
                                          return Text('Lahan: $lahanName | Musim: ${s.seasonName} | Tanggal: ${Formatters.formatLongDate(s.date)}', style: const TextStyle(fontSize: 12, color: Colors.grey));
                                        }
                                      ),
                                      const Divider(height: 18),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Jumlah: ${s.weight} Kg • ${Formatters.formatRupiah(s.pricePerKg)}/Kg'),
                                          Text(Formatters.formatRupiah(s.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                                        ],
                                      ),
                                      if (s.priceGradeA != null || s.priceGradeB != null || s.priceGradeC != null) ...[
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            if (s.priceGradeA != null && s.priceGradeA! > 0)
                                              _buildGradeLabel('A: ${Formatters.formatRupiah(s.priceGradeA!)}/Kg'),
                                            if (s.priceGradeB != null && s.priceGradeB! > 0)
                                              _buildGradeLabel('B: ${Formatters.formatRupiah(s.priceGradeB!)}/Kg'),
                                            if (s.priceGradeC != null && s.priceGradeC! > 0)
                                              _buildGradeLabel('C: ${Formatters.formatRupiah(s.priceGradeC!)}/Kg'),
                                          ],
                                        ),
                                      ],
                                      if (!isLunas) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Dibayar: ${Formatters.formatRupiah(s.amountPaid)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            Text('Piutang: ${Formatters.formatRupiah(s.remainingDebt)}', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                                          ],
                                        )
                                      ],
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final seasons = seasonsState.value ?? [];
          final buyers = buyersState.value ?? [];
          final fields = fieldsState.value ?? [];
          final harvests = harvestsState.value ?? [];
          final crops = cropsState.value ?? [];

          if (_tabController.index == 0) {
            if (seasons.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap buat musim tanam terlebih dahulu!'), backgroundColor: Colors.red));
              return;
            }
            if (buyers.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap tambah data tengkulak / pembeli terlebih dahulu!'), backgroundColor: Colors.red));
              return;
            }
            _showPanenDialog(seasons, fields, buyers, harvests, crops);
          } else if (_tabController.index == 1) {
            _showTengkulakDialog();
          } else {
            if (seasons.isEmpty || buyers.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Musim Tanam dan Data Tengkulak wajib diisi terlebih dahulu!'), backgroundColor: Colors.red));
              return;
            }
            _showPenjualanDialog(seasons, buyers, fields);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGradeLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: Colors.green[800], fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showGradeBreakdownBottomSheet(Panen h) {
    final gA = h.beratGradeA > 0 ? h.beratGradeA : h.gradeAWeight;
    final gB = h.beratGradeB > 0 ? h.beratGradeB : h.gradeBWeight;
    final gC = h.beratGradeC > 0 ? h.beratGradeC : h.gradeCWeight;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Rincian Berat Per Grade',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildGradeBreakdownRow('Grade A', gA, h.priceGradeA),
              const Divider(height: 16),
              _buildGradeBreakdownRow('Grade B', gB, h.priceGradeB),
              const Divider(height: 16),
              _buildGradeBreakdownRow('Grade C', gC, h.priceGradeC),
              const Divider(height: 24, thickness: 1.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Berat:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${h.weight} Kg',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pendapatan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    Formatters.formatRupiah(h.totalPrice ?? 0.0),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeBreakdownRow(String label, double weight, double? price) {
    final hasPrice = price != null && price > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (hasPrice)
              Text(
                'Harga: ${Formatters.formatRupiah(price)}/Kg',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$weight Kg',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (hasPrice)
              Text(
                Formatters.formatRupiah(weight * price),
                style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ],
    );
  }
}
