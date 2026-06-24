import 'package:flutter/material.dart';
import '../../../data/models/doctor_visit_model.dart';
import '../../../shared/utils/date_utils.dart';

class VisitCard extends StatefulWidget {
  final DoctorVisitModel visit;
  final VoidCallback onDelete;

  const VisitCard({
    super.key,
    required this.visit,
    required this.onDelete,
  });

  @override
  State<VisitCard> createState() => _VisitCardState();
}

class _VisitCardState extends State<VisitCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final hasFollowUp = visit.followUpDate != null &&
        visit.followUpDate!.isNotEmpty;
    final followUpSoon = hasFollowUp && _isFollowUpSoon(visit.followUpDate!);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_hospital_rounded,
                        color: Color(0xFF1D9E75), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.doctorName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.formatDisplay(visit.visitDate),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ]),
                        if (visit.diagnosis != null &&
                            visit.diagnosis!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.medical_information_outlined,
                                size: 12, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                visit.diagnosis!,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF6B7280)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            size: 18, color: Colors.grey.shade400),
                        onSelected: (val) {
                          if (val == 'delete') widget.onDelete();
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  color: Color(0xFFE53935), size: 18),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style:
                                      TextStyle(color: Color(0xFFE53935))),
                            ]),
                          ),
                        ],
                      ),
                      if (hasFollowUp)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: followUpSoon
                                ? const Color(0xFFFFC107).withValues(alpha: 0.15)
                                : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Follow-up',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: followUpSoon
                                  ? const Color(0xFFFFC107)
                                  : Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (_expanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (visit.diagnosis != null &&
                      visit.diagnosis!.isNotEmpty)
                    _detailRow(
                      icon: Icons.medical_information_outlined,
                      label: 'Diagnosis',
                      value: visit.diagnosis!,
                    ),
                  if (visit.prescription != null &&
                      visit.prescription!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _detailRow(
                      icon: Icons.medication_outlined,
                      label: 'Prescription',
                      value: visit.prescription!,
                    ),
                  ],
                  if (hasFollowUp) ...[
                    const SizedBox(height: 8),
                    _detailRow(
                      icon: Icons.event_outlined,
                      label: 'Follow-up',
                      value: AppDateUtils.formatDisplay(visit.followUpDate),
                      valueColor: followUpSoon
                          ? const Color(0xFFFFC107)
                          : null,
                    ),
                  ],
                  if (visit.notes != null &&
                      visit.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _detailRow(
                      icon: Icons.notes_outlined,
                      label: 'Notes',
                      value: visit.notes!,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Expand/collapse handle
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            SizedBox(
              width: 260,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? const Color(0xFF1A1A2E),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isFollowUpSoon(String dateStr) {
    final dt = AppDateUtils.parseDate(dateStr);
    if (dt == null) return false;
    final diff = dt.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }
}
