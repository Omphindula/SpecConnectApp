enum UserRole { doctor, patient }

enum AppointmentStatus { scheduled, completed, cancelled, rescheduled }

enum MedicationFrequency { once, twice, thrice, fourTimes, asNeeded }

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatar;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: UserRole.values[json['role'] as int],
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.index,
      'avatar': avatar,
    };
  }
}

class Doctor {
  final String id;
  final String userId;
  final String specialization;
  final String qualifications;
  final String location;
  final double rating;
  final int experience;
  final String bio;
  final List<String> availableDays;
  final String startTime;
  final String endTime;
  final double consultationFee;
  final String licenseNumber;

  const Doctor({
    required this.id,
    required this.userId,
    required this.specialization,
    required this.qualifications,
    required this.location,
    required this.rating,
    required this.experience,
    required this.bio,
    required this.availableDays,
    required this.startTime,
    required this.endTime,
    required this.consultationFee,
    required this.licenseNumber,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      userId: json['userId'] as String,
      specialization: json['specialization'] as String,
      qualifications: json['qualifications'] as String,
      location: json['location'] as String,
      rating: (json['rating'] as num).toDouble(),
      experience: json['experience'] as int,
      bio: json['bio'] as String,
      availableDays: List<String>.from(json['availableDays'] as List),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      consultationFee: (json['consultationFee'] as num).toDouble(),
      licenseNumber: json['licenseNumber'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'specialization': specialization,
      'qualifications': qualifications,
      'location': location,
      'rating': rating,
      'experience': experience,
      'bio': bio,
      'availableDays': availableDays,
      'startTime': startTime,
      'endTime': endTime,
      'consultationFee': consultationFee,
      'licenseNumber': licenseNumber,
    };
  }
}

class Patient {
  final String id;
  final String userId;
  final DateTime dateOfBirth;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> medicalHistory;
  final String emergencyContact;
  final String emergencyPhone;

  const Patient({
    required this.id,
    required this.userId,
    required this.dateOfBirth,
    required this.bloodGroup,
    required this.allergies,
    required this.medicalHistory,
    required this.emergencyContact,
    required this.emergencyPhone,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      userId: json['userId'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      bloodGroup: json['bloodGroup'] as String,
      allergies: List<String>.from(json['allergies'] as List),
      medicalHistory: List<String>.from(json['medicalHistory'] as List),
      emergencyContact: json['emergencyContact'] as String,
      emergencyPhone: json['emergencyPhone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalHistory': medicalHistory,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
    };
  }
}

class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String? notes;
  final String? prescription;
  final double? consultationFee;

  const Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    required this.status,
    this.notes,
    this.prescription,
    this.consultationFee,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String,
      patientId: json['patientId'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      status: AppointmentStatus.values[json['status'] as int],
      notes: json['notes'] as String?,
      prescription: json['prescription'] as String?,
      consultationFee: (json['consultationFee'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'dateTime': dateTime.toIso8601String(),
      'status': status.index,
      'notes': notes,
      'prescription': prescription,
      'consultationFee': consultationFee,
    };
  }
}

class Medication {
  final String id;
  final String name;
  final String dosage;
  final MedicationFrequency frequency;
  final String prescribedBy;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> instructions;
  final String patientId;
  final List<DateTime> takenTimes;

  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.prescribedBy,
    required this.startDate,
    this.endDate,
    required this.instructions,
    required this.patientId,
    required this.takenTimes,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      frequency: MedicationFrequency.values[json['frequency'] as int],
      prescribedBy: json['prescribedBy'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      instructions: List<String>.from(json['instructions'] as List),
      patientId: json['patientId'] as String,
      takenTimes: (json['takenTimes'] as List).map((e) => DateTime.parse(e as String)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency.index,
      'prescribedBy': prescribedBy,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'instructions': instructions,
      'patientId': patientId,
      'takenTimes': takenTimes.map((e) => e.toIso8601String()).toList(),
    };
  }
}

class HealthRecord {
  final String id;
  final String patientId;
  final DateTime visitDate;
  final String doctorId;
  final String diagnosis;
  final String treatment;
  final List<String> prescriptions;
  final String notes;
  final double? weight;
  final double? height;
  final String? bloodPressure;
  final double? temperature;

  const HealthRecord({
    required this.id,
    required this.patientId,
    required this.visitDate,
    required this.doctorId,
    required this.diagnosis,
    required this.treatment,
    required this.prescriptions,
    required this.notes,
    this.weight,
    this.height,
    this.bloodPressure,
    this.temperature,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      visitDate: DateTime.parse(json['visitDate'] as String),
      doctorId: json['doctorId'] as String,
      diagnosis: json['diagnosis'] as String,
      treatment: json['treatment'] as String,
      prescriptions: List<String>.from(json['prescriptions'] as List),
      notes: json['notes'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      bloodPressure: json['bloodPressure'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'visitDate': visitDate.toIso8601String(),
      'doctorId': doctorId,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescriptions': prescriptions,
      'notes': notes,
      'weight': weight,
      'height': height,
      'bloodPressure': bloodPressure,
      'temperature': temperature,
    };
  }
}

// Combined model for UI convenience
class DoctorWithUser {
  final User user;
  final Doctor doctor;

  const DoctorWithUser({
    required this.user,
    required this.doctor,
  });
}

class PatientWithUser {
  final User user;
  final Patient patient;

  const PatientWithUser({
    required this.user,
    required this.patient,
  });
}

class AppointmentWithDetails {
  final Appointment appointment;
  final User doctor;
  final User patient;

  const AppointmentWithDetails({
    required this.appointment,
    required this.doctor,
    required this.patient,
  });
}