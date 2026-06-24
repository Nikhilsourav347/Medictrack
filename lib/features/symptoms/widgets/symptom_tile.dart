import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/symptom_model.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/health_utils.dart';

class SymptomTile extends StatefulWidget {
  final SymptomModel symptom;
  final VoidCallback onDelete;

  const SymptomTile({
    super.key,
    required this.symptom,
    required this.onDelete,
  });

  @override
  State<SymptomTile> createState() => _SymptomTileState();
}

class _SymptomTileState extends State<SymptomTile> {
  bool _isExpanded = false;

  Map<String, dynamic>? _aiData;
  bool _isAiAnalysis = false;

  @override
  void initState() {
    super.initState();
    _checkNotes();
  }

  void _checkNotes() {
    final notes = widget.symptom.notes;
    if (notes != null && notes.startsWith('{')) {
      try {
        final decoded = json.decode(notes) as Map<String, dynamic>;
        if (decoded['isAiAnalysis'] == true) {
          _aiData = decoded;
          _isAiAnalysis = true;
        }
      } catch (_) {
        _isAiAnalysis = false;
        _aiData = null;
      }
    } else {
      _isAiAnalysis = false;
      _aiData = null;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'MINOR':
        return const Color(0xFF1D9E75); // Green
      case 'MODERATE':
        return const Color(0xFFFFC107); // Amber
      case 'SERIOUS':
        return const Color(0xFFFF9800); // Orange
      case 'EMERGENCY':
        return const Color(0xFFE53935); // Red
      default:
        return const Color(0xFF1D9E75);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAiAnalysis && _aiData != null) {
      return _buildAiTile();
    }
    return _buildStandardTile();
  }

  // --- AI ANALYSIS TILE BUILDER ---

  Widget _buildAiTile() {
    final data = _aiData!;
    final severity = data['severity'] as String? ?? 'MINOR';
    final severityColor = _getSeverityColor(severity);
    final recordedAt = widget.symptom.recordedAt;
    final assessment = data['assessment'] as String? ?? 'No assessment details available.';
    final advice = List<String>.from(data['advice'] ?? []);
    final medicines = List<String>.from(data['medicines'] ?? []);
    final watchFor = List<String>.from(data['watch_for'] ?? []);
    final imagePath = data['imagePath'] as String?;
    final File? imageFile = (imagePath != null && imagePath.isNotEmpty) ? File(imagePath) : null;
    final hasImage = imageFile != null && imageFile.existsSync();
    final inputText = data['inputText'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: severity == 'EMERGENCY' ? AppTheme.criticalRed.withValues(alpha: 0.4) : Colors.grey.shade100,
          width: severity == 'EMERGENCY' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: severity == 'EMERGENCY' 
                ? AppTheme.criticalRed.withValues(alpha: 0.04) 
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Avatar Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  severity == 'EMERGENCY' ? Icons.warning_rounded : Icons.auto_awesome,
                  color: severityColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AI Analysis',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: severityColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            severity,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: severityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined, size: 12, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(
                          AppDateUtils.formatDisplayWithTime(recordedAt),
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

              // Options Menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
                onSelected: (val) {
                  if (val == 'delete') widget.onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Color(0xFFE53935))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Short assessment preview
          Text(
            assessment,
            maxLines: _isExpanded ? null : 2,
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Collapsible detail view
          if (_isExpanded) ...[
            const Divider(height: 20),

            // Patient inputs text description
            if (inputText.isNotEmpty) ...[
              const Text(
                'PATIENT DESCRIPTION',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                inputText,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 12),
            ],

            // Photo Preview if exists
            if (hasImage) ...[
              const Text(
                'PHYSICAL SYMPTOM IMAGE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Advice
            if (advice.isNotEmpty) ...[
              const Text(
                'FIRST-AID RECOMMENDATIONS',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              ...advice.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF1D9E75), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],

            // Medicines
            if (medicines.isNotEmpty) ...[
              const Text(
                'SUGGESTED HOME CARE / OTC SOLUTIONS',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              ...medicines.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.healing_outlined, color: Color(0xFF6366F1), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],

            // Watch For
            if (watchFor.isNotEmpty) ...[
              const Text(
                'RED-FLAGS TO WATCH FOR',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              ...watchFor.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF9800), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3)),
                        ),
                      ],
                    ),
                  )),
            ],
          ],

          // Expand / Collapse Trigger Button
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Show Less' : 'View Full Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: severityColor,
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

  // --- STANDARD TILE BUILDER (Backward compatible) ---

  Widget _buildStandardTile() {
    final severityColor = HealthUtils.severityColor(widget.symptom.severity);
    final severityLabel = AppConstants.getSeverityLabel(widget.symptom.severity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                      widget.symptom.symptomName,
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
                              widget.symptom.recordedAt),
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
                      color: severityColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: severityColor.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.symptom.severity}',
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
                          style: TextStyle(color: Color(0xFFE53935))),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          if (widget.symptom.notes != null && widget.symptom.notes!.isNotEmpty) ...[
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
                    widget.symptom.notes!,
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
