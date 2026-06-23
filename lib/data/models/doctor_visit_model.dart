class DoctorVisitModel {
  final int? id;
  final String doctorName;
  final String visitDate;
  final String? diagnosis;
  final String? prescription;
  final String? followUpDate;
  final String? notes;
  final String createdAt;
  final String? userId;
  final int syncStatus;
  final String? lastUpdated;

  DoctorVisitModel({
    this.id,
    required this.doctorName,
    required this.visitDate,
    this.diagnosis,
    this.prescription,
    this.followUpDate,
    this.notes,
    required this.createdAt,
    this.userId,
    this.syncStatus = 0,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'doctorName': doctorName,
      'visitDate': visitDate,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'followUpDate': followUpDate,
      'notes': notes,
      'createdAt': createdAt,
      'userId': userId,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated,
    };
  }

  factory DoctorVisitModel.fromMap(Map<String, dynamic> map) {
    return DoctorVisitModel(
      id: map['id'] as int?,
      doctorName: map['doctorName'] as String,
      visitDate: map['visitDate'] as String,
      diagnosis: map['diagnosis'] as String?,
      prescription: map['prescription'] as String?,
      followUpDate: map['followUpDate'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as String,
      userId: map['userId'] as String?,
      syncStatus: map['syncStatus'] as int? ?? 0,
      lastUpdated: map['lastUpdated'] as String?,
    );
  }

  DoctorVisitModel copyWith({
    int? id,
    String? doctorName,
    String? visitDate,
    String? diagnosis,
    String? prescription,
    String? followUpDate,
    String? notes,
    String? createdAt,
    String? userId,
    int? syncStatus,
    String? lastUpdated,
  }) {
    return DoctorVisitModel(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      visitDate: visitDate ?? this.visitDate,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      followUpDate: followUpDate ?? this.followUpDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
