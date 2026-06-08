import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is Timestamp) return val.toDate();
  if (val is String) {
    return DateTime.tryParse(val) ?? DateTime.now();
  }
  if (val is DateTime) return val;
  return DateTime.now();
}

DateTime? _parseNullableDateTime(dynamic val) {
  if (val == null) return null;
  if (val is Timestamp) return val.toDate();
  if (val is String) return DateTime.tryParse(val);
  if (val is DateTime) return val;
  return null;
}

// --- LAHAN (FIELD) MODEL ---
class Lahan {
  final String id;
  final String name;
  final double area;
  final String unit; // 'm²' or 'hektar'
  final String locationGps; // e.g. "-6.2088, 106.8456"
  final String address;
  final String soilType;
  final String status; // 'Milik Sendiri' or 'Sewa'
  final double rentPrice;
  final DateTime? rentStartDate;
  final DateTime? rentEndDate;
  final String waterSource;
  final String notes;

  Lahan({
    required this.id,
    required this.name,
    required this.area,
    required this.unit,
    required this.locationGps,
    required this.address,
    required this.soilType,
    required this.status,
    this.rentPrice = 0.0,
    this.rentStartDate,
    this.rentEndDate,
    required this.waterSource,
    required this.notes,
  });

  factory Lahan.fromMap(Map<String, dynamic> map, String id) {
    return Lahan(
      id: id,
      name: map['name'] ?? '',
      area: (map['area'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'm²',
      locationGps: map['locationGps'] ?? '',
      address: map['address'] ?? '',
      soilType: map['soilType'] ?? '',
      status: map['status'] ?? 'Milik Sendiri',
      rentPrice: (map['rentPrice'] as num?)?.toDouble() ?? 0.0,
      rentStartDate: _parseNullableDateTime(map['rentStartDate']),
      rentEndDate: _parseNullableDateTime(map['rentEndDate']),
      waterSource: map['waterSource'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'area': area,
      'unit': unit,
      'locationGps': locationGps,
      'address': address,
      'soilType': soilType,
      'status': status,
      'rentPrice': rentPrice,
      'rentStartDate': rentStartDate != null ? Timestamp.fromDate(rentStartDate!) : null,
      'rentEndDate': rentEndDate != null ? Timestamp.fromDate(rentEndDate!) : null,
      'waterSource': waterSource,
      'notes': notes,
    };
  }
}

// --- TANAMAN (CROP) MODEL ---
class Tanaman {
  final String id;
  final String name; // e.g. Melon, Semangka
  final String variety;
  final int harvestAgeDays;
  final String waterRequirement;
  final String description;

  Tanaman({
    required this.id,
    required this.name,
    required this.variety,
    required this.harvestAgeDays,
    required this.waterRequirement,
    required this.description,
  });

  factory Tanaman.fromMap(Map<String, dynamic> map, String id) {
    return Tanaman(
      id: id,
      name: map['name'] ?? '',
      variety: map['variety'] ?? '',
      harvestAgeDays: map['harvestAgeDays'] ?? 60,
      waterRequirement: map['waterRequirement'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'variety': variety,
      'harvestAgeDays': harvestAgeDays,
      'waterRequirement': waterRequirement,
      'description': description,
    };
  }
}

// --- PERENCANAAN TANAM (PLANTING SEASON) MODEL ---
class MusimTanam {
  final String id;
  final String name;
  final String fieldId;
  final String cropId;
  final String variety;
  final double plantingArea;
  final int seedsCount;
  final DateTime seedingDate;
  final DateTime plantingDate;
  final String status; // 'Perencanaan', 'Berjalan', 'Selesai'

  MusimTanam({
    required this.id,
    required this.name,
    required this.fieldId,
    required this.cropId,
    required this.variety,
    required this.plantingArea,
    required this.seedsCount,
    required this.seedingDate,
    required this.plantingDate,
    required this.status,
  });

  factory MusimTanam.fromMap(Map<String, dynamic> map, String id) {
    return MusimTanam(
      id: id,
      name: map['name'] ?? '',
      fieldId: map['fieldId'] ?? '',
      cropId: map['cropId'] ?? '',
      variety: map['variety'] ?? '',
      plantingArea: (map['plantingArea'] as num?)?.toDouble() ?? 0.0,
      seedsCount: map['seedsCount'] ?? 0,
      seedingDate: _parseDateTime(map['seedingDate']),
      plantingDate: _parseDateTime(map['plantingDate']),
      status: map['status'] ?? 'Perencanaan',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'fieldId': fieldId,
      'cropId': cropId,
      'variety': variety,
      'plantingArea': plantingArea,
      'seedsCount': seedsCount,
      'seedingDate': Timestamp.fromDate(seedingDate),
      'plantingDate': Timestamp.fromDate(plantingDate),
      'status': status,
    };
  }
}

// --- PEMBELIAN SAPROTAN MODEL ---
class Pembelian {
  final String id;
  final String itemName;
  final String category; // Bibit, Pupuk, Pestisida, Mulsa, Tali Rambat, Plastik, Peralatan
  final String shop;
  final String supplier;
  final DateTime purchaseDate;
  final double unitPrice;
  final double quantity;
  final double totalPrice;
  final String receiptPhotoUrl;

  Pembelian({
    required this.id,
    required this.itemName,
    required this.category,
    required this.shop,
    required this.supplier,
    required this.purchaseDate,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.receiptPhotoUrl,
  });

  factory Pembelian.fromMap(Map<String, dynamic> map, String id) {
    return Pembelian(
      id: id,
      itemName: map['itemName'] ?? '',
      category: map['category'] ?? 'Bibit',
      shop: map['shop'] ?? '',
      supplier: map['supplier'] ?? '',
      purchaseDate: _parseDateTime(map['purchaseDate']),
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      receiptPhotoUrl: map['receiptPhotoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'category': category,
      'shop': shop,
      'supplier': supplier,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'receiptPhotoUrl': receiptPhotoUrl,
    };
  }
}

// --- STOK (INVENTORY) MODEL ---
class Stok {
  final String id;
  final String itemName;
  final String category;
  final double quantityIn;
  final double quantityOut;
  final String unit; // Kg, Liter, Botol, Karung

  Stok({
    required this.id,
    required this.itemName,
    required this.category,
    required this.quantityIn,
    required this.quantityOut,
    required this.unit,
  });

  double get currentStock => quantityIn - quantityOut;

  factory Stok.fromMap(Map<String, dynamic> map, String id) {
    return Stok(
      id: id,
      itemName: map['itemName'] ?? '',
      category: map['category'] ?? '',
      quantityIn: (map['quantityIn'] as num?)?.toDouble() ?? 0.0,
      quantityOut: (map['quantityOut'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'Kg',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'category': category,
      'quantityIn': quantityIn,
      'quantityOut': quantityOut,
      'unit': unit,
    };
  }
}

// --- JADWAL PEMUPUKAN MODEL ---
class JadwalPemupukan {
  final String id;
  final String seasonId;
  final int hst;
  final DateTime date;
  final String fertilizerName;
  final double dosage;
  final String unit;
  final String method; // 'Kocor', 'Tabur', 'Fertigasi'
  final String status; // 'Belum Dilaksanakan', 'Selesai'

  JadwalPemupukan({
    required this.id,
    required this.seasonId,
    required this.hst,
    required this.date,
    required this.fertilizerName,
    required this.dosage,
    required this.unit,
    required this.method,
    required this.status,
  });

  factory JadwalPemupukan.fromMap(Map<String, dynamic> map, String id) {
    return JadwalPemupukan(
      id: id,
      seasonId: map['seasonId'] ?? '',
      hst: map['hst'] ?? 0,
      date: _parseDateTime(map['date']),
      fertilizerName: map['fertilizerName'] ?? '',
      dosage: (map['dosage'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'Kg',
      method: map['method'] ?? 'Kocor',
      status: map['status'] ?? 'Belum Dilaksanakan',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seasonId': seasonId,
      'hst': hst,
      'date': Timestamp.fromDate(date),
      'fertilizerName': fertilizerName,
      'dosage': dosage,
      'unit': unit,
      'method': method,
      'status': status,
    };
  }
}

// --- JADWAL PENYEMPROTAN MODEL ---
class JadwalPenyemprotan {
  final String id;
  final String seasonId;
  final int hst;
  final DateTime date;
  final String productName;
  final String productType; // 'Fungisida', 'Insektisida', 'Bakterisida', 'Herbisida'
  final double dosage;
  final String targetPest;
  final String notes;
  final String status; // 'Belum Dilaksanakan', 'Selesai'

  JadwalPenyemprotan({
    required this.id,
    required this.seasonId,
    required this.hst,
    required this.date,
    required this.productName,
    required this.productType,
    required this.dosage,
    required this.targetPest,
    required this.notes,
    required this.status,
  });

  factory JadwalPenyemprotan.fromMap(Map<String, dynamic> map, String id) {
    return JadwalPenyemprotan(
      id: id,
      seasonId: map['seasonId'] ?? '',
      hst: map['hst'] ?? 0,
      date: _parseDateTime(map['date']),
      productName: map['productName'] ?? '',
      productType: map['productType'] ?? 'Fungisida',
      dosage: (map['dosage'] as num?)?.toDouble() ?? 0.0,
      targetPest: map['targetPest'] ?? '',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'Belum Dilaksanakan',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seasonId': seasonId,
      'hst': hst,
      'date': Timestamp.fromDate(date),
      'productName': productName,
      'productType': productType,
      'dosage': dosage,
      'targetPest': targetPest,
      'notes': notes,
      'status': status,
    };
  }
}

// --- CATATAN HAMA DAN PENYAKIT MODEL ---
class HamaPenyakit {
  final String id;
  final DateTime date;
  final String seasonId;
  final String name;
  final String severity; // 'Ringan', 'Sedang', 'Berat'
  final String description;
  final String solution;
  final String photoUrl;

  HamaPenyakit({
    required this.id,
    required this.date,
    required this.seasonId,
    required this.name,
    required this.severity,
    required this.description,
    required this.solution,
    required this.photoUrl,
  });

  factory HamaPenyakit.fromMap(Map<String, dynamic> map, String id) {
    return HamaPenyakit(
      id: id,
      date: _parseDateTime(map['date']),
      seasonId: map['seasonId'] ?? '',
      name: map['name'] ?? '',
      severity: map['severity'] ?? 'Ringan',
      description: map['description'] ?? '',
      solution: map['solution'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'seasonId': seasonId,
      'name': name,
      'severity': severity,
      'description': description,
      'solution': solution,
      'photoUrl': photoUrl,
    };
  }
}

// --- TENAGA KERJA MODEL ---
class TenagaKerja {
  final String id;
  final String name;
  final String phone;
  final String address;

  TenagaKerja({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory TenagaKerja.fromMap(Map<String, dynamic> map, String id) {
    return TenagaKerja(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}

// --- AKTIVITAS PEKERJA / ABSENSI / PAYROLL MODEL ---
class AktivitasPekerja {
  final String id;
  final String workerId;
  final String workerName;
  final String activityType; // Pengolahan Lahan, Penanaman, Pemupukan, Penyemprotan, Panen, Lainnya
  final DateTime date;
  final double dailyWage;
  final double daysWorked;
  final double totalWage;

  AktivitasPekerja({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.activityType,
    required this.date,
    required this.dailyWage,
    required this.daysWorked,
    required this.totalWage,
  });

  factory AktivitasPekerja.fromMap(Map<String, dynamic> map, String id) {
    return AktivitasPekerja(
      id: id,
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? '',
      activityType: map['activityType'] ?? 'Lainnya',
      date: _parseDateTime(map['date']),
      dailyWage: (map['dailyWage'] as num?)?.toDouble() ?? 0.0,
      daysWorked: (map['daysWorked'] as num?)?.toDouble() ?? 0.0,
      totalWage: (map['totalWage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'workerName': workerName,
      'activityType': activityType,
      'date': Timestamp.fromDate(date),
      'dailyWage': dailyWage,
      'daysWorked': daysWorked,
      'totalWage': totalWage,
    };
  }
}

// --- PENGELUARAN MODEL ---
class Pengeluaran {
  final String id;
  final DateTime date;
  final String seasonId; // Link to season if specific, or general
  final String category; // Bibit, Pupuk, Pestisida, Upah, Transportasi, Sewa Lahan, BBM, Listrik, Air, Lainnya
  final String description;
  final double amount;
  final String photoUrl;

  Pengeluaran({
    required this.id,
    required this.date,
    required this.seasonId,
    required this.category,
    required this.description,
    required this.amount,
    required this.photoUrl,
  });

  factory Pengeluaran.fromMap(Map<String, dynamic> map, String id) {
    return Pengeluaran(
      id: id,
      date: _parseDateTime(map['date']),
      seasonId: map['seasonId'] ?? '',
      category: map['category'] ?? 'Lainnya',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      photoUrl: map['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'seasonId': seasonId,
      'category': category,
      'description': description,
      'amount': amount,
      'photoUrl': photoUrl,
    };
  }
}

// --- PANEN MODEL ---
class Panen {
  final String id;
  final String seasonId;
  final DateTime date;
  final double weight; // Total weight
  final double gradeAWeight;
  final double gradeBWeight;
  final double gradeCWeight;
  final int fruitsCount;
  final String notes;
  final String? buyerId;
  final String? buyerName;
  final double? pricePerKg;
  final double? totalPrice;
  final int? harvestedTrees;
  final double? priceGradeA;
  final double? priceGradeB;
  final double? priceGradeC;

  Panen({
    required this.id,
    required this.seasonId,
    required this.date,
    required this.weight,
    required this.gradeAWeight,
    required this.gradeBWeight,
    required this.gradeCWeight,
    required this.fruitsCount,
    required this.notes,
    this.buyerId,
    this.buyerName,
    this.pricePerKg,
    this.totalPrice,
    this.harvestedTrees,
    this.priceGradeA,
    this.priceGradeB,
    this.priceGradeC,
  });

  factory Panen.fromMap(Map<String, dynamic> map, String id) {
    return Panen(
      id: id,
      seasonId: map['seasonId'] ?? '',
      date: _parseDateTime(map['date']),
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      gradeAWeight: (map['gradeAWeight'] as num?)?.toDouble() ?? 0.0,
      gradeBWeight: (map['gradeBWeight'] as num?)?.toDouble() ?? 0.0,
      gradeCWeight: (map['gradeCWeight'] as num?)?.toDouble() ?? 0.0,
      fruitsCount: map['fruitsCount'] ?? 0,
      notes: map['notes'] ?? '',
      buyerId: map['buyerId'],
      buyerName: map['buyerName'],
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble(),
      totalPrice: (map['totalPrice'] as num?)?.toDouble(),
      harvestedTrees: map['harvestedTrees'] as int?,
      priceGradeA: (map['priceGradeA'] as num?)?.toDouble(),
      priceGradeB: (map['priceGradeB'] as num?)?.toDouble(),
      priceGradeC: (map['priceGradeC'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seasonId': seasonId,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'gradeAWeight': gradeAWeight,
      'gradeBWeight': gradeBWeight,
      'gradeCWeight': gradeCWeight,
      'fruitsCount': fruitsCount,
      'notes': notes,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'pricePerKg': pricePerKg,
      'totalPrice': totalPrice,
      'harvestedTrees': harvestedTrees,
      'priceGradeA': priceGradeA,
      'priceGradeB': priceGradeB,
      'priceGradeC': priceGradeC,
    };
  }
}

// --- TENGKULAK / PEMBELI MODEL ---
class Tengkulak {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String region;
  final String commodityBought;
  final String notes;

  Tengkulak({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.region,
    required this.commodityBought,
    required this.notes,
  });

  factory Tengkulak.fromMap(Map<String, dynamic> map, String id) {
    return Tengkulak(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      region: map['region'] ?? '',
      commodityBought: map['commodityBought'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'region': region,
      'commodityBought': commodityBought,
      'notes': notes,
    };
  }
}

// --- PENJUALAN MODEL ---
class Penjualan {
  final String id;
  final DateTime date;
  final String buyerId;
  final String buyerName;
  final String seasonId;
  final String seasonName;
  final double weight;
  final double pricePerKg;
  final double totalPrice;
  final String status; // 'Lunas' or 'Belum Lunas'
  final double amountPaid;
  final double remainingDebt;
  final double? priceGradeA;
  final double? priceGradeB;
  final double? priceGradeC;

  Penjualan({
    required this.id,
    required this.date,
    required this.buyerId,
    required this.buyerName,
    required this.seasonId,
    required this.seasonName,
    required this.weight,
    required this.pricePerKg,
    required this.totalPrice,
    required this.status,
    required this.amountPaid,
    required this.remainingDebt,
    this.priceGradeA,
    this.priceGradeB,
    this.priceGradeC,
  });

  factory Penjualan.fromMap(Map<String, dynamic> map, String id) {
    final w = (map['weight'] as num?)?.toDouble() ?? 0.0;
    final p = (map['pricePerKg'] as num?)?.toDouble() ?? 0.0;
    return Penjualan(
      id: id,
      date: _parseDateTime(map['date']),
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? 'Umum',
      seasonId: map['seasonId'] ?? '',
      seasonName: map['seasonName'] ?? '',
      weight: w,
      pricePerKg: p,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? (w * p),
      status: map['status'] ?? 'Belum Lunas',
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      remainingDebt: (map['remainingDebt'] as num?)?.toDouble() ?? 0.0,
      priceGradeA: (map['priceGradeA'] as num?)?.toDouble(),
      priceGradeB: (map['priceGradeB'] as num?)?.toDouble(),
      priceGradeC: (map['priceGradeC'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'buyerId': buyerId,
      'buyerName': buyerName,
      'seasonId': seasonId,
      'seasonName': seasonName,
      'weight': weight,
      'pricePerKg': pricePerKg,
      'totalPrice': totalPrice,
      'status': status,
      'amountPaid': amountPaid,
      'remainingDebt': remainingDebt,
      'priceGradeA': priceGradeA,
      'priceGradeB': priceGradeB,
      'priceGradeC': priceGradeC,
    };
  }
}
