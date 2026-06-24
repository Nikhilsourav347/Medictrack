// lib/features/ai_assistant/screens/ai_assistant_screen.dart

import 'package:flutter/material.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/repositories/vital_repository.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/repositories/medicine_repository.dart';
import '../../../data/models/symptom_model.dart';
import '../../../data/repositories/symptom_repository.dart';
import '../../../shared/utils/date_utils.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/voice_parser.dart';
import '../../symptoms/services/gemini_symptom_service.dart';
import '../../../data/repositories/user_profile_repository.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final Widget? customWidget;
  ChatMessage({required this.text, required this.isUser, this.customWidget});
}

enum AssistantFlow {
  none,
  vitals,
  medicine,
  symptoms,
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _chatMessages = [];
  String _currentStatus = "Tap to start";
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _showConfirmationBanner = false;
  String _confirmationMessage = "";

  AssistantFlow _currentFlow = AssistantFlow.none;
  int _currentStep = 0;
  VoidCallback? _currentStepListener;

  // Vitals State variables
  int? _systolic;
  int? _diastolic;
  double? _bloodSugar;
  String? _sugarType;
  double? _temperature;
  int? _oxygenSaturation;
  double? _weight;

  // Medicine State variables
  String? _medicineName;
  String? _medicineDosage;
  String? _medicineFrequency;
  int? _remainingDoses;

  // Symptom State variables
  String? _symptomDescription;
  int? _symptomSeverity;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _speechService.initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGreeting();
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    _speechService.stopListening();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addMessage(String text, {required bool isUser}) {
    if (_chatMessages.isNotEmpty && !_chatMessages.last.isUser && !isUser && _chatMessages.last.text == text) {
      return;
    }
    setState(() {
      _chatMessages.add(ChatMessage(text: text, isUser: isUser));
      _scrollToBottom();
    });
  }

  void _addCustomWidget(Widget widget) {
    setState(() {
      _chatMessages.add(ChatMessage(text: "", isUser: false, customWidget: widget));
      _scrollToBottom();
    });
  }

  Future<void> _speakAI(String text, {required VoidCallback onComplete}) async {
    setState(() {
      _currentStatus = "Speaking...";
      _isSpeaking = true;
      _isListening = false;
    });
    _addMessage(text, isUser: false);
    
    await _ttsService.speak(text, onComplete: () {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
        onComplete();
      }
    });
  }

  Future<void> _listenUser({required Function(String speechText) onDone}) async {
    setState(() {
      _currentStatus = "Listening...";
      _isListening = true;
      _isSpeaking = false;
    });

    int? userBubbleIndex;

    await _speechService.startListening(
      onResult: (text, isFinal) {
        if (text.isEmpty) return;
        
        setState(() {
          if (userBubbleIndex == null) {
            _chatMessages.add(ChatMessage(text: text, isUser: true));
            userBubbleIndex = _chatMessages.length - 1;
          } else {
            _chatMessages[userBubbleIndex!] = ChatMessage(text: text, isUser: true);
          }
          _scrollToBottom();
        });

        if (isFinal) {
          _speechService.stopListening();
          setState(() {
            _isListening = false;
            _currentStatus = "Processing...";
          });
          onDone(text);
        }
      },
      onError: () {
        setState(() {
          _isListening = false;
          _currentStatus = "Tap to start";
        });
      }
    );
  }

  void _startListeningForCurrentStep() {
    if (_currentStepListener != null) {
      _currentStepListener!();
    }
  }

  void _onMicButtonTapped() {
    if (_isSpeaking) {
      _ttsService.stop();
      _startListeningForCurrentStep();
    } else if (_isListening) {
      _speechService.stopListening();
      setState(() {
        _isListening = false;
        _currentStatus = "Processing...";
      });
    } else {
      _startListeningForCurrentStep();
    }
  }

  void _startGreeting() {
    _currentStepListener = () {
      _speakAI(
        "Hello! I am your health assistant. What would you like to do? Say: log vitals, add medicine, or check symptoms.",
        onComplete: () {
          _listenUser(
            onDone: (response) {
              _parseInitialIntent(response);
            },
          );
        },
      );
    };
    _startListeningForCurrentStep();
  }

  void _parseInitialIntent(String text) {
    final lower = text.toLowerCase();
    
    if (lower.contains('vital') ||
        lower.contains('blood pressure') ||
        lower.contains('sugar') ||
        lower.contains('bp') ||
        lower.contains('log') ||
        lower.contains('reading')) {
      _startVitalsFlow();
      return;
    }
    
    if (lower.contains('medicine') ||
        lower.contains('tablet') ||
        lower.contains('pill') ||
        lower.contains('medication') ||
        lower.contains('drug')) {
      _startMedicineFlow();
      return;
    }
    
    if (lower.contains('symptom') ||
        lower.contains('feeling') ||
        lower.contains('pain') ||
        lower.contains('sick') ||
        lower.contains('headache') ||
        lower.contains('fever') ||
        lower.contains('hurt')) {
      _startSymptomsFlow();
      return;
    }
    
    _currentStepListener = () {
      _speakAI(
        "I'm sorry, I didn't catch that. Would you like to: log vitals, add medicine, or check symptoms?",
        onComplete: () {
          _listenUser(
            onDone: (res) => _parseInitialIntent(res),
          );
        },
      );
    };
    _startListeningForCurrentStep();
  }

  // FLOW 1: VITALS
  void _startVitalsFlow() {
    _currentFlow = AssistantFlow.vitals;
    _currentStep = 0;
    _nextVitalsStep();
  }

  void _nextVitalsStep() {
    switch (_currentStep) {
      case 0:
        _currentStepListener = () {
          _speakAI(
            "What is your blood pressure? Say the two numbers — systolic and diastolic.",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  final bp = VoiceParser.extractTwoInts(response);
                  if (bp.length >= 2) {
                    _systolic = bp[0];
                    _diastolic = bp[1];
                  }
                  _currentStep = 1;
                  _nextVitalsStep();
                },
              );
            },
          );
        };
        break;
        
      case 1:
        _currentStepListener = () {
          _speakAI(
            "What is your blood sugar level?",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  _bloodSugar = VoiceParser.extractFirstDouble(response);
                  _currentStep = 2;
                  _nextVitalsStep();
                },
              );
            },
          );
        };
        break;
        
      case 2:
        _currentStepListener = () {
          _speakAI(
            "Is this fasting or after a meal?",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  final fasting = VoiceParser.isFasting(response);
                  _sugarType = fasting ? "Fasting" : "After meal";
                  _currentStep = 3;
                  _nextVitalsStep();
                },
              );
            },
          );
        };
        break;
        
      case 3:
        _currentStepListener = () {
          _speakAI(
            "What is your temperature in Celsius?",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  _temperature = VoiceParser.extractFirstDouble(response);
                  _currentStep = 4;
                  _nextVitalsStep();
                },
              );
            },
          );
        };
        break;
        
      case 4:
        _currentStepListener = () {
          _speakAI(
            "What is your SpO2 or oxygen level?",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  final val = VoiceParser.extractFirstInt(response);
                  _oxygenSaturation = val;
                  _currentStep = 5;
                  _nextVitalsStep();
                },
              );
            },
          );
        };
        break;
        
      case 5:
        _currentStepListener = () {
          _speakAI(
            "What is your weight in kilograms?",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  _weight = VoiceParser.extractFirstDouble(response);
                  _saveVitals();
                },
              );
            },
          );
        };
        break;
    }
    _startListeningForCurrentStep();
  }

  Future<void> _saveVitals() async {
    final vital = VitalModel(
      systolic: _systolic?.toDouble(),
      diastolic: _diastolic?.toDouble(),
      bloodGlucose: _bloodSugar,
      notes: _sugarType != null ? "Glucose type: $_sugarType" : null,
      temperature: _temperature,
      oxygenSaturation: _oxygenSaturation?.toDouble(),
      weight: _weight,
      recordedAt: AppDateUtils.nowString(),
    );

    await VitalRepository().insertVital(vital);

    final summaryCard = _buildVitalsSummaryCard();
    _addCustomWidget(summaryCard);

    setState(() {
      _currentFlow = AssistantFlow.none;
      _currentStepListener = null;
      _currentStatus = "Vitals Saved";
      _showConfirmationBanner = true;
      _confirmationMessage = "Your vitals have been saved successfully.";
    });

    await _ttsService.speak("Your vitals have been saved successfully.");
  }

  Widget _buildVitalsSummaryCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  "Vitals Summary",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (_systolic != null || _diastolic != null)
              _summaryRow("Blood Pressure", "${_systolic ?? '—'}/${_diastolic ?? '—'} mmHg"),
            if (_bloodSugar != null)
              _summaryRow("Blood Sugar", "$_bloodSugar mg/dL${_sugarType != null ? ' ($_sugarType)' : ''}"),
            if (_temperature != null)
              _summaryRow("Temperature", "$_temperature °C"),
            if (_oxygenSaturation != null)
              _summaryRow("SpO2", "$_oxygenSaturation %"),
            if (_weight != null)
              _summaryRow("Weight", "$_weight kg"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Saved to Local Database",
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FLOW 2: MEDICINE
  void _startMedicineFlow() {
    _currentFlow = AssistantFlow.medicine;
    _currentStep = 0;
    _nextMedicineStep();
  }

  void _nextMedicineStep() {
    switch (_currentStep) {
      case 0:
        _currentStepListener = () {
          _speakAI(
            "What is the name of the medicine?",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  _medicineName = response;
                  _currentStep = 1;
                  _nextMedicineStep();
                },
              );
            },
          );
        };
        break;
        
      case 1:
        _currentStepListener = () {
          _speakAI(
            "What is the dosage? For example, 500 milligrams.",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  _medicineDosage = response;
                  _currentStep = 2;
                  _nextMedicineStep();
                },
              );
            },
          );
        };
        break;
        
      case 2:
        _currentStepListener = () {
          _speakAI(
            "How often do you take it? Say: once daily, twice daily, or three times daily.",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  final lower = response.toLowerCase();
                  if (lower.contains("once")) {
                    _medicineFrequency = "Once daily";
                  } else if (lower.contains("twice") || lower.contains("two")) {
                    _medicineFrequency = "Twice daily";
                  } else if (lower.contains("three") || lower.contains("triple")) {
                    _medicineFrequency = "Three times daily";
                  } else {
                    _medicineFrequency = response.isEmpty
                        ? "Once daily"
                        : response[0].toUpperCase() + response.substring(1);
                  }
                  _currentStep = 3;
                  _nextMedicineStep();
                },
              );
            },
          );
        };
        break;
        
      case 3:
        _currentStepListener = () {
          _speakAI(
            "How many doses do you have remaining?",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  _remainingDoses = VoiceParser.extractFirstInt(response);
                  _saveMedicine();
                },
              );
            },
          );
        };
        break;
    }
    _startListeningForCurrentStep();
  }

  Future<void> _saveMedicine() async {
    final today = AppDateUtils.todayString();
    final now = AppDateUtils.nowString();

    final medicine = MedicineModel(
      name: _medicineName ?? "Unnamed Medicine",
      dosage: _medicineDosage,
      frequency: _medicineFrequency ?? "Once daily",
      times: "08:00",
      startDate: today,
      isActive: true,
      notes: _remainingDoses != null ? "Remaining doses: $_remainingDoses" : null,
      createdAt: now,
    );

    await MedicineRepository().insertMedicine(medicine);

    final summaryCard = _buildMedicineSummaryCard();
    _addCustomWidget(summaryCard);

    setState(() {
      _currentFlow = AssistantFlow.none;
      _currentStepListener = null;
      _currentStatus = "Medicine Added";
      _showConfirmationBanner = true;
      _confirmationMessage = "Medicine has been added to your list.";
    });

    await _ttsService.speak("Medicine has been added to your list.");
  }

  Widget _buildMedicineSummaryCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medication_rounded, color: Colors.blueAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  "Medicine Details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _summaryRow("Name", _medicineName ?? "Unnamed Medicine"),
            if (_medicineDosage != null)
              _summaryRow("Dosage", _medicineDosage!),
            _summaryRow("Frequency", _medicineFrequency ?? "Once daily"),
            _summaryRow("Times", "08:00"),
            if (_remainingDoses != null)
              _summaryRow("Remaining Doses", "$_remainingDoses"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Added to Medicine Tracker",
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FLOW 3: SYMPTOMS
  void _startSymptomsFlow() {
    _currentFlow = AssistantFlow.symptoms;
    _currentStep = 0;
    _nextSymptomsStep();
  }

  void _nextSymptomsStep() {
    switch (_currentStep) {
      case 0:
        _currentStepListener = () {
          _speakAI(
            "Please describe your symptom. What are you feeling?",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  _symptomDescription = response;
                  _currentStep = 1;
                  _nextSymptomsStep();
                },
              );
            },
          );
        };
        break;
        
      case 1:
        _currentStepListener = () {
          _speakAI(
            "On a scale of 1 to 10, how severe is it?",
            onComplete: () {
              _listenUser(
                onDone: (response) {
                  final val = VoiceParser.extractFirstInt(response);
                  _symptomSeverity = (val != null && val >= 1 && val <= 10) ? val : 5;
                  _saveSymptom();
                },
              );
            },
          );
        };
        break;
    }
    _startListeningForCurrentStep();
  }

  int _mapSeverityToScore(String severity) {
    final clean = severity.trim().toUpperCase();
    if (clean.contains("EMERGENCY")) return 10;
    if (clean.contains("SERIOUS")) return 8;
    if (clean.contains("MODERATE")) return 5;
    return 2;
  }

  Future<void> _saveSymptom() async {
    final severityStr = _symptomSeverity != null ? " (Reported Severity: $_symptomSeverity/10)" : "";
    final desc = "${_symptomDescription ?? "Unspecified symptom"}$severityStr";
    
    setState(() {
      _currentStatus = "Analyzing symptom with AI...";
    });
    
    _addMessage("Analyzing your symptoms with Gemini AI...", isUser: false);

    try {
      final profile = await UserProfileRepository().getProfile();
      final recentVitals = await VitalRepository().getRecentVitals(5);
      final activeMedicines = await MedicineRepository().getActiveMedicines();
      final patientContext = GeminiSymptomService.buildPatientContext(
        profile,
        recentVitals,
        activeMedicines,
      );

      final result = await GeminiSymptomService().analyzeSymptom(
        textDescription: desc,
        patientContext: patientContext,
      );
      
      final name = desc.substring(0, desc.length > 60 ? 60 : desc.length);
      final score = _mapSeverityToScore(result.severity);
      final rawNotes = "ASSESSMENT: ${result.assessment}\n\nSEVERITY: ${result.severity}\n\nADVICE: ${result.advice}\n\nMEDICINES: ${result.medicines}\n\nWATCH_FOR: ${result.watchFor}\n\nVOICE_SUMMARY: ${result.voiceSummary}";

      final symptom = SymptomModel(
        symptomName: name,
        severity: score,
        notes: rawNotes,
        recordedAt: AppDateUtils.nowString(),
      );

      await SymptomRepository().insertSymptom(symptom);

      final aiCard = _buildAiAnalysisCard(result);
      _addCustomWidget(aiCard);

      setState(() {
        _currentFlow = AssistantFlow.none;
        _currentStepListener = null;
        _currentStatus = "Analysis Complete";
        _showConfirmationBanner = true;
        _confirmationMessage = "AI analysis complete and saved to your history.";
      });

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
    } catch (e) {
      _addMessage("AI analysis failed: $e", isUser: false);
      setState(() {
        _currentFlow = AssistantFlow.none;
        _currentStepListener = null;
        _currentStatus = "Analysis Failed";
      });
      await _ttsService.speak("Sorry, I encountered an error while analyzing your symptoms.");
    }
  }

  Widget _buildAiAnalysisCard(SymptomAnalysis result) {
    final isEmergency = result.severity.trim().toUpperCase().contains('EMERGENCY');
    final severityColor = isEmergency 
        ? const Color(0xFFF43F5E) 
        : result.severity.trim().toUpperCase().contains('SERIOUS')
            ? const Color(0xFFF59E0B)
            : const Color(0xFF1D9E75);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_rounded, color: Color(0xFF6366F1), size: 24),
                const SizedBox(width: 8),
                const Text(
                  "AI Symptom Analysis",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: severityColor, width: 1),
                  ),
                  child: Text(
                    result.severity.toUpperCase(),
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            const Text(
              "ASSESSMENT",
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1), letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              result.assessment,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 12),
            const Text(
              "ADVICE",
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1), letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              result.advice,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
            if (result.medicines.isNotEmpty && result.medicines != 'None recommended.') ...[
              const SizedBox(height: 12),
              const Text(
                "MEDICINES",
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF6366F1), letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                result.medicines,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ],
            if (result.watchFor.isNotEmpty && result.watchFor != 'None specified.') ...[
              const SizedBox(height: 12),
              const Text(
                "WARNING SIGNS TO WATCH FOR",
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFF43F5E), letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                result.watchFor,
                style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF991B1B)),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isMe = msg.isUser;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1D9E75) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 14.5,
            height: 1.3,
            fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Health Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _ttsService.stop();
            _speechService.stopListening();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Conversation',
            onPressed: () {
              _ttsService.stop();
              _speechService.stopListening();
              setState(() {
                _chatMessages.clear();
                _currentFlow = AssistantFlow.none;
                _currentStep = 0;
                _showConfirmationBanner = false;
              });
              _startGreeting();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_showConfirmationBanner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF1D9E75),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _confirmationMessage,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _showConfirmationBanner = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = _chatMessages[index];
                  if (msg.customWidget != null) {
                    return msg.customWidget!;
                  }
                  return _buildChatBubble(msg);
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  PulsingMicCircle(
                    isListening: _isListening,
                    isSpeaking: _isSpeaking,
                    onTap: _onMicButtonTapped,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentStatus,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (_currentFlow != AssistantFlow.none) ...[
                    const SizedBox(height: 6),
                    Chip(
                      label: Text(
                        _currentFlow == AssistantFlow.vitals
                            ? 'LOGGING VITALS'
                            : _currentFlow == AssistantFlow.medicine
                                ? 'ADDING MEDICINE'
                                : 'CHECKING SYMPTOMS',
                        style: const TextStyle(
                          color: Color(0xFF1D9E75),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                      side: const BorderSide(color: Color(0xFF1D9E75), width: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Center(
                child: InkWell(
                  onTap: _onMicButtonTapped,
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1D9E75),
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PulsingMicCircle extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final VoidCallback onTap;

  const PulsingMicCircle({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    required this.onTap,
  });

  @override
  State<PulsingMicCircle> createState() => _PulsingMicCircleState();
}

class _PulsingMicCircleState extends State<PulsingMicCircle>
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
    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isListening) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingMicCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.isSpeaking) {
      child = const Icon(Icons.volume_up_rounded, color: Color(0xFF1D9E75), size: 36);
    } else {
      child = const Icon(Icons.mic_rounded, color: Color(0xFF1D9E75), size: 36);
    }

    return ScaleTransition(
      scale: widget.isListening ? _animation : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFF1D9E75), width: 3.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: widget.isListening ? 4 : 1,
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
