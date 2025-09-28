import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../widgets/appointment_card.dart';
import '../widgets/role_selector.dart';
import '../widgets/emergency_widget.dart';
import '../pages/appointment_booking.dart';
import '../pages/doctor_profile_page.dart';
import '../pages/quick_appointment_page.dart';
import '../pages/landing_page.dart';
import '../utils/date_formatter.dart';
import '../services/doctor_bank_service.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> with TickerProviderStateMixin {
  void _showBankingDetailsDialog() {
    final accountHolderController = TextEditingController(text: accountHolder ?? '');
    final accountNumberController = TextEditingController(text: accountNumber ?? '');
    final branchCodeController = TextEditingController(text: branchCode ?? '');
    String? selectedBank = bankName;
    final List<String> bankList = [
      'ABSA', 'Capitec', 'FNB', 'Nedbank', 'Standard Bank', 'Investec', 'TymeBank', 'African Bank', 'Other'
    ];
    bool isEditing = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Banking Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: accountHolderController,
                    decoration: const InputDecoration(labelText: 'Account Name'),
                    enabled: isEditing,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedBank,
                    decoration: const InputDecoration(labelText: 'Bank Name'),
                    items: bankList.map((bank) => DropdownMenuItem(
                      value: bank,
                      child: Text(bank),
                    )).toList(),
                    onChanged: isEditing ? (value) => setStateDialog(() => selectedBank = value) : null,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: accountNumberController,
                    decoration: const InputDecoration(labelText: 'Account Number'),
                    keyboardType: TextInputType.number,
                    enabled: isEditing,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: branchCodeController,
                    decoration: const InputDecoration(labelText: 'Branch Code'),
                    keyboardType: TextInputType.number,
                    enabled: isEditing,
                  ),
                ],
              ),
            ),
            actions: [
              if (!isEditing)
                TextButton(
                  onPressed: () => setStateDialog(() => isEditing = true),
                  child: const Text('Edit'),
                ),
              if (isEditing) ...[
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      accountHolder = accountHolderController.text;
                      bankName = selectedBank;
                      accountNumber = accountNumberController.text;
                      branchCode = branchCodeController.text;
                    });
                    // Save to backend
                    final doctorId = currentDoctor?.id ?? currentUser?.id ?? '';
                    final success = await DoctorBankService().saveBankDetails(
                      doctorId: doctorId,
                      accountHolder: accountHolder ?? '',
                      bankName: bankName ?? '',
                      accountNumber: accountNumber ?? '',
                      branchCode: branchCode ?? '',
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Banking details updated' : 'Failed to update banking details')),
                    );
                  },
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  late TabController _tabController;
  User? currentUser;
  Doctor? currentDoctor;
  List<AppointmentWithDetails> appointments = [];
  List<PatientWithUser> patients = [];
  bool isLoading = true;

    // Mocked banking details
    String? bankName;
    String? accountHolder;
    String? accountNumber;
    String? branchCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      currentUser = await DataService.instance.getCurrentUser();
      if (currentUser != null) {
        final doctors = await DataService.instance.getDoctors();
        currentDoctor = doctors.firstWhere((d) => d.userId == currentUser!.id);
        
        final allAppointments = await DataService.instance.getAppointmentsWithDetails();
        appointments = allAppointments.where((a) => 
          a.appointment.doctorId == currentDoctor!.id
        ).toList();
        
        patients = await DataService.instance.getPatientsWithUsers();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good ${_getGreeting()}!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            Text(
              currentUser?.name ?? 'Doctor',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          // Logout Button with confirmation
          IconButton(
            onPressed: () => _showLogoutConfirmation(),
            icon: Icon(
              Icons.logout,
              color: theme.colorScheme.onPrimary,
            ),
          ),
            // Profile button
            IconButton(
              onPressed: _showDoctorProfile,
              icon: Icon(
                Icons.person,
                color: theme.colorScheme.onPrimary,
              ),
              tooltip: 'Profile',
            ),
            // Banking details button
            IconButton(
              onPressed: () => _showBankingDetailsDialog(),
              icon: Icon(
                Icons.account_balance,
                color: theme.colorScheme.onPrimary,
              ),
              tooltip: 'Banking Details',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: theme.colorScheme.secondary,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'Appointments', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Patients', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayView(),
          _buildAppointmentsView(),
          _buildPatientsView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new_appointment',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const QuickAppointmentPage(),
            ),
          ).then((result) {
            if (result == true) {
              _loadData(); // Refresh data when appointment is created
            }
          });
        },
        icon: Icon(
          Icons.add,
          color: theme.colorScheme.onPrimary,
        ),
        label: Text(
          'Schedule Appointment',
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTodayView() {
    final theme = Theme.of(context);
    final todayAppointments = appointments.where((a) => 
      DateFormatter.isToday(a.appointment.dateTime) &&
      a.appointment.status == AppointmentStatus.scheduled
    ).toList();
    
    final upcomingAppointments = appointments.where((a) => 
      DateFormatter.isUpcoming(a.appointment.dateTime) &&
      a.appointment.status == AppointmentStatus.scheduled
    ).take(3).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Statistics
          SliverToBoxAdapter(
            child: Container(
              color: theme.colorScheme.primary,
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      _buildStatCard(
                        theme,
                        'Today\'s Appointments',
                        todayAppointments.length.toString(),
                        Icons.today,
                        theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        theme,
                        'Total Patients',
                        patients.length.toString(),
                        Icons.people,
                        theme.colorScheme.tertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Today's appointments
          if (todayAppointments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Today\'s Schedule',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => AppointmentCard(
                  appointmentDetails: todayAppointments[index],
                  isDoctor: true,
                  onTap: () => _showAppointmentDetails(todayAppointments[index]),
                  onReschedule: () => _rescheduleAppointment(todayAppointments[index]),
                  onCancel: () => _cancelAppointment(todayAppointments[index]),
                ),
                childCount: todayAppointments.length,
              ),
            ),
          ],
          
          // Upcoming appointments
          if (upcomingAppointments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Upcoming Appointments',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => AppointmentCard(
                  appointmentDetails: upcomingAppointments[index],
                  isDoctor: true,
                  onTap: () => _showAppointmentDetails(upcomingAppointments[index]),
                  onReschedule: () => _rescheduleAppointment(upcomingAppointments[index]),
                  onCancel: () => _cancelAppointment(upcomingAppointments[index]),
                ),
                childCount: upcomingAppointments.length,
              ),
            ),
          ],
          
          // Empty state
          if (todayAppointments.isEmpty && upcomingAppointments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No appointments scheduled',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsView() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: appointments.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No appointments found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: appointments.length,
            itemBuilder: (context, index) => AppointmentCard(
              appointmentDetails: appointments[index],
              isDoctor: true,
              onTap: () => _showAppointmentDetails(appointments[index]),
              onReschedule: appointments[index].appointment.status == AppointmentStatus.scheduled
                ? () => _rescheduleAppointment(appointments[index])
                : null,
              onCancel: appointments[index].appointment.status == AppointmentStatus.scheduled
                ? () => _cancelAppointment(appointments[index])
                : null,
            ),
          ),
    );
  }

  Widget _buildPatientsView() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: patients.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No patients found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: patients.length,
            itemBuilder: (context, index) => _buildPatientCard(patients[index]),
          ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(PatientWithUser patientWithUser) {
    final theme = Theme.of(context);
    final patient = patientWithUser.patient;
    final user = patientWithUser.user;
    final age = DateFormatter.calculateAge(patient.dateOfBirth);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Text(
            user.name.split(' ').map((n) => n[0]).take(2).join(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Age: $age · Blood Group: ${patient.bloodGroup}'),
            if (patient.medicalHistory.isNotEmpty)
              Text('Medical History: ${patient.medicalHistory.join(', ')}'),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: theme.colorScheme.primary,
          size: 16,
        ),
        onTap: () => _showPatientDetails(patientWithUser),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  void _showAppointmentDetails(AppointmentWithDetails appointmentDetails) {
    // Show appointment details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${appointmentDetails.patient.name}'),
            Text('Date: ${DateFormatter.formatAppointmentDate(appointmentDetails.appointment.dateTime)}'),
            if (appointmentDetails.appointment.notes != null)
              Text('Notes: ${appointmentDetails.appointment.notes}'),
            if (appointmentDetails.appointment.consultationFee != null)
              Text('Fee: R${appointmentDetails.appointment.consultationFee!.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPatientDetails(PatientWithUser patientWithUser) {
    // Show patient details dialog
    final patient = patientWithUser.patient;
    final user = patientWithUser.user;
    final age = DateFormatter.calculateAge(patient.dateOfBirth);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Age: $age'),
            Text('Blood Group: ${patient.bloodGroup}'),
            Text('Phone: ${user.phone}'),
            Text('Email: ${user.email}'),
            if (patient.allergies.isNotEmpty)
              Text('Allergies: ${patient.allergies.join(', ')}'),
            if (patient.medicalHistory.isNotEmpty)
              Text('Medical History: ${patient.medicalHistory.join(', ')}'),
            Text('Emergency Contact: ${patient.emergencyContact} (${patient.emergencyPhone})'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment(AppointmentWithDetails appointmentDetails) {
    // Show reschedule dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reschedule functionality coming soon')),
    );
  }

  void _cancelAppointment(AppointmentWithDetails appointmentDetails) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final cancelledAppointment = Appointment(
                id: appointmentDetails.appointment.id,
                doctorId: appointmentDetails.appointment.doctorId,
                patientId: appointmentDetails.appointment.patientId,
                dateTime: appointmentDetails.appointment.dateTime,
                status: AppointmentStatus.cancelled,
                notes: appointmentDetails.appointment.notes,
                prescription: appointmentDetails.appointment.prescription,
                consultationFee: appointmentDetails.appointment.consultationFee,
              );
              
              await DataService.instance.saveAppointment(cancelledAppointment);
              await _loadData();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment cancelled')),
                );
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthService().logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                );
              }

                void _showBankingDetailsDialog() {
                  final bankNameController = TextEditingController(text: bankName ?? '');
                  final accountHolderController = TextEditingController(text: accountHolder ?? '');
                  final accountNumberController = TextEditingController(text: accountNumber ?? '');
                  final branchCodeController = TextEditingController(text: branchCode ?? '');

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Banking Details'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: bankNameController,
                              decoration: const InputDecoration(labelText: 'Bank Name'),
                            ),
                            TextField(
                              controller: accountHolderController,
                              decoration: const InputDecoration(labelText: 'Account Holder'),
                            ),
                            TextField(
                              controller: accountNumberController,
                              decoration: const InputDecoration(labelText: 'Account Number'),
                              keyboardType: TextInputType.number,
                            ),
                            TextField(
                              controller: branchCodeController,
                              decoration: const InputDecoration(labelText: 'Branch Code'),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              bankName = bankNameController.text;
                              accountHolder = accountHolderController.text;
                              accountNumber = accountNumberController.text;
                              branchCode = branchCodeController.text;
                            });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Banking details saved')),
                            );
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDoctorProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DoctorProfilePage()),
    ).then((_) => _loadData()); // Refresh data when returning from profile
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}