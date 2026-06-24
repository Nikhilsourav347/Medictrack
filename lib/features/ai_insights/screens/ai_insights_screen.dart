import 'package:flutter/material.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/models/symptom_model.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../../data/repositories/medicine_repository.dart';
import '../../../data/repositories/symptom_repository.dart';
import '../../../shared/utils/auth_helper.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../ai_assistant/services/tts_service.dart';
import '../services/gemini_insights_service.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  final TtsService _ttsService = TtsService();
  final GeminiInsightsService _insightsService = GeminiInsightsService();

  UserProfileModel? _profile;
  List<VitalModel> _vitals = [];
  List<MedicineModel> _medicines = [];
  List<SymptomModel> _symptoms = [];

  bool _loading = true;
  String? _errorMessage;
  HealthInsights? _insights;
  int _healthScore = 100;
  bool _isSpeaking = false;
  double _playbackProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDataAndGenerateInsights();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _loadDataAndGenerateInsights() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userEmail = AuthHelper().userEmail;
      
      // Fetch details from local DB repositories
      _profile = await UserProfileRepository().getProfile(userId: userEmail);
      _vitals = await VitalRepository().getRecentVitals(10, userId: userEmail);
      _medicines = await MedicineRepository().getActiveMedicines(userId: userEmail);
      _symptoms = await SymptomRepository().getRecentSymptoms(5, userId: userEmail);

      // Compute dynamic overall health score
      _calculateDynamicHealthScore();

      // Call Gemini for comprehensive report
      final report = await _insightsService.generateHealthInsights(
        profile: _profile,
        recentVitals: _vitals,
        activeMedicines: _medicines,
        recentSymptoms: _symptoms,
      );

      if (mounted) {
        setState(() {
          _insights = report;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting health insights: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _calculateDynamicHealthScore() {
    int score = 95; // default baseline

    // Vitals deductions
    if (_vitals.isNotEmpty) {
      final latest = _vitals.first;
      
      // Blood Pressure
      if (latest.systolic != null && latest.diastolic != null) {
        final sys = latest.systolic!;
        final dia = latest.diastolic!;
        if (sys > 160 || dia > 100) {
          score -= 15;
        } else if (sys > 140 || dia > 90) {
          score -= 8;
        } else if (sys < 90 || dia < 60) {
          score -= 6;
        }
      }

      // Oxygen saturation
      if (latest.oxygenSaturation != null) {
        final spo2 = latest.oxygenSaturation!;
        if (spo2 < 90) {
          score -= 18;
        } else if (spo2 < 94) {
          score -= 10;
        }
      }

      // Glucose level
      if (latest.bloodGlucose != null) {
        final bg = latest.bloodGlucose!;
        if (bg > 250) {
          score -= 15;
        } else if (bg > 180) {
          score -= 8;
        } else if (bg < 70) {
          score -= 10;
        }
      }
    }

    // Symptoms deductions
    if (_symptoms.isNotEmpty) {
      // Find highest symptom severity recorded recently
      int highestSeverity = 0;
      for (var s in _symptoms) {
        if (s.severity > highestSeverity) {
          highestSeverity = s.severity;
        }
      }
      if (highestSeverity >= 8) {
        score -= 20;
      } else if (highestSeverity >= 5) {
        score -= 12;
      } else if (highestSeverity >= 3) {
        score -= 5;
      }
    }

    // Clamp score between 30 and 100
    if (score < 30) score = 30;
    if (score > 100) score = 100;
    _healthScore = score;
  }

  Future<void> _toggleAudio() async {
    if (_insights == null) return;

    if (_isSpeaking) {
      await _ttsService.stop();
      setState(() {
        _isSpeaking = false;
        _playbackProgress = 0.0;
      });
    } else {
      setState(() {
        _isSpeaking = true;
        _playbackProgress = 0.5; // mid slider position when speaking
      });
      
      await _ttsService.speak(
        _insights!.voiceSummary,
        rate: 0.45,
        onComplete: () {
          if (mounted) {
            setState(() {
              _isSpeaking = false;
              _playbackProgress = 1.0;
            });
          }
        },
      );
    }
  }

  Color _getScoreColor() {
    if (_healthScore >= 80) return const Color(0xFF1D9E75); // Green
    if (_healthScore >= 55) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFF43F5E); // Red
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _getScoreColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: 'AI Health Insights', showBack: true),
      body: _loading
          ? const LoadingIndicator(message: 'Generating personalized insights with AI...')
          : _errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 56),
                        const SizedBox(height: 16),
                        const Text(
                          'Insights Generation Failed',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadDataAndGenerateInsights,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D9E75),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Circular Health Score Card (Image 2 representation)
                            Card(
                              elevation: 2,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(color: Colors.grey.shade100),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 36),
                                child: Column(
                                  children: [
                                    Text(
                                      'Overall Health Score',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: const Color(0xFF475569),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: 140,
                                      height: 140,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Background track
                                          SizedBox(
                                            width: 130,
                                            height: 130,
                                            child: CircularProgressIndicator(
                                              value: 1.0,
                                              strokeWidth: 10,
                                              color: Colors.grey.shade100,
                                            ),
                                          ),
                                          // Dynamic color fill
                                          SizedBox(
                                            width: 130,
                                            height: 130,
                                            child: CircularProgressIndicator(
                                              value: _healthScore / 100.0,
                                              strokeWidth: 10,
                                              strokeCap: StrokeCap.round,
                                              color: scoreColor,
                                            ),
                                          ),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$_healthScore',
                                                style: TextStyle(
                                                  fontSize: 42,
                                                  fontWeight: FontWeight.w900,
                                                  color: scoreColor,
                                                ),
                                              ),
                                              const Text(
                                                '/ 100',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Recommendations header
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFF6366F1), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Personalized AI Recommendations',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Condition Summary Card
                            _buildInfoCard(
                              title: 'Body Condition Summary',
                              content: _insights!.conditionSummary,
                              icon: Icons.favorite_border_rounded,
                              iconColor: Colors.redAccent,
                            ),
                            const SizedBox(height: 12),

                            // Score Adjustment Card
                            _buildInfoCard(
                              title: 'Health Score Analysis',
                              content: _insights!.scoreAdjustment,
                              icon: Icons.trending_up_rounded,
                              iconColor: Colors.blueAccent,
                            ),
                            const SizedBox(height: 12),

                            // Main Recommendations Card
                            _buildInfoCard(
                              title: 'AI Suggested Action Plan',
                              content: _insights!.recommendations,
                              icon: Icons.task_alt_rounded,
                              iconColor: const Color(0xFF1D9E75),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Audio Playback Bar at the bottom (Image 2 style)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          )
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            // Play/Pause icon button
                            GestureDetector(
                              onTap: _toggleAudio,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isSpeaking ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: const Color(0xFF1D9E75),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Audio Track Slider
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFF1D9E75),
                                  inactiveTrackColor: Colors.grey.shade100,
                                  thumbColor: const Color(0xFF1D9E75),
                                  overlayColor: const Color(0xFF1D9E75).withValues(alpha: 0.12),
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                ),
                                child: Slider(
                                  value: _playbackProgress,
                                  onChanged: (val) {
                                    setState(() {
                                      _playbackProgress = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Volume Speaker Icon
                            Icon(
                              Icons.volume_up_rounded,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            SelectableText(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
