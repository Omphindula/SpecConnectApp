import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import 'data_service.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  static const String _emergencyContactsKey = 'emergency_contacts';
  static const String _emergencyLogsKey = 'emergency_logs';

  Future<void> logEmergencyCall(String patientId, String emergencyType, String description) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getEmergencyLogs();
    
    final newLog = EmergencyLog(
      id: DataService.instance.generateId(),
      patientId: patientId,
      emergencyType: emergencyType,
      description: description,
      timestamp: DateTime.now(),
      resolved: false,
    );
    
    logs.add(newLog);
    
    final logsJson = logs.map((log) => log.toJson()).toList();
    await prefs.setString(_emergencyLogsKey, jsonEncode(logsJson));
  }

  Future<List<EmergencyLog>> getEmergencyLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getString(_emergencyLogsKey);
    
    if (logsJson != null) {
      final List<dynamic> decoded = jsonDecode(logsJson);
      return decoded.map((json) => EmergencyLog.fromJson(json)).toList();
    }
    
    return [];
  }

  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString(_emergencyContactsKey);
    
    if (contactsJson != null) {
      final List<dynamic> decoded = jsonDecode(contactsJson);
      return decoded.map((json) => EmergencyContact.fromJson(json)).toList();
    }
    
    return _getDefaultEmergencyContacts();
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = await getEmergencyContacts();
    
    contacts.add(contact);
    
    final contactsJson = contacts.map((contact) => contact.toJson()).toList();
    await prefs.setString(_emergencyContactsKey, jsonEncode(contactsJson));
  }

  Future<void> removeEmergencyContact(String contactId) async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = await getEmergencyContacts();
    
    contacts.removeWhere((contact) => contact.id == contactId);
    
    final contactsJson = contacts.map((contact) => contact.toJson()).toList();
    await prefs.setString(_emergencyContactsKey, jsonEncode(contactsJson));
  }

  List<EmergencyContact> _getDefaultEmergencyContacts() {
    return [
      EmergencyContact(
        id: '1',
        name: 'Emergency Services',
        number: '10111',
        type: EmergencyContactType.emergency,
        description: 'National emergency number',
      ),
      EmergencyContact(
        id: '2',
        name: 'Medical Emergency',
        number: '112',
        type: EmergencyContactType.medical,
        description: 'Mobile emergency number',
      ),
      EmergencyContact(
        id: '3',
        name: 'Poison Control',
        number: '0861555777',
        type: EmergencyContactType.poison,
        description: 'Poison information centre',
      ),
      EmergencyContact(
        id: '4',
        name: 'UMP Health Center',
        number: '0134000000',
        type: EmergencyContactType.hospital,
        description: 'University of Mpumalanga Health Center',
      ),
    ];
  }

  Future<void> markEmergencyResolved(String logId) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getEmergencyLogs();
    
    for (var log in logs) {
      if (log.id == logId) {
        log.resolved = true;
        break;
      }
    }
    
    final logsJson = logs.map((log) => log.toJson()).toList();
    await prefs.setString(_emergencyLogsKey, jsonEncode(logsJson));
  }
}

class EmergencyLog {
  final String id;
  final String patientId;
  final String emergencyType;
  final String description;
  final DateTime timestamp;
  bool resolved;

  EmergencyLog({
    required this.id,
    required this.patientId,
    required this.emergencyType,
    required this.description,
    required this.timestamp,
    required this.resolved,
  });

  factory EmergencyLog.fromJson(Map<String, dynamic> json) {
    return EmergencyLog(
      id: json['id'],
      patientId: json['patientId'],
      emergencyType: json['emergencyType'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      resolved: json['resolved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'emergencyType': emergencyType,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'resolved': resolved,
    };
  }
}

enum EmergencyContactType { emergency, medical, poison, hospital, personal }

class EmergencyContact {
  final String id;
  final String name;
  final String number;
  final EmergencyContactType type;
  final String description;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.number,
    required this.type,
    required this.description,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      number: json['number'],
      type: EmergencyContactType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => EmergencyContactType.personal,
      ),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'type': type.toString(),
      'description': description,
    };
  }
}