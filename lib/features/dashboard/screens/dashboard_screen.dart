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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final VitalRepository _vitalRepo = VitalRepository();
  final MedicineRepository _medRepo = MedicineRepository();

  VitalModel? _latestVital;
  List<MedicineModel> _medicines = [];
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
    if (mounted) {
      setState(() {
        _latestVital = vital;
        _medicines = meds;
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
                    _buildQuickActions(context),
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

  Widget _buildQuickActions(BuildContext context) {
    final blocks = [
      {
        'label': 'Getting\nStarted',
        'icon': Icons.menu_book_rounded,
        'bgColor': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF2E7D32),
        'onTap': () => context.push('/getting-started'),
      },
      {
        'label': 'AI\nInsights',
        'icon': Icons.auto_awesome_rounded,
        'bgColor': const Color(0xFFF3E5F5),
        'iconColor': const Color(0xFF7B1FA2),
        'onTap': () => context.push('/ai-insights'),
      },
      {
        'label': 'Log\nVital',
        'icon': Icons.favorite_rounded,
        'bgColor': const Color(0xFFE0F2F1),
        'iconColor': const Color(0xFF00796B),
        'onTap': () => context.push('/vitals/add'),
      },
      {
        'label': 'Log\nSymptom',
        'icon': Icons.sick_rounded,
        'bgColor': const Color(0xFFFFF8E1),
        'iconColor': const Color(0xFFF57F17),
        'onTap': () => context.push('/symptoms/add'),
      },
    ];

    return Row(
      children: blocks.map((b) {
        return Expanded(
          child: GestureDetector(
            onTap: b['onTap'] as VoidCallback,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 100,
              decoration: BoxDecoration(
                color: b['bgColor'] as Color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    b['icon'] as IconData,
                    color: b['iconColor'] as Color,
                    size: 26,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    b['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: (b['iconColor'] as Color).withValues(alpha: 0.9),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
