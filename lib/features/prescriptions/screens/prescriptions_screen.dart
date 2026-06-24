import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/prescription_model.dart';
import '../../../data/repositories/prescription_repository.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final PrescriptionRepository _repo = PrescriptionRepository();
  List<PrescriptionModel> _prescriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getAllPrescriptions();
      if (mounted) {
        setState(() {
          _prescriptions = list;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading prescriptions: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deletePrescription(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription'),
        content: const Text('Are you sure you want to delete this prescription? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repo.deletePrescription(id);
      _loadPrescriptions();
    }
  }

  void _showImageDialog(PrescriptionModel p) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black87,
              title: Text(p.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () {
                    Navigator.pop(context);
                    if (p.id != null) {
                      _deletePrescription(p.id!);
                    }
                  },
                ),
              ],
            ),
            Container(
              color: Colors.black,
              height: MediaQuery.of(context).size.height * 0.7,
              width: double.infinity,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: kIsWeb
                    ? Image.network(p.imagePath, fit: BoxFit.contain)
                    : Image.file(File(p.imagePath), fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'Doctor Prescriptions', showBack: false),
      body: _loading
          ? const LoadingIndicator(message: 'Loading prescriptions...')
          : _prescriptions.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.receipt_long_rounded,
                  title: 'No Prescriptions',
                  subtitle: 'You have not uploaded any prescriptions or medical reports yet.',
                  actionLabel: 'Upload Prescription',
                  onAction: () async {
                    final added = await context.push('/prescriptions/add');
                    if (added == true) {
                      _loadPrescriptions();
                    }
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _prescriptions.length,
                  itemBuilder: (context, index) {
                    final p = _prescriptions[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: InkWell(
                        onTap: () => _showImageDialog(p),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Image thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey.shade100,
                                  child: kIsWeb
                                      ? Image.network(p.imagePath, fit: BoxFit.cover)
                                      : Image.file(File(p.imagePath), fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.title,
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 3),
                                    if (p.doctorName != null && p.doctorName!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 3),
                                        child: Text(
                                          p.doctorName!,
                                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    Text(
                                      AppDateUtils.formatDisplay(p.date),
                                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () {
                                  if (p.id != null) {
                                    _deletePrescription(p.id!);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await context.push('/prescriptions/add');
          if (added == true) {
            _loadPrescriptions();
          }
        },
        backgroundColor: const Color(0xFF1D9E75),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
