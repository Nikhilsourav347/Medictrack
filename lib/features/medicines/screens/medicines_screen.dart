import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/repositories/medicine_repository.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../medicines/widgets/medicine_card.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final MedicineRepository _repo = MedicineRepository();
  List<MedicineModel> _medicines = [];
  bool _loading = true;
  bool _showActiveOnly = false;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() => _loading = true);
    final data = _showActiveOnly
        ? await _repo.getActiveMedicines()
        : await _repo.getAllMedicines();
    if (mounted) setState(() { _medicines = data; _loading = false; });
  }

  Future<void> _deleteMedicine(int id) async {
    await _repo.deleteMedicine(id);
    _loadMedicines();
  }

  Future<void> _toggleActive(MedicineModel m) async {
    await _repo.toggleActive(m.id!, !m.isActive);
    _loadMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Medicines',
        actions: [
          IconButton(
            icon: Icon(_showActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: _showActiveOnly ? 'Show all' : 'Active only',
            onPressed: () {
              setState(() => _showActiveOnly = !_showActiveOnly);
              _loadMedicines();
            },
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _medicines.isEmpty
              ? EmptyStateWidget(
                  title: 'No medicines',
                  subtitle: 'Add your medicines to track dosages and schedules.',
                  icon: Icons.medication_outlined,
                  actionLabel: 'Add Medicine',
                  onAction: () async {
                    await context.push('/medicines/add');
                    _loadMedicines();
                  },
                )
              : RefreshIndicator(
                  color: const Color(0xFF1D9E75),
                  onRefresh: _loadMedicines,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _medicines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => MedicineCard(
                      medicine: _medicines[i],
                      onDelete: () => _deleteMedicine(_medicines[i].id!),
                      onToggleActive: () => _toggleActive(_medicines[i]),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/medicines/add');
          _loadMedicines();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
