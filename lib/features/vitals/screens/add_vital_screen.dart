// lib/features/vitals/screens/add_vital_screen.dart
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
                  Expanded(child: _field('Systolic', 'mmHg', 'e.g. 120', _systolicCtrl, Icons.favorite_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Diastolic', 'mmHg', 'e.g. 80', _diastolicCtrl, Icons.favorite_outline)),
                ]),
              ]),
              _section('Heart Rate', [_field('Heart Rate', 'bpm', 'e.g. 72', _heartRateCtrl, Icons.monitor_heart_outlined)]),
              _section('Temperature', [_field('Temperature', '°C', 'e.g. 36.6', _tempCtrl, Icons.thermostat_outlined)]),
              _section('Oxygen Saturation', [_field('SpO₂', '%', 'e.g. 98', _spo2Ctrl, Icons.water_drop_outlined)]),
              _section('Blood Glucose', [_field('Blood Glucose', 'mg/dL', 'e.g. 100', _glucoseCtrl, Icons.opacity_outlined)]),
              _section('Weight', [_field('Weight', 'kg', 'e.g. 70', _weightCtrl, Icons.scale_outlined)]),
              _section('Notes', [
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText: 'e.g. Recorded after morning walk, feeling good...',
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
                          'Save Vitals',
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

  Widget _field(String label, String suffix, String hint, TextEditingController ctrl, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: const Color(0xFF1D9E75), size: 20),
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
