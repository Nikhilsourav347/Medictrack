import 'package:flutter/foundation.dart';
import '../../shared/utils/auth_helper.dart';
import '../database/database_helper.dart';
import '../database/in_memory_db.dart';
import '../models/symptom_model.dart';

class SymptomRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _getCurrentUserEmail() {
    return AuthHelper().userEmail ?? 'anonymous';
  }

  Future<int> insertSymptom(SymptomModel symptom) async {
    final finalUser = symptom.userId ?? _getCurrentUserEmail();
    final symWithUser = symptom.copyWith(userId: finalUser, syncStatus: symptom.syncStatus);
    
    if (kIsWeb) {
      final newId = InMemoryDb.symptoms.isEmpty ? 1 : InMemoryDb.symptoms.map((s) => s.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      InMemoryDb.symptoms.insert(0, symWithUser.copyWith(id: newId));
      return newId;
    }
    final db = await _dbHelper.database;
    return await db.insert('symptoms', symWithUser.toMap());
  }

  Future<List<SymptomModel>> getAllSymptoms({String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      return InMemoryDb.symptoms.where((s) => s.userId == targetUser).toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'symptoms',
      where: 'userId = ?',
      whereArgs: [targetUser],
      orderBy: 'recordedAt DESC',
    );
    return maps.map((m) => SymptomModel.fromMap(m)).toList();
  }

  Future<List<SymptomModel>> getSymptomsBetween(
      String startDate, String endDate, {String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      final endLimit = '$endDate 23:59:59';
      return InMemoryDb.symptoms.where((s) {
        return s.userId == targetUser && s.recordedAt.compareTo(startDate) >= 0 && s.recordedAt.compareTo(endLimit) <= 0;
      }).toList()..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'symptoms',
      where: 'userId = ? AND recordedAt >= ? AND recordedAt <= ?',
      whereArgs: [targetUser, startDate, '$endDate 23:59:59'],
      orderBy: 'recordedAt DESC',
    );
    return maps.map((m) => SymptomModel.fromMap(m)).toList();
  }

  Future<List<SymptomModel>> getSymptomsByDateRange(
      String startDate, String endDate, {String? userId}) async {
    return getSymptomsBetween(startDate, endDate, userId: userId);
  }

  Future<List<SymptomModel>> getRecentSymptoms(int limit, {String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      final userSymptoms = InMemoryDb.symptoms.where((s) => s.userId == targetUser).toList();
      userSymptoms.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return userSymptoms.take(limit).toList();
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'symptoms',
      where: 'userId = ?',
      whereArgs: [targetUser],
      orderBy: 'recordedAt DESC',
      limit: limit,
    );
    return maps.map((m) => SymptomModel.fromMap(m)).toList();
  }

  Future<int> updateSymptom(SymptomModel symptom) async {
    final finalUser = symptom.userId ?? _getCurrentUserEmail();
    final symWithUser = symptom.copyWith(userId: finalUser);
    
    if (kIsWeb) {
      final idx = InMemoryDb.symptoms.indexWhere((s) => s.id == symptom.id);
      if (idx >= 0) {
        InMemoryDb.symptoms[idx] = symWithUser;
        return 1;
      }
      return 0;
    }
    final db = await _dbHelper.database;
    return await db.update(
      'symptoms',
      symWithUser.toMap(),
      where: 'id = ?',
      whereArgs: [symptom.id],
    );
  }

  Future<int> deleteSymptom(int id) async {
    if (kIsWeb) {
      InMemoryDb.symptoms.removeWhere((s) => s.id == id);
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.delete('symptoms', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SymptomModel>> getUnsyncedSymptoms() async {
    if (kIsWeb) {
      return InMemoryDb.symptoms.where((s) => s.syncStatus == 0).toList();
    }
    final db = await _dbHelper.database;
    final maps = await db.query('symptoms', where: 'syncStatus = 0');
    return maps.map((m) => SymptomModel.fromMap(m)).toList();
  }

  Future<void> markAsSynced(int id) async {
    if (kIsWeb) {
      final idx = InMemoryDb.symptoms.indexWhere((s) => s.id == id);
      if (idx >= 0) {
        InMemoryDb.symptoms[idx] = InMemoryDb.symptoms[idx].copyWith(syncStatus: 1);
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update('symptoms', {'syncStatus': 1}, where: 'id = ?', whereArgs: [id]);
  }
}

