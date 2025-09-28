import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../widgets/appointment_card.dart';
import '../widgets/medication_card.dart';
import '../widgets/role_selector.dart';
import '../widgets/ai_chat_widget.dart';
import '../widgets/emergency_widget.dart';
import '../pages/appointment_booking.dart';
import '../pages/medication_tracker.dart';
import '../pages/health_records.dart';
import '../pages/landing_page.dart';
import '../utils/date_formatter.dart';


class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  User? currentUser;
  Patient? currentPatient;
  List<AppointmentWithDetails> appointments = [];
  List<Medication> medications = [];
  List<DoctorWithUser> doctors = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        final patients = await DataService.instance.getPatients();
        currentPatient = patients.firstWhere((p) => p.userId == currentUser!.id);
        
        final allAppointments = await DataService.instance.getAppointmentsWithDetails();
        appointments = allAppointments.where((a) => 
          a.appointment.patientId == currentPatient!.id
        ).toList();
        
        final allMedications = await DataService.instance.getMedications();
        medications = allMedications.where((m) => m.patientId == currentPatient!.id).toList();
        
        doctors = await DataService.instance.getDoctorsWithUsers();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  // Save last route for session restore
  AuthService().setLastRoute('patient_dashboard');
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
              'Hello!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            Text(
              currentUser?.name ?? 'Patient',
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
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HealthRecords()),
              );
            },
            icon: Icon(
              Icons.folder_shared,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          IconButton(
            onPressed: () => _showLogoutConfirmation(),
            icon: Icon(
              Icons.logout,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: theme.colorScheme.secondary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Doctors', icon: Icon(Icons.medical_services)),
            Tab(text: 'Appointments', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Medications', icon: Icon(Icons.medication)),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardView(),
          _buildDoctorsView(),
          _buildAppointmentsView(),
          _buildMedicationsView(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // AI Assistant Button
          FloatingActionButton(
            heroTag: 'ai_chat',
            onPressed: () {
              if (currentPatient != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AIChatWidget(patientId: currentPatient!.id),
                  ),
                );
              }
            },
            backgroundColor: theme.colorScheme.secondary,
            child: Icon(
              Icons.smart_toy,
              color: theme.colorScheme.onSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AppointmentBooking(isDoctor: false),
                ),
              ).then((_) => _loadData());
            },
            heroTag: "book_appointment",
            icon: Icon(
              Icons.add,
              color: theme.colorScheme.onPrimary,
            ),
            label: Text(
              'Book Appointment',
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
            backgroundColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    final theme = Theme.of(context);
    final upcomingAppointments = appointments.where((a) => 
      DateFormatter.isUpcoming(a.appointment.dateTime) &&
      a.appointment.status == AppointmentStatus.scheduled
    ).take(3).toList();
    
    final todayMedications = medications.where((m) {
      final todayTaken = m.takenTimes.where((time) => DateFormatter.isToday(time)).length;
      final required = _getRequiredDailyCount(m.frequency);
      return todayTaken < required;
    }).take(3).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Health Summary Card
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Overview',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildHealthStat(
                            theme,
                            'Upcoming',
                            upcomingAppointments.length.toString(),
                            'Appointments',
                            Icons.event,
                            theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          _buildHealthStat(
                            theme,
                            'Pending',
                            todayMedications.length.toString(),
                            'Medications',
                            Icons.medication,
                            theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickAction(
                        theme,
                        'Find Doctor',
                        Icons.search,
                        theme.colorScheme.primary,
                        () => _tabController.animateTo(1),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        theme,
                        'Medications',
                        Icons.medication,
                        theme.colorScheme.tertiary,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MedicationTracker()),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        theme,
                        'Health Records',
                        Icons.folder_shared,
                        theme.colorScheme.secondary,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HealthRecords()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Upcoming Appointments
          if (upcomingAppointments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Upcoming Appointments',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => AppointmentCard(
                  appointmentDetails: upcomingAppointments[index],
                  isDoctor: false,
                  onTap: () => _showAppointmentDetails(upcomingAppointments[index]),
                  onReschedule: () => _rescheduleAppointment(upcomingAppointments[index]),
                  onCancel: () => _cancelAppointment(upcomingAppointments[index]),
                ),
                childCount: upcomingAppointments.length,
              ),
            ),
          ],
          
          // Today's Medications
          if (todayMedications.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Today\'s Medications',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => MedicationCard(
                  medication: todayMedications[index],
                  onMarkTaken: () => _markMedicationTaken(todayMedications[index]),
                ),
                childCount: todayMedications.length,
              ),
            ),
          ],
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsView() {
    final theme = Theme.of(context);
    final filteredDoctors = doctors.where((doctor) {
      if (searchQuery.isEmpty) return true;
      return doctor.user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
             doctor.doctor.specialization.toLowerCase().contains(searchQuery.toLowerCase()) ||
             doctor.doctor.location.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search doctors, specialization, location...',
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            ),
          ),
        ),
        
        // Doctors list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: filteredDoctors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isEmpty ? 'No doctors available' : 'No doctors found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredDoctors.length,
                  itemBuilder: (context, index) => _buildDoctorCard(filteredDoctors[index]),
                ),
          ),
        ),
      ],
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
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AppointmentBooking(isDoctor: false),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: const Text('Book Your First Appointment'),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: appointments.length,
            itemBuilder: (context, index) => AppointmentCard(
              appointmentDetails: appointments[index],
              isDoctor: false,
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

  Widget _buildMedicationsView() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: medications.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No medications found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MedicationTracker()),
                    ).then((_) => _loadData());
                  },
                  child: const Text('Add Medication'),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: medications.length,
            itemBuilder: (context, index) => MedicationCard(
              medication: medications[index],
              onMarkTaken: () => _markMedicationTaken(medications[index]),
              onTap: () => _showMedicationDetails(medications[index]),
            ),
          ),
    );
  }

  Widget _buildHealthStat(ThemeData theme, String label, String value, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
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
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(ThemeData theme, String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorWithUser doctorWithUser) {
    final theme = Theme.of(context);
    final doctor = doctorWithUser.doctor;
    final user = doctorWithUser.user;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showDoctorDetails(doctorWithUser),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Doctor image/avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "https://images.unsplash.com/photo-1546659934-038aab8f3f3b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTEyNDg3MTJ8&ixlib=rb-4.1.0&q=80&w=1080",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.medical_services,
                      size: 30,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doctor.location,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R${doctor.consultationFee.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => _bookWithDoctor(doctorWithUser),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Book'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getRequiredDailyCount(MedicationFrequency frequency) {
    switch (frequency) {
      case MedicationFrequency.once:
        return 1;
      case MedicationFrequency.twice:
        return 2;
      case MedicationFrequency.thrice:
        return 3;
      case MedicationFrequency.fourTimes:
        return 4;
      case MedicationFrequency.asNeeded:
        return 1;
    }
  }

  void _showAppointmentDetails(AppointmentWithDetails appointmentDetails) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor: ${appointmentDetails.doctor.name}'),
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

  void _showDoctorDetails(DoctorWithUser doctorWithUser) {
    final doctor = doctorWithUser.doctor;
    final user = doctorWithUser.user;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specialization: ${doctor.specialization}'),
            Text('Experience: ${doctor.experience} years'),
            Text('Location: ${doctor.location}'),
            Text('Rating: ${doctor.rating}/5.0'),
            Text('Consultation Fee: R${doctor.consultationFee.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Text('Bio:', style: Theme.of(context).textTheme.titleSmall),
            Text(doctor.bio),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bookWithDoctor(doctorWithUser);
            },
            child: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }

  void _showMedicationDetails(Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medication.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: ${medication.dosage}'),
            Text('Frequency: ${DateFormatter.formatMedicationFrequency(medication.frequency.name)}'),
            Text('Prescribed by: ${medication.prescribedBy}'),
            Text('Start Date: ${DateFormatter.formatDate(medication.startDate)}'),
            if (medication.endDate != null)
              Text('End Date: ${DateFormatter.formatDate(medication.endDate!)}'),
            if (medication.instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...medication.instructions.map((instruction) => Text('• $instruction')),
            ],
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

  void _bookWithDoctor(DoctorWithUser doctorWithUser) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentBooking(
          isDoctor: false,
          selectedDoctor: doctorWithUser,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _markMedicationTaken(Medication medication) async {
    final updatedMedication = Medication(
      id: medication.id,
      name: medication.name,
      dosage: medication.dosage,
      frequency: medication.frequency,
      prescribedBy: medication.prescribedBy,
      startDate: medication.startDate,
      endDate: medication.endDate,
      instructions: medication.instructions,
      patientId: medication.patientId,
      takenTimes: [...medication.takenTimes, DateTime.now()],
    );
    
    await DataService.instance.saveMedication(updatedMedication);
    await _loadData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${medication.name} marked as taken')),
      );
    }
  }

  void _rescheduleAppointment(AppointmentWithDetails appointmentDetails) {
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
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}