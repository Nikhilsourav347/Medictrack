import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/doctor_visit_model.dart';
import '../../../data/repositories/doctor_visit_repository.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../widgets/visit_card.dart';

class DoctorVisitsScreen extends StatefulWidget {
  const DoctorVisitsScreen({super.key});

  @override
  State<DoctorVisitsScreen> createState() => _DoctorVisitsScreenState();
}

class _DoctorVisitsScreenState extends State<DoctorVisitsScreen> {
  final DoctorVisitRepository _repo = DoctorVisitRepository();
  List<DoctorVisitModel> _visits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() => _loading = true);
    final data = await _repo.getAllVisits();
    if (mounted) {
      setState(() {
        _visits = data;
        _loading = false;
      });
    }
  }

  Future<void> _deleteVisit(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Visit'),
        content: const Text(
            'Are you sure you want to delete this doctor visit record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE53935)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.deleteVisit(id);
      _loadVisits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Doctor Visits',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await context.push('/visits/add');
              _loadVisits();
            },
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator(message: 'Loading visits...')
          : _visits.isEmpty
              ? EmptyStateWidget(
                  title: 'No visits recorded',
                  subtitle:
                      'Keep a log of your doctor visits, diagnoses, and prescriptions.',
                  icon: Icons.local_hospital_outlined,
                  actionLabel: 'Add Visit',
                  onAction: () async {
                    await context.push('/visits/add');
                    _loadVisits();
                  },
                )
              : RefreshIndicator(
                  color: const Color(0xFF1D9E75),
                  onRefresh: _loadVisits,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _visits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => VisitCard(
                      visit: _visits[index],
                      onDelete: () => _deleteVisit(_visits[index].id!),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'visit_fab',
        onPressed: () async {
          await context.push('/visits/add');
          _loadVisits();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
