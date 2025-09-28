import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../utils/currency_formatter.dart';
import '../services/doctor_bank_service.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  // Banking details
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _branchCodeController = TextEditingController();
  String? selectedBank;
  bool isBankEditing = false;
  final List<String> bankList = [
    'ABSA', 'Capitec', 'FNB', 'Nedbank', 'Standard Bank', 'Investec', 'TymeBank', 'African Bank', 'Other'
  ];
  User? currentUser;
  Doctor? currentDoctor;
  bool isLoading = true;
  bool isEditing = false;
  
  // Controllers for editing
  final _specializationController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _locationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  
  List<String> selectedDays = [];
  final List<String> weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
  _specializationController.dispose();
  _qualificationsController.dispose();
  _locationController.dispose();
  _bioController.dispose();
  _experienceController.dispose();
  _feeController.dispose();
  _startTimeController.dispose();
  _endTimeController.dispose();
  _accountHolderController.dispose();
  _accountNumberController.dispose();
  _branchCodeController.dispose();
  super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      currentUser = await DataService.instance.getCurrentUser();
      if (currentUser != null) {
        final doctors = await DataService.instance.getDoctors();
        currentDoctor = doctors.firstWhere((d) => d.userId == currentUser!.id);
        _populateControllers();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _populateControllers() {
    if (currentDoctor != null) {
      _specializationController.text = currentDoctor!.specialization;
      _qualificationsController.text = currentDoctor!.qualifications;
      _locationController.text = currentDoctor!.location;
      _licenseController.text = currentDoctor!.licenseNumber;
      _bioController.text = currentDoctor!.bio;
      _experienceController.text = currentDoctor!.experience.toString();
      _feeController.text = currentDoctor!.consultationFee.toString();
      _startTimeController.text = currentDoctor!.startTime;
      _endTimeController.text = currentDoctor!.endTime;
      selectedDays = List.from(currentDoctor!.availableDays);
      // Fetch banking details from backend
      final doctorId = currentDoctor!.id;
      DoctorBankService().fetchBankDetails(doctorId).then((bankData) {
        if (bankData != null) {
          setState(() {
            _accountHolderController.text = bankData['accountHolder'] ?? '';
            selectedBank = bankData['bankName'] ?? bankList.first;
            _accountNumberController.text = bankData['accountNumber'] ?? '';
            _branchCodeController.text = bankData['branchCode'] ?? '';
          });
        } else {
          setState(() {
            _accountHolderController.text = currentUser?.name ?? '';
            selectedBank = bankList.first;
            _accountNumberController.text = '';
            _branchCodeController.text = '';
          });
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (currentDoctor == null) return;
    
    try {
      final updatedDoctor = Doctor(
        id: currentDoctor!.id,
        userId: currentDoctor!.userId,
        specialization: _specializationController.text.trim(),
        qualifications: _qualificationsController.text.trim(),
        location: _locationController.text.trim(),
        rating: currentDoctor!.rating, // Keep existing rating
        experience: int.tryParse(_experienceController.text) ?? currentDoctor!.experience,
        bio: _bioController.text.trim(),
        availableDays: selectedDays,
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        consultationFee: double.tryParse(_feeController.text) ?? currentDoctor!.consultationFee,
        licenseNumber: _licenseController.text.trim()
      );
      await DataService.instance.updateDoctor(updatedDoctor);
      setState(() {
        currentDoctor = updatedDoctor;
        isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Doctor Profile'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (!isEditing)
            IconButton(
              onPressed: () => setState(() => isEditing = true),
              icon: const Icon(Icons.edit),
            )
          else ...[
            IconButton(
              onPressed: () {
                _populateControllers();
                setState(() => isEditing = false);
              },
              icon: const Icon(Icons.cancel),
            ),
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        currentUser?.name.split(' ').map((n) => n[0]).take(2).join() ?? 'D',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${currentUser?.name ?? 'Unknown'}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser?.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Professional Information
            _buildSectionTitle('Professional Information'),
            const SizedBox(height: 16),
            
            _buildTextField(
              'Specialization',
              _specializationController,
              Icons.medical_services,
              enabled: isEditing,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              'Qualifications',
              _qualificationsController,
              Icons.school,
              enabled: isEditing,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              'Location',
              _locationController,
              Icons.location_on,
              enabled: isEditing,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Experience (years)',
                    _experienceController,
                    Icons.work,
                    enabled: isEditing,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    'Consultation Fee (${CurrencyFormatter.currencySymbol})',
                    _feeController,
                    Icons.attach_money,
                    enabled: isEditing,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Bio
            _buildSectionTitle('Bio'),
            const SizedBox(height: 16),
            
            _buildTextField(
              'Tell patients about yourself',
              _bioController,
              Icons.person,
              enabled: isEditing,
              maxLines: 4,
            ),
            
            const SizedBox(height: 24),
            
            // Availability
            _buildSectionTitle('Availability'),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Start Time (e.g., 08:00)',
                    _startTimeController,
                    Icons.access_time,
                    enabled: isEditing,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    'End Time (e.g., 17:00)',
                    _endTimeController,
                    Icons.access_time_filled,
                    enabled: isEditing,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Available Days',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weekDays.map((day) {
                final isSelected = selectedDays.contains(day);
                return FilterChip(
                  label: Text(day),
                  selected: isSelected,
                  onSelected: isEditing ? (selected) {
                    setState(() {
                      if (selected) {
                        selectedDays.add(day);
                      } else {
                        selectedDays.remove(day);
                      }
                    });
                  } : null,
                  selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            
            // Stats Card
            if (!isEditing) ...[
              _buildSectionTitle('Statistics'),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Banking Details'),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _accountHolderController,
                                decoration: const InputDecoration(labelText: 'Account Name'),
                                enabled: isBankEditing,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: selectedBank,
                                decoration: const InputDecoration(labelText: 'Bank Name'),
                                items: bankList.map((bank) => DropdownMenuItem(
                                  value: bank,
                                  child: Text(bank),
                                )).toList(),
                                onChanged: isBankEditing ? (value) => setState(() => selectedBank = value) : null,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _accountNumberController,
                                decoration: const InputDecoration(labelText: 'Account Number'),
                                keyboardType: TextInputType.number,
                                enabled: isBankEditing,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _branchCodeController,
                                decoration: const InputDecoration(labelText: 'Branch Code'),
                                keyboardType: TextInputType.number,
                                enabled: isBankEditing,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (!isBankEditing)
                                    ElevatedButton(
                                      onPressed: () => setState(() => isBankEditing = true),
                                      child: const Text('Edit'),
                                    ),
                                  if (isBankEditing) ...[
                                    ElevatedButton(
                                      onPressed: () async {
                                        // Save to backend
                                        final doctorId = currentDoctor?.id ?? currentUser?.id ?? '';
                                        final success = await DoctorBankService().saveBankDetails(
                                          doctorId: doctorId,
                                          accountHolder: _accountHolderController.text,
                                          bankName: selectedBank ?? '',
                                          accountNumber: _accountNumberController.text,
                                          branchCode: _branchCodeController.text,
                                        );
                                        setState(() => isBankEditing = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(success ? 'Banking details updated' : 'Failed to update banking details')),
                                        );
                                      },
                                      child: const Text('Save'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () {
                                        _populateControllers();
                                        setState(() => isBankEditing = false);
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatItem(
                            'Rating',
                            '${currentDoctor?.rating ?? 0}/5.0',
                            Icons.star,
                            theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 20),
                          _buildStatItem(
                            'Experience',
                            '${currentDoctor?.experience ?? 0} years',
                            Icons.work,
                            theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 80),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: enabled 
          ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
          : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}