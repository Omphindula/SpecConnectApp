import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../utils/date_formatter.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentWithDetails appointmentDetails;
  final bool isDoctor;
  final VoidCallback? onTap;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  const AppointmentCard({
    super.key,
    required this.appointmentDetails,
    required this.isDoctor,
    this.onTap,
    this.onReschedule,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appointment = appointmentDetails.appointment;
    final otherUser = isDoctor ? appointmentDetails.patient : appointmentDetails.doctor;
    
    Color statusColor = _getStatusColor(appointment.status, theme);
    String statusText = _getStatusText(appointment.status);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
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
                  // Status indicator
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Avatar and info
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      otherUser.name.split(' ').map((n) => n[0]).take(2).join(),
                      style: theme.textTheme.titleMedium?.copyWith(
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
                          otherUser.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 2),
                        
                        if (isDoctor) ...[
                          Text(
                            'Patient · ${otherUser.phone}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Doctor · ${otherUser.phone}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Date and time
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormatter.formatAppointmentDate(appointment.dateTime),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  if (appointment.consultationFee != null) ...[
                    Icon(
                      Icons.payments,
                      size: 16,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'R${appointment.consultationFee!.toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Notes (if available)
              if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appointment.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              
              // Action buttons
              if (appointment.status == AppointmentStatus.scheduled && 
                  (onReschedule != null || onCancel != null)) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onReschedule != null) ...[
                      OutlinedButton.icon(
                        onPressed: onReschedule,
                        icon: Icon(
                          Icons.schedule,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          'Reschedule',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    if (onCancel != null) ...[
                      OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: Icon(
                          Icons.cancel_outlined,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        label: Text(
                          'Cancel',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.error),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status, ThemeData theme) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return theme.colorScheme.primary;
      case AppointmentStatus.completed:
        return theme.colorScheme.tertiary;
      case AppointmentStatus.cancelled:
        return theme.colorScheme.error;
      case AppointmentStatus.rescheduled:
        return theme.colorScheme.secondary;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
    }
  }
}