class PrescriptionModel {
  final int? id;
  final String title;
  final String? doctorName;
  final String date;
  final String imagePath;
  final String? notes;
  final String createdAt;
  final String? userId;
  final int syncStatus;
  final String? lastUpdated;

  PrescriptionModel({
    this.id,
    required this.title,
    this.doctorName,
    required this.date,
    required this.imagePath,
    this.notes,
    required this.createdAt,
    this.userId,
    this.syncStatus = 0,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'doctorName': doctorName,
      'date': date,
      'imagePath': imagePath,
      'notes': notes,
      'createdAt': createdAt,
      'userId': userId,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated,
    };
  }

  factory PrescriptionModel.fromMap(Map<String, dynamic> map) {
    return PrescriptionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      doctorName: map['doctorName'] as String?,
      date: map['date'] as String,
      imagePath: map['imagePath'] as String,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] as String,
      userId: map['userId'] as String?,
      syncStatus: map['syncStatus'] as int? ?? 0,
      lastUpdated: map['lastUpdated'] as String?,
    );
  }

  PrescriptionModel copyWith({
    int? id,
    String? title,
    String? doctorName,
    String? date,
    String? imagePath,
    String? notes,
    String? createdAt,
    String? userId,
    int? syncStatus,
    String? lastUpdated,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      doctorName: doctorName ?? this.doctorName,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
