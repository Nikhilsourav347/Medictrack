import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../../data/repositories/medicine_repository.dart';
import '../../../data/models/medicine_model.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/health_utils.dart';
import '../../../shared/utils/auth_helper.dart';
import '../../../shared/utils/sync_service.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final VitalRepository _vitalRepo = VitalRepository();
  final MedicineRepository _medRepo = MedicineRepository();

  final GlobalKey _weeklyTrendsKey = GlobalKey();

  VitalModel? _latestVital;
  List<MedicineModel> _medicines = [];
  List<VitalModel> _recentVitals = [];
  String _activeChartMetric = 'BP';
  String _userName = 'Guest';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SyncService().addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    SyncService().removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final vital = await _vitalRepo.getLatestVital();
    final meds = await _medRepo.getActiveMedicines();
    final profile = await AuthHelper().getCurrentProfile();
    final recent = (await _vitalRepo.getRecentVitals(7)).reversed.toList();
    if (mounted) {
      setState(() {
        _latestVital = vital;
        _medicines = meds;
        _recentVitals = recent;
        _userName = profile?.name ?? 'Guest';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'MediTrack',
        actions: [
          // Connected simulated state pill
          AnimatedBuilder(
            animation: SyncService(),
            builder: (context, _) {
              return FutureBuilder<int>(
                future: SyncService().getPendingSyncCount(),
                builder: (context, snapshot) {
                  final pendingCount = snapshot.data ?? 0;
                  final isOnline = SyncService().isOnline;
                  return GestureDetector(
                    onTap: () => SyncService().toggleConnectivity(),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF1D9E75).withValues(alpha: 0.1)
                            : const Color(0xFFF43F5E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOnline ? const Color(0xFF1D9E75) : const Color(0xFFF43F5E),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? const Color(0xFF1D9E75) : const Color(0xFFF43F5E),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline
                                ? 'ONLINE'
                                : 'OFFLINE${pendingCount > 0 ? " ($pendingCount)" : ""}',
                            style: TextStyle(
                              color: isOnline ? const Color(0xFF1D9E75) : const Color(0xFFF43F5E),
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.local_hospital_rounded,
                color: Color(0xFFE53935)),
            tooltip: 'Emergency',
            onPressed: () => context.push('/emergency'),
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator(message: 'Loading health data...')
          : RefreshIndicator(
              color: const Color(0xFF1D9E75),
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 20),
                    _buildGridActions(context),
                    const SizedBox(height: 20),
                    _buildWeeklyTrendsSection(),
                    const SizedBox(height: 20),
                    const Text(
                      'Latest Vitals',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildVitalsSummary(),
                    const SizedBox(height: 20),
                    const Text(
                      'Active Medicines',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildMedicinesList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/ai-assistant'),
        backgroundColor: const Color(0xFF1D9E75),
        child: const Icon(Icons.mic, color: Colors.white),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1), // Indigo
            Color(0xFF4F46E5), // Indigo dark
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 15,
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
              Text(
                '$greeting,',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await AuthHelper().logout();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 11,
                ),
                const SizedBox(width: 6),
                Text(
                  AppDateUtils.formatDisplay(AppDateUtils.todayString()),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridActions(BuildContext context) {
    final actions = [
      {
        'label': 'Medicines',
        'icon': Icons.medication,
        'color': const Color(0xFFEF6C00),
        'bgColor': const Color(0xFFFFF3E0),
        'onTap': () => context.go('/medicines'),
      },
      {
        'label': 'Symptoms',
        'icon': Icons.sick_outlined,
        'color': const Color(0xFF8E24AA),
        'bgColor': const Color(0xFFF3E5F5),
        'onTap': () => context.push('/symptoms'),
      },
      {
        'label': 'Doctor Visits',
        'icon': Icons.local_hospital,
        'color': const Color(0xFF00796B),
        'bgColor': const Color(0xFFE0F2F1),
        'onTap': () => context.push('/visits'),
      },
      {
        'label': 'Prescriptions',
        'icon': Icons.description,
        'color': const Color(0xFF5D4037),
        'bgColor': const Color(0xFFEFEBE9),
        'onTap': () => context.push('/prescriptions'),
      },
      {
        'label': 'Weekly Charts',
        'icon': Icons.bar_chart,
        'color': const Color(0xFF3F51B5),
        'bgColor': const Color(0xFFE8EAF6),
        'onTap': () {
          final targetContext = _weeklyTrendsKey.currentContext;
          if (targetContext != null) {
            Scrollable.ensureVisible(
              targetContext,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        },
      },
      {
        'label': 'PDF Report',
        'icon': Icons.picture_as_pdf,
        'color': const Color(0xFF455A64),
        'bgColor': const Color(0xFFECEFF1),
        'onTap': () => context.go('/reports'),
      },
      {
        'label': 'Emergency SOS',
        'icon': Icons.emergency,
        'color': const Color(0xFFC62828),
        'bgColor': const Color(0xFFFFEBEE),
        'onTap': () => context.push('/emergency'),
      },
      {
        'label': 'AI Insights',
        'icon': Icons.auto_awesome,
        'color': const Color(0xFF6D28D9),
        'bgColor': const Color(0xFFF5F3FF),
        'onTap': () => context.push('/ai-insights'),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final act = actions[index];
        return GestureDetector(
          onTap: act['onTap'] as VoidCallback,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: act['bgColor'] as Color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    act['icon'] as IconData,
                    color: act['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  act['label'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVitalsSummary() {
    if (_latestVital == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.monitor_heart_outlined,
                size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('No vitals recorded yet',
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => context.push('/vitals/add'),
              child: const Text('Add your first vital'),
            )
          ],
        ),
      );
    }
    final v = _latestVital!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            'Recorded ${AppDateUtils.relativeDate(v.recordedAt)}',
            style:
                TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.go('/vitals'),
            child: const Text('View all',
                style: TextStyle(
                    color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.15,
          children: [
            if (v.systolic != null && v.diastolic != null)
              _VitalSummaryCard(
                label: 'Blood Pressure',
                value: '${v.systolic!.toInt()}/${v.diastolic!.toInt()}',
                unit: 'mmHg',
                icon: Icons.favorite_rounded,
                gradient: const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                textColor: const Color(0xFFF43F5E),
                status: HealthUtils.bloodPressureStatus(v.systolic!, v.diastolic!),
              ),
            if (v.heartRate != null)
              _VitalSummaryCard(
                label: 'Heart Rate',
                value: v.heartRate!.toInt().toString(),
                unit: 'bpm',
                icon: Icons.monitor_heart_rounded,
                gradient: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                textColor: const Color(0xFFEA580C),
                status: HealthUtils.heartRateStatus(v.heartRate!),
              ),
            if (v.oxygenSaturation != null)
              _VitalSummaryCard(
                label: 'Oxygen SpO₂',
                value: '${v.oxygenSaturation!.toInt()}',
                unit: '%',
                icon: Icons.water_drop_rounded,
                gradient: const [Color(0xFFECFEFF), Color(0xFFCFFAFE)],
                textColor: const Color(0xFF0891B2),
                status: HealthUtils.oxygenStatus(v.oxygenSaturation!),
              ),
            if (v.temperature != null)
              _VitalSummaryCard(
                label: 'Body Temp',
                value: v.temperature!.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_rounded,
                gradient: const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                textColor: const Color(0xFF9333EA),
                status: HealthUtils.temperatureStatus(v.temperature!),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicinesList() {
    if (_medicines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(children: [
          Icon(Icons.medication_outlined,
              size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text('No active medicines',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => context.push('/medicines/add'),
            child: const Text('Add a medicine'),
          )
        ]),
      );
    }
    return Column(
      children: _medicines
          .take(3)
          .map((m) => _MiniMedCard(medicine: m))
          .toList(),
    );
  }

  String _getShortDate(String recordedAt) {
    try {
      final dateTime = DateTime.parse(recordedAt);
      return '${dateTime.day}/${dateTime.month}';
    } catch (e) {
      return '';
    }
  }

  double _getMinY() {
    double base = 50;
    if (_activeChartMetric == 'HR') base = 40;
    if (_activeChartMetric == 'SpO2') base = 80;
    if (_activeChartMetric == 'Glucose') base = 50;

    for (var v in _recentVitals) {
      double? val;
      if (_activeChartMetric == 'BP') val = v.diastolic;
      if (_activeChartMetric == 'HR') val = v.heartRate;
      if (_activeChartMetric == 'SpO2') val = v.oxygenSaturation;
      if (_activeChartMetric == 'Glucose') val = v.bloodGlucose;
      if (val != null && val < base) {
        base = (val - 10).clamp(0.0, double.infinity);
      }
    }
    return base;
  }

  double _getMaxY() {
    double base = 180;
    if (_activeChartMetric == 'HR') base = 130;
    if (_activeChartMetric == 'SpO2') base = 100;
    if (_activeChartMetric == 'Glucose') base = 250;

    for (var v in _recentVitals) {
      double? val;
      if (_activeChartMetric == 'BP') val = v.systolic;
      if (_activeChartMetric == 'HR') val = v.heartRate;
      if (_activeChartMetric == 'SpO2') val = v.oxygenSaturation;
      if (_activeChartMetric == 'Glucose') val = v.bloodGlucose;
      if (val != null && val > base) {
        base = val + 10;
      }
    }
    return base;
  }

  double _getGridInterval() {
    if (_activeChartMetric == 'BP') return 30;
    if (_activeChartMetric == 'HR') return 20;
    if (_activeChartMetric == 'SpO2') return 5;
    if (_activeChartMetric == 'Glucose') return 50;
    return 20;
  }

  Widget _buildWeeklyTrendsSection() {
    return Container(
      key: _weeklyTrendsKey,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_rounded, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Charts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Interactive trend visualization',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricTabs(),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _recentVitals.isEmpty 
                ? _buildGraphEmptyState("No vitals recorded yet. Log your vitals to see trends.")
                : _buildLineChart(),
          ),
          if (_recentVitals.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildChartInsights(),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTabs() {
    final metrics = [
      {'key': 'BP', 'label': 'Blood Pressure'},
      {'key': 'HR', 'label': 'Heart Rate'},
      {'key': 'SpO2', 'label': 'Oxygen (SpO₂)'},
      {'key': 'Glucose', 'label': 'Blood Glucose'},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: metrics.map((m) {
          final isSelected = _activeChartMetric == m['key'];
          return GestureDetector(
            onTap: () => setState(() => _activeChartMetric = m['key']!),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF6366F1) 
                    : const Color(0xFF6366F1).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.transparent : const Color(0xFF6366F1).withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                m['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6366F1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart() {
    final systolicPoints = <FlSpot>[];
    final diastolicPoints = <FlSpot>[];
    final hrPoints = <FlSpot>[];
    final spo2Points = <FlSpot>[];
    final glucosePoints = <FlSpot>[];

    for (int i = 0; i < _recentVitals.length; i++) {
      final v = _recentVitals[i];
      if (v.systolic != null) systolicPoints.add(FlSpot(i.toDouble(), v.systolic!));
      if (v.diastolic != null) diastolicPoints.add(FlSpot(i.toDouble(), v.diastolic!));
      if (v.heartRate != null) hrPoints.add(FlSpot(i.toDouble(), v.heartRate!));
      if (v.oxygenSaturation != null) spo2Points.add(FlSpot(i.toDouble(), v.oxygenSaturation!));
      if (v.bloodGlucose != null) glucosePoints.add(FlSpot(i.toDouble(), v.bloodGlucose!));
    }

    List<LineChartBarData> bars = [];
    Color primaryColor = const Color(0xFF6366F1);

    if (_activeChartMetric == 'BP') {
      if (systolicPoints.isEmpty && diastolicPoints.isEmpty) {
        return _buildGraphEmptyState("No Blood Pressure readings available.");
      }
      primaryColor = const Color(0xFFF43F5E);
      bars = [
        LineChartBarData(
          spots: systolicPoints,
          isCurved: true,
          barWidth: 3,
          color: const Color(0xFFF43F5E),
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [const Color(0xFFF43F5E).withValues(alpha: 0.15), const Color(0xFFF43F5E).withValues(alpha: 0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        LineChartBarData(
          spots: diastolicPoints,
          isCurved: true,
          barWidth: 3,
          color: const Color(0xFF3B82F6),
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [const Color(0xFF3B82F6).withValues(alpha: 0.15), const Color(0xFF3B82F6).withValues(alpha: 0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ];
    } else if (_activeChartMetric == 'HR') {
      if (hrPoints.isEmpty) return _buildGraphEmptyState("No Heart Rate readings available.");
      primaryColor = const Color(0xFFEA580C);
      bars = [
        LineChartBarData(
          spots: hrPoints,
          isCurved: true,
          barWidth: 3,
          color: primaryColor,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [primaryColor.withValues(alpha: 0.15), primaryColor.withValues(alpha: 0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ];
    } else if (_activeChartMetric == 'SpO2') {
      if (spo2Points.isEmpty) return _buildGraphEmptyState("No Oxygen Saturation readings available.");
      primaryColor = const Color(0xFF06B6D4);
      bars = [
        LineChartBarData(
          spots: spo2Points,
          isCurved: true,
          barWidth: 3,
          color: primaryColor,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [primaryColor.withValues(alpha: 0.15), primaryColor.withValues(alpha: 0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ];
    } else if (_activeChartMetric == 'Glucose') {
      if (glucosePoints.isEmpty) return _buildGraphEmptyState("No Blood Glucose readings available.");
      primaryColor = const Color(0xFF0D9488);
      bars = [
        LineChartBarData(
          spots: glucosePoints,
          isCurved: true,
          barWidth: 3,
          color: primaryColor,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [primaryColor.withValues(alpha: 0.15), primaryColor.withValues(alpha: 0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 10),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (_recentVitals.length - 1).toDouble(),
          minY: _getMinY(),
          maxY: _getMaxY(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getGridInterval(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.1),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF1E293B).withValues(alpha: 0.95),
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final label = _activeChartMetric == 'BP' 
                      ? (spot.barIndex == 0 ? 'Systolic' : 'Diastolic')
                      : _activeChartMetric;
                  return LineTooltipItem(
                    '$label: ${spot.y.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: _getGridInterval(),
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _recentVitals.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        _getShortDate(_recentVitals[index].recordedAt),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          lineBarsData: bars,
        ),
      ),
    );
  }

  Widget _buildGraphEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart_rounded, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartInsights() {
    String insightText = "";
    Color insightColor = const Color(0xFF475569);

    if (_activeChartMetric == 'BP') {
      final validBP = _recentVitals.where((v) => v.systolic != null && v.diastolic != null).toList();
      if (validBP.isNotEmpty) {
        final avgSys = validBP.map((v) => v.systolic!).reduce((a, b) => a + b) / validBP.length;
        final avgDia = validBP.map((v) => v.diastolic!).reduce((a, b) => a + b) / validBP.length;
        final status = HealthUtils.bloodPressureStatus(avgSys, avgDia);
        insightColor = HealthUtils.statusColor(status);
        insightText = "Avg BP: ${avgSys.toInt()}/${avgDia.toInt()} mmHg (${status.name.toUpperCase()})";
      } else {
        insightText = "No blood pressure records for analysis.";
      }
    } else if (_activeChartMetric == 'HR') {
      final validHR = _recentVitals.where((v) => v.heartRate != null).toList();
      if (validHR.isNotEmpty) {
        final avgHR = validHR.map((v) => v.heartRate!).reduce((a, b) => a + b) / validHR.length;
        final status = HealthUtils.heartRateStatus(avgHR);
        insightColor = HealthUtils.statusColor(status);
        insightText = "Avg Heart Rate: ${avgHR.toInt()} bpm (${status.name.toUpperCase()})";
      } else {
        insightText = "No heart rate records for analysis.";
      }
    } else if (_activeChartMetric == 'SpO2') {
      final validSpO2 = _recentVitals.where((v) => v.oxygenSaturation != null).toList();
      if (validSpO2.isNotEmpty) {
        final avgSpO2 = validSpO2.map((v) => v.oxygenSaturation!).reduce((a, b) => a + b) / validSpO2.length;
        final status = HealthUtils.oxygenStatus(avgSpO2);
        insightColor = HealthUtils.statusColor(status);
        insightText = "Avg SpO₂: ${avgSpO2.toInt()}% (${status.name.toUpperCase()})";
      } else {
        insightText = "No SpO₂ records for analysis.";
      }
    } else if (_activeChartMetric == 'Glucose') {
      final validGlucose = _recentVitals.where((v) => v.bloodGlucose != null).toList();
      if (validGlucose.isNotEmpty) {
        final avgGlucose = validGlucose.map((v) => v.bloodGlucose!).reduce((a, b) => a + b) / validGlucose.length;
        final status = HealthUtils.glucoseStatus(avgGlucose);
        insightColor = HealthUtils.statusColor(status);
        insightText = "Avg Blood Glucose: ${avgGlucose.toInt()} mg/dL (${status.name.toUpperCase()})";
      } else {
        insightText = "No blood glucose records for analysis.";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Data Analysis',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: insightColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: insightColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: insightColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insightText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: insightColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _VitalSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final List<Color> gradient;
  final Color textColor;
  final VitalStatus status;

  const _VitalSummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.gradient,
    required this.textColor,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = HealthUtils.statusColor(status);
    final statusLabel = status.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: textColor, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMedCard extends StatelessWidget {
  final MedicineModel medicine;
  const _MiniMedCard({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final times = medicine.times.split(',');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.medication,
                color: theme.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  '${medicine.frequency}  •  ${times.join(', ')}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
