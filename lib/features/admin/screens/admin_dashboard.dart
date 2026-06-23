import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/models/symptom_model.dart';
import '../../../data/models/doctor_visit_model.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../../data/repositories/medicine_repository.dart';
import '../../../data/repositories/symptom_repository.dart';
import '../../../data/repositories/doctor_visit_repository.dart';
import '../../../shared/utils/auth_helper.dart';
import '../../../shared/utils/sync_service.dart';
import '../../../shared/widgets/pulse_indicator.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final UserProfileRepository _profileRepo = UserProfileRepository();
  final VitalRepository _vitalRepo = VitalRepository();
  final MedicineRepository _medicineRepo = MedicineRepository();
  final SymptomRepository _symptomRepo = SymptomRepository();
  final DoctorVisitRepository _visitRepo = DoctorVisitRepository();
  final SyncService _syncService = SyncService();

  List<UserProfileModel> _elders = [];
  UserProfileModel? _selectedElder;
  bool _isLoadingElders = true;
  bool _viewingDetails = false;
  Map<String, VitalModel?> _latestVitals = {};

  // Selected Elder Logs
  List<VitalModel> _selectedVitals = [];
  List<MedicineModel> _selectedMedicines = [];
  List<SymptomModel> _selectedSymptoms = [];
  List<DoctorVisitModel> _selectedVisits = [];
  bool _isLoadingLogs = false;

  // Search filter
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Animation controller for details panel
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _syncService.addListener(_onSyncChanged);
    _loadElders();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncChanged);
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) {
      _loadElders();
      if (_selectedElder != null) {
        _loadElderLogs(_selectedElder!.userId!);
      }
    }
  }

  Future<void> _loadElders() async {
    setState(() => _isLoadingElders = true);
    final list = await _profileRepo.getAllProfiles();
    
    // Fetch latest vitals for all profiles
    final Map<String, VitalModel?> vitalsMap = {};
    for (final elder in list) {
      if (elder.userId != null) {
        vitalsMap[elder.userId!] = await _vitalRepo.getLatestVital(userId: elder.userId);
      }
    }
    
    final isMobile = MediaQuery.of(context).size.width <= 750;
    setState(() {
      _elders = list;
      _latestVitals = vitalsMap;
      _isLoadingElders = false;
      // Auto select first elder if nothing selected yet (desktop only)
      if (!isMobile && _elders.isNotEmpty && _selectedElder == null) {
        _selectElder(_elders.first);
      }
    });
  }

  Future<void> _selectElder(UserProfileModel elder) async {
    setState(() {
      _selectedElder = elder;
      _isLoadingLogs = true;
      _viewingDetails = true;
    });
    _animController.reset();
    _animController.forward();
    await _loadElderLogs(elder.userId ?? '');
  }

  Future<void> _loadElderLogs(String email) async {
    if (email.isEmpty) return;
    final vitals = await _vitalRepo.getAllVitals(userId: email);
    final medicines = await _medicineRepo.getAllMedicines(userId: email);
    final symptoms = await _symptomRepo.getAllSymptoms(userId: email);
    final visits = await _visitRepo.getAllVisits(userId: email);

    if (mounted && _selectedElder?.userId == email) {
      setState(() {
        _selectedVitals = vitals;
        _selectedMedicines = medicines;
        _selectedSymptoms = symptoms;
        _selectedVisits = visits;
        _isLoadingLogs = false;
      });
    }
  }

  Color _getAlertColor(VitalModel? vital) {
    if (vital == null) return Colors.green;
    final sys = vital.systolic ?? 120;
    final dia = vital.diastolic ?? 80;
    final glucose = vital.bloodGlucose ?? 100;
    
    if (sys > 140 || dia > 90 || glucose > 150) {
      return const Color(0xFFF43F5E); // Critical Red
    } else if (sys > 130 || dia > 85 || glucose > 130) {
      return const Color(0xFFF59E0B); // Amber warning
    }
    return const Color(0xFF10B981); // Green stable
  }

  String _getAlertStatusText(VitalModel? vital) {
    if (vital == null) return 'No Logs';
    final color = _getAlertColor(vital);
    if (color == const Color(0xFFF43F5E)) return 'CRITICAL';
    if (color == const Color(0xFFF59E0B)) return 'STRESS';
    return 'STABLE';
  }

  Widget _buildSyncStatusPill(bool isMobile) {
    return AnimatedBuilder(
      animation: _syncService,
      builder: (context, _) {
        final isOnline = _syncService.isOnline;
        final statusColor = isOnline ? const Color(0xFF1D9E75) : const Color(0xFFF43F5E);
        
        if (isMobile) {
          return IconButton(
            tooltip: isOnline ? 'Online (Tap to go offline)' : 'Offline (Tap to go online)',
            icon: Icon(
              isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: statusColor,
            ),
            onPressed: () {
              _syncService.toggleConnectivity();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isOnline ? 'Switched to Offline Mode' : 'Switched to Online Mode'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        }
        
        return GestureDetector(
          onTap: () => _syncService.toggleConnectivity(),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor,
                        blurRadius: 6,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSyncLogsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.terminal_rounded, color: Color(0xFF10B981), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Cloud Sync Terminal Logs',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.grey, size: 16),
                        label: const Text('Clear', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        onPressed: () => _syncService.clearLogs(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _syncService,
                    builder: (context, _) {
                      final logs = _syncService.syncLogs;
                      if (logs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No logs yet. Waiting for sync activity...',
                            style: TextStyle(color: Color(0xFF475569), fontFamily: 'monospace'),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              logs[index],
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncStatusBar() {
    return AnimatedBuilder(
      animation: _syncService,
      builder: (context, _) {
        final lastLog = _syncService.syncLogs.isNotEmpty ? _syncService.syncLogs.last : 'System idle. Waiting for logs...';
        return GestureDetector(
          onTap: () => _showSyncLogsSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync_alt_rounded, color: Color(0xFF1D9E75), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lastLog,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Logs',
                  style: TextStyle(
                    color: Color(0xFF1D9E75),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF1D9E75), size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width <= 750;
    final filteredElders = _elders.where((elder) {
      return elder.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (elder.conditions?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    if (isMobile && _viewingDetails && _selectedElder != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () => setState(() => _viewingDetails = false),
          ),
          title: Text(
            _selectedElder!.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          actions: [
            _buildSyncStatusPill(isMobile),
            IconButton(
              icon: const Icon(Icons.sync_rounded, color: Color(0xFF64748B)),
              onPressed: () => _syncService.triggerSync(),
            ),
            IconButton(
              icon: const Icon(Icons.terminal_rounded, color: Color(0xFF64748B)),
              tooltip: 'Sync Logs',
              onPressed: () => _showSyncLogsSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFF43F5E)),
              onPressed: () async {
                await AuthHelper().logout();
              },
            ),
          ],
        ),
        body: _isLoadingLogs
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildElderBioHeader(),
                      const SizedBox(height: 20),
                      _buildVitalsSnapshotRow(),
                      const SizedBox(height: 20),
                      _buildVitalsTrendChart(),
                      const SizedBox(height: 20),
                      _buildMedicationTimeline(),
                      const SizedBox(height: 20),
                      _buildSymptomsAndVisitsPanel(),
                    ],
                  ),
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF1D9E75), size: 24),
            const SizedBox(width: 8),
            Text(
              isMobile ? 'Admin Panel' : 'Admin Central Console',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          _buildSyncStatusPill(isMobile),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF64748B)),
            onPressed: () => _syncService.triggerSync(),
          ),
          IconButton(
            icon: const Icon(Icons.terminal_rounded, color: Color(0xFF64748B)),
            tooltip: 'Sync Logs',
            onPressed: () => _showSyncLogsSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFF43F5E)),
            onPressed: () async {
              await AuthHelper().logout();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: isMobile ? double.infinity : 320,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search elders by name...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Registered Elders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${filteredElders.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoadingElders
                      ? const Center(child: CircularProgressIndicator())
                      : filteredElders.isEmpty
                          ? const Center(child: Text('No elders found'))
                          : ListView.builder(
                              itemCount: filteredElders.length,
                              itemBuilder: (context, index) {
                                final elder = filteredElders[index];
                                final isSelected = _selectedElder?.userId == elder.userId;
                                final latestVital = _latestVitals[elder.userId];
                                final alertColor = _getAlertColor(latestVital);
                                
                                return GestureDetector(
                                  onTap: () => _selectElder(elder),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: isSelected
                                          ? Border.all(color: const Color(0xFF1D9E75).withOpacity(0.3), width: 1.5)
                                          : Border.all(color: Colors.transparent, width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isSelected ? const Color(0xFF1D9E75) : const Color(0xFF64748B).withOpacity(0.1),
                                          child: Text(
                                            elder.name.substring(0, 2).toUpperCase(),
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                elder.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                'Age ${elder.age} • ${elder.bloodGroup}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        alertColor == const Color(0xFF10B981)
                                            ? Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: alertColor,
                                                  border: Border.all(color: Colors.white, width: 1.5),
                                                ),
                                              )
                                            : PulseIndicator(color: alertColor, size: 8),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                _buildSyncStatusBar(),
              ],
            ),
          ),
          if (!isMobile)
            Expanded(
              child: _selectedElder == null
                  ? const Center(child: Text('Select an elder from the list to view vitals details.'))
                  : _isLoadingLogs
                      ? const Center(child: CircularProgressIndicator())
                      : FadeTransition(
                          opacity: _slideAnimation,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildElderBioHeader(),
                                const SizedBox(height: 24),
                                _buildVitalsSnapshotRow(),
                                const SizedBox(height: 24),
                                _buildVitalsTrendChart(),
                                const SizedBox(height: 24),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildMedicationTimeline()),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildSymptomsAndVisitsPanel()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
        ],
      ),
    );
  }

  Widget _buildElderBioHeader() {
    final e = _selectedElder!;
    final alertColor = _selectedVitals.isNotEmpty ? _getAlertColor(_selectedVitals.first) : Colors.green;
    final isMobile = MediaQuery.of(context).size.width <= 750;
    
    final bioInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                e.name,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: alertColor, width: 1),
              ),
              child: Text(
                'HEALTH ${_getAlertStatusText(_selectedVitals.isNotEmpty ? _selectedVitals.first : null)}',
                style: TextStyle(
                  color: alertColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Conditions: ${e.conditions ?? "None"} • Allergies: ${e.allergies ?? "None"}',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );

    final contactCard = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EMERGENCY CONTACT',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            e.emergencyContactName ?? 'None listed',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          Text(
            e.emergencyContactPhone ?? 'None listed',
            style: const TextStyle(fontSize: 12, color: Color(0xFF1D9E75), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bioInfo,
          const SizedBox(height: 16),
          contactCard,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: bioInfo),
        const SizedBox(width: 16),
        contactCard,
      ],
    );
  }

  Widget _buildVitalsSnapshotRow() {
    if (_selectedVitals.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No vitals data recorded yet for this elder.')),
        ),
      );
    }

    final latest = _selectedVitals.first;
    final bpAlert = latest.systolic != null && (latest.systolic! > 140 || latest.diastolic! > 90);
    final glucoseAlert = latest.bloodGlucose != null && latest.bloodGlucose! > 140;
    final oxygenAlert = latest.oxygenSaturation != null && latest.oxygenSaturation! < 95;
    final heartAlert = latest.heartRate != null && (latest.heartRate! > 100 || latest.heartRate! < 60);
    final isMobile = MediaQuery.of(context).size.width <= 750;

    final bpCard = _buildVitalIndicatorCard(
      'Blood Pressure',
      '${latest.systolic?.toInt() ?? 120}/${latest.diastolic?.toInt() ?? 80}',
      'mmHg',
      bpAlert ? Icons.warning_rounded : Icons.check_circle_outline_rounded,
      bpAlert ? const Color(0xFFF43F5E) : const Color(0xFF1D9E75),
      isAlert: bpAlert,
    );
    final glucoseCard = _buildVitalIndicatorCard(
      'Blood Glucose',
      '${latest.bloodGlucose?.toInt() ?? 100}',
      'mg/dL',
      glucoseAlert ? Icons.warning_rounded : Icons.water_drop_outlined,
      glucoseAlert ? const Color(0xFFF43F5E) : const Color(0xFF6366F1),
      isAlert: glucoseAlert,
    );
    final oxygenCard = _buildVitalIndicatorCard(
      'Oxygen Saturation',
      '${latest.oxygenSaturation?.toInt() ?? 98}',
      '% SpO₂',
      oxygenAlert ? Icons.warning_rounded : Icons.bubble_chart_outlined,
      oxygenAlert ? const Color(0xFFF43F5E) : const Color(0xFF0EA5E9),
      isAlert: oxygenAlert,
    );
    final heartCard = _buildVitalIndicatorCard(
      'Heart Rate',
      '${latest.heartRate?.toInt() ?? 72}',
      'bpm',
      heartAlert ? Icons.warning_rounded : Icons.favorite_outline_rounded,
      heartAlert ? const Color(0xFFF43F5E) : const Color(0xFFEC4899),
      isAlert: heartAlert,
    );

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          bpCard,
          glucoseCard,
          oxygenCard,
          heartCard,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: bpCard),
        const SizedBox(width: 16),
        Expanded(child: glucoseCard),
        const SizedBox(width: 16),
        Expanded(child: oxygenCard),
        const SizedBox(width: 16),
        Expanded(child: heartCard),
      ],
    );
  }

  Widget _buildVitalIndicatorCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color, {
    bool isAlert = false,
  }) {
    final isMobile = MediaQuery.of(context).size.width <= 750;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlert ? const Color(0xFFF43F5E).withOpacity(0.5) : const Color(0xFFE2E8F0),
          width: isAlert ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isAlert ? const Color(0xFFF43F5E).withOpacity(0.06) : color.withOpacity(0.04),
            blurRadius: 12,
            spreadRadius: isAlert ? 1 : 0,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 13),
                ),
              ),
              isAlert
                  ? const PulseIndicator(color: Color(0xFFF43F5E), size: 7)
                  : Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsTrendChart() {
    if (_selectedVitals.length < 2) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text('Chart requires at least 2 vitals readings to graph trends.'),
        ),
      );
    }

    final sortedVitals = List<VitalModel>.from(_selectedVitals).reversed.toList();
    final sysSpots = <FlSpot>[];
    final glSpots = <FlSpot>[];

    for (int i = 0; i < sortedVitals.length; i++) {
      final v = sortedVitals[i];
      sysSpots.add(FlSpot(i.toDouble(), v.systolic ?? 120));
      glSpots.add(FlSpot(i.toDouble(), v.bloodGlucose ?? 100));
    }

    final isMobile = MediaQuery.of(context).size.width <= 750;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vitals Trends History',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChartLegendItem('BP Systolic', const Color(0xFFF43F5E)),
                        const SizedBox(width: 16),
                        _buildChartLegendItem('Glucose', const Color(0xFF6366F1)),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vitals Trends History (Systolic BP & Glucose)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15),
                    ),
                    Row(
                      children: [
                        _buildChartLegendItem('BP Systolic', const Color(0xFFF43F5E)),
                        const SizedBox(width: 16),
                        _buildChartLegendItem('Glucose', const Color(0xFF6366F1)),
                      ],
                    ),
                  ],
                ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedBarSpot) => const Color(0xFF0F172A),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        final val = barSpot.y;
                        final isBP = barSpot.barIndex == 0;
                        return LineTooltipItem(
                          '${isBP ? "BP" : "Glucose"}: ${val.toInt()}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: sysSpots,
                    isCurved: true,
                    color: const Color(0xFFF43F5E),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFF43F5E).withOpacity(0.08),
                    ),
                  ),
                  LineChartBarData(
                    spots: glSpots,
                    isCurved: true,
                    color: const Color(0xFF6366F1),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6366F1).withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildMedicationTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prescribed Medications',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15),
              ),
              Icon(Icons.medication_rounded, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 16),
          _selectedMedicines.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No active medicines registered.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedMedicines.length,
                  separatorBuilder: (c, idx) => const Divider(color: Color(0xFFF1F5F9), height: 20),
                  itemBuilder: (context, index) {
                    final med = _selectedMedicines[index];
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                          child: const Icon(Icons.medication_rounded, color: Color(0xFF6366F1), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
                              ),
                              Text(
                                '${med.dosage ?? ""} • ${med.frequency} • Schedule: ${med.times}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: med.isActive ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF64748B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            med.isActive ? 'Active' : 'Stopped',
                            style: TextStyle(
                              color: med.isActive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSymptomsAndVisitsPanel() {
    return Column(
      children: [
        // Symptoms Log Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Symptom Tracker Logs',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15),
              ),
              const SizedBox(height: 12),
              _selectedSymptoms.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('No symptoms logged.')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedSymptoms.length,
                      itemBuilder: (context, index) {
                        final sym = _selectedSymptoms[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sym.symptomName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  if (sym.notes != null)
                                    Text(
                                      sym.notes!,
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                    ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: sym.severity > 5 ? const Color(0xFFF43F5E).withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Sev ${sym.severity}/10',
                                  style: TextStyle(
                                    color: sym.severity > 5 ? const Color(0xFFF43F5E) : const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Appointments Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming Consultations',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15),
              ),
              const SizedBox(height: 12),
              _selectedVisits.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('No follow-up visits listed.')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedVisits.length,
                      itemBuilder: (context, index) {
                        final visit = _selectedVisits[index];
                        final dateStr = visit.visitDate.length > 10 ? visit.visitDate.substring(0, 10) : visit.visitDate;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Color(0xFF1D9E75), size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      visit.doctorName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      'Date: $dateStr • ${visit.diagnosis ?? "Routine Check"}',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
