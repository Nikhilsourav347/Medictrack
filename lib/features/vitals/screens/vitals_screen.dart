import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/health_utils.dart';
import 'package:fl_chart/fl_chart.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  final VitalRepository _repo = VitalRepository();
  List<VitalModel> _vitals = [];
  bool _loading = true;
  String _activeChartMetric = 'BP';

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  Future<void> _loadVitals() async {
    setState(() => _loading = true);
    final data = await _repo.getAllVitals();
    if (mounted) setState(() { _vitals = data; _loading = false; });
  }

  Future<void> _deleteVital(int id) async {
    await _repo.deleteVital(id);
    _loadVitals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Vitals',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await context.push('/vitals/add');
              _loadVitals();
            },
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _vitals.isEmpty
              ? EmptyStateWidget(
                  title: 'No vitals recorded',
                  subtitle: 'Start tracking your blood pressure, heart rate and more.',
                  icon: Icons.monitor_heart_outlined,
                  actionLabel: 'Record Vital',
                  onAction: () async {
                    await context.push('/vitals/add');
                    _loadVitals();
                  },
                )
              : RefreshIndicator(
                  color: const Color(0xFF1D9E75),
                  onRefresh: _loadVitals,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildWeeklyTrendsSection(),
                      const SizedBox(height: 20),
                      const Text(
                        'History Log',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_vitals.length, (index) {
                        final v = _vitals[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _VitalHistoryTile(
                            vital: v,
                            onDelete: () => _deleteVital(v.id!),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/vitals/add');
          _loadVitals();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<VitalModel> get _recentVitals => _vitals.take(7).toList().reversed.toList();

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

class _VitalHistoryTile extends StatelessWidget {
  final VitalModel vital;
  final VoidCallback onDelete;

  const _VitalHistoryTile({required this.vital, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.access_time_outlined, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text(
              AppDateUtils.formatDisplayWithTime(vital.recordedAt),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE53935)),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: onDelete,
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (vital.systolic != null && vital.diastolic != null)
                _chip('BP', '${vital.systolic!.toInt()}/${vital.diastolic!.toInt()} mmHg',
                    HealthUtils.bloodPressureStatus(vital.systolic!, vital.diastolic!)),
              if (vital.heartRate != null)
                _chip('HR', '${vital.heartRate!.toInt()} bpm', HealthUtils.heartRateStatus(vital.heartRate!)),
              if (vital.oxygenSaturation != null)
                _chip('SpO₂', '${vital.oxygenSaturation!.toInt()}%', HealthUtils.oxygenStatus(vital.oxygenSaturation!)),
              if (vital.temperature != null)
                _chip('Temp', '${vital.temperature!.toStringAsFixed(1)}°C', HealthUtils.temperatureStatus(vital.temperature!)),
              if (vital.bloodGlucose != null)
                _chip('Glucose', '${vital.bloodGlucose!.toInt()} mg/dL', HealthUtils.glucoseStatus(vital.bloodGlucose!)),
              if (vital.weight != null)
                _chip('Weight', '${vital.weight!.toStringAsFixed(1)} kg', VitalStatus.normal),
            ],
          ),
          if (vital.notes != null && vital.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(vital.notes!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, String value, VitalStatus status) {
    final color = HealthUtils.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
