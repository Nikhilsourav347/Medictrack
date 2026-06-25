import 'package:flutter/foundation.dart';
import '../../shared/utils/auth_helper.dart';
import '../database/database_helper.dart';
import '../database/in_memory_db.dart';
import '../models/vital_model.dart';

class VitalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _getCurrentUserEmail() {
    return AuthHelper().userEmail ?? 'anonymous';
  }

  Future<int> insertVital(VitalModel vital) async {
    final finalUser = vital.userId ?? _getCurrentUserEmail();
    final vitalWithUser = vital.copyWith(userId: finalUser, syncStatus: vital.syncStatus);
    
    if (kIsWeb) {
      final newId = InMemoryDb.vitals.isEmpty ? 1 : InMemoryDb.vitals.map((v) => v.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      InMemoryDb.vitals.insert(0, vitalWithUser.copyWith(id: newId));
      return newId;
    }
    final db = await _dbHelper.database;
    return await db.insert('vitals', vitalWithUser.toMap());
  }

  Future<List<VitalModel>> getAllVitals({String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      return InMemoryDb.vitals.where((v) => v.userId == targetUser).toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'vitals',
      where: 'userId = ?',
      whereArgs: [targetUser],
      orderBy: 'recordedAt DESC',
    );
    return maps.map((m) => VitalModel.fromMap(m)).toList();
  }

  Future<List<VitalModel>> getVitalsBetween(
      String startDate, String endDate, {String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      final endLimit = '$endDate 23:59:59';
      return InMemoryDb.vitals.where((v) {
        return v.userId == targetUser && v.recordedAt.compareTo(startDate) >= 0 && v.recordedAt.compareTo(endLimit) <= 0;
      }).toList()..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'vitals',
      where: 'userId = ? AND recordedAt >= ? AND recordedAt <= ?',
      whereArgs: [targetUser, startDate, '$endDate 23:59:59'],
      orderBy: 'recordedAt DESC',
    );
    return maps.map((m) => VitalModel.fromMap(m)).toList();
  }

  Future<List<VitalModel>> getVitalsByDateRange(
      String startDate, String endDate, {String? userId}) async {
    return getVitalsBetween(startDate, endDate, userId: userId);
  }

  Future<VitalModel?> getLatestVital({String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      final userVitals = InMemoryDb.vitals.where((v) => v.userId == targetUser).toList();
      if (userVitals.isEmpty) return null;
      userVitals.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return userVitals.first;
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'vitals',
      where: 'userId = ?',
      whereArgs: [targetUser],
      orderBy: 'recordedAt DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return VitalModel.fromMap(maps.first);
  }

  Future<List<VitalModel>> getRecentVitals(int limit, {String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      final userVitals = InMemoryDb.vitals.where((v) => v.userId == targetUser).toList();
      userVitals.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return userVitals.take(limit).toList();
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'vitals',
      where: 'userId = ?',
      whereArgs: [targetUser],
      orderBy: 'recordedAt DESC',
      limit: limit,
    );
    return maps.map((m) => VitalModel.fromMap(m)).toList();
  }

  Future<int> updateVital(VitalModel vital) async {
    final finalUser = vital.userId ?? _getCurrentUserEmail();
    final vitalWithUser = vital.copyWith(userId: finalUser);
    
    if (kIsWeb) {
      final idx = InMemoryDb.vitals.indexWhere((v) => v.id == vital.id);
      if (idx >= 0) {
        InMemoryDb.vitals[idx] = vitalWithUser;
        return 1;
      }
      return 0;
    }
    final db = await _dbHelper.database;
    return await db.update(
      'vitals',
      vitalWithUser.toMap(),
      where: 'id = ?',
      whereArgs: [vital.id],
    );
  }

  Future<int> deleteVital(int id) async {
    if (kIsWeb) {
      InMemoryDb.vitals.removeWhere((v) => v.id == id);
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.delete('vitals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<VitalModel>> getUnsyncedVitals() async {
    if (kIsWeb) {
      return InMemoryDb.vitals.where((v) => v.syncStatus == 0).toList();
    }
    final db = await _dbHelper.database;
    final maps = await db.query('vitals', where: 'syncStatus = 0');
    return maps.map((m) => VitalModel.fromMap(m)).toList();
  }

  Future<void> markAsSynced(int id) async {
    if (kIsWeb) {
      final idx = InMemoryDb.vitals.indexWhere((v) => v.id == id);
      if (idx >= 0) {
        InMemoryDb.vitals[idx] = InMemoryDb.vitals[idx].copyWith(syncStatus: 1);
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update('vitals', {'syncStatus': 1}, where: 'id = ?', whereArgs: [id]);
  }
}

