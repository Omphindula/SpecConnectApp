import 'package:flutter/material.dart';
import 'package:mediconnect/pages/login_page.dart';
import 'package:mediconnect/pages/registration_page.dart';
import 'package:mediconnect/widgets/ump_logo.dart';
import '../widgets/emergency_widget.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;
    
    return Scaffold(
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF081FBF),
              ),
              child: SafeArea(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        children: [
                          // Header Section
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 16.0 : 32.0,
                              vertical: isSmallScreen ? 20.0 : 40.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // University Logo
                                Hero(
                                  tag: 'ump_logo',
                                  child: Image.asset(
                                    'assets/images/ump_logo.png',
                                    width: isSmallScreen ? 80 : 120,
                                    height: isSmallScreen ? 80 : 120,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 32),
                                // App Title
                                Text(
                                  'SpecConnect',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 32 : 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Subtitle
                                Text(
                                  'University of Mpumalanga',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 18,
                                    color: Colors.white.withOpacity(0.9),
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 8 : 16),
                                // Tagline
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16 : 24,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFffcc00).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFffcc00).withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Specialized Healthcare Connection',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 16,
                                      color: const Color(0xFFffcc00),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Content Section
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 32.0),
                              child: Column(
                                children: [
                                  SizedBox(height: isSmallScreen ? 16 : 24),
                                  // Welcome Message
                                  Text(
                                    'Connect with Healthcare Excellence',
                                    style: TextStyle(
                                      color: const Color(0xFF002f6c),
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                      fontSize: isSmallScreen ? 20 : 24,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Experience seamless healthcare management with our comprehensive platform designed for students, staff, and healthcare professionals.',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w400,
                                      fontSize: isSmallScreen ? 14 : 16,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: isSmallScreen ? 24 : 40),
                                  // Feature Cards
                                  Column(
                                    children: [
                                      _buildFeatureCard(
                                        icon: Icons.calendar_today_outlined,
                                        title: 'Smart Scheduling',
                                        description:
                                            'Book appointments with AI-powered scheduling assistance',
                                        color: const Color(0xFF6F61EF),
                                        isSmallScreen: isSmallScreen,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildFeatureCard(
                                        icon: Icons.medical_services_outlined,
                                        title: 'Digital Health Records',
                                        description:
                                            'Secure access to your medical history and prescriptions',
                                        color: const Color(0xFF39D2C0),
                                        isSmallScreen: isSmallScreen,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildFeatureCard(
                                        icon: Icons.psychology_outlined,
                                        title: 'AI Health Assistant',
                                        description:
                                            'Get personalized health guidance and appointment support',
                                        color: const Color(0xFFEE8B60),
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 24 : 32),
                                  // Action Buttons
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (context, animation,
                                                        secondaryAnimation) =>
                                                    const LoginPage(),
                                                transitionsBuilder: (context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child) {
                                                  const begin = Offset(1.0, 0.0);
                                                  const end = Offset.zero;
                                                  const curve = Curves.easeInOut;
                                                  var tween =
                                                      Tween(begin: begin, end: end)
                                                          .chain(
                                                    CurveTween(curve: curve),
                                                  );
                                                  return SlideTransition(
                                                    position: animation.drive(tween),
                                                    child: child,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.login,
                                              color: Colors.white),
                                          label: Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF002f6c),
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isSmallScreen ? 20 : 24,
                                              vertical: isSmallScreen ? 14 : 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (context, animation,
                                                        secondaryAnimation) =>
                                                    const RegistrationPage(),
                                                transitionsBuilder: (context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child) {
                                                  const begin = Offset(1.0, 0.0);
                                                  const end = Offset.zero;
                                                  const curve = Curves.easeInOut;
                                                  var tween =
                                                      Tween(begin: begin, end: end)
                                                          .chain(
                                                    CurveTween(curve: curve),
                                                  );
                                                  return SlideTransition(
                                                    position: animation.drive(tween),
                                                    child: child,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.person_add,
                                              color: Color(0xFF002f6c)),
                                          label: Text(
                                            'Register',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF002f6c),
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF002f6c),
                                            side: const BorderSide(
                                              color: Color(0xFF002f6c),
                                              width: 2,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isSmallScreen ? 20 : 24,
                                              vertical: isSmallScreen ? 14 : 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 24),
                                  // Footer
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shield_outlined,
                                        size: isSmallScreen ? 14 : 16,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Secure • Confidential • Professional',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 12,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 32),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Emergency Button (floating)
          Positioned(
            bottom: 32,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EmergencyWidget(patientId: ''),
                  ),
                );
              },
              backgroundColor: Colors.red.shade700,
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
              label: const Text(
                'Emergency',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              elevation: 4,
              heroTag: 'emergency_landing',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    bool isSmallScreen = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF002f6c),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
