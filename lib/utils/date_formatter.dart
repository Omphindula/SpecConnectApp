import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date.toLocal());
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date.toLocal());
  }

  static String formatDateTimeShort(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today ${formatTime(date)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday ${formatTime(date)}';
    } else if (now.difference(date).inDays < 7) {
      return '${DateFormat('EEEE').format(date)} ${formatTime(date)}';
    } else {
      return formatDateTime(date);
    }
  }

  static String formatAppointmentDate(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(localDate.year, localDate.month, localDate.day);

    if (dateOnly == today) {
      return 'Today at ${formatTime(localDate)}';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow at ${formatTime(localDate)}';
    } else if (localDate.difference(now).inDays < 7 && localDate.isAfter(now)) {
      return '${DateFormat('EEEE').format(localDate)} at ${formatTime(localDate)}';
    } else {
      return '${formatDate(localDate)} at ${formatTime(localDate)}';
    }
  }

  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static List<DateTime> getNextSevenDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return List.generate(7, (index) => today.add(Duration(days: index)));
  }

  static List<DateTime> getTimeSlots(String startTime, String endTime, {int intervalMinutes = 30}) {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    final slots = <DateTime>[];
    
    var current = start;
    while (current.isBefore(end)) {
      slots.add(current);
      current = current.add(Duration(minutes: intervalMinutes));
    }
    
    return slots;
  }

  static DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static String formatMedicationFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'once':
        return 'Once daily';
      case 'twice':
        return 'Twice daily';
      case 'thrice':
        return 'Three times daily';
      case 'fourtimes':
        return 'Four times daily';
      case 'asneeded':
        return 'As needed';
      default:
        return frequency;
    }
  }

  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    return dateOnly == today;
  }

  static bool isUpcoming(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  static String getDayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  static String getMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
}