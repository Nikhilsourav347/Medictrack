import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/prescription_model.dart';
import '../../../data/repositories/prescription_repository.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class AddPrescriptionScreen extends StatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final PrescriptionRepository _repo = PrescriptionRepository();

  final _titleCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  String _date = AppDateUtils.todayString();
  XFile? _pickedImage;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _doctorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload or capture a prescription image'),
          backgroundColor: Color(0xFFF43F5E),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String finalImagePath = _pickedImage!.path;

      // Persist the image to local app documents directory on mobile
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = await File(_pickedImage!.path).copy('${appDir.path}/$fileName');
        finalImagePath = savedFile.path;
      }

      final prescription = PrescriptionModel(
        title: _titleCtrl.text.trim(),
        doctorName: _doctorCtrl.text.trim().isNotEmpty ? _doctorCtrl.text.trim() : null,
        date: _date,
        imagePath: finalImagePath,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        createdAt: AppDateUtils.nowString(),
      );

      await _repo.insertPrescription(prescription);

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription saved successfully'),
            backgroundColor: Color(0xFF1D9E75),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error saving prescription: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving prescription: $e')),
        );
      }
    }
  }

  Widget _card(List<Widget> children) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'Upload Prescription', showBack: true),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Box Card
              _card([
                const Text(
                  'Prescription / Report Image *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1D9E75)),
                                title: const Text('Capture with Camera'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.image_rounded, color: Color(0xFF6366F1)),
                                title: const Text('Upload from Gallery'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: _pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: kIsWeb
                                  ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                                  : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to capture or upload image',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ]),

              // Prescription details card
              _card([
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prescription/Report Title *',
                    hintText: 'e.g. Heart Checkup Report, Dental Prescription',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _doctorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name (Optional)',
                    hintText: 'e.g. Dr. Sarah Jenkins',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Prescription Date *',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text(
                      AppDateUtils.formatDisplay(_date),
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    hintText: 'e.g. Take medicines twice a day, follow-up in 2 weeks',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ]),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF1D9E75),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Prescription'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
