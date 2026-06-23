import 'package:flutter/foundation.dart';
import '../../shared/utils/auth_helper.dart';
import '../database/database_helper.dart';
import '../database/in_memory_db.dart';
import '../models/user_profile_model.dart';

class UserProfileRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _getCurrentUserEmail() {
    return AuthHelper().userEmail ?? 'anonymous';
  }

  Future<int> insertProfile(UserProfileModel profile) async {
    final finalUser = profile.userId ?? _getCurrentUserEmail();
    final profileWithUser = profile.copyWith(userId: finalUser, syncStatus: profile.syncStatus);
    
    if (kIsWeb) {
      InMemoryDb.userProfile = profileWithUser;
      // Add to list if not already there
      final idx = InMemoryDb.profiles.indexWhere((p) => p.userId == finalUser);
      if (idx >= 0) {
        InMemoryDb.profiles[idx] = profileWithUser;
      } else {
        InMemoryDb.profiles.add(profileWithUser);
      }
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.insert('user_profile', profileWithUser.toMap());
  }

  Future<UserProfileModel?> getProfile({String? userId}) async {
    final targetUser = userId ?? _getCurrentUserEmail();
    if (kIsWeb) {
      final matches = InMemoryDb.profiles.where((p) => p.userId == targetUser);
      if (matches.isNotEmpty) return matches.first;
      return InMemoryDb.userProfile;
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'user_profile',
      where: 'userId = ?',
      whereArgs: [targetUser],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserProfileModel.fromMap(maps.first);
  }

  Future<List<UserProfileModel>> getAllProfiles() async {
    if (kIsWeb) {
      return InMemoryDb.profiles;
    }
    final db = await _dbHelper.database;
    final maps = await db.query('user_profile');
    return maps.map((m) => UserProfileModel.fromMap(m)).toList();
  }

  Future<int> updateProfile(UserProfileModel profile) async {
    final finalUser = profile.userId ?? _getCurrentUserEmail();
    final profileWithUser = profile.copyWith(userId: finalUser);
    
    if (kIsWeb) {
      InMemoryDb.userProfile = profileWithUser;
      final idx = InMemoryDb.profiles.indexWhere((p) => p.userId == finalUser);
      if (idx >= 0) {
        InMemoryDb.profiles[idx] = profileWithUser;
      }
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.update(
      'user_profile',
      profileWithUser.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  /// Insert if not exists, update if exists
  Future<void> upsertProfile(UserProfileModel profile) async {
    final finalUser = profile.userId ?? _getCurrentUserEmail();
    final existing = await getProfile(userId: finalUser);
    if (existing == null) {
      await insertProfile(profile.copyWith(userId: finalUser));
    } else {
      await updateProfile(profile.copyWith(id: existing.id, userId: finalUser));
    }
  }

  Future<int> deleteProfile(int id) async {
    if (kIsWeb) {
      InMemoryDb.userProfile = null;
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.delete('user_profile', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<UserProfileModel>> getUnsyncedProfiles() async {
    if (kIsWeb) {
      return InMemoryDb.profiles.where((p) => p.syncStatus == 0).toList();
    }
    final db = await _dbHelper.database;
    final maps = await db.query('user_profile', where: 'syncStatus = 0');
    return maps.map((m) => UserProfileModel.fromMap(m)).toList();
  }

  Future<void> markAsSynced(int id) async {
    if (kIsWeb) {
      final idx = InMemoryDb.profiles.indexWhere((p) => p.id == id);
      if (idx >= 0) {
        InMemoryDb.profiles[idx] = InMemoryDb.profiles[idx].copyWith(syncStatus: 1);
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update('user_profile', {'syncStatus': 1}, where: 'id = ?', whereArgs: [id]);
  }
}

