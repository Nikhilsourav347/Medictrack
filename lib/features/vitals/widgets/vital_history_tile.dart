import 'package:flutter/material.dart';
import '../../../data/models/vital_model.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/health_utils.dart';

class VitalHistoryTile extends StatelessWidget {
  final VitalModel vital;
  final VoidCallback onDelete;

  const VitalHistoryTile({
    super.key,
    required this.vital,
    required this.onDelete,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'borderline':
        return const Color(0xFFF59E0B);
      case 'critical':
        return const Color(0xFFF43F5E);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    String bpStatus = '';
    if (vital.systolic != null && vital.diastolic != null) {
      bpStatus = HealthUtils.bpStatus(vital.systolic!, vital.diastolic!);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                AppDateUtils.formatDisplayWithTime(vital.recordedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: Colors.grey.shade400),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (vital.systolic != null)
                _VitalChip(
                  label: 'BP',
                  value: '${vital.systolic}/${vital.diastolic}',
                  unit: 'mmHg',
                  color: _statusColor(bpStatus),
                ),
              if (vital.bloodSugar != null)
                _VitalChip(
                  label:
                      vital.sugarType == 'fasting' ? 'Sugar (F)' : 'Sugar (PP)',
                  value: vital.bloodSugar!.toStringAsFixed(1),
                  unit: 'mg/dL',
                  color: _statusColor(
                    HealthUtils.sugarStatus(
                        vital.bloodSugar!, vital.sugarType ?? 'fasting'),
                  ),
                ),
              if (vital.temperature != null)
                _VitalChip(
                  label: 'Temp',
                  value: vital.temperature!.toStringAsFixed(1),
                  unit: '°C',
                  color:
                      _statusColor(HealthUtils.tempStatus(vital.temperature!)),
                ),
              if (vital.weight != null)
                _VitalChip(
                  label: 'Weight',
                  value: vital.weight!.toStringAsFixed(1),
                  unit: 'kg',
                  color: Colors.grey.shade600,
                ),
              if (vital.spo2 != null)
                _VitalChip(
                  label: 'SpO2',
                  value: '${vital.spo2}',
                  unit: '%',
                  color: _statusColor(HealthUtils.spo2Status(vital.spo2!)),
                ),
            ],
          ),
          if (vital.notes != null && vital.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              vital.notes!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _VitalChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 9,
                  color: color.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
