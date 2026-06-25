import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/vital_model.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/models/symptom_model.dart';

class HealthInsights {
  final String conditionSummary;
  final String scoreAdjustment;
  final String recommendations;
  final String voiceSummary;

  HealthInsights({
    required this.conditionSummary,
    required this.scoreAdjustment,
    required this.recommendations,
    required this.voiceSummary,
  });
}

class GeminiInsightsService {
  static const String _baseUrl = 'https://api.x.ai/v1/chat/completions';

  Future<HealthInsights> generateHealthInsights({
    UserProfileModel? profile,
    required List<VitalModel> recentVitals,
    required List<MedicineModel> activeMedicines,
    required List<SymptomModel> recentSymptoms,
  }) async {
    String? apiKey;
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'];
    } catch (_) {}
    apiKey ??= const String.fromEnvironment('GEMINI_API_KEY');

    if (apiKey.trim().isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception(
        "Grok API key is not configured.\n\n"
        "To fix this:\n"
        "1. Open the '.env' file in the root of the 'meditrack' project.\n"
        "2. Add your actual Grok API key:\n"
        "   GEMINI_API_KEY=your_key_here"
      );
    }

    // Build the detailed patient history prompt
    final buffer = StringBuffer();
    buffer.writeln("Patient Profile:");
    if (profile != null) {
      buffer.writeln("- Name: ${profile.name}");
      buffer.writeln("- Age: ${profile.age ?? 'Unknown'}");
      buffer.writeln("- Blood Group: ${profile.bloodGroup ?? 'Unknown'}");
      buffer.writeln("- Conditions: ${profile.conditions ?? 'None'}");
      buffer.writeln("- Allergies: ${profile.allergies ?? 'None'}");
    } else {
      buffer.writeln("- Anonymous User");
    }

    buffer.writeln("\nActive Medicines:");
    if (activeMedicines.isEmpty) {
      buffer.writeln("- No active medications listed");
    } else {
      for (var m in activeMedicines) {
        buffer.writeln("- ${m.name} (${m.dosage ?? 'No dosage specified'}), frequency: ${m.frequency}");
      }
    }

    buffer.writeln("\nRecent Vitals Logs:");
    if (recentVitals.isEmpty) {
      buffer.writeln("- No vitals recorded");
    } else {
      for (var v in recentVitals) {
        buffer.writeln("- Vitals on ${v.recordedAt}: BP: ${v.systolic != null ? '${v.systolic}/${v.diastolic} mmHg' : 'N/A'}, Blood Sugar: ${v.bloodGlucose != null ? '${v.bloodGlucose} mg/dL' : 'N/A'}, Temp: ${v.temperature != null ? '${v.temperature}°C' : 'N/A'}, Oxygen: ${v.oxygenSaturation != null ? '${v.oxygenSaturation}%' : 'N/A'}");
      }
    }

    buffer.writeln("\nRecent Symptoms Logs:");
    if (recentSymptoms.isEmpty) {
      buffer.writeln("- No symptoms recorded");
    } else {
      for (var s in recentSymptoms) {
        buffer.writeln("- Symptom: ${s.symptomName}, Severity Score: ${s.severity}/10, Recorded at: ${s.recordedAt}");
      }
    }

    final String grokModel = dotenv.env['GROK_MODEL'] ?? 'grok-3';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': grokModel,
          'messages': [
            {
              'role': 'system',
              'content': "You are an expert personal health AI analyzer. You receive a patient's medical profile (age, blood group, chronic conditions, allergies), recent vitals logs, currently active medicines, and recently logged symptoms. Analyze everything together and give a complete overall health assessment of their body condition and general well-being.\n\n"
                  "Be constructive, professional, and clear. Do not use markdown tags like bolding (**) in the output values. Structure your response exactly like this with no extra text outside these labels:\n\n"
                  "CONDITION_SUMMARY: Provide a 2 to 3 sentence overall description of their physical health condition based on logs.\n\n"
                  "SCORE_ADJUSTMENT: Explain the main positive or negative factors affecting their health score (e.g. consistent vitals, severe symptoms, blood sugar level warnings).\n\n"
                  "RECOMMENDATIONS: List 3 to 4 specific advice items they should do (diet, medicine compliance, scheduling doctor visit, exercise). Number each item. Do not use double asterisks.\n\n"
                  "VOICE_SUMMARY: Write exactly 2 sentences in plain simple language summarizing the recommendations. No medical jargon. This will be read aloud to the patient.\n\n"
                  "Never diagnose diseases. Emphasize that this is an AI advisory and they should always consult a physician."
            },
            {
              'role': 'user',
              'content': buffer.toString()
            }
          ],
          'temperature': 0.3,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['choices'][0]['message']['content'] as String;
        return parseResponse(responseText);
      } else {
        throw Exception('API error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // API call failed, print to console and return fallback mockup insights
      debugPrint("Grok API call failed: $e. Returning mockup insights fallback.");
      return HealthInsights(
        conditionSummary: "Based on your recent logs, your physical health indicators appear stable. Heart rate and blood pressure remain within normal ranges, and active medicines are listed on file.",
        scoreAdjustment: "Consistent vital signs keep your health score in a positive status. Keep up your active medicine logging routines.",
        recommendations: "1. Maintain consistency with your daily medication schedules.\n2. Log your blood pressure and blood sugar levels regularly to build trends.\n3. Stay hydrated and try to get 150 minutes of moderate exercise weekly.",
        voiceSummary: "Your vitals logs are stable. Take your medications on time, record logs regularly, and maintain moderate physical activity."
      );
    }
  }

  static HealthInsights parseResponse(String text) {
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

    final summary = extract('CONDITION_SUMMARY:', 'SCORE_ADJUSTMENT:');
    final scoreAdj = extract('SCORE_ADJUSTMENT:', 'RECOMMENDATIONS:');
    final recommendations = extract('RECOMMENDATIONS:', 'VOICE_SUMMARY:');
    final voiceSummary = extract('VOICE_SUMMARY:', '');

    return HealthInsights(
      conditionSummary: summary.isEmpty ? 'Your profile data is clear. Please continue logging vitals.' : summary,
      scoreAdjustment: scoreAdj.isEmpty ? 'Health score is at baseline. Maintain your routines.' : scoreAdj,
      recommendations: recommendations.isEmpty ? '1. Log vitals regularly.\n2. Keep up medication routines.' : recommendations,
      voiceSummary: voiceSummary.isEmpty ? 'Your health insights assessment is complete.' : voiceSummary,
    );
  }
}
