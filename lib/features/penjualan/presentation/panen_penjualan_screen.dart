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
  double _perkiraanPanen = 25.0;

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
  String _gradeMode = 'A';

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
      _gradeMode = 'A';
      _salesStatus = 'Lunas';
      _perkiraanPanen = 25.0;
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



  void _showPanenDialog(List<MusimTanam> seasons, List<Lahan> fields, List<Tengkulak> buyers, {Panen? harvest}) {
    _resetPanenForm();
    if (harvest != null) {
      _selectedSeasonId = harvest.seasonId;
      _selectedBuyerId = harvest.buyerId;
      _weightController.text = harvest.weight.toString();
      // Menggunakan field baru beratGradeA/B/C dengan fallback untuk data lama
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
      _date = harvest.date;
      _perkiraanPanen = harvest.perkiraanPanen;
      
      // Determine grade mode based on values
      if (gA > 0 && gB == 0 && gC == 0) {
        _gradeMode = 'A';
      } else if (gB > 0 && gA == 0 && gC == 0) {
        _gradeMode = 'B';
      } else if (gC > 0 && gA == 0 && gB == 0) {
        _gradeMode = 'C';
      } else {
        _gradeMode = 'Custom';
      }
    } else {
      if (seasons.isNotEmpty) {
        _selectedSeasonId = seasons.first.id;
      }
      if (buyers.isNotEmpty) _selectedBuyerId = buyers.first.id;

      _weightController.text = '0';
      _gradeAController.text = '0';
      _gradeBController.text = '0';
      _gradeCController.text = '0';
      _perkiraanPanen = 25.0;
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
                      const Text('Catat Hasil Panen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
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
                        onChanged: (val) {
                          setDialogState(() {
                            _selectedSeasonId = val;
                          });
                        },
                        validator: (value) => value == null ? 'Musim tanam wajib dipilih' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Berat (Kg) (Otomatis)', prefixIcon: Icon(Icons.scale)),
                        enabled: false, // Total berat dihitung otomatis dari Grade A + B + C
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<double>(
                        value: _perkiraanPanen,
                        decoration: const InputDecoration(
                          labelText: 'Perkiraan Hasil Panen (%)',
                          prefixIcon: Icon(Icons.percent),
                        ),
                        items: const [
                          DropdownMenuItem(value: 25.0, child: Text('25%')),
                          DropdownMenuItem(value: 50.0, child: Text('50%')),
                          DropdownMenuItem(value: 75.0, child: Text('75%')),
                          DropdownMenuItem(value: 100.0, child: Text('100%')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              _perkiraanPanen = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text('Alokasi Kualitas (Grade):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Semua Grade A'),
                              selected: _gradeMode == 'A',
                              selectedColor: Colors.green[800],
                              labelStyle: TextStyle(
                                color: _gradeMode == 'A' ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() {
                                    _gradeMode = 'A';
                                    _gradeBController.text = '0';
                                    _gradeCController.text = '0';
                                    final a = double.tryParse(_gradeAController.text) ?? 0.0;
                                    _weightController.text = a == a.toInt() ? a.toInt().toString() : a.toString();
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Semua Grade B'),
                              selected: _gradeMode == 'B',
                              selectedColor: Colors.green[800],
                              labelStyle: TextStyle(
                                color: _gradeMode == 'B' ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() {
                                    _gradeMode = 'B';
                                    _gradeAController.text = '0';
                                    _gradeCController.text = '0';
                                    final b = double.tryParse(_gradeBController.text) ?? 0.0;
                                    _weightController.text = b == b.toInt() ? b.toInt().toString() : b.toString();
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Semua Grade C'),
                              selected: _gradeMode == 'C',
                              selectedColor: Colors.green[800],
                              labelStyle: TextStyle(
                                color: _gradeMode == 'C' ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() {
                                    _gradeMode = 'C';
                                    _gradeAController.text = '0';
                                    _gradeBController.text = '0';
                                    final c = double.tryParse(_gradeCController.text) ?? 0.0;
                                    _weightController.text = c == c.toInt() ? c.toInt().toString() : c.toString();
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Kustom (A/B/C)'),
                              selected: _gradeMode == 'Custom',
                              selectedColor: Colors.green[800],
                              labelStyle: TextStyle(
                                color: _gradeMode == 'Custom' ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() {
                                    _gradeMode = 'Custom';
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gradeAController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Grade A (Kg)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                              enabled: _gradeMode == 'A' || _gradeMode == 'Custom',
                              onTap: () {
                                if (_gradeAController.text == '0') {
                                  _gradeAController.clear();
                                }
                              },
                              onChanged: (val) {
                                final a = double.tryParse(val) ?? 0.0;
                                final b = double.tryParse(_gradeBController.text) ?? 0.0;
                                final c = double.tryParse(_gradeCController.text) ?? 0.0;
                                final total = a + b + c;
                                setDialogState(() {
                                  _weightController.text = total == total.toInt() ? total.toInt().toString() : total.toString();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _gradeBController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Grade B (Kg)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                              enabled: _gradeMode == 'B' || _gradeMode == 'Custom',
                              onTap: () {
                                if (_gradeBController.text == '0') {
                                  _gradeBController.clear();
                                }
                              },
                              onChanged: (val) {
                                final a = double.tryParse(_gradeAController.text) ?? 0.0;
                                final b = double.tryParse(val) ?? 0.0;
                                final c = double.tryParse(_gradeCController.text) ?? 0.0;
                                final total = a + b + c;
                                setDialogState(() {
                                  _weightController.text = total == total.toInt() ? total.toInt().toString() : total.toString();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _gradeCController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Grade C (Kg)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                              enabled: _gradeMode == 'C' || _gradeMode == 'Custom',
                              onTap: () {
                                if (_gradeCController.text == '0') {
                                  _gradeCController.clear();
                                }
                              },
                              onChanged: (val) {
                                final a = double.tryParse(_gradeAController.text) ?? 0.0;
                                final b = double.tryParse(_gradeBController.text) ?? 0.0;
                                final c = double.tryParse(val) ?? 0.0;
                                final total = a + b + c;
                                setDialogState(() {
                                  _weightController.text = total == total.toInt() ? total.toInt().toString() : total.toString();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Catatan Panen', prefixIcon: Icon(Icons.note_alt_outlined)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Tanggal Panen: ${Formatters.formatDate(_date)}'),
                        onPressed: () async {
                          final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (d != null) {
                            setDialogState(() => _date = d);
                          }
                        },
                      ),
                      const Divider(height: 32),
                      const Text('Detail Penjualan (Wajib)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedBuyerId,
                        decoration: const InputDecoration(labelText: 'Pilih Tengkulak / Pembeli', prefixIcon: Icon(Icons.person)),
                        items: buyers.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedBuyerId = val),
                        validator: (value) => value == null ? 'Pembeli wajib dipilih' : null,
                      ),
                      if ((double.tryParse(_gradeAController.text) ?? 0.0) > 0) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceAController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Grade A per Kg (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
                          onTap: () {
                            if (_priceAController.text == '0') {
                              _priceAController.clear();
                            }
                          },
                          validator: (value) => (value == null || value.isEmpty) ? 'Harga Grade A wajib diisi' : null,
                          onChanged: (val) => setDialogState(() {}),
                        ),
                      ],
                      if ((double.tryParse(_gradeBController.text) ?? 0.0) > 0) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceBController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Grade B per Kg (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
                          onTap: () {
                            if (_priceBController.text == '0') {
                              _priceBController.clear();
                            }
                          },
                          validator: (value) => (value == null || value.isEmpty) ? 'Harga Grade B wajib diisi' : null,
                          onChanged: (val) => setDialogState(() {}),
                        ),
                      ],
                      if ((double.tryParse(_gradeCController.text) ?? 0.0) > 0) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceCController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Grade C per Kg (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
                          onTap: () {
                            if (_priceCController.text == '0') {
                              _priceCController.clear();
                            }
                          },
                          validator: (value) => (value == null || value.isEmpty) ? 'Harga Grade C wajib diisi' : null,
                          onChanged: (val) => setDialogState(() {}),
                        ),
                      ],
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
                          validator: (value) => _salesStatus == 'Belum Lunas' && (value == null || value.isEmpty) ? 'Nominal dibayar wajib diisi' : null,
                        ),
                      ],
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
                                final gradeA = double.tryParse(_gradeAController.text) ?? 0.0;
                                final gradeB = double.tryParse(_gradeBController.text) ?? 0.0;
                                final gradeC = double.tryParse(_gradeCController.text) ?? 0.0;
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
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          
                          final gradeA = double.tryParse(_gradeAController.text) ?? 0.0;
                          final gradeB = double.tryParse(_gradeBController.text) ?? 0.0;
                          final gradeC = double.tryParse(_gradeCController.text) ?? 0.0;
                          final weight = gradeA + gradeB + gradeC; // Total berat dihitung otomatis
                          final notes = _notesController.text.trim();

                          final buyer = buyers.firstWhere((b) => b.id == _selectedBuyerId);
                          final priceA = double.tryParse(_priceAController.text) ?? 0.0;
                          final priceB = double.tryParse(_priceBController.text) ?? 0.0;
                          final priceC = double.tryParse(_priceCController.text) ?? 0.0;
                          
                          final totalSales = (gradeA * priceA) + (gradeB * priceB) + (gradeC * priceC);
                          final averagePrice = weight > 0 ? (totalSales / weight) : 0.0;

                          // Aturan Bisnis Utama: Menentukan statusPeriode berdasarkan perkiraanPanen
                          // Jika perkiraanPanen >= 100%, statusPeriode adalah 'Selesai', jika tidak maka 'Aktif'
                          final statusPeriode = _perkiraanPanen >= 100.0 ? 'Selesai' : 'Aktif';

                          final data = Panen(
                            id: harvest?.id ?? '',
                            seasonId: _selectedSeasonId!,
                            date: _date,
                            weight: weight,
                            gradeAWeight: gradeA,
                            gradeBWeight: gradeB,
                            gradeCWeight: gradeC,
                            beratGradeA: gradeA,
                            beratGradeB: gradeB,
                            beratGradeC: gradeC,
                            fruitsCount: 0,
                            notes: notes,
                            buyerId: buyer.id,
                            buyerName: buyer.name,
                            pricePerKg: averagePrice,
                            totalPrice: totalSales,
                            perkiraanPanen: _perkiraanPanen,
                            statusPeriode: statusPeriode,
                            priceGradeA: priceA > 0 ? priceA : null,
                            priceGradeB: priceB > 0 ? priceB : null,
                            priceGradeC: priceC > 0 ? priceC : null,
                          );

                          if (harvest != null) {
                            await ref.read(databaseRepositoryProvider).updateHarvest(data);
                          } else {
                            await ref.read(databaseRepositoryProvider).addHarvest(data);
                            
                            final season = seasons.firstWhere((s) => s.id == _selectedSeasonId);
                            double paid = totalSales;
                            if (_salesStatus == 'Belum Lunas') {
                              paid = double.tryParse(_amountPaidController.text) ?? 0.0;
                            }
                            
                            final saleData = Penjualan(
                              id: '',
                              date: _date,
                              buyerId: buyer.id,
                              buyerName: buyer.name,
                              seasonId: _selectedSeasonId!,
                              seasonName: season.name,
                              weight: weight,
                              pricePerKg: averagePrice,
                              totalPrice: totalSales,
                              status: _salesStatus,
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
                              content: Text(harvest != null ? 'Data Panen berhasil diperbarui!' : 'Data Panen & Penjualan melon berhasil disimpan!'), 
                              backgroundColor: Colors.green
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
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
                                          Text(Formatters.formatDate(h.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                                                    _showPanenDialog(seasonsState.value ?? [], fieldsState.value ?? [], buyersState.value ?? [], harvest: h);
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

          if (_tabController.index == 0) {
            if (seasons.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap buat musim tanam terlebih dahulu!'), backgroundColor: Colors.red));
              return;
            }
            if (buyers.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap tambah data tengkulak / pembeli terlebih dahulu!'), backgroundColor: Colors.red));
              return;
            }
            _showPanenDialog(seasons, fields, buyers);
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
