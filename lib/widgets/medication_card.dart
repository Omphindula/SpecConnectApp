import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../utils/date_formatter.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback? onTap;
  final VoidCallback? onMarkTaken;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onTap,
    this.onMarkTaken,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = _isOverdue();
    final todayTakenCount = _getTodayTakenCount();
    final requiredCount = _getRequiredDailyCount();
    final isCompleteToday = todayTakenCount >= requiredCount;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverdue 
            ? theme.colorScheme.error.withOpacity(0.3)
            : isCompleteToday 
              ? theme.colorScheme.tertiary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Medication icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOverdue 
                        ? theme.colorScheme.error.withOpacity(0.1)
                        : isCompleteToday 
                          ? theme.colorScheme.tertiary.withOpacity(0.1)
                          : theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getMedicationIcon(),
                      color: isOverdue 
                        ? theme.colorScheme.error
                        : isCompleteToday 
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 2),
                        
                        Text(
                          '${medication.dosage} · ${DateFormatter.formatMedicationFrequency(medication.frequency.name)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status indicator
                  if (isCompleteToday) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Complete',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (isOverdue) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Overdue',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // More options
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
                                const SizedBox(width: 8),
                                const Text('Delete'),
                              ],
                            ),
                          ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Progress indicator
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Today\'s Progress',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              '$todayTakenCount / $requiredCount',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isCompleteToday 
                                  ? theme.colorScheme.tertiary 
                                  : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        LinearProgressIndicator(
                          value: requiredCount > 0 ? todayTakenCount / requiredCount : 0,
                          backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleteToday 
                              ? theme.colorScheme.tertiary 
                              : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (onMarkTaken != null && !isCompleteToday) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onMarkTaken,
                      icon: Icon(
                        Icons.medication,
                        size: 18,
                        color: theme.colorScheme.onPrimary,
                      ),
                      label: Text(
                        'Take',
                        style: TextStyle(color: theme.colorScheme.onPrimary),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Additional info
              if (medication.instructions.isNotEmpty) ...[
                const SizedBox(height: 12),
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
                        'Instructions:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...medication.instructions.map((instruction) => 
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '• $instruction',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Prescribed by and dates
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Prescribed by ${medication.prescribedBy}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(
                    'Started ${DateFormatter.formatDate(medication.startDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMedicationIcon() {
    final name = medication.name.toLowerCase();
    if (name.contains('insulin')) return Icons.water_drop;
    if (name.contains('tablet') || name.contains('pill')) return Icons.medication;
    if (name.contains('syrup') || name.contains('liquid')) return Icons.local_drink;
    if (name.contains('cream') || name.contains('gel')) return Icons.soap;
    return Icons.medication;
  }

  bool _isOverdue() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTaken = _getTodayTakenCount();
    final required = _getRequiredDailyCount();
    
    // If we haven't taken all required doses and it's past noon, consider overdue
    return todayTaken < required && now.hour >= 12;
  }

  int _getTodayTakenCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return medication.takenTimes.where((time) {
      final takenDate = DateTime(time.year, time.month, time.day);
      return takenDate == today;
    }).length;
  }

  int _getRequiredDailyCount() {
    switch (medication.frequency) {
      case MedicationFrequency.once:
        return 1;
      case MedicationFrequency.twice:
        return 2;
      case MedicationFrequency.thrice:
        return 3;
      case MedicationFrequency.fourTimes:
        return 4;
      case MedicationFrequency.asNeeded:
        return 1; // Flexible, but show 1 for progress
    }
  }
}