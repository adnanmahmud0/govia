class UserModel {
  final String? id;
  final String? name;
  final String? role;
  final String? email;
  final String? image;
  final String? status;
  final bool? verified;
  final String? subRole;
  final String? phoneNumber;
  final String? phone;
  final String? languagesSpoken;
  final String? preferredAttorney;
  final String? preferredBailBondsman;
  final String? licensedStatesToPractice;
  final String? barAssociationNumber;
  final String? lawFirmName;
  final String? officeName;
  final String? datePassedTheBar;
  final String? medicalLicenseNumber;
  final String? specialization;
  final String? specialty;
  final String? companyName;
  final String? businessAddress;
  final String? badgeNumber;
  final String? assignedNumber;
  final String? departmentOrPrecinct;
  final String? didCarNumberChange;
  final String? newCarNumber;
  final String? licenseNumber;
  final String? shortHexId;
  final String? country;
  final String? gender;
  final String? dateOfBirth;
  final String? profilePicture;
  final bool? isOnboardingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    this.name,
    this.role,
    this.email,
    this.image,
    this.status,
    this.verified,
    this.subRole,
    this.phoneNumber,
    this.phone,
    this.languagesSpoken,
    this.preferredAttorney,
    this.preferredBailBondsman,
    this.licensedStatesToPractice,
    this.barAssociationNumber,
    this.lawFirmName,
    this.officeName,
    this.datePassedTheBar,
    this.medicalLicenseNumber,
    this.specialization,
    this.specialty,
    this.companyName,
    this.businessAddress,
    this.badgeNumber,
    this.assignedNumber,
    this.departmentOrPrecinct,
    this.didCarNumberChange,
    this.newCarNumber,
    this.licenseNumber,
    this.shortHexId,
    this.country,
    this.gender,
    this.dateOfBirth,
    this.profilePicture,
    this.isOnboardingCompleted,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'],
      name: json['name'],
      role: json['role']?.toString().toUpperCase(),
      email: json['email'],
      image: json['image'] ?? json['profilePicture'],
      status: json['status'],
      verified: json['verified'],
      subRole: json['subRole'],
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      phone: json['phone'] ?? json['phoneNumber'],
      languagesSpoken: json['languagesSpoken'],
      preferredAttorney: json['preferredAttorney'],
      preferredBailBondsman: json['preferredBailBondsman'],
      licensedStatesToPractice: json['licensedStatesToPractice'],
      barAssociationNumber: json['barAssociationNumber'],
      lawFirmName: json['lawFirmName'],
      officeName: json['officeName'],
      datePassedTheBar: json['datePassedTheBar'],
      medicalLicenseNumber: json['medicalLicenseNumber'],
      specialization: json['specialization'] ?? json['specialty'],
      specialty: json['specialty'] ?? json['specialization'],
      companyName: json['companyName'],
      businessAddress: json['businessAddress'],
      badgeNumber: json['badgeNumber'],
      assignedNumber: json['assignedNumber'],
      departmentOrPrecinct: json['departmentOrPrecinct'],
      didCarNumberChange: json['didCarNumberChange'],
      newCarNumber: json['newCarNumber'],
      licenseNumber: json['licenseNumber'],
      shortHexId: json['shortHexId']?.toString() ??
          (json['id'] != null || json['_id'] != null
              ? ((json['id'] ?? json['_id']).toString().length >= 8
                  ? (json['id'] ?? json['_id'])
                      .toString()
                      .substring(
                          (json['id'] ?? json['_id']).toString().length - 8)
                      .toUpperCase()
                  : (json['id'] ?? json['_id']).toString().toUpperCase())
              : null),
      country: json['country'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'],
      profilePicture: json['profilePicture'] ?? json['image'],
      isOnboardingCompleted: json['isOnboardingCompleted'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'email': email,
      'image': image,
      'status': status,
      'verified': verified,
      'subRole': subRole,
      'phoneNumber': phoneNumber,
      'phone': phone,
      'languagesSpoken': languagesSpoken,
      'preferredAttorney': preferredAttorney,
      'preferredBailBondsman': preferredBailBondsman,
      'licensedStatesToPractice': licensedStatesToPractice,
      'barAssociationNumber': barAssociationNumber,
      'lawFirmName': lawFirmName,
      'officeName': officeName,
      'datePassedTheBar': datePassedTheBar,
      'medicalLicenseNumber': medicalLicenseNumber,
      'specialization': specialization,
      'companyName': companyName,
      'businessAddress': businessAddress,
      'badgeNumber': badgeNumber,
      'assignedNumber': assignedNumber,
      'departmentOrPrecinct': departmentOrPrecinct,
      'didCarNumberChange': didCarNumberChange,
      'newCarNumber': newCarNumber,
      'licenseNumber': licenseNumber,
      'shortHexId': shortHexId,
      'country': country,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'profilePicture': profilePicture,
      'isOnboardingCompleted': isOnboardingCompleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
