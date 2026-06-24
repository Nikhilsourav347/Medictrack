import 'package:flutter/material.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/utils/date_utils.dart';

class AddVitalScreen extends StatefulWidget {
  const AddVitalScreen({super.key});

  @override
  State<AddVitalScreen> createState() => _AddVitalScreenState();
}

class _AddVitalScreenState extends State<AddVitalScreen> {
  final _formKey = GlobalKey<FormState>();
  final VitalRepository _repo = VitalRepository();

  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _glucoseCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _heartRateCtrl.dispose();
    _tempCtrl.dispose();
    _spo2Ctrl.dispose();
    _glucoseCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final hasAny = [
      _systolicCtrl.text, _diastolicCtrl.text, _heartRateCtrl.text,
      _tempCtrl.text, _spo2Ctrl.text, _glucoseCtrl.text, _weightCtrl.text
    ].any((t) => t.isNotEmpty);
    if (!hasAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one vital value.')),
      );
      return;
    }
    setState(() => _saving = true);
    final vital = VitalModel(
      systolic: _systolicCtrl.text.isNotEmpty ? double.tryParse(_systolicCtrl.text) : null,
      diastolic: _diastolicCtrl.text.isNotEmpty ? double.tryParse(_diastolicCtrl.text) : null,
      heartRate: _heartRateCtrl.text.isNotEmpty ? double.tryParse(_heartRateCtrl.text) : null,
      temperature: _tempCtrl.text.isNotEmpty ? double.tryParse(_tempCtrl.text) : null,
      oxygenSaturation: _spo2Ctrl.text.isNotEmpty ? double.tryParse(_spo2Ctrl.text) : null,
      bloodGlucose: _glucoseCtrl.text.isNotEmpty ? double.tryParse(_glucoseCtrl.text) : null,
      weight: _weightCtrl.text.isNotEmpty ? double.tryParse(_weightCtrl.text) : null,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
      recordedAt: AppDateUtils.nowString(),
    );
    await _repo.insertVital(vital);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'Record Vitals', showBack: true),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Blood Pressure', [
                Row(children: [
                  Expanded(child: _field('Systolic', 'mmHg', _systolicCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Diastolic', 'mmHg', _diastolicCtrl)),
                ]),
              ]),
              _section('Heart Rate', [_field('Heart Rate', 'bpm', _heartRateCtrl)]),
              _section('Temperature', [_field('Temperature', '°C', _tempCtrl)]),
              _section('Oxygen Saturation', [_field('SpO₂', '%', _spo2Ctrl)]),
              _section('Blood Glucose', [_field('Blood Glucose', 'mg/dL', _glucoseCtrl)]),
              _section('Weight', [_field('Weight', 'kg', _weightCtrl)]),
              _section('Notes', [
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Any additional notes...',
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
                      : const Text('Save Vitals'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, String suffix, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
    );
  }
}
