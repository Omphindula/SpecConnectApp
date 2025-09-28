import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../pages/doctor_dashboard.dart';
import '../pages/patient_dashboard.dart';
import '../pages/login_page.dart';
import '../widgets/ump_logo.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Common fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Doctor specific fields
  String? _selectedSpecialization = '';
  final _qualificationsController = TextEditingController();
  final _locationController = TextEditingController();
  final _licenseController = TextEditingController();
  final List<String> _doctorSpecializations = [
    'General Practice',
    'Cardiology',
    'Dermatology',
    'Pediatrics',
    'Orthopedics',
    'Gynecology',
    'Neurology',
    'Psychiatry',
    'Radiology',
    'Other',
  ];
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _consultationFeeController = TextEditingController();

  // Patient specific fields
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  UserRole _selectedRole = UserRole.patient;
  DateTime? _dateOfBirth;
  String? _bloodGroup;
  List<String> _allergies = [];
  List<String> _medicalHistory = [];

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _bloodGroups = ['A', 'B', 'AB', 'O'];
  final List<String> _commonAllergies = [
    'Penicillin', 'Shellfish', 'Nuts', 'Latex', 'Dust', 'Pollen', 'Dairy', 'Eggs'
  ];
  final List<String> _commonConditions = [
    'Hypertension', 'Diabetes', 'Asthma', 'Arthritis', 'Heart Disease', 'Allergies'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _qualificationsController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _consultationFeeController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    AuthResult result;
    try {
      result = await AuthService().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        specialization: _selectedRole == UserRole.doctor ? _selectedSpecialization : null,
        qualifications: _selectedRole == UserRole.doctor ? _qualificationsController.text.trim() : null,
        location: _selectedRole == UserRole.doctor ? _locationController.text.trim() : null,
        licenseNumber: _selectedRole == UserRole.doctor ? 'MED${_licenseController.text.trim()}' : null,
        bio: _selectedRole == UserRole.doctor ? _bioController.text.trim() : null,
        experience: _selectedRole == UserRole.doctor ? int.tryParse(_experienceController.text) : null,
        consultationFee: _selectedRole == UserRole.doctor ? double.tryParse(_consultationFeeController.text) : null,
        dateOfBirth: _selectedRole == UserRole.patient ? _dateOfBirth : null,
        bloodGroup: _selectedRole == UserRole.patient ? _bloodGroup : null,
        allergies: _selectedRole == UserRole.patient ? _allergies : null,
        medicalHistory: _selectedRole == UserRole.patient ? _medicalHistory : null,
        emergencyContact: _selectedRole == UserRole.patient ? _emergencyContactController.text.trim() : null,
        emergencyPhone: _selectedRole == UserRole.patient ? _emergencyPhoneController.text.trim() : null,
      );
    } catch (e) {
      result = AuthResult(success: false, error: 'Registration failed: ${e.toString()}');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success && result.user != null) {
        if (_selectedRole == UserRole.doctor) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DoctorDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PatientDashboard()),
          );
        }
      } else {
        setState(() => _errorMessage = result.error);
      }
    }
  }

  void _nextPage() {
    if (_currentPage == 0 && _formKey.currentState!.validate()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF002f6c),
              Color(0xFF1a4b7a),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Spacer(),
                        Hero(
                          tag: 'ump_logo',
                          child: UMPLogo(size: 60, showText: false),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Join SpecConnect',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Create your healthcare account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        children: [
                          _buildBasicInfoPage(),
                          _buildRoleSpecificPage(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: 0.5,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF002f6c)),
          ),
          const SizedBox(height: 32),
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002f6c),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Let\'s start with your basic details',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          const Text(
            'I am a:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF002f6c),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  role: UserRole.patient,
                  icon: Icons.person,
                  title: 'Patient',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoleCard(
                  role: UserRole.doctor,
                  icon: Icons.medical_services,
                  title: 'Doctor',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
              ),
            ),
            validator: (value) {
              final phone = value?.trim() ?? '';
              if (phone.isEmpty) {
                return 'Please enter your phone number';
              }
              if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
                return 'Phone number must be 10 digits and start with 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a password';
              if (value.length < 8) return 'Password must be at least 8 characters';
              if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$').hasMatch(value)) {
                return 'Password must include upper, lower, digit, and special character';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
              ),
            ),
            validator: (value) {
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002f6c),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Next', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? ', style: TextStyle(color: Colors.grey)),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(color: Color(0xFF002f6c), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSpecificPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF002f6c)),
          ),
          const SizedBox(height: 32),
          Text(
            '${_selectedRole == UserRole.doctor ? 'Professional' : 'Personal'} Information',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002f6c),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your ${_selectedRole == UserRole.doctor ? 'professional' : 'health'} profile',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          if (_selectedRole == UserRole.doctor) ..._buildDoctorFields(),
          if (_selectedRole == UserRole.patient) ..._buildPatientFields(),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
            ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF002f6c),
                    side: const BorderSide(color: Color(0xFF002f6c)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF002f6c),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDoctorFields() {
    final List<String> specializations = _doctorSpecializations;
    return [
      DropdownButtonFormField<String>(
        value: (specializations.contains(_selectedSpecialization) && _selectedSpecialization != '')
            ? _selectedSpecialization
            : null,
        items: specializations.isNotEmpty
            ? specializations.map((spec) => DropdownMenuItem<String>(
                value: spec,
                child: Text(spec),
              )).toList()
            : [DropdownMenuItem<String>(value: 'General Practice', child: Text('General Practice'))],
        onChanged: (value) => setState(() => _selectedSpecialization = value),
        decoration: InputDecoration(
          labelText: 'Specialization',
          prefixIcon: const Icon(Icons.medical_services_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
          ),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Please select your specialization' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _qualificationsController,
        decoration: InputDecoration(
          labelText: 'Qualifications',
          prefixIcon: const Icon(Icons.school_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
          ),
        ),
        onTap: () {
          if (_qualificationsController.text.isEmpty) _qualificationsController.text = 'DR';
        },
        validator: (value) => value?.trim().isEmpty == true ? 'Please enter your qualifications' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _licenseController,
        decoration: InputDecoration(
          labelText: 'License Number',
          prefixIcon: const Icon(Icons.badge_outlined),
          prefixText: 'MED',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        keyboardType: TextInputType.number,
        validator: (value) => value == null || value.length != 6 ? 'Enter last 6 digits of license' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _locationController,
        decoration: InputDecoration(
          labelText: 'Location',
          prefixIcon: const Icon(Icons.location_on_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
          ),
        ),
        validator: (value) => value?.trim().isEmpty == true ? 'Please enter your location' : null,
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.map_outlined),
          label: const Text('Pick Location on Google Maps'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF002f6c),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final url = Uri.parse('https://www.google.com/maps');
            if (await canLaunchUrl(url)) await launchUrl(url);
          },
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _bioController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Bio',
          prefixIcon: const Icon(Icons.info_outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildPatientFields() {
    return [
      InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (date != null) setState(() => _dateOfBirth = date);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
            ),
          ),
          child: Text(
            _dateOfBirth != null
                ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                : 'Select date of birth',
            style: TextStyle(
              color: _dateOfBirth != null ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _bloodGroup,
        decoration: InputDecoration(
          labelText: 'Blood Group',
          prefixIcon: const Icon(Icons.bloodtype_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
          ),
        ),
        items: _bloodGroups.map((group) => DropdownMenuItem(
          value: group,
          child: Text(group),
        )).toList(),
        onChanged: (value) => setState(() => _bloodGroup = value),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emergencyContactController,
        decoration: InputDecoration(
          labelText: 'Emergency Contact Name',
          prefixIcon: const Icon(Icons.contact_emergency_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
          ),
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emergencyPhoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          LengthLimitingTextInputFormatter(10),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: 'Emergency Contact Phone',
          prefixIcon: const Icon(Icons.phone_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF002f6c), width: 2),
          ),
        ),
        validator: (value) {
          final phone = value?.trim() ?? '';
          if (phone.isEmpty) return 'Please enter emergency phone number';
          if (!RegExp(r'^0\d{9}$').hasMatch(phone)) return 'Emergency number must be 10 digits and start with 0';
          return null;
        },
      ),
    ];
  }

  Widget _buildRoleCard({required UserRole role, required IconData icon, required String title}) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF002f6c) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF002f6c) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
