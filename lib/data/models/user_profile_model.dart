class UserProfileModel {
  final int? id;
  final String name;
  final int? age;
  final String? bloodGroup;
  final String? conditions; // comma-separated
  final String? allergies; // comma-separated
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String createdAt;
  final String? userId;
  final int syncStatus;
  final String? lastUpdated;
  final String? profileImagePath;

  UserProfileModel({
    this.id,
    required this.name,
    this.age,
    this.bloodGroup,
    this.conditions,
    this.allergies,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.createdAt,
    this.userId,
    this.syncStatus = 0,
    this.lastUpdated,
    this.profileImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'age': age,
      'bloodGroup': bloodGroup,
      'conditions': conditions,
      'allergies': allergies,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'createdAt': createdAt,
      'userId': userId,
      'syncStatus': syncStatus,
      'lastUpdated': lastUpdated,
      'profileImagePath': profileImagePath,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      age: map['age'] as int?,
      bloodGroup: map['bloodGroup'] as String?,
      conditions: map['conditions'] as String?,
      allergies: map['allergies'] as String?,
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
      createdAt: map['createdAt'] as String,
      userId: map['userId'] as String?,
      syncStatus: map['syncStatus'] as int? ?? 0,
      lastUpdated: map['lastUpdated'] as String?,
      profileImagePath: map['profileImagePath'] as String?,
    );
  }

  UserProfileModel copyWith({
    int? id,
    String? name,
    int? age,
    String? bloodGroup,
    String? conditions,
    String? allergies,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? createdAt,
    String? userId,
    int? syncStatus,
    String? lastUpdated,
    String? profileImagePath,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      conditions: conditions ?? this.conditions,
      allergies: allergies ?? this.allergies,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}
