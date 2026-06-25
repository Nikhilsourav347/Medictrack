// lib/features/symptoms/screens/smart_symptom_screen.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/symptom_model.dart';
import '../../../data/repositories/symptom_repository.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../../data/repositories/medicine_repository.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../shared/utils/date_utils.dart';
import '../../ai_assistant/services/speech_service.dart';
import '../../ai_assistant/services/tts_service.dart';
import '../services/gemini_symptom_service.dart';

class SmartSymptomScreen extends StatefulWidget {
  const SmartSymptomScreen({super.key});

  @override
  State<SmartSymptomScreen> createState() => _SmartSymptomScreenState();
}

class _SmartSymptomScreenState extends State<SmartSymptomScreen> {
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();
  final TextEditingController _textController = TextEditingController();
  final GeminiSymptomService _geminiService = GeminiSymptomService();

  bool _isListening = false;
  String? _voiceTranscript;
  Uint8List? _imageBytes;

  bool _isAnalyzing = false;
  int _loadingTextIndex = 0;
  Timer? _loadingTimer;

  SymptomAnalysis? _analysisResult;
  int? _savedSymptomId;
  String _patientContext = 'No medical profile on file.';

  final List<String> _loadingTexts = [
    "Reading your symptom...",
    "Checking your medical history...",
    "Analyzing the image...",
    "Preparing your advice...",
  ];

  @override
  void initState() {
    super.initState();
    _loadPatientContext();
  }

  Future<void> _loadPatientContext() async {
    try {
      final profile = await UserProfileRepository().getProfile();
      final vitals = await VitalRepository().getVitalsByDateRange(
        AppDateUtils.daysAgoString(7),
        AppDateUtils.todayString(),
      );
      final medicines = await MedicineRepository().getActiveMedicines();
      if (mounted) {
        setState(() {
          _patientContext = GeminiSymptomService.buildPatientContext(
            profile,
            vitals,
            medicines,
          );
        });
      }
    } catch (e) {
      debugPrint("Error loading patient context: $e");
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    _speechService.stopListening();
    _loadingTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  bool get _canAnalyze {
    return !_isAnalyzing &&
        ((_voiceTranscript != null && _voiceTranscript!.isNotEmpty) ||
            (_imageBytes != null));
  }

  Future<void> _startSpeechListening() async {
    await _ttsService.stop();
    setState(() {
      _isListening = true;
      _voiceTranscript = null;
    });

    await _speechService.startListening(
      onResult: (text, isFinal) {
        if (text.isEmpty) return;
        setState(() {
          _voiceTranscript = text;
        });

        if (isFinal) {
          _speechService.stopListening();
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: () {
        setState(() {
          _isListening = false;
        });
      },
    );
  }

  Future<void> _stopSpeechListening() async {
    await _speechService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      await _ttsService.stop();
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }

  void _startAnalysis() async {
    if (_isAnalyzing) return;
    await _ttsService.stop();
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _savedSymptomId = null;
      _loadingTextIndex = 0;
    });

    _loadingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _loadingTextIndex = (_loadingTextIndex + 1) % _loadingTexts.length;
        });
      }
    });

    try {
      final result = await _geminiService.analyzeSymptom(
        voiceDescription: _voiceTranscript,
        textDescription: _textController.text,
        imageBytes: _imageBytes,
        patientContext: _patientContext,
      );

      _loadingTimer?.cancel();
      _loadingTimer = null;

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });

        await _autoSave(result);

        final isEmergency = result.severity.trim().toUpperCase().contains('EMERGENCY');
        if (isEmergency) {
          await _ttsService.speak(
            "Warning. This looks serious. Please seek emergency medical care immediately.",
            rate: 0.4,
          );
        } else {
          await _ttsService.speak(
            result.voiceSummary,
            rate: 0.5,
          );
        }
      }
    } catch (e) {
      _loadingTimer?.cancel();
      _loadingTimer = null;
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    }
  }

  int _mapSeverityToScore(String severity) {
    final clean = severity.trim().toUpperCase();
    if (clean.contains("EMERGENCY")) return 10;
    if (clean.contains("SERIOUS")) return 8;
    if (clean.contains("MODERATE")) return 5;
    return 2;
  }

  String _getSymptomName() {
    String desc = "";
    if (_voiceTranscript != null && _voiceTranscript!.isNotEmpty) {
      desc = _voiceTranscript!;
    } else if (_textController.text.isNotEmpty) {
      desc = _textController.text;
    } else {
      desc = "Image Analysis";
    }
    return desc.substring(0, desc.length > 60 ? 60 : desc.length);
  }

  Future<void> _autoSave(SymptomAnalysis analysis) async {
    try {
      final name = _getSymptomName();
      final score = _mapSeverityToScore(analysis.severity);
      final rawNotes = "ASSESSMENT: ${analysis.assessment}\n\nSEVERITY: ${analysis.severity}\n\nADVICE: ${analysis.advice}\n\nMEDICINES: ${analysis.medicines}\n\nWATCH_FOR: ${analysis.watchFor}\n\nVOICE_SUMMARY: ${analysis.voiceSummary}";

      final symptom = SymptomModel(
        symptomName: name,
        severity: score,
        notes: rawNotes,
        recordedAt: AppDateUtils.nowString(),
      );

      final id = await SymptomRepository().insertSymptom(symptom);
      setState(() {
        _savedSymptomId = id;
      });
    } catch (e) {
      debugPrint("Auto save error: $e");
    }
  }

  Future<void> _handleSaveDone() async {
    await _ttsService.stop();
    if (_savedSymptomId == null && _analysisResult != null) {
      await _autoSave(_analysisResult!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to your health history')),
      );
      _resetAnalysis();
    }
  }

  Future<void> _speakSummaryAgain() async {
    if (_analysisResult == null) return;
    await _ttsService.stop();
    
    final isEmergency = _analysisResult!.severity.trim().toUpperCase().contains('EMERGENCY');
    if (isEmergency) {
      await _ttsService.speak(
        "Warning. This looks serious. Please seek emergency medical care immediately.",
        rate: 0.4,
      );
    } else {
      await _ttsService.speak(
        _analysisResult!.voiceSummary,
        rate: 0.5,
      );
    }
  }

  void _resetAnalysis() {
    _ttsService.stop();
    setState(() {
      _voiceTranscript = null;
      _imageBytes = null;
      _analysisResult = null;
      _savedSymptomId = null;
      _isAnalyzing = false;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Symptom Analyzer'),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Symptom History',
            onPressed: () {
              _ttsService.stop();
              context.push('/symptoms/history');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isAnalyzing
            ? _buildLoadingSection()
            : _analysisResult != null
                ? _buildResultSection()
                : _buildInputSection(),
      ),
    );
  }

  Widget _buildInputSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Describe your symptom",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _inputButton(
                      icon: Icons.mic_rounded,
                      label: "Speak",
                      onTap: _isListening ? _stopSpeechListening : _startSpeechListening,
                      active: _isListening,
                    ),
                    _inputButton(
                      icon: Icons.camera_alt_rounded,
                      label: "Camera",
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    _inputButton(
                      icon: Icons.image_rounded,
                      label: "Gallery",
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),
                AnimatedWaveform(isListening: _isListening),
                if (_voiceTranscript != null && _voiceTranscript!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _voiceTranscript = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5EE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF1D9E75), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mic, color: Color(0xFF0F6E56), size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _voiceTranscript!,
                                style: const TextStyle(
                                  color: Color(0xFF0F6E56),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.cancel, color: Color(0xFF0F6E56), size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_imageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _imageBytes = null;
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Additional details",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Add more details (optional)...",
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canAnalyze ? _startAnalysis : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: _canAnalyze ? 2 : 0,
              ),
              child: const Text(
                'Analyze Symptom',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1D9E75).withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? const Color(0xFF1D9E75) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: active ? const Color(0xFF1D9E75) : const Color(0xFF6366F1),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: active ? const Color(0xFF1D9E75) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF1D9E75),
              strokeWidth: 4,
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _loadingTexts[_loadingTextIndex],
                key: ValueKey<int>(_loadingTextIndex),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final result = _analysisResult!;
    final isEmergency = result.severity.trim().toUpperCase().contains('EMERGENCY');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: _buildSeverityPill(result.severity),
          ),
          const SizedBox(height: 16),
          
          Card(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    "ASSESSMENT",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: SelectableText(
                      result.assessment,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  
                  const Text(
                    "ADVICE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: SelectableText(
                      result.advice,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                  ),
                  
                  CollapsibleSection(
                    title: "MEDICINES",
                    content: result.medicines,
                    icon: Icons.medical_services_outlined,
                  ),
                  
                  CollapsibleSection(
                    title: "WATCH FOR WARNINGS",
                    content: result.watchFor,
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
              ),
            ),
          ),
          
          if (isEmergency) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _ttsService.stop();
                  context.push('/emergency');
                },
                icon: const Icon(Icons.local_hospital_rounded),
                label: const Text("Go to Emergency Screen"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(
                icon: Icons.volume_up_rounded,
                label: "Speak",
                onTap: _speakSummaryAgain,
              ),
              _actionButton(
                icon: Icons.check_circle_rounded,
                label: "Save & Done",
                onTap: _handleSaveDone,
              ),
              _actionButton(
                icon: Icons.refresh_rounded,
                label: "New",
                onTap: _resetAnalysis,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSeverityPill(String severity) {
    final cleanSeverity = severity.trim().toUpperCase();
    
    Color bgColor;
    Color textColor;
    Border? border;

    if (cleanSeverity.contains('EMERGENCY')) {
      return PulsingBorderEmergency(
        enabled: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFCEBEB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFA32D2D), width: 1.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_rounded, color: Color(0xFFA32D2D), size: 16),
              SizedBox(width: 6),
              Text(
                "EMERGENCY",
                style: TextStyle(
                  color: Color(0xFFA32D2D),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (cleanSeverity.contains('SERIOUS')) {
      bgColor = Colors.transparent;
      textColor = const Color(0xFFE65100);
      border = Border.all(color: const Color(0xFFFF9800), width: 1.5);
    } else if (cleanSeverity.contains('MODERATE')) {
      bgColor = const Color(0xFFFAEEDA);
      textColor = const Color(0xFF854F0B);
    } else {
      bgColor = const Color(0xFFE1F5EE);
      textColor = const Color(0xFF0F6E56);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: Text(
        cleanSeverity,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF1D9E75), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedWaveform extends StatefulWidget {
  final bool isListening;
  const AnimatedWaveform({super.key, required this.isListening});

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isListening) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final animValue = (index % 2 == 0) ? _controller.value : 1.0 - _controller.value;
              final height = 10.0 + (animValue * 25.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 6,
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class CollapsibleSection extends StatefulWidget {
  final String title;
  final String content;
  final IconData icon;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.icon, color: const Color(0xFF6366F1), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
              child: Text(
                widget.content,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PulsingBorderEmergency extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PulsingBorderEmergency({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PulsingBorderEmergency> createState() => _PulsingBorderEmergencyState();
}

class _PulsingBorderEmergencyState extends State<PulsingBorderEmergency>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(begin: 1.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingBorderEmergency oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA32D2D).withValues(alpha: 0.4),
                blurRadius: _animation.value * 2.5,
                spreadRadius: _animation.value * 0.5,
              ),
            ],
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
