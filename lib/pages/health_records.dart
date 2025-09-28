import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../utils/date_formatter.dart';

class HealthRecords extends StatefulWidget {
  const HealthRecords({super.key});

  @override
  State<HealthRecords> createState() => _HealthRecordsState();
}

class _HealthRecordsState extends State<HealthRecords> with TickerProviderStateMixin {
  late TabController _tabController;
  List<HealthRecord> healthRecords = [];
  List<AppointmentWithDetails> appointments = [];
  Patient? currentPatient;
  User? currentUser;
  bool isLoading = true;

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
      if (currentUser != null && currentUser!.role == UserRole.patient) {
        final patients = await DataService.instance.getPatients();
        currentPatient = patients.firstWhere((p) => p.userId == currentUser!.id);
        
        final allHealthRecords = await DataService.instance.getHealthRecords();
        healthRecords = allHealthRecords.where((hr) => hr.patientId == currentPatient!.id).toList();
        
        final allAppointments = await DataService.instance.getAppointmentsWithDetails();
        appointments = allAppointments.where((a) => 
          a.appointment.patientId == currentPatient!.id &&
          a.appointment.status == AppointmentStatus.completed
        ).toList();
      }
    } catch (e) {
      debugPrint('Error loading health records: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: theme.colorScheme.secondary,
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.person)),
            Tab(text: 'Records', icon: Icon(Icons.folder_shared)),
            Tab(text: 'Visits', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildProfileView(),
              _buildRecordsView(),
              _buildVisitsView(),
            ],
          ),
    );
  }

  Widget _buildProfileView() {
    final theme = Theme.of(context);
    
    if (currentPatient == null || currentUser == null) {
      return const Center(child: Text('Patient information not available'));
    }
    
    final age = DateFormatter.calculateAge(currentPatient!.dateOfBirth);
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        currentUser!.name.split(' ').map((n) => n[0]).take(2).join(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentUser!.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Age: $age · ${currentPatient!.bloodGroup}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Basic Information
            Text(
              'Basic Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildInfoCard([
              _buildInfoRow('Date of Birth', DateFormatter.formatDate(currentPatient!.dateOfBirth)),
              _buildInfoRow('Blood Group', currentPatient!.bloodGroup),
              _buildInfoRow('Phone', currentUser!.phone),
              _buildInfoRow('Email', currentUser!.email),
            ]),
            
            const SizedBox(height: 24),
            
            // Emergency Contact
            Text(
              'Emergency Contact',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildInfoCard([
              _buildInfoRow('Name', currentPatient!.emergencyContact),
              _buildInfoRow('Phone', currentPatient!.emergencyPhone),
            ]),
            
            const SizedBox(height: 24),
            
            // Medical History
            if (currentPatient!.medicalHistory.isNotEmpty) ...[
              Text(
                'Medical History',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: currentPatient!.medicalHistory.map((condition) => 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.medical_information,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(condition),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Allergies
            if (currentPatient!.allergies.isNotEmpty) ...[
              Text(
                'Allergies',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: currentPatient!.allergies.map((allergy) => 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(allergy),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsView() {
    final theme = Theme.of(context);
    
    if (healthRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_shared,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No health records found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your medical records will appear here after visits',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: healthRecords.length,
        itemBuilder: (context, index) => _buildHealthRecordCard(healthRecords[index]),
      ),
    );
  }

  Widget _buildVisitsView() {
    final theme = Theme.of(context);
    
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No visit history',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed appointments will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) => _buildVisitCard(appointments[index]),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildHealthRecordCard(HealthRecord record) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medical_information,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.diagnosis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDate(record.visitDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Treatment
            if (record.treatment.isNotEmpty) ...[
              Text(
                'Treatment:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(record.treatment),
              const SizedBox(height: 12),
            ],
            
            // Prescriptions
            if (record.prescriptions.isNotEmpty) ...[
              Text(
                'Prescriptions:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...record.prescriptions.map((prescription) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medication,
                        size: 16,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(prescription)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Vital Signs
            if (record.weight != null || record.height != null || 
                record.bloodPressure != null || record.temperature != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vital Signs:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (record.weight != null) ...[
                          _buildVitalSign('Weight', '${record.weight}kg'),
                          const SizedBox(width: 16),
                        ],
                        if (record.height != null) ...[
                          _buildVitalSign('Height', '${record.height}cm'),
                          const SizedBox(width: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (record.bloodPressure != null) ...[
                          _buildVitalSign('BP', record.bloodPressure!),
                          const SizedBox(width: 16),
                        ],
                        if (record.temperature != null) ...[
                          _buildVitalSign('Temp', '${record.temperature}°C'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Notes
            if (record.notes.isNotEmpty) ...[
              Text(
                'Notes:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard(AppointmentWithDetails appointmentDetails) {
    final theme = Theme.of(context);
    final appointment = appointmentDetails.appointment;
    final doctor = appointmentDetails.doctor;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    doctor.name.split(' ').map((n) => n[0]).take(2).join(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDateTime(appointment.dateTime),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Completed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.notes!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            
            if (appointment.prescription != null && appointment.prescription!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.medication,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Prescription: ${appointment.prescription}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            
            if (appointment.consultationFee != null) ...[
              const SizedBox(height: 8),
              Text(
                'Consultation Fee: R${appointment.consultationFee!.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSign(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}