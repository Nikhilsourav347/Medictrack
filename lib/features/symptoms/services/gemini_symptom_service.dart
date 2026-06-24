// lib/features/symptoms/services/gemini_symptom_service.dart

import 'dart:convert';
import 'dart:typed_data';
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
  Future<SymptomAnalysis> analyzeSymptom({
    String? voiceDescription,
    String? textDescription,
    Uint8List? imageBytes,
    required String patientContext,
  }) async {
    const String apiKey = "gen-lang-client-0568525969";
    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey");

    final List<Map<String, dynamic>> parts = [];

    // 1. Always first — the system instruction
    parts.add({
      "text": "You are a medical first-aid assistant in a personal health app. You receive a patient's medical profile, their symptom description, and optionally a photo of their wound, rash, eye, or skin issue. Analyze everything together. Consider their existing medical conditions and current medicines when giving advice — for example if they are diabetic, treat any wound as higher risk. Do NOT use rigid categories — reason naturally based on what you observe.\n\nStructure your response exactly like this with no extra text outside these labels:\n\nASSESSMENT: Describe what you see or understand from the image and description in 2 sentences.\n\nSEVERITY: One word only — MINOR or MODERATE or SERIOUS or EMERGENCY\n\nADVICE: Give 3 to 5 specific steps the patient should do right now. Be specific to what you see — for wounds mention cleaning, ointment, dressing, signs of infection. For rash mention triggers, topical relief. For eye issues mention rinsing. Number each step.\n\nMEDICINES: Name a specific safe over-the-counter medicine if appropriate. If their allergies or conditions make it unsafe, explain why and say what to avoid. If prescription is needed, say so clearly.\n\nWATCH_FOR: List 2 to 3 warning signs that mean they must go to a hospital immediately.\n\nVOICE_SUMMARY: Write exactly 2 sentences in plain simple language summarizing the advice. No medical jargon. This will be read aloud to the patient.\n\nNever diagnose. Always recommend professional care for anything beyond minor issues."
    });

    // 2. Always — patientContext string
    parts.add({"text": patientContext});

    // 3. If voiceDescription not empty — add it as text part
    if (voiceDescription != null && voiceDescription.isNotEmpty) {
      parts.add({"text": "Voice Description of Symptom: $voiceDescription"});
    }

    // 4. If textDescription not empty — add it as text part
    if (textDescription != null && textDescription.isNotEmpty) {
      parts.add({"text": "Text Description of Symptom: $textDescription"});
    }

    // 5. If imageBytes not null — add as inlineData
    if (imageBytes != null) {
      parts.add({
        "inlineData": {
          "mimeType": "image/jpeg",
          "data": base64Encode(imageBytes)
        }
      });
    }

    final body = {
      "contents": [
        {"parts": parts}
      ]
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("Gemini API call failed with status: ${response.statusCode}");
    }

    final jsonResponse = jsonDecode(response.body);
    final String responseText = jsonResponse['candidates'][0]['content']['parts'][0]['text'] ?? '';
    
    return parseResponse(responseText);
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

  static String buildPatientContext(
    UserProfileModel? profile,
    List<VitalModel> recentVitals,
    List<MedicineModel> activeMedicines,
  ) {
    final buffer = StringBuffer();
    buffer.writeln("Patient Profile Context:");
    if (profile != null) {
      buffer.writeln("- Name: ${profile.name}");
      buffer.writeln("- Age: ${profile.age ?? 'Unknown'}");
      buffer.writeln("- Blood Group: ${profile.bloodGroup ?? 'Unknown'}");
      buffer.writeln("- Existing Conditions: ${profile.conditions ?? 'None stated'}");
      buffer.writeln("- Allergies: ${profile.allergies ?? 'None stated'}");
    } else {
      buffer.writeln("- Name: Guest");
      buffer.writeln("- Age: Unknown");
      buffer.writeln("- Blood Group: Unknown");
      buffer.writeln("- Existing Conditions: None stated");
      buffer.writeln("- Allergies: None stated");
    }

    buffer.writeln("\nCurrent Medicines:");
    if (activeMedicines.isEmpty) {
      buffer.writeln("- None active");
    } else {
      for (var med in activeMedicines) {
        buffer.writeln("- ${med.name} (${med.dosage ?? 'No dose specified'}), Frequency: ${med.frequency}");
      }
    }

    buffer.writeln("\nRecent Vitals Readings:");
    if (recentVitals.isEmpty) {
      buffer.writeln("- No recent vitals available");
    } else {
      // Find most recent blood pressure and sugar reading
      VitalModel? latestBp;
      for (var v in recentVitals) {
        if (v.systolic != null && v.diastolic != null) {
          latestBp = v;
          break;
        }
      }
      
      VitalModel? latestSugar;
      for (var v in recentVitals) {
        if (v.bloodGlucose != null) {
          latestSugar = v;
          break;
        }
      }

      if (latestBp != null) {
        buffer.writeln("- Most Recent BP: ${latestBp.systolic!.toInt()}/${latestBp.diastolic!.toInt()} mmHg (recorded at: ${latestBp.recordedAt})");
      } else {
        buffer.writeln("- Most Recent BP: N/A");
      }

      if (latestSugar != null) {
        final sugarNote = latestSugar.notes ?? '';
        buffer.writeln("- Most Recent Blood Sugar: ${latestSugar.bloodGlucose} mg/dL ($sugarNote) (recorded at: ${latestSugar.recordedAt})");
      } else {
        buffer.writeln("- Most Recent Blood Sugar: N/A");
      }
    }

    return buffer.toString();
  }
}
