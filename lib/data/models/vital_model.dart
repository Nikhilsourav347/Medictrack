class VitalModel {
  final int? id;
  final double? systolic;
  final double? diastolic;
  final double? heartRate;
  final double? temperature;
  final double? oxygenSaturation;
  final double? bloodGlucose;
  final double? weight;
  final String? notes;
  final String recordedAt;
  final String? userId;
  final int syncStatus; // 0 = local/pending, 1 = synced
  final String? lastUpdated;

  VitalModel({
    this.id,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.temperature,
    this.oxygenSaturation,
    this.bloodGlucose,
    this.weight,
    this.notes,
    required this.recordedAt,
    this.userId,
    this.syncStatus = 0,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'heartRate': heartRate,
      'temperature': temperature,
      'oxygenSaturation': oxygenSaturation,
      'bloodGlucose': bloodGlucose,
      'weight': weight,
      'notes': notes,
      'recordedAt': recordedAt,
      'userId': userId,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated,
    };
  }

  factory VitalModel.fromMap(Map<String, dynamic> map) {
    return VitalModel(
      id: map['id'] as int?,
      systolic:
          map['systolic'] != null ? (map['systolic'] as num).toDouble() : null,
      diastolic: map['diastolic'] != null
          ? (map['diastolic'] as num).toDouble()
          : null,
      heartRate: map['heartRate'] != null
          ? (map['heartRate'] as num).toDouble()
          : null,
      temperature: map['temperature'] != null
          ? (map['temperature'] as num).toDouble()
          : null,
      oxygenSaturation: map['oxygenSaturation'] != null
          ? (map['oxygenSaturation'] as num).toDouble()
          : null,
      bloodGlucose: map['bloodGlucose'] != null
          ? (map['bloodGlucose'] as num).toDouble()
          : null,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      notes: map['notes'] as String?,
      recordedAt: map['recordedAt'] as String,
      userId: map['userId'] as String?,
      syncStatus: map['syncStatus'] as int? ?? 0,
      lastUpdated: map['lastUpdated'] as String?,
    );
  }

  double? get bloodSugar => bloodGlucose;

  String? get sugarType => 'fasting';

  double? get spo2 => oxygenSaturation;

  VitalModel copyWith({
    int? id,
    double? systolic,
    double? diastolic,
    double? heartRate,
    double? temperature,
    double? oxygenSaturation,
    double? bloodGlucose,
    double? weight,
    String? notes,
    String? recordedAt,
    String? userId,
    int? syncStatus,
    String? lastUpdated,
  }) {
    return VitalModel(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      heartRate: heartRate ?? this.heartRate,
      temperature: temperature ?? this.temperature,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      bloodGlucose: bloodGlucose ?? this.bloodGlucose,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      recordedAt: recordedAt ?? this.recordedAt,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
