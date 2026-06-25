// lib/features/symptoms/services/gemini_symptom_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/models/medicine_model.dart';

class SymptomAnalysis {
  final String assessment;
  final String severity;
  final String advice;
  final String medicines;
  final String watchFor;
  final String voiceSummary;

  SymptomAnalysis({
    required this.assessment,
    required this.severity,
    required this.advice,
    required this.medicines,
    required this.watchFor,
    required this.voiceSummary,
  });

  Map<String, String> toMap() {
    return {
      'assessment': assessment,
      'severity': severity,
      'advice': advice,
      'medicines': medicines,
      'watchFor': watchFor,
      'voiceSummary': voiceSummary,
    };
  }
}

class GeminiSymptomService {
  static const String _baseUrl = 
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  // Cache to avoid duplicate calls
  static String? _lastInputHash;
  static SymptomAnalysis? _lastResult;
  
  // Single call, everything bundled
  Future<SymptomAnalysis> analyzeSymptom({
    required String patientContext,
    String? voiceDescription,
    String? textDescription,
    Uint8List? imageBytes,
  }) async {
    String? apiKey;
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'];
    } catch (_) {}
    apiKey ??= const String.fromEnvironment('GEMINI_API_KEY');

    if (apiKey.trim().isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception(
        "Gemini API key is not configured.\n\n"
        "To fix this:\n"
        "1. Open the '.env' file in the root of the 'meditrack' project.\n"
        "2. Add your actual Gemini API key:\n"
        "   GEMINI_API_KEY=your_key_here"
      );
    }

    // Check cache first
    final inputHash = _buildHash(
      patientContext, voiceDescription, textDescription, imageBytes
    );
    if (inputHash == _lastInputHash && _lastResult != null) {
      return _lastResult!;
    }
    
    // Build all parts in one shot
    final parts = _buildParts(
      patientContext, voiceDescription, textDescription, imageBytes
    );
    
    final response = await http.post(
      Uri.parse('$_baseUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{'parts': parts}],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 500,
        }
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final resultText = data['candidates'][0]['content']['parts'][0]['text'] as String;
      
      final parsed = parseResponse(resultText);
      // Save to cache
      _lastInputHash = inputHash;
      _lastResult = parsed;
      return parsed;
    } else {
      throw Exception('API error ${response.statusCode}');
    }
  }
  
  String _buildHash(String ctx, String? voice, String? text, Uint8List? img) {
    return '${ctx.hashCode}_${voice?.hashCode}_${text?.hashCode}_${img?.length}';
  }
  
  List<Map<String, dynamic>> _buildParts(
    String patientContext,
    String? voiceDescription,
    String? textDescription,
    Uint8List? imageBytes,
  ) {
    final parts = <Map<String, dynamic>>[];
    
    // 1. System instruction
    parts.add({
      'text': '''You are a medical first-aid AI assistant in a health app.
Analyze the patient profile, symptom description, and image (if provided).
Give a complete assessment in ONE response. Do not ask follow-up questions.
Work with whatever information is given.
Provide your complete assessment in one response. Do not ask the user any follow-up questions. Work with whatever information is provided.

Respond EXACTLY in this format:
ASSESSMENT: [2 sentences on what you observe]
SEVERITY: [MINOR or MODERATE or SERIOUS or EMERGENCY]
ADVICE: [3-5 numbered actionable steps specific to what you see]
MEDICINES: [Specific OTC suggestion OR reason why not safe for this patient]
WATCH_FOR: [2-3 signs that mean go to hospital immediately]
VOICE_SUMMARY: [2 sentences max, plain language, for text-to-speech]'''
    });
    
    // 2. Patient context
    parts.add({'text': 'PATIENT PROFILE:\n$patientContext'});
    
    // 3. Voice description if available
    if (voiceDescription != null && voiceDescription.isNotEmpty) {
      parts.add({'text': 'SYMPTOM (spoken): $voiceDescription'});
    }
    
    // 4. Text description if available
    if (textDescription != null && textDescription.isNotEmpty) {
      parts.add({'text': 'EXTRA DETAILS: $textDescription'});
    }
    
    // 5. Image if available - base64 encoded
    if (imageBytes != null) {
      parts.add({
        'inlineData': {
          'mimeType': 'image/jpeg',
          'data': base64Encode(imageBytes),
        }
      });
    }
    
    return parts;
  }

  static SymptomAnalysis parseResponse(String text) {
    String extract(String label, String nextLabel) {
      final regExp = RegExp(label, caseSensitive: false);
      final match = regExp.firstMatch(text);
      if (match == null) return '';
      final contentStart = match.end;
      if (nextLabel.isEmpty) {
        return text.substring(contentStart).trim();
      }
      final nextRegExp = RegExp(nextLabel, caseSensitive: false);
      final nextMatch = nextRegExp.firstMatch(text.substring(contentStart));
      if (nextMatch == null) {
        return text.substring(contentStart).trim();
      }
      return text.substring(contentStart, contentStart + nextMatch.start).trim();
    }

    final assessment = extract('ASSESSMENT:', 'SEVERITY:');
    final severity = extract('SEVERITY:', 'ADVICE:');
    final advice = extract('ADVICE:', 'MEDICINES:');
    final medicines = extract('MEDICINES:', 'WATCH_FOR:');
    final watchFor = extract('WATCH_FOR:', 'VOICE_SUMMARY:');
    final voiceSummary = extract('VOICE_SUMMARY:', '');

    return SymptomAnalysis(
      assessment: assessment.isEmpty ? 'No assessment details provided.' : assessment,
      severity: severity.isEmpty ? 'MINOR' : severity.toUpperCase(),
      advice: advice.isEmpty ? 'No advice provided.' : advice,
      medicines: medicines.isEmpty ? 'None recommended.' : medicines,
      watchFor: watchFor.isEmpty ? 'None specified.' : watchFor,
      voiceSummary: voiceSummary.isEmpty ? 'Your symptom analysis is complete.' : voiceSummary,
    );
  }
  
  // Build patient context string from SQLite data
  static String buildPatientContext(
    UserProfileModel? profile,
    List<VitalModel> recentVitals,
    List<MedicineModel> activeMedicines,
  ) {
    final b = StringBuffer();
    if (profile != null) {
      if (profile.conditions?.isNotEmpty == true) {
        b.writeln('Conditions: ${profile.conditions}');
      }
      if (profile.allergies?.isNotEmpty == true) {
        b.writeln('Allergies: ${profile.allergies}');
      }
      if (profile.bloodGroup?.isNotEmpty == true) {
        b.writeln('Blood group: ${profile.bloodGroup}');
      }
    }
    if (activeMedicines.isNotEmpty) {
      b.writeln('Current medicines: ${activeMedicines.map((m) => m.name).join(", ")}');
    }
    if (recentVitals.isNotEmpty) {
      final v = recentVitals.first;
      b.writeln('Latest vitals: BP ${v.systolic}/${v.diastolic} mmHg, '
          'Sugar ${v.bloodGlucose} mg/dL, Temp ${v.temperature}°C');
    }
    return b.isEmpty ? 'No medical profile on file.' : b.toString();
  }
}
