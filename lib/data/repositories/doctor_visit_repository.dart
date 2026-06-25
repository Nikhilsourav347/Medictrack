import 'package:flutter/foundation.dart';
import '../../shared/utils/auth_helper.dart';
import '../database/database_helper.dart';
import '../database/in_memory_db.dart';
import '../models/doctor_visit_model.dart';

class DoctorVisitRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _getCurrentUserEmail() {
    return AuthHelper().userEmail ?? 'anonymous';
  }

  Future<int> insertVisit(DoctorVisitModel visit) async {
    final finalUser = visit.userId ?? _getCurrentUserEmail();
    final visitWithUser = visit.copyWith(userId: finalUser, syncStatus: visit.syncStatus);
    
    if (kIsWeb) {
      final newId = InMemoryDb.doctorVisits.isEmpty ? 1 : InMemoryDb.doctorVisits.map((v) => v.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      InMemoryDb.doctorVisits.insert(0, visitWithUser.copyWith(id: newId));
      return newId;
    }
    final db = await _dbHelper.database;
    return await db.insert('doctor_visits', visitWithUser.toMap());
  }

  Future<List<DoctorVisitModel>> getAllVisits({String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      return InMemoryDb.doctorVisits.where((v) => v.userId == targetUser).toList()
        ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'doctor_visits',
      where: 'userId = ?',
      whereArgs: [targetUser],
      orderBy: 'visitDate DESC',
    );
    return maps.map((m) => DoctorVisitModel.fromMap(m)).toList();
  }

  Future<List<DoctorVisitModel>> getVisitsBetween(
      String startDate, String endDate, {String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      return InMemoryDb.doctorVisits.where((v) {
        return v.userId == targetUser && v.visitDate.compareTo(startDate) >= 0 && v.visitDate.compareTo(endDate) <= 0;
      }).toList()..sort((a, b) => b.visitDate.compareTo(a.visitDate));
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'doctor_visits',
      where: 'userId = ? AND visitDate >= ? AND visitDate <= ?',
      whereArgs: [targetUser, startDate, endDate],
      orderBy: 'visitDate DESC',
    );
    return maps.map((m) => DoctorVisitModel.fromMap(m)).toList();
  }

  Future<List<DoctorVisitModel>> getVisitsByDateRange(
      String startDate, String endDate, {String? userId}) async {
    return getVisitsBetween(startDate, endDate, userId: userId);
  }

  Future<DoctorVisitModel?> getLatestVisit({String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      final userVisits = InMemoryDb.doctorVisits.where((v) => v.userId == targetUser).toList();
      if (userVisits.isEmpty) return null;
      userVisits.sort((a, b) => b.visitDate.compareTo(a.visitDate));
      return userVisits.first;
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'doctor_visits',
      where: 'userId = ?',
      whereArgs: [targetUser],
      orderBy: 'visitDate DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DoctorVisitModel.fromMap(maps.first);
  }

  Future<List<DoctorVisitModel>> getRecentVisits(int limit, {String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      final userVisits = InMemoryDb.doctorVisits.where((v) => v.userId == targetUser).toList();
      userVisits.sort((a, b) => b.visitDate.compareTo(a.visitDate));
      return userVisits.take(limit).toList();
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'doctor_visits',
      where: 'userId = ?',
      whereArgs: [targetUser],
      orderBy: 'visitDate DESC',
      limit: limit,
    );
    return maps.map((m) => DoctorVisitModel.fromMap(m)).toList();
  }

  Future<int> updateVisit(DoctorVisitModel visit) async {
    final finalUser = visit.userId ?? _getCurrentUserEmail();
    final visitWithUser = visit.copyWith(userId: finalUser);
    
    if (kIsWeb) {
      final idx = InMemoryDb.doctorVisits.indexWhere((v) => v.id == visit.id);
      if (idx >= 0) {
        InMemoryDb.doctorVisits[idx] = visitWithUser;
        return 1;
      }
      return 0;
    }
    final db = await _dbHelper.database;
    return await db.update(
      'doctor_visits',
      visitWithUser.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<int> deleteVisit(int id) async {
    if (kIsWeb) {
      InMemoryDb.doctorVisits.removeWhere((v) => v.id == id);
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.delete('doctor_visits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DoctorVisitModel>> getUnsyncedVisits() async {
    if (kIsWeb) {
      return InMemoryDb.doctorVisits.where((v) => v.syncStatus == 0).toList();
    }
    final db = await _dbHelper.database;
    final maps = await db.query('doctor_visits', where: 'syncStatus = 0');
    return maps.map((m) => DoctorVisitModel.fromMap(m)).toList();
  }

  Future<void> markAsSynced(int id) async {
    if (kIsWeb) {
      final idx = InMemoryDb.doctorVisits.indexWhere((v) => v.id == id);
      if (idx >= 0) {
        InMemoryDb.doctorVisits[idx] = InMemoryDb.doctorVisits[idx].copyWith(syncStatus: 1);
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update('doctor_visits', {'syncStatus': 1}, where: 'id = ?', whereArgs: [id]);
  }
}

