import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/symptom_model.dart';
import '../../../data/repositories/symptom_repository.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/health_utils.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class AddSymptomScreen extends StatefulWidget {
  const AddSymptomScreen({super.key});

  @override
  State<AddSymptomScreen> createState() => _AddSymptomScreenState();
}

class _AddSymptomScreenState extends State<AddSymptomScreen> {
  final _formKey = GlobalKey<FormState>();
  final SymptomRepository _repo = SymptomRepository();

  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _severity = 1;
  bool _saving = false;

  // Common symptom suggestions for quick selection
  static const _commonSymptoms = [
    'Headache', 'Fever', 'Fatigue', 'Nausea', 'Dizziness',
    'Chest Pain', 'Shortness of Breath', 'Back Pain', 'Joint Pain',
    'Cough', 'Sore Throat', 'Abdominal Pain', 'Vomiting', 'Diarrhea',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final symptom = SymptomModel(
      symptomName: _nameCtrl.text.trim(),
      severity: _severity,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
      recordedAt: AppDateUtils.nowString(),
    );

    await _repo.insertSymptom(symptom);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  Color get _severityColor => HealthUtils.severityColor(_severity);

  String get _severityLabel => AppConstants.getSeverityLabel(_severity);

  String _getSeverityDescription(int val) {
    if (val <= 2) return "Mild symptom. Barely noticeable, does not interfere with daily activities.";
    if (val <= 4) return "Minor discomfort. Noticeable but easily tolerated and managed.";
    if (val <= 6) return "Moderate symptom. Interferes somewhat with concentration or activities.";
    if (val <= 8) return "Severe discomfort. Significant impact, requires rest and attention.";
    return "Extreme/unbearable symptom. Disrupts all activities. Seek medical evaluation.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: 'Log Symptom', showBack: true),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Intro header
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you feeling?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Log your symptoms to help track patterns or analyze with AI.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Symptom name card
              _card([
                const Text(
                  'Symptom Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Enter Symptom *',
                    hintText: 'e.g. Headache',
                    prefixIcon: const Icon(Icons.sick_outlined, color: Color(0xFF1D9E75)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter a symptom name' : null,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (v) => setState(() {}), // refresh chips highlights
                ),
                const SizedBox(height: 16),
                const Text(
                  'Common suggestions:',
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonSymptoms.map((s) {
                    final isSelected = _nameCtrl.text.trim().toLowerCase() == s.toLowerCase();
                    return ChoiceChip(
                      label: Text(s),
                      selected: isSelected,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF1D9E75),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _nameCtrl.text = s);
                        }
                      },
                      selectedColor: const Color(0xFF1D9E75),
                      backgroundColor: const Color(0xFF1D9E75).withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : const Color(0xFF1D9E75).withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]),

              const SizedBox(height: 16),

              // Severity card
              _card([
                const Text(
                  'Severity Level (1-10)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(10, (index) {
                    final val = index + 1;
                    final isSelected = _severity == val;
                    final color = HealthUtils.severityColor(val);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: () => setState(() => _severity = val),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSelected ? color : color.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? Colors.white : color.withValues(alpha: 0.25),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$val',
                              style: TextStyle(
                                color: isSelected ? Colors.white : color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _severityColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: _severityColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level: $_severity — $_severityLabel',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _severityColor,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _getSeverityDescription(_severity),
                              style: TextStyle(
                                color: _severityColor.withValues(alpha: 0.85),
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // Notes card
              _card([
                const Text(
                  'Additional Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'e.g. Felt dizzy after lunch, duration was 10 mins...',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
                    ),
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ]),

              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D9E75), Color(0xFF10B981)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D9E75).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_outlined, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Save Symptom Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
