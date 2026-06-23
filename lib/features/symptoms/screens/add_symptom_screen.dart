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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'Log Symptom', showBack: true),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Symptom name card
              _card([
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Symptom Name *',
                    hintText: 'e.g. Headache',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sick_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter a symptom name' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Common symptoms:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _commonSymptoms.map((s) {
                    return ActionChip(
                      label: Text(s,
                          style: const TextStyle(fontSize: 11)),
                      onPressed: () => setState(() => _nameCtrl.text = s),
                      backgroundColor:
                          const Color(0xFF1D9E75).withOpacity(0.07),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: const Color(0xFF1D9E75).withOpacity(0.2)),
                      ),
                    );
                  }).toList(),
                ),
              ]),

              const SizedBox(height: 12),

              // Severity card
              _card([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Severity Level',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _severityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _severityColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_severity',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _severityColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '— $_severityLabel',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _severityColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _severityColor,
                    thumbColor: _severityColor,
                    inactiveTrackColor: _severityColor.withOpacity(0.2),
                    overlayColor: _severityColor.withOpacity(0.1),
                    trackHeight: 6,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _severity.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) => setState(() => _severity = v.round()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 - Minimal',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade400)),
                    Text('10 - Unbearable',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade400)),
                  ],
                ),
              ]),

              const SizedBox(height: 12),

              // Notes card
              _card([
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Describe the symptom, triggers, duration...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ]),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined, size: 18),
                  label:
                      Text(_saving ? 'Saving...' : 'Save Symptom'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
