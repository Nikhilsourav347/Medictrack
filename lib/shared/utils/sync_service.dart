import 'package:flutter/material.dart';
import '../../data/repositories/vital_repository.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/symptom_repository.dart';
import '../../data/repositories/doctor_visit_repository.dart';
import '../../data/repositories/user_profile_repository.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final UserProfileRepository _profileRepo = UserProfileRepository();
  final VitalRepository _vitalRepo = VitalRepository();
  final MedicineRepository _medicineRepo = MedicineRepository();
  final SymptomRepository _symptomRepo = SymptomRepository();
  final DoctorVisitRepository _visitRepo = DoctorVisitRepository();

  bool _isOnline = true;
  bool _isSyncing = false;
  final List<String> _syncLogs = [];

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  List<String> get syncLogs => List.unmodifiable(_syncLogs);

  void log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _syncLogs.insert(0, '[$timestamp] $message');
    notifyListeners();
  }

  void clearLogs() {
    _syncLogs.clear();
    notifyListeners();
  }

  Future<void> toggleConnectivity() async {
    _isOnline = !_isOnline;
    log(_isOnline ? 'Simulated connection: ONLINE' : 'Simulated connection: OFFLINE');
    notifyListeners();
    if (_isOnline) {
      await triggerSync();
    }
  }

  Future<int> getPendingSyncCount() async {
    try {
      final unsyncedProfiles = await _profileRepo.getUnsyncedProfiles();
      final unsyncedVitals = await _vitalRepo.getUnsyncedVitals();
      final unsyncedMeds = await _medicineRepo.getUnsyncedMedicines();
      final unsyncedSymptoms = await _symptomRepo.getUnsyncedSymptoms();
      final unsyncedVisits = await _visitRepo.getUnsyncedVisits();
      
      return unsyncedProfiles.length +
          unsyncedVitals.length +
          unsyncedMeds.length +
          unsyncedSymptoms.length +
          unsyncedVisits.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> triggerSync() async {
    if (!_isOnline) {
      log('Cannot sync: System is offline');
      return;
    }
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();
    log('Synchronization cycle started...');

    try {
      // Sync Profiles
      final profiles = await _profileRepo.getUnsyncedProfiles();
      if (profiles.isNotEmpty) {
        log('Uploading ${profiles.length} profile updates...');
        for (var p in profiles) {
          await Future.delayed(const Duration(milliseconds: 200)); // Simulate delay
          if (p.id != null) {
            await _profileRepo.markAsSynced(p.id!);
            log('Profile synced for elder: ${p.name}');
          }
        }
      }

      // Sync Vitals
      final vitals = await _vitalRepo.getUnsyncedVitals();
      if (vitals.isNotEmpty) {
        log('Uploading ${vitals.length} vital records...');
        for (var v in vitals) {
          await Future.delayed(const Duration(milliseconds: 150));
          if (v.id != null) {
            await _vitalRepo.markAsSynced(v.id!);
            log('Synced Vital reading (systolic: ${v.systolic}, diastolic: ${v.diastolic})');
          }
        }
      }

      // Sync Medicines
      final medicines = await _medicineRepo.getUnsyncedMedicines();
      if (medicines.isNotEmpty) {
        log('Uploading ${medicines.length} medicine records...');
        for (var m in medicines) {
          await Future.delayed(const Duration(milliseconds: 150));
          if (m.id != null) {
            await _medicineRepo.markAsSynced(m.id!);
            log('Synced medicine reminder: ${m.name}');
          }
        }
      }

      // Sync Symptoms
      final symptoms = await _symptomRepo.getUnsyncedSymptoms();
      if (symptoms.isNotEmpty) {
        log('Uploading ${symptoms.length} symptom diary records...');
        for (var s in symptoms) {
          await Future.delayed(const Duration(milliseconds: 150));
          if (s.id != null) {
            await _symptomRepo.markAsSynced(s.id!);
            log('Synced symptom record: ${s.symptomName}');
          }
        }
      }

      // Sync Doctor Visits
      final visits = await _visitRepo.getUnsyncedVisits();
      if (visits.isNotEmpty) {
        log('Uploading ${visits.length} doctor visit records...');
        for (var v in visits) {
          await Future.delayed(const Duration(milliseconds: 150));
          if (v.id != null) {
            await _visitRepo.markAsSynced(v.id!);
            log('Synced Doctor Visit log: ${v.doctorName}');
          }
        }
      }

      log('Synchronization complete! All records are in sync.');
    } catch (e) {
      log('Error during sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
