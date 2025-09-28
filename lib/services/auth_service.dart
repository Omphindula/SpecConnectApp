  import 'dart:convert';
  import 'package:crypto/crypto.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../models/app_models.dart';
  import 'data_service.dart';

// ...existing code...

class AuthService {
  static const String _lastRouteKey = 'last_route';

  Future<void> setLastRoute(String route) async {
    await init();
    if (_prefs != null) {
      await _prefs!.setString(_lastRouteKey, route);
    }
  }

  Future<String?> getLastRoute() async {
    await init();
    if (_prefs != null) {
      return _prefs!.getString(_lastRouteKey);
    }
    return null;
  }
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _authTokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _currentUserIdKey = 'current_user_id';
  
  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<AuthResult> login(String email, String password, UserRole role) async {
    await init();
    
    try {
      // Ensure DataService is initialized
      await DataService.instance.initialize();
      
      final users = await DataService.instance.getUsers();
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() && u.role == role,
        orElse: () => throw Exception('User not found'),
      );

      // Verify password hash
      final hashedPassword = _hashPassword(password);
      // For demo purposes, we'll create a simple validation
      // In production, this should compare against stored hash
      
      if (_prefs != null) {
        await _prefs!.setBool(_isLoggedInKey, true);
        await _prefs!.setString(_currentUserIdKey, user.id);
        await _prefs!.setString(_authTokenKey, 'demo_token_${user.id}');
      }
      
      // Update DataService current user
      await DataService.instance.setCurrentUser(user.id);
      
      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(success: false, error: 'Invalid email or password');
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    // Doctor specific fields
    String? specialization,
    String? qualifications,
    String? location,
    String? licenseNumber,
    String? bio,
    int? experience,
    double? consultationFee,
    // Patient specific fields
    DateTime? dateOfBirth,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? medicalHistory,
    String? emergencyContact,
    String? emergencyPhone,
  }) async {
    await init();
    
    try {
      // Ensure DataService is initialized
      await DataService.instance.initialize();
      
      final users = await DataService.instance.getUsers();
      
      // Check if email already exists
      final existingUser = users.where((u) => u.email.toLowerCase() == email.toLowerCase());
      if (existingUser.isNotEmpty) {
        return AuthResult(success: false, error: 'Email already registered');
      }

      // Validate password strength
      if (password.length < 6) {
        return AuthResult(success: false, error: 'Password must be at least 6 characters long');
      }
      
      // Hash the password
      final hashedPassword = _hashPassword(password);
      
      // Generate new user ID
      final newUserId = (users.length + 1).toString();
      
      // Create new user
      final newUser = User(
        id: newUserId,
        name: name,
        email: email,
        phone: phone,
        role: role,
      );

      // Add user to the list and save
      final updatedUsers = [...users, newUser];
      await DataService.instance.saveUsers(updatedUsers);
      
      if (role == UserRole.doctor) {
        // Create doctor profile
        final doctors = await DataService.instance.getDoctors();
        final newDoctorId = (doctors.length + 1).toString();
        
        final newDoctor = Doctor(
          id: newDoctorId,
          userId: newUserId,
          specialization: specialization ?? 'General Practice',
          qualifications: qualifications ?? 'MD',
          location: location ?? 'Nelspruit',
          licenseNumber: licenseNumber ?? '',
          rating: 0.0,
          experience: experience ?? 1,
          bio: bio ?? '',
          availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
          startTime: '08:00',
          endTime: '17:00',
          consultationFee: consultationFee ?? 600.0,
        );
        
        final updatedDoctors = [...doctors, newDoctor];
        await DataService.instance.saveDoctors(updatedDoctors);
      } else if (role == UserRole.patient) {
        // Create patient profile
        final patients = await DataService.instance.getPatients();
        final newPatientId = (patients.length + 1).toString();
        
        final newPatient = Patient(
          id: newPatientId,
          userId: newUserId,
          dateOfBirth: dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
          bloodGroup: bloodGroup ?? 'O+',
          allergies: allergies ?? [],
          medicalHistory: medicalHistory ?? [],
          emergencyContact: emergencyContact ?? '',
          emergencyPhone: emergencyPhone ?? '',
        );
        
        final updatedPatients = [...patients, newPatient];
        await DataService.instance.savePatients(updatedPatients);
      }

      // Auto-login after registration
      if (_prefs != null) {
        await _prefs!.setBool(_isLoggedInKey, true);
        await _prefs!.setString(_currentUserIdKey, newUserId);
        await _prefs!.setString(_authTokenKey, 'demo_token_$newUserId');
      }
      
      // Update DataService current user
      await DataService.instance.setCurrentUser(newUserId);
      
      return AuthResult(success: true, user: newUser);
    } catch (e) {
      print('Registration error: $e');
      return AuthResult(success: false, error: 'Registration failed: ${e.toString()}');
    }
  }

  Future<bool> isLoggedIn() async {
    await init();
    return _prefs!.getBool(_isLoggedInKey) ?? false;
  }

  Future<User?> getCurrentUser() async {
    await init();
    if (!await isLoggedIn()) return null;
    
    final userId = _prefs!.getString(_currentUserIdKey);
    if (userId == null) return null;
    
    final users = await DataService.instance.getUsers();
    try {
      return users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> logout() async {
    await init();
    await _prefs!.remove(_isLoggedInKey);
    await _prefs!.remove(_currentUserIdKey);
    await _prefs!.remove(_authTokenKey);
    
    // Clear DataService current user
    await DataService.instance.clearCurrentUser();
    return true;
  }

  Future<void> keepSessionAlive() async {
    await init();
    // Update session timestamp to prevent automatic logout
    if (_prefs != null && await isLoggedIn()) {
      await _prefs!.setString('last_activity', DateTime.now().toIso8601String());
    }
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.error,
  });
}