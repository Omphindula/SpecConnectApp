import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/emergency_service.dart';
import '../services/ai_service.dart';
import '../services/data_service.dart';
import '../models/app_models.dart';

class EmergencyWidget extends StatefulWidget {
  final String patientId;
  
  const EmergencyWidget({super.key, required this.patientId});

  @override
  State<EmergencyWidget> createState() => _EmergencyWidgetState();
}

class _EmergencyWidgetState extends State<EmergencyWidget> 
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _pulseController;
  late AnimationController _emergencyController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _emergencyAnimation;
  
  List<EmergencyContact> emergencyContacts = [];
  List<EmergencyLog> emergencyLogs = [];
  bool isLoading = false;
  bool isEmergencyMode = false;
  String? aiResponse;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadEmergencyData();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _emergencyController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _emergencyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _emergencyController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _loadEmergencyData() async {
    setState(() => isLoading = true);
    
    try {
      final contacts = await EmergencyService().getEmergencyContacts();
      final logs = await EmergencyService().getEmergencyLogs();
      
      setState(() {
        emergencyContacts = contacts;
        emergencyLogs = logs.where((log) => log.patientId == widget.patientId).toList();
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load emergency data');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emergencyController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Emergency Assistance',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          // Emergency Button Section
          _buildEmergencyButtonSection(theme),
          
          // Content Section
          Expanded(
            child: isEmergencyMode
                ? _buildEmergencyModeContent(theme)
                : _buildNormalModeContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButtonSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: GestureDetector(
                  onTap: _activateEmergencyMode,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.red.shade600,
                          Colors.red.shade800,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.medical_services,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'EMERGENCY',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap for immediate assistance',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyModeContent(ThemeData theme) {
    return AnimatedBuilder(
      animation: _emergencyAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _emergencyAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade300, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emergency Header
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.red.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Emergency Mode Active',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Emergency Contacts
                Text(
                  'Emergency Contacts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                ...emergencyContacts.take(4).map((contact) =>
                  _buildEmergencyContactCard(contact, theme),
                ),
                
                const SizedBox(height: 20),
                
                // AI Emergency Assistant
                _buildEmergencyAISection(theme),
                
                const SizedBox(height: 20),
                
                // Exit Emergency Mode
                Center(
                  child: TextButton(
                    onPressed: _exitEmergencyMode,
                    child: Text(
                      'Exit Emergency Mode',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNormalModeContent(ThemeData theme) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'Emergency Contacts'),
              Tab(text: 'Emergency History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildEmergencyContactsList(theme),
                _buildEmergencyHistoryList(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: emergencyContacts.length,
      itemBuilder: (context, index) {
        final contact = emergencyContacts[index];
        return _buildContactCard(contact, theme);
      },
    );
  }

  Widget _buildEmergencyHistoryList(ThemeData theme) {
    if (emergencyLogs.isEmpty) {
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
              'No emergency history',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: emergencyLogs.length,
      itemBuilder: (context, index) {
        final log = emergencyLogs[index];
        return _buildEmergencyLogCard(log, theme);
      },
    );
  }

  Widget _buildEmergencyContactCard(EmergencyContact contact, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade700,
          child: Icon(
            _getContactIcon(contact.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          contact.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          contact.number,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.call,
            color: Colors.green.shade600,
          ),
          onPressed: () => _makeEmergencyCall(contact),
        ),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getContactColor(contact.type),
          child: Icon(
            _getContactIcon(contact.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          contact.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.number,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              contact.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.call,
                color: Colors.green.shade600,
              ),
              onPressed: () => _makeEmergencyCall(contact),
            ),
            if (contact.type == EmergencyContactType.personal)
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.red.shade600,
                ),
                onPressed: () => _deleteContact(contact),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyLogCard(EmergencyLog log, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: log.resolved ? Colors.green : Colors.orange,
          child: Icon(
            log.resolved ? Icons.check : Icons.warning,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          log.emergencyType,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              log.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(log.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        trailing: log.resolved
            ? null
            : TextButton(
                onPressed: () => _markEmergencyResolved(log),
                child: Text('Mark Resolved'),
              ),
      ),
    );
  }

  Widget _buildEmergencyAISection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency AI Assistant',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Describe your emergency...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _getEmergencyGuidance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Get Help'),
              ),
            ],
          ),
          
          if (aiResponse != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                aiResponse!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _activateEmergencyMode() {
    setState(() {
      isEmergencyMode = true;
    });
    _emergencyController.forward();
    
    // Vibrate if available
    HapticFeedback.heavyImpact();
  }

  void _exitEmergencyMode() {
    setState(() {
      isEmergencyMode = false;
      aiResponse = null;
    });
    _emergencyController.reverse();
    _messageController.clear();
  }

  Future<void> _makeEmergencyCall(EmergencyContact contact) async {
    try {
      final uri = Uri.parse('tel:${contact.number}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        
        // Log the emergency call
        await EmergencyService().logEmergencyCall(
          widget.patientId,
          contact.name,
          'Emergency call made to ${contact.name}',
        );
        
        _loadEmergencyData(); // Refresh data
      } else {
        _showErrorSnackBar('Cannot make phone call');
      }
    } catch (e) {
      _showErrorSnackBar('Error making emergency call');
    }
  }

  Future<void> _getEmergencyGuidance() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    setState(() => isLoading = true);
    
    try {
      final response = await AIService().processEmergencyRequest(
        message,
      );
      
      setState(() {
        aiResponse = response;
      });
      
      // Log the emergency request
      await EmergencyService().logEmergencyCall(
        widget.patientId,
        'AI Emergency Guidance',
        message,
      );
      
      _loadEmergencyData(); // Refresh data
    } catch (e) {
      _showErrorSnackBar('Error getting emergency guidance');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markEmergencyResolved(EmergencyLog log) async {
    await EmergencyService().markEmergencyResolved(log.id);
    _loadEmergencyData(); // Refresh data
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    await EmergencyService().removeEmergencyContact(contact.id);
    _loadEmergencyData(); // Refresh data
  }

  IconData _getContactIcon(EmergencyContactType type) {
    switch (type) {
      case EmergencyContactType.emergency:
        return Icons.local_police;
      case EmergencyContactType.medical:
        return Icons.medical_services;
      case EmergencyContactType.poison:
        return Icons.warning;
      case EmergencyContactType.hospital:
        return Icons.local_hospital;
      case EmergencyContactType.personal:
        return Icons.person;
    }
  }

  Color _getContactColor(EmergencyContactType type) {
    switch (type) {
      case EmergencyContactType.emergency:
        return Colors.red.shade700;
      case EmergencyContactType.medical:
        return Colors.blue.shade700;
      case EmergencyContactType.poison:
        return Colors.orange.shade700;
      case EmergencyContactType.hospital:
        return Colors.green.shade700;
      case EmergencyContactType.personal:
        return Colors.purple.shade700;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }
}