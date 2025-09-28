import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'pages/landing_page.dart';
import 'pages/patient_dashboard.dart';
import 'pages/doctor_dashboard.dart';
import 'models/app_models.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  dotenv.load().then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpecConnect - University of Mpumalanga',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      // For hot reload testing, you can temporarily use LandingPage() directly
      home: const AppInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Small delay for splash effect
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Initialize data service first
      await DataService.instance.initialize();

      final authService = AuthService();
      await authService.init();

      if (await authService.isLoggedIn()) {
        final user = await authService.getCurrentUser();
        final lastRoute = await authService.getLastRoute();
        if (user != null && mounted) {
          // Restore last dashboard if available
          if (lastRoute == 'doctor_dashboard' && user.role == UserRole.doctor) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DoctorDashboard()),
            );
            return;
          } else if (lastRoute == 'patient_dashboard' && user.role == UserRole.patient) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PatientDashboard()),
            );
            return;
          } else {
            // Fallback to role-based dashboard
            if (user.role == UserRole.doctor) {
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
            return;
          }
        }
      }

      // Navigate to landing page if not logged in
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      }
    } catch (e) {
      // In case of any error, just navigate to landing page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      }
    }
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ump_logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: Color(0xFFffcc00),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                'SpecConnect',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'University of Mpumalanga',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
