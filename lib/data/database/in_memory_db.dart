import '../../data/models/user_profile_model.dart';
import '../../data/models/vital_model.dart';
import '../../data/models/medicine_model.dart';
import '../../data/models/symptom_model.dart';
import '../../data/models/doctor_visit_model.dart';
import '../../data/models/prescription_model.dart';

class InMemoryDb {
  static final List<UserProfileModel> profiles = [
    UserProfileModel(
      id: 1,
      name: 'Margaret Chen',
      age: 78,
      bloodGroup: 'O+',
      conditions: 'Hypertension, Mild Osteoarthritis',
      allergies: 'Penicillin',
      emergencyContactName: 'David Chen (Son)',
      emergencyContactPhone: '+1-555-0199',
      createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      userId: 'margaret@meditrack.com',
      syncStatus: 1,
      profileImagePath: null,
    ),
    UserProfileModel(
      id: 2,
      name: 'James Miller',
      age: 82,
      bloodGroup: 'A+',
      conditions: 'Type 2 Diabetes, Coronary Artery Disease',
      allergies: 'Sulfa Drugs',
      emergencyContactName: 'Emily Miller (Daughter)',
      emergencyContactPhone: '+1-555-0142',
      createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      userId: 'james@meditrack.com',
      syncStatus: 1,
      profileImagePath: null,
    ),
    UserProfileModel(
      id: 3,
      name: 'Evelyn Stone',
      age: 74,
      bloodGroup: 'B-',
      conditions: 'Chronic Kidney Disease Stage 2',
      allergies: 'None',
      emergencyContactName: 'Robert Stone (Husband)',
      emergencyContactPhone: '+1-555-0185',
      createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      userId: 'evelyn@meditrack.com',
      syncStatus: 1,
      profileImagePath: null,
    ),
  ];

  static UserProfileModel? userProfile;

  static final List<VitalModel> vitals = [
    // Margaret Chen's logs
    VitalModel(
      id: 1,
      systolic: 128,
      diastolic: 82,
      heartRate: 72,
      temperature: 36.6,
      oxygenSaturation: 98,
      bloodGlucose: 95,
      weight: 64.5,
      recordedAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      notes: 'Blood pressure slightly elevated but stable.',
      userId: 'margaret@meditrack.com',
      syncStatus: 1,
    ),
    VitalModel(
      id: 2,
      systolic: 142, // High! Alerts will be triggered
      diastolic: 92,
      heartRate: 80,
      temperature: 36.8,
      oxygenSaturation: 97,
      bloodGlucose: 104,
      weight: 64.6,
      recordedAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      notes: 'Felt slightly dizzy in the morning.',
      userId: 'margaret@meditrack.com',
      syncStatus: 1,
    ),
    
    // James Miller's logs
    VitalModel(
      id: 3,
      systolic: 118,
      diastolic: 76,
      heartRate: 68,
      temperature: 36.5,
      oxygenSaturation: 96,
      bloodGlucose: 165, // High glucose!
      weight: 78.2,
      recordedAt: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      notes: 'Post-lunch glucose test.',
      userId: 'james@meditrack.com',
      syncStatus: 1,
    ),
    VitalModel(
      id: 4,
      systolic: 120,
      diastolic: 78,
      heartRate: 70,
      temperature: 36.6,
      oxygenSaturation: 97,
      bloodGlucose: 115,
      weight: 78.0,
      recordedAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      notes: 'Fasting glucose level normal.',
      userId: 'james@meditrack.com',
      syncStatus: 1,
    ),

    // Evelyn Stone's logs
    VitalModel(
      id: 5,
      systolic: 115,
      diastolic: 70,
      heartRate: 64,
      temperature: 36.4,
      oxygenSaturation: 99,
      bloodGlucose: 88,
      weight: 59.0,
      recordedAt: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      notes: 'Feeling active today.',
      userId: 'evelyn@meditrack.com',
      syncStatus: 1,
    ),
  ];

  static final List<MedicineModel> medicines = [
    // Margaret Chen
    MedicineModel(
      id: 1,
      name: 'Lisinopril',
      dosage: '10mg',
      frequency: 'Once daily',
      times: '09:00',
      startDate: '2026-01-01',
      isActive: true,
      notes: 'For blood pressure control. Take with water.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      userId: 'margaret@meditrack.com',
      syncStatus: 1,
    ),
    MedicineModel(
      id: 2,
      name: 'Glucosamine',
      dosage: '500mg',
      frequency: 'Twice daily',
      times: '08:00,20:00',
      startDate: '2026-01-01',
      isActive: true,
      notes: 'Joint health support.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      userId: 'margaret@meditrack.com',
      syncStatus: 1,
    ),

    // James Miller
    MedicineModel(
      id: 3,
      name: 'Metformin',
      dosage: '850mg',
      frequency: 'Twice daily',
      times: '08:00,19:00',
      startDate: '2026-02-15',
      isActive: true,
      notes: 'Diabetes management. Take with meals.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      userId: 'james@meditrack.com',
      syncStatus: 1,
    ),
    MedicineModel(
      id: 4,
      name: 'Clopidogrel',
      dosage: '75mg',
      frequency: 'Once daily',
      times: '21:00',
      startDate: '2026-03-01',
      isActive: true,
      notes: 'Cardiovascular protection.',
      createdAt: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      userId: 'james@meditrack.com',
      syncStatus: 1,
    ),

    // Evelyn Stone
    MedicineModel(
      id: 5,
      name: 'Calcium Carbonate',
      dosage: '600mg',
      frequency: 'Once daily',
      times: '12:00',
      startDate: '2026-04-10',
      isActive: true,
      notes: 'Kidney support and bone health.',
      createdAt: DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
      userId: 'evelyn@meditrack.com',
      syncStatus: 1,
    ),
  ];

  static final List<SymptomModel> symptoms = [
    // Margaret Chen
    SymptomModel(
      id: 1,
      symptomName: 'Mild Joint Stiffness',
      severity: 3,
      notes: 'Stiffness in knees after sitting for long periods.',
      recordedAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      userId: 'margaret@meditrack.com',
      syncStatus: 1,
    ),

    // James Miller
    SymptomModel(
      id: 2,
      symptomName: 'Increased Thirst',
      severity: 5,
      notes: 'Felt unusually dry mouth, glucose was high.',
      recordedAt: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      userId: 'james@meditrack.com',
      syncStatus: 1,
    ),
  ];

  static final List<DoctorVisitModel> doctorVisits = [
    // Margaret Chen
    DoctorVisitModel(
      id: 1,
      doctorName: 'Dr. Sarah Jenkins (Cardiologist)',
      visitDate: DateTime.now().add(const Duration(days: 4)).toIso8601String(),
      diagnosis: 'Routine Cardiovascular Follow-up',
      prescription: 'Continue Lisinopril 10mg',
      followUpDate: DateTime.now().add(const Duration(days: 90)).toIso8601String(),
      notes: 'Bring vital logs for review.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      userId: 'margaret@meditrack.com',
      syncStatus: 1,
    ),

    // James Miller
    DoctorVisitModel(
      id: 2,
      doctorName: 'Dr. Alan Parker (Endocrinologist)',
      visitDate: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      diagnosis: 'Diabetes Type 2 Progress Check',
      prescription: 'Increase Metformin if fasting glucose exceeds 140.',
      followUpDate: DateTime.now().add(const Duration(days: 60)).toIso8601String(),
      notes: 'HbA1c test results requested.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      userId: 'james@meditrack.com',
      syncStatus: 1,
    ),
  ];

  static final List<PrescriptionModel> prescriptions = [];
}
