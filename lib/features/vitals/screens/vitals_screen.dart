import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/health_utils.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  final VitalRepository _repo = VitalRepository();
  List<VitalModel> _vitals = [];
  bool _loading = true;

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
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vitals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _VitalHistoryTile(
                      vital: _vitals[index],
                      onDelete: () => _deleteVital(_vitals[index].id!),
                    ),
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
