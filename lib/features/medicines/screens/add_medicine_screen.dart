// lib/features/medicines/screens/add_medicine_screen.dart
import 'package:flutter/material.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/repositories/medicine_repository.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/utils/date_utils.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicineRepository _repo = MedicineRepository();

  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _frequency = AppConstants.frequencyOptions.first;
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _timesString() =>
      _times.map((t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}').join(',');

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1D9E75),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _times.add(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final med = MedicineModel(
      name: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.isNotEmpty ? _dosageCtrl.text.trim() : null,
      frequency: _frequency,
      times: _timesString(),
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
      createdAt: AppDateUtils.nowString(),
    );
    await _repo.insertMedicine(med);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecorationTheme = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'Add Medicine', showBack: true),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _card([
                TextFormField(
                  controller: _nameCtrl,
                  decoration: inputDecorationTheme.copyWith(
                    labelText: 'Medicine Name *',
                    hintText: 'e.g. Paracetamol',
                    prefixIcon: const Icon(Icons.medication, color: Color(0xFF1D9E75)),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dosageCtrl,
                  decoration: inputDecorationTheme.copyWith(
                    labelText: 'Dosage',
                    hintText: 'e.g. 500 mg',
                    prefixIcon: const Icon(Icons.healing, color: Color(0xFF1D9E75)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _card([
                const Text('Frequency',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: inputDecorationTheme,
                  items: AppConstants.frequencyOptions
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
              ]),
              const SizedBox(height: 12),
              _card([
                Row(children: [
                  const Text('Reminder Times',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280))),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addTime,
                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF1D9E75)),
                    label: const Text('Add Time', style: TextStyle(color: Color(0xFF1D9E75), fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _times.asMap().entries.map((e) {
                    final t = e.value;
                    final label =
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    return Chip(
                      backgroundColor: const Color(0xFF1D9E75).withValues(alpha: 0.08),
                      side: BorderSide(color: const Color(0xFF1D9E75).withValues(alpha: 0.2)),
                      label: Text(label, style: const TextStyle(color: Color(0xFF1D9E75), fontWeight: FontWeight.bold)),
                      deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF1D9E75)),
                      onDeleted: _times.length > 1
                          ? () => setState(() => _times.removeAt(e.key))
                          : null,
                    );
                  }).toList(),
                ),
              ]),
              const SizedBox(height: 12),
              _card([
                TextFormField(
                  controller: _notesCtrl,
                  decoration: inputDecorationTheme.copyWith(
                    labelText: 'Notes',
                    hintText: 'e.g. Take twice a day after lunch and dinner.',
                    prefixIcon: const Icon(Icons.note_alt_outlined, color: Color(0xFF1D9E75)),
                  ),
                  maxLines: 3,
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Medicine',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
