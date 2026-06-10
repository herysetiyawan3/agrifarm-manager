import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

class DatabaseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DatabaseRepository() {
    // Configure Firestore Settings for Offline Persistence
    _db.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  // Generic Stream helper
  Stream<List<T>> _getStream<T>({
    required String collection,
    required T Function(Map<String, dynamic> data, String id) builder,
    Query Function(Query query)? queryBuilder,
  }) {
    Query query = _db.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => builder(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  // --- LAHAN (FIELD) CRUD ---
  Stream<List<Lahan>> watchFields() => _getStream(collection: 'fields', builder: Lahan.fromMap);
  Future<void> addField(Lahan field) => _db.collection('fields').add(field.toMap());
  Future<void> updateField(Lahan field) => _db.collection('fields').doc(field.id).update(field.toMap());
  Future<void> deleteField(String id) => _db.collection('fields').doc(id).delete();

  // --- TANAMAN (CROP) CRUD ---
  Stream<List<Tanaman>> watchCrops() => _getStream(collection: 'crops', builder: Tanaman.fromMap);
  Future<void> addCrop(Tanaman crop) => _db.collection('crops').add(crop.toMap());
  Future<void> updateCrop(Tanaman crop) => _db.collection('crops').doc(crop.id).update(crop.toMap());
  Future<void> deleteCrop(String id) => _db.collection('crops').doc(id).delete();

  // --- PERENCANAAN / MUSIM TANAM CRUD ---
  Stream<List<MusimTanam>> watchSeasons() => _getStream(collection: 'planting_seasons', builder: MusimTanam.fromMap);
  Future<void> addSeason(MusimTanam season) => _db.collection('planting_seasons').add(season.toMap());
  Future<void> updateSeason(MusimTanam season) => _db.collection('planting_seasons').doc(season.id).update(season.toMap());
  Future<void> deleteSeason(String id) => _db.collection('planting_seasons').doc(id).delete();

  // --- STOK (INVENTORY) ---
  Stream<List<Stok>> watchStok() => _getStream(collection: 'inventory', builder: Stok.fromMap);

  // --- PEMBELIAN CRUD WITH AUTOMATIC INVENTORY STOCK IN ---
  Stream<List<Pembelian>> watchPurchases({
    String orderByField = 'purchaseDate',
    bool descending = true,
  }) => _getStream(
        collection: 'purchases',
        builder: Pembelian.fromMap,
        queryBuilder: (q) => q.orderBy(orderByField, descending: descending),
      );
  
  Future<void> addPurchase(Pembelian purchase) async {
    // 1. Add purchase record
    await _db.collection('purchases').add(purchase.toMap());

    // 2. Add expense record automatically
    final expense = Pengeluaran(
      id: '',
      date: purchase.purchaseDate,
      seasonId: '', // General expense, can be linked manually
      category: purchase.category,
      description: 'Beli ${purchase.itemName} (${purchase.jumlah})',
      amount: purchase.totalPrice,
      photoUrl: purchase.receiptPhotoUrl,
    );
    await addExpense(expense);

    // 3. Update inventory (stock in)
    final query = await _db
        .collection('inventory')
        .where('itemName', isEqualTo: purchase.itemName)
        .limit(1)
        .get();

    final unit = extractUnit(purchase.jumlah);

    if (query.docs.isEmpty) {
      // Create new stock
      final newStok = Stok(
        id: '',
        itemName: purchase.itemName,
        category: purchase.category,
        quantityIn: purchase.quantity,
        quantityOut: 0.0,
        unit: unit,
      );
      await _db.collection('inventory').add(newStok.toMap());
    } else {
      // Update existing stock in
      final doc = query.docs.first;
      final currentIn = (doc.data()['quantityIn'] as num).toDouble();
      await _db.collection('inventory').doc(doc.id).update({
        'quantityIn': currentIn + purchase.quantity,
        'unit': unit,
      });
    }
  }

  Future<void> deletePurchase(String id, Pembelian purchase) async {
    await _db.collection('purchases').doc(id).delete();
    
    // Revert inventory stock in
    final query = await _db
        .collection('inventory')
        .where('itemName', isEqualTo: purchase.itemName)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final currentIn = (doc.data()['quantityIn'] as num).toDouble();
      await _db.collection('inventory').doc(doc.id).update({
        'quantityIn': (currentIn - purchase.quantity) >= 0 ? currentIn - purchase.quantity : 0.0,
      });
    }

    // Search and delete corresponding expense record
    final queryExpense = await _db
        .collection('expenses')
        .where('category', isEqualTo: purchase.category)
        .where('date', isEqualTo: Timestamp.fromDate(purchase.purchaseDate))
        .where('amount', isEqualTo: purchase.totalPrice)
        .limit(1)
        .get();

    if (queryExpense.docs.isNotEmpty) {
      await _db.collection('expenses').doc(queryExpense.docs.first.id).delete();
    }
  }

  Future<void> updatePurchase(Pembelian oldPurchase, Pembelian newPurchase) async {
    // 1. Revert old purchase inventory stock in
    final queryOld = await _db
        .collection('inventory')
        .where('itemName', isEqualTo: oldPurchase.itemName)
        .limit(1)
        .get();

    if (queryOld.docs.isNotEmpty) {
      final doc = queryOld.docs.first;
      final currentIn = (doc.data()['quantityIn'] as num).toDouble();
      await _db.collection('inventory').doc(doc.id).update({
        'quantityIn': (currentIn - oldPurchase.quantity) >= 0 ? currentIn - oldPurchase.quantity : 0.0,
      });
    }

    // 2. Search and update corresponding expense record
    final queryExpense = await _db
        .collection('expenses')
        .where('category', isEqualTo: oldPurchase.category)
        .where('date', isEqualTo: Timestamp.fromDate(oldPurchase.purchaseDate))
        .where('amount', isEqualTo: oldPurchase.totalPrice)
        .limit(1)
        .get();

    if (queryExpense.docs.isNotEmpty) {
      await _db.collection('expenses').doc(queryExpense.docs.first.id).update({
        'category': newPurchase.category,
        'date': Timestamp.fromDate(newPurchase.purchaseDate),
        'description': 'Beli ${newPurchase.itemName} (${newPurchase.jumlah})',
        'amount': newPurchase.totalPrice,
        'photoUrl': newPurchase.receiptPhotoUrl,
      });
    }

    // 3. Update the purchase document
    await _db.collection('purchases').doc(newPurchase.id).update(newPurchase.toMap());

    // 4. Apply new purchase inventory stock in
    final queryNew = await _db
        .collection('inventory')
        .where('itemName', isEqualTo: newPurchase.itemName)
        .limit(1)
        .get();

    final unit = extractUnit(newPurchase.jumlah);

    if (queryNew.docs.isEmpty) {
      final newStok = Stok(
        id: '',
        itemName: newPurchase.itemName,
        category: newPurchase.category,
        quantityIn: newPurchase.quantity,
        quantityOut: 0.0,
        unit: unit,
      );
      await _db.collection('inventory').add(newStok.toMap());
    } else {
      final doc = queryNew.docs.first;
      final currentIn = (doc.data()['quantityIn'] as num).toDouble();
      await _db.collection('inventory').doc(doc.id).update({
        'quantityIn': currentIn + newPurchase.quantity,
        'unit': unit,
      });
    }
  }

  // --- JADWAL PEMUPUKAN CRUD WITH AUTOMATIC INVENTORY STOCK OUT ---
  Stream<List<JadwalPemupukan>> watchFertilizations(String seasonId) {
    return _db
        .collection('fertilizations')
        .where('seasonId', isEqualTo: seasonId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => JadwalPemupukan.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  Future<void> addFertilization(JadwalPemupukan fert) => _db.collection('fertilizations').add(fert.toMap());
  
  Future<void> updateFertilization(JadwalPemupukan fert) async {
    // Check if status is changed to Selesai
    final oldDoc = await _db.collection('fertilizations').doc(fert.id).get();
    final oldStatus = oldDoc.data()?['status'] ?? 'Belum Dilaksanakan';

    await _db.collection('fertilizations').doc(fert.id).update(fert.toMap());

    // If marked done, reduce inventory stock out
    if (oldStatus != 'Selesai' && fert.status == 'Selesai') {
      final query = await _db
          .collection('inventory')
          .where('itemName', isEqualTo: fert.fertilizerName)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final currentOut = (doc.data()['quantityOut'] as num).toDouble();
        await _db.collection('inventory').doc(doc.id).update({
          'quantityOut': currentOut + fert.dosage,
        });
      } else {
        // Create inventory stock with negative current (only out)
        final newStok = Stok(
          id: '',
          itemName: fert.fertilizerName,
          category: 'Pupuk',
          quantityIn: 0.0,
          quantityOut: fert.dosage,
          unit: fert.unit,
        );
        await _db.collection('inventory').add(newStok.toMap());
      }
    }
  }

  Future<void> deleteFertilization(String id, JadwalPemupukan fert) async {
    await _db.collection('fertilizations').doc(id).delete();
    if (fert.status == 'Selesai') {
      final query = await _db
          .collection('inventory')
          .where('itemName', isEqualTo: fert.fertilizerName)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final currentOut = (doc.data()['quantityOut'] as num).toDouble();
        await _db.collection('inventory').doc(doc.id).update({
          'quantityOut': (currentOut - fert.dosage) >= 0 ? currentOut - fert.dosage : 0.0,
        });
      }
    }
  }

  // --- JADWAL PENYEMPROTAN CRUD WITH AUTOMATIC INVENTORY STOCK OUT ---
  Stream<List<JadwalPenyemprotan>> watchSprayings(String seasonId) {
    return _db
        .collection('sprayings')
        .where('seasonId', isEqualTo: seasonId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => JadwalPenyemprotan.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  Future<void> addSpraying(JadwalPenyemprotan spray) => _db.collection('sprayings').add(spray.toMap());

  Future<void> updateSpraying(JadwalPenyemprotan spray) async {
    final oldDoc = await _db.collection('sprayings').doc(spray.id).get();
    final oldStatus = oldDoc.data()?['status'] ?? 'Belum Dilaksanakan';

    await _db.collection('sprayings').doc(spray.id).update(spray.toMap());

    if (oldStatus != 'Selesai' && spray.status == 'Selesai') {
      final query = await _db
          .collection('inventory')
          .where('itemName', isEqualTo: spray.productName)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final currentOut = (doc.data()['quantityOut'] as num).toDouble();
        await _db.collection('inventory').doc(doc.id).update({
          'quantityOut': currentOut + spray.dosage,
        });
      } else {
        final newStok = Stok(
          id: '',
          itemName: spray.productName,
          category: 'Pestisida',
          quantityIn: 0.0,
          quantityOut: spray.dosage,
          unit: 'Liter',
        );
        await _db.collection('inventory').add(newStok.toMap());
      }
    }
  }

  Future<void> deleteSpraying(String id, JadwalPenyemprotan spray) async {
    await _db.collection('sprayings').doc(id).delete();
    if (spray.status == 'Selesai') {
      final query = await _db
          .collection('inventory')
          .where('itemName', isEqualTo: spray.productName)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final currentOut = (doc.data()['quantityOut'] as num).toDouble();
        await _db.collection('inventory').doc(doc.id).update({
          'quantityOut': (currentOut - spray.dosage) >= 0 ? currentOut - spray.dosage : 0.0,
        });
      }
    }
  }

  // --- CATATAN HAMA DAN PENYAKIT CRUD ---
  Stream<List<HamaPenyakit>> watchPests() => _getStream(
        collection: 'pests',
        builder: HamaPenyakit.fromMap,
        queryBuilder: (q) => q.orderBy('date', descending: true),
      );
  Future<void> addPest(HamaPenyakit pest) => _db.collection('pests').add(pest.toMap());
  Future<void> updatePest(HamaPenyakit pest) => _db.collection('pests').doc(pest.id).update(pest.toMap());
  Future<void> deletePest(String id) => _db.collection('pests').doc(id).delete();

  // --- TENAGA KERJA & AKTIVITAS CRUD ---
  Stream<List<TenagaKerja>> watchWorkers() => _getStream(collection: 'workers', builder: TenagaKerja.fromMap);
  Future<void> addWorker(TenagaKerja worker) => _db.collection('workers').add(worker.toMap());
  Future<void> updateWorker(TenagaKerja worker) => _db.collection('workers').doc(worker.id).update(worker.toMap());
  Future<void> deleteWorker(String id) => _db.collection('workers').doc(id).delete();

  Stream<List<AktivitasPekerja>> watchWorkerActivities() => _getStream(
        collection: 'workers_activities',
        builder: AktivitasPekerja.fromMap,
        queryBuilder: (q) => q.orderBy('date', descending: true),
      );
  
  Future<void> addWorkerActivity(AktivitasPekerja act) async {
    await _db.collection('workers_activities').add(act.toMap());
    
    // Automatically log wages as operational expense
    final expense = Pengeluaran(
      id: '',
      date: act.date,
      seasonId: '',
      category: 'Upah',
      description: 'Upah kerja ${act.workerName} - ${act.activityType} (${act.daysWorked} hari)',
      amount: act.totalWage,
      photoUrl: '',
    );
    await addExpense(expense);
  }

  Future<void> updateWorkerActivity(AktivitasPekerja oldAct, AktivitasPekerja newAct) async {
    await _db.collection('workers_activities').doc(newAct.id).update(newAct.toMap());
    
    // Search and update corresponding expense
    final query = await _db
        .collection('expenses')
        .where('category', isEqualTo: 'Upah')
        .where('date', isEqualTo: Timestamp.fromDate(oldAct.date))
        .where('amount', isEqualTo: oldAct.totalWage)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) {
      await _db.collection('expenses').doc(query.docs.first.id).update({
        'date': Timestamp.fromDate(newAct.date),
        'description': 'Upah kerja ${newAct.workerName} - ${newAct.activityType} (${newAct.daysWorked} hari)',
        'amount': newAct.totalWage,
      });
    }
  }

  Future<void> deleteWorkerActivity(String id, AktivitasPekerja act) async {
    await _db.collection('workers_activities').doc(id).delete();
    
    // Search and delete corresponding expense
    final query = await _db
        .collection('expenses')
        .where('category', isEqualTo: 'Upah')
        .where('date', isEqualTo: Timestamp.fromDate(act.date))
        .where('amount', isEqualTo: act.totalWage)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) {
      await _db.collection('expenses').doc(query.docs.first.id).delete();
    }
  }

  // --- PENGELUARAN CRUD ---
  Stream<List<Pengeluaran>> watchExpenses() => _getStream(
        collection: 'expenses',
        builder: Pengeluaran.fromMap,
        queryBuilder: (q) => q.orderBy('date', descending: true),
      );
  Future<void> addExpense(Pengeluaran exp) => _db.collection('expenses').add(exp.toMap());
  Future<void> updateExpense(Pengeluaran exp) => _db.collection('expenses').doc(exp.id).update(exp.toMap());
  Future<void> deleteExpense(String id) => _db.collection('expenses').doc(id).delete();

  // --- PANEN CRUD ---
  Stream<List<Panen>> watchHarvests() => _getStream(
        collection: 'harvests',
        builder: Panen.fromMap,
        queryBuilder: (q) => q.orderBy('date', descending: true),
      );
  Future<void> addHarvest(Panen harvest) => _db.collection('harvests').add(harvest.toMap());
  Future<void> updateHarvest(Panen harvest) => _db.collection('harvests').doc(harvest.id).update(harvest.toMap());
  Future<void> deleteHarvest(String id) => _db.collection('harvests').doc(id).delete();

  // --- TENGKULAK / BUYER CRUD ---
  Stream<List<Tengkulak>> watchBuyers() => _getStream(collection: 'buyers', builder: Tengkulak.fromMap);
  Future<void> addBuyer(Tengkulak buyer) => _db.collection('buyers').add(buyer.toMap());
  Future<void> updateBuyer(Tengkulak buyer) => _db.collection('buyers').doc(buyer.id).update(buyer.toMap());
  Future<void> deleteBuyer(String id) => _db.collection('buyers').doc(id).delete();

  // --- PENJUALAN CRUD ---
  // Logika Filter Penjualan untuk Firestore Query
  // Mengurutkan data berdasarkan field dan arah (descending/ascending)
  Stream<List<Penjualan>> watchSales({
    String orderByField = 'date',
    bool descending = true,
  }) => _getStream(
        collection: 'sales',
        builder: Penjualan.fromMap,
        queryBuilder: (q) => q.orderBy(orderByField, descending: descending),
      );
  Future<void> addSale(Penjualan sale) => _db.collection('sales').add(sale.toMap());
  Future<void> updateSale(Penjualan sale) => _db.collection('sales').doc(sale.id).update(sale.toMap());
  Future<void> deleteSale(String id) => _db.collection('sales').doc(id).delete();

  // --- AKTIVITAS LAPANGAN CRUD & INTEGRASI ---
  Stream<List<AktivitasLapangan>> watchActivities(String seasonId) {
    return _db
        .collection('activities')
        .where('seasonId', isEqualTo: seasonId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AktivitasLapangan.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
      return list;
    });
  }

  Future<String> addActivity(AktivitasLapangan act) async {
    final docRef = await _db.collection('activities').add(act.toMap());
    return docRef.id;
  }

  Future<void> updateActivity(AktivitasLapangan act) => _db.collection('activities').doc(act.id).update(act.toMap());

  Future<double> getUnitPriceForProduct(String productName) async {
    final query = await _db
        .collection('purchases')
        .where('itemName', isEqualTo: productName)
        .orderBy('purchaseDate', descending: true)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      final totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
      final quantity = (data['quantity'] as num?)?.toDouble() ?? 1.0;
      return quantity > 0 ? (totalPrice / quantity) : 0.0;
    }
    return 0.0;
  }

  Future<void> executeActivity(AktivitasLapangan act) async {
    // 1. Update activity status to 'Dilaksanakan'
    final executedAct = AktivitasLapangan(
      id: act.id,
      seasonId: act.seasonId,
      fieldIds: act.fieldIds,
      activityType: act.activityType,
      product: act.product,
      quantity: act.quantity,
      unit: act.unit,
      date: act.date,
      description: act.description,
      status: 'Dilaksanakan',
    );
    await _db.collection('activities').doc(act.id).update(executedAct.toMap());

    // 2. Reduce inventory stock
    if (act.activityType != 'Tenaga Kerja' && act.product.isNotEmpty) {
      final stockQuery = await _db
          .collection('inventory')
          .where('itemName', isEqualTo: act.product)
          .limit(1)
          .get();
      if (stockQuery.docs.isNotEmpty) {
        final doc = stockQuery.docs.first;
        final currentOut = (doc.data()['quantityOut'] as num?)?.toDouble() ?? 0.0;
        await _db.collection('inventory').doc(doc.id).update({
          'quantityOut': currentOut + act.quantity,
        });
      } else {
        // Create stock item
        final newStok = Stok(
          id: '',
          itemName: act.product,
          category: act.activityType == 'Pemupukan' ? 'Pupuk' : 'Pestisida',
          quantityIn: 0.0,
          quantityOut: act.quantity,
          unit: act.unit,
        );
        await _db.collection('inventory').add(newStok.toMap());
      }
    }

    // 3. Calculate cost
    double cost = 0.0;
    String category = 'Lainnya';
    if (act.activityType == 'Tenaga Kerja') {
      category = 'Upah';
      // Find worker wage
      final workerQuery = await _db
          .collection('workers')
          .where('name', isEqualTo: act.product)
          .limit(1)
          .get();
      if (workerQuery.docs.isNotEmpty) {
        final wage = (workerQuery.docs.first.data()['dailyWage'] as num?)?.toDouble() ?? 0.0;
        cost = wage * act.quantity;
      }
    } else {
      // Find product unit price from purchases
      final unitPrice = await getUnitPriceForProduct(act.product);
      cost = unitPrice * act.quantity;
      
      if (act.activityType == 'Pemupukan') {
        category = 'Pupuk';
      } else if (act.activityType == 'Penyemprotan') {
        category = 'Pestisida';
      } else if (act.activityType == 'Pemasangan Mulsa') {
        category = 'Mulsa';
      } else if (act.activityType == 'Pengairan') {
        category = 'Air';
      }
    }

    // 4. Add expense
    final expense = Pengeluaran(
      id: '',
      date: act.date,
      seasonId: act.seasonId,
      category: category,
      description: '${act.activityType} - ${act.product} (${act.quantity} ${act.unit})',
      amount: cost,
      photoUrl: '',
    );
    await addExpense(expense);
  }

  Future<void> deleteActivity(AktivitasLapangan act) async {
    await _db.collection('activities').doc(act.id).delete();
    
    if (act.status == 'Dilaksanakan') {
      // Revert stock
      if (act.activityType != 'Tenaga Kerja' && act.product.isNotEmpty) {
        final stockQuery = await _db
            .collection('inventory')
            .where('itemName', isEqualTo: act.product)
            .limit(1)
            .get();
        if (stockQuery.docs.isNotEmpty) {
          final doc = stockQuery.docs.first;
          final currentOut = (doc.data()['quantityOut'] as num?)?.toDouble() ?? 0.0;
          await _db.collection('inventory').doc(doc.id).update({
            'quantityOut': (currentOut - act.quantity) >= 0 ? (currentOut - act.quantity) : 0.0,
          });
        }
      }
      
      // Revert expense
      double cost = 0.0;
      String category = 'Lainnya';
      if (act.activityType == 'Tenaga Kerja') {
        category = 'Upah';
        final workerQuery = await _db
            .collection('workers')
            .where('name', isEqualTo: act.product)
            .limit(1)
            .get();
        if (workerQuery.docs.isNotEmpty) {
          final wage = (workerQuery.docs.first.data()['dailyWage'] as num?)?.toDouble() ?? 0.0;
          cost = wage * act.quantity;
        }
      } else {
        final unitPrice = await getUnitPriceForProduct(act.product);
        cost = unitPrice * act.quantity;
        if (act.activityType == 'Pemupukan') {
          category = 'Pupuk';
        } else if (act.activityType == 'Penyemprotan') {
          category = 'Pestisida';
        } else if (act.activityType == 'Pemasangan Mulsa') {
          category = 'Mulsa';
        } else if (act.activityType == 'Pengairan') {
          category = 'Air';
        }
      }

      final expenseQuery = await _db
          .collection('expenses')
          .where('seasonId', isEqualTo: act.seasonId)
          .where('category', isEqualTo: category)
          .where('amount', isEqualTo: cost)
          .limit(1)
          .get();
      if (expenseQuery.docs.isNotEmpty) {
        await _db.collection('expenses').doc(expenseQuery.docs.first.id).delete();
      }
    }
  }
}

// Watch Activities Stream
final watchActivitiesProvider = StreamProvider.family<List<AktivitasLapangan>, String>((ref, seasonId) {
  return ref.watch(databaseRepositoryProvider).watchActivities(seasonId);
});

// --- RIVERPOD PROVIDER ---
final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return DatabaseRepository();
});

// Watch Fields Stream
final watchFieldsProvider = StreamProvider<List<Lahan>>((ref) {
  return ref.watch(databaseRepositoryProvider).watchFields();
});

// Watch Crops Stream
final watchCropsProvider = StreamProvider<List<Tanaman>>((ref) {
  return ref.watch(databaseRepositoryProvider).watchCrops();
});

// Watch Seasons Stream
final watchSeasonsProvider = StreamProvider<List<MusimTanam>>((ref) {
  return ref.watch(databaseRepositoryProvider).watchSeasons();
});

// Watch Stok Stream
final watchStokProvider = StreamProvider<List<Stok>>((ref) {
  return ref.watch(databaseRepositoryProvider).watchStok();
});

// Watch Purchases Stream
final purchasesFilterProvider = StateProvider<String>((ref) => 'date_desc');

final watchPurchasesProvider = StreamProvider<List<Pembelian>>((ref) {
  final filter = ref.watch(purchasesFilterProvider);
  String orderByField = 'purchaseDate';
  bool descending = true;

  switch (filter) {
    case 'date_desc':
      orderByField = 'purchaseDate';
      descending = true;
      break;
    case 'date_asc':
      orderByField = 'purchaseDate';
      descending = false;
      break;
    case 'price_desc':
      orderByField = 'totalPrice';
      descending = true;
      break;
    case 'price_asc':
      orderByField = 'totalPrice';
      descending = false;
      break;
  }

  return ref.watch(databaseRepositoryProvider).watchPurchases(
        orderByField: orderByField,
        descending: descending,
      );
});

// Watch Pests Stream
final watchPestsProvider = StreamProvider<List<HamaPenyakit>>((ref) {
  return ref.watch(databaseRepositoryProvider).watchPests();
});

// Watch Workers Stream
final watchWorkersProvider = StreamProvider<List<TenagaKerja>>((ref) {
  return ref.watch(databaseRepositoryProvider).watchWorkers();
});

// Watch Worker Activities Stream
final watchWorkerActivitiesProvider = StreamProvider<List<AktivitasPekerja>>((ref) {
  return ref.watch(databaseRepositoryProvider).watchWorkerActivities();
});

// Watch Expenses Stream
final watchExpensesProvider = StreamProvider<List<Pengeluaran>>((ref) {
  return ref.watch(databaseRepositoryProvider).watchExpenses();
});

// Watch Harvests Stream
final watchHarvestsProvider = StreamProvider<List<Panen>>((ref) {
  return ref.watch(databaseRepositoryProvider).watchHarvests();
});

// Watch Buyers Stream
final watchBuyersProvider = StreamProvider<List<Tengkulak>>((ref) {
  return ref.watch(databaseRepositoryProvider).watchBuyers();
});

// Provider untuk menyimpan state filter pengurutan penjualan
final salesFilterProvider = StateProvider<String>((ref) => 'date_desc');

// Watch Sales Stream
final watchSalesProvider = StreamProvider<List<Penjualan>>((ref) {
  final filter = ref.watch(salesFilterProvider);
  String orderByField = 'date';
  bool descending = true;

  // Memetakan nilai filter pilihan pengguna ke parameter query Firestore
  switch (filter) {
    case 'date_desc': // Tanggal Terbaru
      orderByField = 'date';
      descending = true;
      break;
    case 'date_asc': // Tanggal Terlama
      orderByField = 'date';
      descending = false;
      break;
    case 'price_desc': // Nominal Penjualan Terbesar
      orderByField = 'totalPrice';
      descending = true;
      break;
    case 'price_asc': // Nominal Penjualan Terkecil
      orderByField = 'totalPrice';
      descending = false;
      break;
    case 'weight_desc': // Berat Terbesar
      orderByField = 'weight';
      descending = true;
      break;
    case 'weight_asc': // Berat Terkecil
      orderByField = 'weight';
      descending = false;
      break;
  }

  return ref.watch(databaseRepositoryProvider).watchSales(
        orderByField: orderByField,
        descending: descending,
      );
});

double parseQuantity(String text) {
  final regExp = RegExp(r'^\s*([0-9]+(?:[\.,][0-9]+)?)');
  final match = regExp.firstMatch(text);
  if (match != null) {
    final numStr = match.group(1)!.replaceAll(',', '.');
    return double.tryParse(numStr) ?? 0.0;
  }
  return 0.0;
}

String extractUnit(String text) {
  final regExp = RegExp(r'^\s*[0-9]+(?:[\.,][0-9]+)?\s*(.*)$');
  final match = regExp.firstMatch(text);
  if (match != null) {
    final unitStr = match.group(1)!.trim();
    return unitStr.isNotEmpty ? unitStr : 'Pcs';
  }
  return 'Pcs';
}
