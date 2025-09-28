import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../utils/date_formatter.dart';
import '../utils/currency_formatter.dart';

class QuickAppointmentPage extends StatefulWidget {
  const QuickAppointmentPage({super.key});

  @override
  State<QuickAppointmentPage> createState() => _QuickAppointmentPageState();
}

class _QuickAppointmentPageState extends State<QuickAppointmentPage> {
  User? currentUser;
  Doctor? currentDoctor;
  List<PatientWithUser> patients = [];
  PatientWithUser? selectedPatient;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String notes = '';
  bool isLoading = false;

  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      currentUser = await DataService.instance.getCurrentUser();
      if (currentUser != null) {
        final doctors = await DataService.instance.getDoctors();
        currentDoctor = doctors.firstWhere((d) => d.userId == currentUser!.id);
        patients = await DataService.instance.getPatientsWithUsers();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createAppointment() async {
    if (selectedPatient == null || currentDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final appointmentDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final appointment = Appointment(
        id: DataService.instance.generateId(),
        doctorId: currentDoctor!.id,
        patientId: selectedPatient!.patient.id,
        dateTime: appointmentDateTime,
        status: AppointmentStatus.scheduled,
        notes: _notesController.text.trim().isEmpty ? 'Doctor scheduled appointment' : _notesController.text.trim(),
        consultationFee: currentDoctor!.consultationFee,
      );

      await DataService.instance.saveAppointment(appointment);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment scheduled for ${selectedPatient!.user.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create appointment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading && patients.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Schedule Appointment'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Appointment'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          TextButton(
            onPressed: selectedPatient != null && !isLoading ? _createAppointment : null,
            child: Text(
              'Schedule',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Selection
            _buildSectionTitle('Select Patient'),
            const SizedBox(height: 12),
            _buildPatientSelector(),
            
            const SizedBox(height: 24),
            
            // Date Selection
            _buildSectionTitle('Date & Time'),
            const SizedBox(height: 12),
            _buildDateTimeSelector(),
            
            const SizedBox(height: 24),
            
            // Notes
            _buildSectionTitle('Notes (Optional)'),
            const SizedBox(height: 12),
            _buildNotesField(),
            
            const SizedBox(height: 24),
            
            // Summary
            if (selectedPatient != null)
              _buildSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPatientSelector() {
    final theme = Theme.of(context);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: selectedPatient == null
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.person_search,
                  size: 48,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select a patient',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showPatientPicker(),
                    child: const Text('Choose Patient'),
                  ),
                ),
              ],
            ),
          )
        : ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                selectedPatient!.user.name.split(' ').map((n) => n[0]).take(2).join(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              selectedPatient!.user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Age: ${DateFormatter.calculateAge(selectedPatient!.patient.dateOfBirth)}'),
                Text('Blood Group: ${selectedPatient!.patient.bloodGroup}'),
              ],
            ),
            trailing: IconButton(
              onPressed: () => _showPatientPicker(),
              icon: const Icon(Icons.edit),
            ),
          ),
    );
  }

  Widget _buildDateTimeSelector() {
    final theme = Theme.of(context);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMMM d, y').format(selectedDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Time picker
            Row(
              children: [
                Icon(Icons.access_time, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedTime.format(context),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add any notes for this appointment...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final theme = Theme.of(context);
    final appointmentDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildSummaryRow('Patient', selectedPatient!.user.name),
            _buildSummaryRow('Doctor', 'Dr. ${currentUser!.name}'),
            _buildSummaryRow('Date', DateFormatter.formatDate(selectedDate)),
            _buildSummaryRow('Time', selectedTime.format(context)),
            _buildSummaryRow('Fee', CurrencyFormatter.formatConsultationFee(currentDoctor!.consultationFee)),
            
            if (_notesController.text.trim().isNotEmpty)
              _buildSummaryRow('Notes', _notesController.text.trim()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  void _showPatientPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Select Patient',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  final age = DateFormatter.calculateAge(patient.patient.dateOfBirth);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        patient.user.name.split(' ').first[0],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(patient.user.name),
                    subtitle: Text('Age: $age • ${patient.patient.bloodGroup} • ${patient.user.phone}'),
                    onTap: () {
                      setState(() {
                        selectedPatient = patient;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}