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

  Widget _buildAnalyzerBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E24AA), Color(0xFF673AB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E24AA).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'AI Symptom Analyzer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Talk or upload a photo to analyze symptoms with Gemini AI.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.push('/symptom-analyzer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF8E24AA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Start', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Symptom History',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF8E24AA)),
            tooltip: 'AI Symptom Analyzer',
            onPressed: () {
              context.push('/symptom-analyzer');
            },
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator(message: 'Loading symptoms...')
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildAnalyzerBanner(),
                ),
                Expanded(
                  child: _symptoms.isEmpty
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
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _symptoms.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, index) => SymptomTile(
                              symptom: _symptoms[index],
                              onDelete: () => _deleteSymptom(_symptoms[index].id!),
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'symptom_fab',
        onPressed: () async {
          await context.push('/symptoms/add');
          _loadSymptoms();
        },
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
