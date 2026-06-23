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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'Add Medicine', showBack: true),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _card([
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosage (e.g. 500mg)',
                    border: OutlineInputBorder(),
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
                  value: _frequency,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
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
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Time'),
                  ),
                ]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _times.asMap().entries.map((e) {
                    final t = e.value;
                    final label =
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    return Chip(
                      label: Text(label),
                      deleteIcon: const Icon(Icons.close, size: 16),
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
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Take with food, etc.',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Medicine'),
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
