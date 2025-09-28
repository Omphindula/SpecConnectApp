import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../widgets/medication_card.dart';
import '../utils/date_formatter.dart';

class MedicationTracker extends StatefulWidget {
  const MedicationTracker({super.key});

  @override
  State<MedicationTracker> createState() => _MedicationTrackerState();
}

class _MedicationTrackerState extends State<MedicationTracker> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Medication> medications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMedications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    setState(() => isLoading = true);
    
    try {
      final currentUser = await DataService.instance.getCurrentUser();
      if (currentUser != null && currentUser.role == UserRole.patient) {
        final patients = await DataService.instance.getPatients();
        final currentPatient = patients.firstWhere((p) => p.userId == currentUser.id);
        
        final allMedications = await DataService.instance.getMedications();
        medications = allMedications.where((m) => m.patientId == currentPatient.id).toList();
      }
    } catch (e) {
      debugPrint('Error loading medications: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Tracker'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: theme.colorScheme.secondary,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'All', icon: Icon(Icons.medication)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildTodayView(),
              _buildAllMedicationsView(),
              _buildHistoryView(),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicationDialog,
        icon: Icon(
          Icons.add,
          color: theme.colorScheme.onPrimary,
        ),
        label: Text(
          'Add Medication',
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTodayView() {
    final theme = Theme.of(context);
    final todayMedications = medications.where((m) {
      final todayTaken = m.takenTimes.where((time) => DateFormatter.isToday(time)).length;
      final required = _getRequiredDailyCount(m.frequency);
      return todayTaken < required;
    }).toList();

    if (todayMedications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'All medications taken for today!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Great job staying on track!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedications,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: todayMedications.length,
        itemBuilder: (context, index) => MedicationCard(
          medication: todayMedications[index],
          onMarkTaken: () => _markMedicationTaken(todayMedications[index]),
          onTap: () => _showMedicationDetails(todayMedications[index]),
          onEdit: () => _showEditMedicationDialog(todayMedications[index]),
          onDelete: () => _deleteMedication(todayMedications[index]),
        ),
      ),
    );
  }

  Widget _buildAllMedicationsView() {
    final theme = Theme.of(context);

    if (medications.isEmpty) {
      return Center(
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
              'No medications added',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first medication to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedications,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: medications.length,
        itemBuilder: (context, index) => MedicationCard(
          medication: medications[index],
          onMarkTaken: () => _markMedicationTaken(medications[index]),
          onTap: () => _showMedicationDetails(medications[index]),
          onEdit: () => _showEditMedicationDialog(medications[index]),
          onDelete: () => _deleteMedication(medications[index]),
        ),
      ),
    );
  }

  Widget _buildHistoryView() {
    final theme = Theme.of(context);
    final medicationsWithHistory = medications.where((m) => m.takenTimes.isNotEmpty).toList();

    if (medicationsWithHistory.isEmpty) {
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
              'No medication history',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start taking your medications to see history',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedications,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: medicationsWithHistory.length,
        itemBuilder: (context, index) {
          final medication = medicationsWithHistory[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(
                medication.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${medication.takenTimes.length} doses taken'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent doses:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...medication.takenTimes.take(10).map((time) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• ${DateFormatter.formatDateTimeShort(time)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      )),
                      if (medication.takenTimes.length > 10)
                        Text(
                          '... and ${medication.takenTimes.length - 10} more',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddMedicationDialog() {
    _showMedicationDialog();
  }

  void _showEditMedicationDialog(Medication medication) {
    _showMedicationDialog(medication: medication);
  }

  void _showMedicationDialog({Medication? medication}) {
    final isEditing = medication != null;
    
    String name = medication?.name ?? '';
    String dosage = medication?.dosage ?? '';
    MedicationFrequency frequency = medication?.frequency ?? MedicationFrequency.once;
    String prescribedBy = medication?.prescribedBy ?? '';
    DateTime startDate = medication?.startDate ?? DateTime.now();
    DateTime? endDate = medication?.endDate;
    List<String> instructions = List.from(medication?.instructions ?? []);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Medication' : 'Add Medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Medication Name'),
                  controller: TextEditingController(text: name),
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Dosage (e.g., 10mg)'),
                  controller: TextEditingController(text: dosage),
                  onChanged: (value) => dosage = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MedicationFrequency>(
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  value: frequency,
                  items: MedicationFrequency.values.map((freq) => DropdownMenuItem(
                    value: freq,
                    child: Text(DateFormatter.formatMedicationFrequency(freq.name)),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => frequency = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Prescribed By'),
                  controller: TextEditingController(text: prescribedBy),
                  onChanged: (value) => prescribedBy = value,
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
              onPressed: () async {
                if (name.isNotEmpty && dosage.isNotEmpty && prescribedBy.isNotEmpty) {
                  final currentUser = await DataService.instance.getCurrentUser();
                  if (currentUser != null) {
                    final patients = await DataService.instance.getPatients();
                    final currentPatient = patients.firstWhere((p) => p.userId == currentUser.id);
                    
                    final newMedication = Medication(
                      id: medication?.id ?? DataService.instance.generateId(),
                      name: name,
                      dosage: dosage,
                      frequency: frequency,
                      prescribedBy: prescribedBy,
                      startDate: medication?.startDate ?? DateTime.now(),
                      endDate: medication?.endDate,
                      instructions: medication?.instructions ?? [],
                      patientId: currentPatient.id,
                      takenTimes: medication?.takenTimes ?? [],
                    );
                    
                    await DataService.instance.saveMedication(newMedication);
                    await _loadMedications();
                    
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing 
                            ? 'Medication updated successfully' 
                            : 'Medication added successfully'),
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
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
            const SizedBox(height: 8),
            Text('Total doses taken: ${medication.takenTimes.length}'),
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
    await _loadMedications();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${medication.name} marked as taken')),
      );
    }
  }

  void _deleteMedication(Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Note: In a real app, you'd implement delete functionality in DataService
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete functionality coming soon')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
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
}