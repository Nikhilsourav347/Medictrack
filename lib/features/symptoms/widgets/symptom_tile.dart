import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/symptom_model.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/health_utils.dart';

class SymptomTile extends StatelessWidget {
  final SymptomModel symptom;
  final VoidCallback onDelete;

  const SymptomTile({
    super.key,
    required this.symptom,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = HealthUtils.severityColor(symptom.severity);
    final severityLabel = AppConstants.getSeverityLabel(symptom.severity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Severity indicator bar
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symptom.symptomName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined,
                            size: 12, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(
                          AppDateUtils.formatDisplayWithTime(
                              symptom.recordedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Severity badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: severityColor.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '${symptom.severity}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: severityColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    severityLabel,
                    style: TextStyle(
                        fontSize: 9,
                        color: severityColor,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: 18, color: Colors.grey.shade400),
                onSelected: (val) {
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          color: Color(0xFFE53935), size: 18),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: Color(0xFFE53935))),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          if (symptom.notes != null && symptom.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_outlined,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    symptom.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
