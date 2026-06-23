import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/symptom_model.dart';
import '../../../data/repositories/symptom_repository.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../widgets/symptom_tile.dart';

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({super.key});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final SymptomRepository _repo = SymptomRepository();
  List<SymptomModel> _symptoms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    setState(() => _loading = true);
    final data = await _repo.getAllSymptoms();
    if (mounted) {
      setState(() {
        _symptoms = data;
        _loading = false;
      });
    }
  }

  Future<void> _deleteSymptom(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Symptom'),
        content:
            const Text('Are you sure you want to delete this symptom record?'),
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
      await _repo.deleteSymptom(id);
      _loadSymptoms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Symptoms',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await context.push('/symptoms/add');
              _loadSymptoms();
            },
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator(message: 'Loading symptoms...')
          : _symptoms.isEmpty
              ? EmptyStateWidget(
                  title: 'No symptoms logged',
                  subtitle:
                      'Track your symptoms to understand patterns in your health.',
                  icon: Icons.sick_outlined,
                  actionLabel: 'Log Symptom',
                  onAction: () async {
                    await context.push('/symptoms/add');
                    _loadSymptoms();
                  },
                )
              : RefreshIndicator(
                  color: const Color(0xFF1D9E75),
                  onRefresh: _loadSymptoms,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _symptoms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => SymptomTile(
                      symptom: _symptoms[index],
                      onDelete: () => _deleteSymptom(_symptoms[index].id!),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'symptom_fab',
        onPressed: () async {
          await context.push('/symptoms/add');
          _loadSymptoms();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
