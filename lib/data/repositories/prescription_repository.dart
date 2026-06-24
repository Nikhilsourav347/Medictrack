import 'package:flutter/foundation.dart';
import '../../shared/utils/auth_helper.dart';
import '../database/database_helper.dart';
import '../database/in_memory_db.dart';
import '../models/prescription_model.dart';

class PrescriptionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _getCurrentUserEmail() {
    return AuthHelper().userEmail ?? 'anonymous';
  }

  Future<int> insertPrescription(PrescriptionModel prescription) async {
    final finalUser = prescription.userId ?? _getCurrentUserEmail();
    final pWithUser = prescription.copyWith(userId: finalUser, syncStatus: prescription.syncStatus);
    
    if (kIsWeb) {
      final newId = InMemoryDb.prescriptions.isEmpty
          ? 1
          : InMemoryDb.prescriptions.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      InMemoryDb.prescriptions.insert(0, pWithUser.copyWith(id: newId));
      return newId;
    }
    final db = await _dbHelper.database;
    return await db.insert('prescriptions', pWithUser.toMap());
  }

  Future<List<PrescriptionModel>> getAllPrescriptions({String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      return InMemoryDb.prescriptions.where((p) => p.userId == targetUser).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'prescriptions',
      where: 'userId = ?',
      whereArgs: [targetUser],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => PrescriptionModel.fromMap(m)).toList();
  }

  Future<int> updatePrescription(PrescriptionModel prescription) async {
    final finalUser = prescription.userId ?? _getCurrentUserEmail();
    final pWithUser = prescription.copyWith(userId: finalUser);
    
    if (kIsWeb) {
      final idx = InMemoryDb.prescriptions.indexWhere((p) => p.id == prescription.id);
      if (idx >= 0) {
        InMemoryDb.prescriptions[idx] = pWithUser;
        return 1;
      }
      return 0;
    }
    final db = await _dbHelper.database;
    return await db.update(
      'prescriptions',
      pWithUser.toMap(),
      where: 'id = ?',
      whereArgs: [prescription.id],
    );
  }

  Future<int> deletePrescription(int id) async {
    if (kIsWeb) {
      InMemoryDb.prescriptions.removeWhere((p) => p.id == id);
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.delete('prescriptions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PrescriptionModel>> getUnsyncedPrescriptions() async {
    if (kIsWeb) {
      return InMemoryDb.prescriptions.where((p) => p.syncStatus == 0).toList();
    }
    final db = await _dbHelper.database;
    final maps = await db.query('prescriptions', where: 'syncStatus = 0');
    return maps.map((m) => PrescriptionModel.fromMap(m)).toList();
  }

  Future<void> markAsSynced(int id) async {
    if (kIsWeb) {
      final idx = InMemoryDb.prescriptions.indexWhere((p) => p.id == id);
      if (idx >= 0) {
        InMemoryDb.prescriptions[idx] = InMemoryDb.prescriptions[idx].copyWith(syncStatus: 1);
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update('prescriptions', {'syncStatus': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
