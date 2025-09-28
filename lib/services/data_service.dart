import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class DataService {
  static const String _usersKey = 'users';
  static const String _doctorsKey = 'doctors';
  static const String _patientsKey = 'patients';
  static const String _appointmentsKey = 'appointments';
  static const String _medicationsKey = 'medications';
  static const String _healthRecordsKey = 'health_records';
  static const String _currentUserKey = 'current_user';

  static DataService? _instance;
  static DataService get instance => _instance ??= DataService._();
  DataService._();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _initializeSampleData();
    } catch (e) {
      print('Error initializing DataService: $e');
    }
  }

  Future<void> _initializeSampleData() async {
    if (_prefs == null || _prefs!.containsKey(_usersKey)) return;

    // Sample Users
      final users = [
        User(id: '1', name: 'Dr. Lucas', email: 'dr.lucas@mediclinic.com', phone: '+27123456789', role: UserRole.doctor),
        User(id: '6', name: 'John Smith', email: 'john.smith@email.com', phone: '+27123456794', role: UserRole.patient),
        User(id: '7', name: 'Mary Johnson', email: 'mary.johnson@email.com', phone: '+27123456795', role: UserRole.patient),
        User(id: '8', name: 'Peter Williams', email: 'peter.williams@email.com', phone: '+27123456796', role: UserRole.patient),
        User(id: '9', name: 'Susan Brown', email: 'susan.brown@email.com', phone: '+27123456797', role: UserRole.patient),
        User(id: '10', name: 'James Davis', email: 'james.davis@email.com', phone: '+27123456798', role: UserRole.patient),
      ];

    // Sample Doctors
      final doctors = [
        Doctor(
          id: '1', userId: '1', specialization: 'General Practice', qualifications: 'MD, Family Medicine',
          location: 'Nelspruit', licenseNumber: 'LIC001', rating: 4.9, experience: 20, bio: 'Dr. Lucas is an experienced general practitioner dedicated to providing quality healthcare.',
          availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'], startTime: '08:00', endTime: '17:00', consultationFee: 800.0,
        ),
      ];

    // Sample Patients
    final patients = [
      Patient(
        id: '1', userId: '6', dateOfBirth: DateTime(1985, 3, 15),
        bloodGroup: 'O+', allergies: ['Penicillin'], medicalHistory: ['Hypertension'],
        emergencyContact: 'Jane Smith', emergencyPhone: '+27123456800',
      ),
      Patient(
        id: '2', userId: '7', dateOfBirth: DateTime(1990, 8, 22),
        bloodGroup: 'A+', allergies: [], medicalHistory: ['Diabetes Type 2'],
        emergencyContact: 'Robert Johnson', emergencyPhone: '+27123456801',
      ),
      Patient(
        id: '3', userId: '8', dateOfBirth: DateTime(1978, 12, 5),
        bloodGroup: 'B-', allergies: ['Shellfish'], medicalHistory: ['Asthma'],
        emergencyContact: 'Sarah Williams', emergencyPhone: '+27123456802',
      ),
      Patient(
        id: '4', userId: '9', dateOfBirth: DateTime(1965, 6, 30),
        bloodGroup: 'AB+', allergies: ['Latex'], medicalHistory: ['Arthritis', 'High Cholesterol'],
        emergencyContact: 'Michael Brown', emergencyPhone: '+27123456803',
      ),
      Patient(
        id: '5', userId: '10', dateOfBirth: DateTime(1995, 11, 18),
        bloodGroup: 'O-', allergies: [], medicalHistory: [],
        emergencyContact: 'Emily Davis', emergencyPhone: '+27123456804',
      ),
    ];

    // Sample Appointments
    final now = DateTime.now();
    final appointments = [
      Appointment(
        id: '1', doctorId: '1', patientId: '1',
        dateTime: now.add(const Duration(days: 1, hours: 10)),
        status: AppointmentStatus.scheduled, consultationFee: 850.0,
      ),
      Appointment(
        id: '2', doctorId: '2', patientId: '2',
        dateTime: now.add(const Duration(days: 2, hours: 14)),
        status: AppointmentStatus.scheduled, consultationFee: 700.0,
      ),
      Appointment(
        id: '3', doctorId: '1', patientId: '3',
        dateTime: now.subtract(const Duration(days: 7, hours: 2)),
        status: AppointmentStatus.completed,
        notes: 'Patient showing good recovery. Continue medication.',
        prescription: 'Metformin 500mg twice daily',
        consultationFee: 850.0,
      ),
    ];

    // Sample Medications
    final medications = [
      Medication(
        id: '1', name: 'Lisinopril', dosage: '10mg', frequency: MedicationFrequency.once,
        prescribedBy: 'Dr. Sarah Johnson', startDate: now.subtract(const Duration(days: 30)),
        instructions: ['Take with food', 'Monitor blood pressure'],
        patientId: '1', takenTimes: [],
      ),
      Medication(
        id: '2', name: 'Metformin', dosage: '500mg', frequency: MedicationFrequency.twice,
        prescribedBy: 'Dr. Michael Chen', startDate: now.subtract(const Duration(days: 60)),
        instructions: ['Take with meals', 'Monitor blood sugar'],
        patientId: '2', takenTimes: [],
      ),
    ];

    // Sample Health Records
    final healthRecords = [
      HealthRecord(
        id: '1', patientId: '1', visitDate: now.subtract(const Duration(days: 30)),
        doctorId: '1', diagnosis: 'Hypertension', treatment: 'Medication adjustment',
        prescriptions: ['Lisinopril 10mg'], notes: 'Blood pressure well controlled',
        weight: 75.5, height: 175.0, bloodPressure: '120/80', temperature: 36.5,
      ),
      HealthRecord(
        id: '2', patientId: '2', visitDate: now.subtract(const Duration(days: 45)),
        doctorId: '2', diagnosis: 'Diabetes Type 2', treatment: 'Lifestyle counseling',
        prescriptions: ['Metformin 500mg'], notes: 'HbA1c improved',
        weight: 68.2, height: 162.0, bloodPressure: '118/75', temperature: 36.8,
      ),
    ];

    await _saveData(_usersKey, users);
    await _saveData(_doctorsKey, doctors);
    await _saveData(_patientsKey, patients);
    await _saveData(_appointmentsKey, appointments);
    await _saveData(_medicationsKey, medications);
    await _saveData(_healthRecordsKey, healthRecords);
  }

  Future<void> _saveData<T>(String key, List<T> data) async {
    if (_prefs == null) return;
    
    try {
      final jsonList = data.map((item) => (item as dynamic).toJson()).toList();
      await _prefs!.setString(key, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<List<T>> _loadData<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    if (_prefs == null) return [];
    
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // User methods
  Future<List<User>> getUsers() async {
    return await _loadData(_usersKey, User.fromJson);
  }

  Future<User?> getCurrentUser() async {
    if (_prefs == null) return null;
    final userId = _prefs!.getString(_currentUserKey);
    if (userId == null) return null;
    
    final users = await getUsers();
    try {
      return users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  Future<void> setCurrentUser(String userId) async {
    if (_prefs != null) {
      await _prefs!.setString(_currentUserKey, userId);
    }
  }

  Future<void> clearCurrentUser() async {
    if (_prefs != null) {
      await _prefs!.remove(_currentUserKey);
    }
  }

  Future<void> saveUsers(List<User> users) async {
    await _saveData(_usersKey, users);
  }

  Future<void> saveDoctors(List<Doctor> doctors) async {
    await _saveData(_doctorsKey, doctors);
  }

  Future<void> savePatients(List<Patient> patients) async {
    await _saveData(_patientsKey, patients);
  }

  Future<void> addAppointment(Appointment appointment) async {
    final appointments = await getAppointments();
    appointments.add(appointment);
    await _saveData(_appointmentsKey, appointments);
  }

  Future<void> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    final appointments = await getAppointments();
    final index = appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      final updatedAppointment = Appointment(
        id: appointments[index].id,
        doctorId: appointments[index].doctorId,
        patientId: appointments[index].patientId,
        dateTime: appointments[index].dateTime,
        status: status,
        notes: appointments[index].notes,
        prescription: appointments[index].prescription,
        consultationFee: appointments[index].consultationFee,
      );
      appointments[index] = updatedAppointment;
      await _saveData(_appointmentsKey, appointments);
    }
  }

  Future<void> rescheduleAppointment(String appointmentId, DateTime newDateTime) async {
    final appointments = await getAppointments();
    final index = appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      final updatedAppointment = Appointment(
        id: appointments[index].id,
        doctorId: appointments[index].doctorId,
        patientId: appointments[index].patientId,
        dateTime: newDateTime,
        status: AppointmentStatus.rescheduled,
        notes: appointments[index].notes,
        prescription: appointments[index].prescription,
        consultationFee: appointments[index].consultationFee,
      );
      appointments[index] = updatedAppointment;
      await _saveData(_appointmentsKey, appointments);
    }
  }

  // Doctor methods
  Future<List<Doctor>> getDoctors() async {
    return await _loadData(_doctorsKey, Doctor.fromJson);
  }

  Future<List<DoctorWithUser>> getDoctorsWithUsers() async {
    final doctors = await getDoctors();
    final users = await getUsers();
    
    return doctors.map((doctor) {
      final user = users.firstWhere((u) => u.id == doctor.userId);
      return DoctorWithUser(user: user, doctor: doctor);
    }).toList();
  }

  Future<DoctorWithUser?> getDoctorWithUser(String doctorId) async {
    final doctors = await getDoctorsWithUsers();
    try {
      return doctors.firstWhere((d) => d.doctor.id == doctorId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateDoctor(Doctor doctor) async {
    final doctors = await getDoctors();
    final index = doctors.indexWhere((d) => d.id == doctor.id);
    
    if (index >= 0) {
      doctors[index] = doctor;
      await saveDoctors(doctors);
    }
  }

  // Patient methods
  Future<List<Patient>> getPatients() async {
    return await _loadData(_patientsKey, Patient.fromJson);
  }

  Future<List<PatientWithUser>> getPatientsWithUsers() async {
    final patients = await getPatients();
    final users = await getUsers();
    
    return patients.map((patient) {
      final user = users.firstWhere((u) => u.id == patient.userId);
      return PatientWithUser(user: user, patient: patient);
    }).toList();
  }

  // Appointment methods
  Future<List<Appointment>> getAppointments() async {
    return await _loadData(_appointmentsKey, Appointment.fromJson);
  }

  Future<List<AppointmentWithDetails>> getAppointmentsWithDetails() async {
    final appointments = await getAppointments();
    final users = await getUsers();
    final doctors = await getDoctors();
    final patients = await getPatients();
    
    return appointments.map((appointment) {
      final doctorData = doctors.firstWhere((d) => d.id == appointment.doctorId);
      final patientData = patients.firstWhere((p) => p.id == appointment.patientId);
      final doctorUser = users.firstWhere((u) => u.id == doctorData.userId);
      final patientUser = users.firstWhere((u) => u.id == patientData.userId);
      
      return AppointmentWithDetails(
        appointment: appointment,
        doctor: doctorUser,
        patient: patientUser,
      );
    }).toList();
  }

  Future<void> saveAppointment(Appointment appointment) async {
    final appointments = await getAppointments();
    final index = appointments.indexWhere((a) => a.id == appointment.id);
    
    if (index >= 0) {
      appointments[index] = appointment;
    } else {
      appointments.add(appointment);
    }
    
    await _saveData(_appointmentsKey, appointments);
  }

  // Medication methods
  Future<List<Medication>> getMedications() async {
    return await _loadData(_medicationsKey, Medication.fromJson);
  }

  Future<void> saveMedication(Medication medication) async {
    final medications = await getMedications();
    final index = medications.indexWhere((m) => m.id == medication.id);
    
    if (index >= 0) {
      medications[index] = medication;
    } else {
      medications.add(medication);
    }
    
    await _saveData(_medicationsKey, medications);
  }

  // Health Record methods
  Future<List<HealthRecord>> getHealthRecords() async {
    return await _loadData(_healthRecordsKey, HealthRecord.fromJson);
  }

  Future<void> saveHealthRecord(HealthRecord record) async {
    final records = await getHealthRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    
    await _saveData(_healthRecordsKey, records);
  }

  // Utility methods
  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  Future<void> clearAllData() async {
    await _prefs!.clear();
  }
}