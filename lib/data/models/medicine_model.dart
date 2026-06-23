class MedicineModel {
  final int? id;
  final String name;
  final String? dosage;
  final String frequency;
  final String times; // comma-separated, e.g. "08:00,14:00,20:00"
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final String? notes;
  final String createdAt;
  final String? userId;
  final int syncStatus;
  final String? lastUpdated;

  MedicineModel({
    this.id,
    required this.name,
    this.dosage,
    required this.frequency,
    required this.times,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    this.userId,
    this.syncStatus = 0,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt,
      'userId': userId,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated,
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      dosage: map['dosage'] as String?,
      frequency: map['frequency'] as String,
      times: map['times'] as String,
      startDate: map['startDate'] as String?,
      endDate: map['endDate'] as String?,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as String,
      userId: map['userId'] as String?,
      syncStatus: map['syncStatus'] as int? ?? 0,
      lastUpdated: map['lastUpdated'] as String?,
    );
  }

  MedicineModel copyWith({
    int? id,
    String? name,
    String? dosage,
    String? frequency,
    String? times,
    String? startDate,
    String? endDate,
    bool? isActive,
    String? notes,
    String? createdAt,
    String? userId,
    int? syncStatus,
    String? lastUpdated,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
