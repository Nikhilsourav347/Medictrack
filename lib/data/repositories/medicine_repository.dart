import 'package:flutter/foundation.dart';
import '../../shared/utils/auth_helper.dart';
import '../database/database_helper.dart';
import '../database/in_memory_db.dart';
import '../models/medicine_model.dart';

class MedicineRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _getCurrentUserEmail() {
    return AuthHelper().userEmail ?? 'anonymous';
  }

  Future<int> insertMedicine(MedicineModel medicine) async {
    final finalUser = medicine.userId ?? _getCurrentUserEmail();
    final medWithUser = medicine.copyWith(userId: finalUser, syncStatus: medicine.syncStatus);
    
    if (kIsWeb) {
      final newId = InMemoryDb.medicines.isEmpty ? 1 : InMemoryDb.medicines.map((m) => m.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      InMemoryDb.medicines.insert(0, medWithUser.copyWith(id: newId));
      return newId;
    }
    final db = await _dbHelper.database;
    return await db.insert('medicines', medWithUser.toMap());
  }

  Future<List<MedicineModel>> getAllMedicines({String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      return InMemoryDb.medicines.where((m) => m.userId == targetUser).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'medicines',
      where: 'userId = ?',
      whereArgs: [targetUser],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => MedicineModel.fromMap(m)).toList();
  }

  Future<List<MedicineModel>> getActiveMedicines({String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      return InMemoryDb.medicines.where((m) => m.userId == targetUser && m.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'medicines',
      where: 'userId = ? AND isActive = ?',
      whereArgs: [targetUser, 1],
      orderBy: 'name ASC',
    );
    return maps.map((m) => MedicineModel.fromMap(m)).toList();
  }

  Future<MedicineModel?> getMedicineById(int id) async {
    if (kIsWeb) {
      final matches = InMemoryDb.medicines.where((m) => m.id == id);
      return matches.isEmpty ? null : matches.first;
    }
    final db = await _dbHelper.database;
    final maps = await db.query('medicines', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return MedicineModel.fromMap(maps.first);
  }

  Future<int> updateMedicine(MedicineModel medicine) async {
    final finalUser = medicine.userId ?? _getCurrentUserEmail();
    final medWithUser = medicine.copyWith(userId: finalUser);
    
    if (kIsWeb) {
      final idx = InMemoryDb.medicines.indexWhere((m) => m.id == medicine.id);
      if (idx >= 0) {
        InMemoryDb.medicines[idx] = medWithUser;
        return 1;
      }
      return 0;
    }
    final db = await _dbHelper.database;
    return await db.update(
      'medicines',
      medWithUser.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<int> toggleActive(int id, bool isActive) async {
    if (kIsWeb) {
      final idx = InMemoryDb.medicines.indexWhere((m) => m.id == id);
      if (idx >= 0) {
        InMemoryDb.medicines[idx] = InMemoryDb.medicines[idx].copyWith(isActive: isActive);
        return 1;
      }
      return 0;
    }
    final db = await _dbHelper.database;
    return await db.update(
      'medicines',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedicine(int id) async {
    if (kIsWeb) {
      InMemoryDb.medicines.removeWhere((m) => m.id == id);
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MedicineModel>> getUnsyncedMedicines() async {
    if (kIsWeb) {
      return InMemoryDb.medicines.where((m) => m.syncStatus == 0).toList();
    }
    final db = await _dbHelper.database;
    final maps = await db.query('medicines', where: 'syncStatus = 0');
    return maps.map((m) => MedicineModel.fromMap(m)).toList();
  }

  Future<void> markAsSynced(int id) async {
    if (kIsWeb) {
      final idx = InMemoryDb.medicines.indexWhere((m) => m.id == id);
      if (idx >= 0) {
        InMemoryDb.medicines[idx] = InMemoryDb.medicines[idx].copyWith(syncStatus: 1);
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update('medicines', {'syncStatus': 1}, where: 'id = ?', whereArgs: [id]);
  }
}

