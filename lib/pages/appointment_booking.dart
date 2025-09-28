import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../utils/date_formatter.dart';


class AppointmentBooking extends StatefulWidget {
  final bool isDoctor;
  final DoctorWithUser? selectedDoctor;

  const AppointmentBooking({
    super.key,
    required this.isDoctor,
    this.selectedDoctor,
  });

  @override
  State<AppointmentBooking> createState() => _AppointmentBookingState();
}

class _AppointmentBookingState extends State<AppointmentBooking> {
  DoctorWithUser? selectedDoctor;
  Patient? selectedPatient;
  User? selectedPatientUser;
  DateTime selectedDate = DateTime.now();
  DateTime? selectedTime;
  String notes = '';
  bool isLoading = false;
  
  List<DoctorWithUser> doctors = [];
  List<PatientWithUser> patients = [];
  List<DateTime> availableTimeSlots = [];

  @override
  void initState() {
    super.initState();
    selectedDoctor = widget.selectedDoctor;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      doctors = await DataService.instance.getDoctorsWithUsers();
      patients = await DataService.instance.getPatientsWithUsers();
      
      if (selectedDoctor != null) {
        _generateTimeSlots();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _generateTimeSlots() {
    if (selectedDoctor == null) return;
    
    final doctor = selectedDoctor!.doctor;
    availableTimeSlots = DateFormatter.getTimeSlots(
      doctor.startTime, 
      doctor.endTime,
      intervalMinutes: 30,
    );
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Selection
                if (widget.isDoctor) ...[
                  _buildSectionTitle('Select Patient'),
                  const SizedBox(height: 12),
                  _buildPatientSelector(),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildSectionTitle('Select Doctor'),
                  const SizedBox(height: 12),
                  _buildDoctorSelector(),
                  const SizedBox(height: 24),
                ],
                
                // Date Selection
                if (selectedDoctor != null || selectedPatient != null) ...[
                  _buildSectionTitle('Select Date'),
                  const SizedBox(height: 12),
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                ],
                
                // Time Selection
                if ((selectedDoctor != null || selectedPatient != null) && 
                    availableTimeSlots.isNotEmpty) ...[
                  _buildSectionTitle('Select Time'),
                  const SizedBox(height: 12),
                  _buildTimeSelector(),
                  const SizedBox(height: 24),
                ],
                
                // Notes
                if (selectedTime != null) ...[
                  _buildSectionTitle('Additional Notes (Optional)'),
                  const SizedBox(height: 12),
                  _buildNotesField(),
                  const SizedBox(height: 32),
                  
                  // Summary and Book Button
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _bookAppointment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
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

  Widget _buildDoctorSelector() {
    final theme = Theme.of(context);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: selectedDoctor == null
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.medical_services,
                  size: 48,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select a doctor',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showDoctorPicker(),
                    child: const Text('Choose Doctor'),
                  ),
                ),
              ],
            ),
          )
        : ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  "https://images.unsplash.com/photo-1708676293001-d02f8515624c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTEyNDg4MDB8&ixlib=rb-4.1.0&q=80&w=1080",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.medical_services,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            title: Text(
              selectedDoctor!.user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(selectedDoctor!.doctor.specialization),
            trailing: IconButton(
              onPressed: () => _showDoctorPicker(),
              icon: const Icon(Icons.edit),
            ),
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
                  Icons.person,
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
                selectedPatientUser!.name.split(' ').map((n) => n[0]).take(2).join(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              selectedPatientUser!.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Age: ${DateFormatter.calculateAge(selectedPatient!.dateOfBirth)}'),
            trailing: IconButton(
              onPressed: () => _showPatientPicker(),
              icon: const Icon(Icons.edit),
            ),
          ),
    );
  }

  Widget _buildDateSelector() {
    final theme = Theme.of(context);
    final nextSevenDays = DateFormatter.getNextSevenDays();
    
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: nextSevenDays.length,
        itemBuilder: (context, index) {
          final date = nextSevenDays[index];
          final isSelected = selectedDate.day == date.day &&
                           selectedDate.month == date.month &&
                           selectedDate.year == date.year;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = date;
                selectedTime = null; // Reset time when date changes
              });
              _generateTimeSlots();
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormatter.getDayOfWeek(date).substring(0, 3),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM').format(date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector() {
    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: availableTimeSlots.map((time) {
        final isSelected = selectedTime != null &&
                          selectedTime!.hour == time.hour &&
                          selectedTime!.minute == time.minute;
        
        return GestureDetector(
          onTap: () {
            final appointmentDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              time.hour,
              time.minute,
            );
            
            setState(() {
              selectedTime = appointmentDateTime;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              DateFormatter.formatTime(time),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected 
                  ? theme.colorScheme.onPrimary 
                  : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      maxLines: 3,
      onChanged: (value) => notes = value,
      decoration: InputDecoration(
        hintText: 'Enter any additional notes or special requirements...',
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
    final doctor = widget.isDoctor ? selectedDoctor : selectedDoctor;
    final patient = widget.isDoctor ? selectedPatientUser : null;
    
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
            
            if (doctor != null) ...[
              _buildSummaryRow('Doctor', doctor.user.name),
              _buildSummaryRow('Specialization', doctor.doctor.specialization),
            ],
            
            if (patient != null)
              _buildSummaryRow('Patient', patient.name),
            
            _buildSummaryRow('Date', DateFormatter.formatDate(selectedDate)),
            _buildSummaryRow('Time', DateFormatter.formatTime(selectedTime!)),
            
            if (doctor != null)
              _buildSummaryRow('Fee', 'R${doctor.doctor.consultationFee.toStringAsFixed(0)}'),
            
            if (notes.isNotEmpty)
              _buildSummaryRow('Notes', notes),
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
            width: 100,
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

  void _showDoctorPicker() {
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
                'Select Doctor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doctor = doctors[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        doctor.user.name.split(' ').first[0],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(doctor.user.name),
                    subtitle: Text('${doctor.doctor.specialization} · ${doctor.doctor.location}'),
                    trailing: Text('R${doctor.doctor.consultationFee.toStringAsFixed(0)}'),
                    onTap: () {
                      setState(() {
                        selectedDoctor = doctor;
                        selectedTime = null;
                      });
                      _generateTimeSlots();
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
                    subtitle: Text('Age: $age · ${patient.patient.bloodGroup}'),
                    onTap: () {
                      setState(() {
                        selectedPatient = patient.patient;
                        selectedPatientUser = patient.user;
                        selectedTime = null;
                      });
                      _generateTimeSlots();
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

  void _bookAppointment() async {
    if (selectedTime == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final currentUser = await DataService.instance.getCurrentUser();
      if (currentUser == null) return;
      
      String doctorId, patientId;
      
      if (widget.isDoctor) {
        // Doctor is booking for a patient
        final doctors = await DataService.instance.getDoctors();
        final currentDoctor = doctors.firstWhere((d) => d.userId == currentUser.id);
        doctorId = currentDoctor.id;
        patientId = selectedPatient!.id;
      } else {
        // Patient is booking with a doctor
        final patients = await DataService.instance.getPatients();
        final currentPatient = patients.firstWhere((p) => p.userId == currentUser.id);
        doctorId = selectedDoctor!.doctor.id;
        patientId = currentPatient.id;
      }
      
      final appointment = Appointment(
        id: DataService.instance.generateId(),
        doctorId: doctorId,
        patientId: patientId,
        dateTime: selectedTime!,
        status: AppointmentStatus.scheduled,
        notes: notes.isNotEmpty ? notes : null,
        consultationFee: selectedDoctor!.doctor.consultationFee,
      );
      
      await DataService.instance.saveAppointment(appointment);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to book appointment. Please try again.')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }
}

