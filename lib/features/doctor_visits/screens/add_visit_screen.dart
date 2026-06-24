import 'package:flutter/material.dart';
import '../../../data/models/doctor_visit_model.dart';
import '../../../data/repositories/doctor_visit_repository.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class AddVisitScreen extends StatefulWidget {
  const AddVisitScreen({super.key});

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final DoctorVisitRepository _repo = DoctorVisitRepository();

  final _doctorCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _prescriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _visitDate = DateTime.now();
  DateTime? _followUpDate;
  bool _saving = false;

  @override
  void dispose() {
    _doctorCtrl.dispose();
    _diagnosisCtrl.dispose();
    _prescriptionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVisitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1D9E75)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1D9E75)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _followUpDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final visit = DoctorVisitModel(
      doctorName: _doctorCtrl.text.trim(),
      visitDate: AppDateUtils.todayString().replaceAll(
          AppDateUtils.todayString(),
          '${_visitDate.year}-${_visitDate.month.toString().padLeft(2, '0')}-${_visitDate.day.toString().padLeft(2, '0')}'),
      diagnosis: _diagnosisCtrl.text.isNotEmpty ? _diagnosisCtrl.text.trim() : null,
      prescription:
          _prescriptionCtrl.text.isNotEmpty ? _prescriptionCtrl.text.trim() : null,
      followUpDate: _followUpDate != null
          ? '${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}'
          : null,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
      createdAt: AppDateUtils.nowString(),
    );

    await _repo.insertVisit(visit);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'Add Doctor Visit', showBack: true),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Doctor & date card
              _card([
                TextFormField(
                  controller: _doctorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name *',
                    hintText: 'e.g. Dr. Sharma',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                _datePickerRow(
                  label: 'Visit Date',
                  date: _visitDate,
                  onTap: _pickVisitDate,
                ),
              ]),

              const SizedBox(height: 12),

              // Clinical info card
              _card([
                const _SectionTitle('Clinical Information'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _diagnosisCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis',
                    hintText: 'e.g. Hypertension',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medical_information_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _prescriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prescription',
                    hintText: 'e.g. Amlodipine 5mg once daily',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication_outlined),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ]),

              const SizedBox(height: 12),

              // Follow-up card
              _card([
                const _SectionTitle('Follow-up'),
                const SizedBox(height: 12),
                _followUpRow(),
              ]),

              const SizedBox(height: 12),

              // Notes card
              _card([
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes',
                    hintText: 'Any other details about the visit...',
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
                  label: Text(_saving ? 'Saving...' : 'Save Visit'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datePickerRow({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 18, color: Color(0xFF1D9E75)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 2),
            Text(
              '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ]),
          const Spacer(),
          Icon(Icons.edit_calendar_outlined,
              size: 18, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  Widget _followUpRow() {
    return Row(children: [
      Expanded(
        child: _followUpDate != null
            ? _datePickerRow(
                label: 'Follow-up Date',
                date: _followUpDate!,
                onTap: _pickFollowUpDate,
              )
            : OutlinedButton.icon(
                onPressed: _pickFollowUpDate,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Set Follow-up Date'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1D9E75),
                  side: const BorderSide(color: Color(0xFF1D9E75)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
      ),
      if (_followUpDate != null) ...[
        const SizedBox(width: 8),
        IconButton(
          icon:
              const Icon(Icons.close, color: Color(0xFFE53935), size: 20),
          onPressed: () => setState(() => _followUpDate = null),
          tooltip: 'Remove follow-up',
        ),
      ],
    ]);
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
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  String _monthName(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m];
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280)),
    );
  }
}
