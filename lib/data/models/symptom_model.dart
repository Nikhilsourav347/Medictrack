class SymptomModel {
  final int? id;
  final String symptomName;
  final int severity; // 1-10
  final String? notes;
  final String recordedAt;
  final String? userId;
  final int syncStatus;
  final String? lastUpdated;

  SymptomModel({
    this.id,
    required this.symptomName,
    required this.severity,
    this.notes,
    required this.recordedAt,
    this.userId,
    this.syncStatus = 0,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'symptomName': symptomName,
      'severity': severity,
      'notes': notes,
      'recordedAt': recordedAt,
      'userId': userId,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated,
    };
  }

  factory SymptomModel.fromMap(Map<String, dynamic> map) {
    return SymptomModel(
      id: map['id'] as int?,
      symptomName: map['symptomName'] as String,
      severity: map['severity'] as int,
      notes: map['notes'] as String?,
      recordedAt: map['recordedAt'] as String,
      userId: map['userId'] as String?,
      syncStatus: map['syncStatus'] as int? ?? 0,
      lastUpdated: map['lastUpdated'] as String?,
    );
  }

  SymptomModel copyWith({
    int? id,
    String? symptomName,
    int? severity,
    String? notes,
    String? recordedAt,
    String? userId,
    int? syncStatus,
    String? lastUpdated,
  }) {
    return SymptomModel(
      id: id ?? this.id,
      symptomName: symptomName ?? this.symptomName,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      recordedAt: recordedAt ?? this.recordedAt,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
