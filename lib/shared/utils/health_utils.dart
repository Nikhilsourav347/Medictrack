import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

enum VitalStatus { normal, borderline, critical, unknown }

class HealthUtils {
  /// Returns color based on vital status
  static Color statusColor(VitalStatus status) {
    switch (status) {
      case VitalStatus.normal:
        return const Color(AppConstants.primaryGreenValue);
      case VitalStatus.borderline:
        return const Color(AppConstants.borderlineAmberValue);
      case VitalStatus.critical:
        return const Color(AppConstants.criticalRedValue);
      case VitalStatus.unknown:
        return Colors.grey;
    }
  }

  /// Returns icon based on vital status
  static IconData statusIcon(VitalStatus status) {
    switch (status) {
      case VitalStatus.normal:
        return Icons.check_circle_outline;
      case VitalStatus.borderline:
        return Icons.warning_amber_outlined;
      case VitalStatus.critical:
        return Icons.error_outline;
      case VitalStatus.unknown:
        return Icons.help_outline;
    }
  }

  /// Evaluates blood pressure status
  static VitalStatus bloodPressureStatus(double systolic, double diastolic) {
    if (systolic > 180 || diastolic > 120) return VitalStatus.critical;
    if (systolic > 140 || diastolic > 90) return VitalStatus.borderline;
    if (systolic < 90 || diastolic < 60) return VitalStatus.borderline;
    return VitalStatus.normal;
  }

  /// Evaluates blood pressure status as a string ('normal', 'borderline', 'critical')
  static String bpStatus(num systolic, num diastolic) {
    final s = systolic.toDouble();
    final d = diastolic.toDouble();
    if (s > 180 || d > 120) return 'critical';
    if (s > 140 || d > 90) return 'critical';
    if (s < 90 || d < 60) return 'borderline';
    if (s > 120 || d > 80) return 'borderline';
    return 'normal';
  }

  /// Evaluates SpO2 status as a string ('normal', 'borderline', 'critical')
  static String spo2Status(num spo2) {
    final v = spo2.toDouble();
    if (v < 90) return 'critical';
    if (v < 95) return 'borderline';
    return 'normal';
  }

  /// Evaluates temperature status (Celsius) as a string ('normal', 'borderline', 'critical')
  static String tempStatus(num temp) {
    final t = temp.toDouble();
    if (t > 39.5 || t < 35.0) return 'critical';
    if (t > 37.5 || t < 36.1) return 'borderline';
    return 'normal';
  }

  /// Evaluates blood sugar status as a string ('normal', 'borderline', 'critical')
  static String sugarStatus(num value, String type) {
    final v = value.toDouble();
    if (type == 'fasting') {
      if (v >= 126) return 'critical';
      if (v >= 100) return 'borderline';
      return 'normal';
    } else {
      if (v >= 200) return 'critical';
      if (v >= 140) return 'borderline';
      return 'normal';
    }
  }


  /// Evaluates heart rate status
  static VitalStatus heartRateStatus(double bpm) {
    if (bpm < 40 || bpm > 150) return VitalStatus.critical;
    if (bpm < 60 || bpm > 100) return VitalStatus.borderline;
    return VitalStatus.normal;
  }

  /// Evaluates SpO2 status
  static VitalStatus oxygenStatus(double spo2) {
    if (spo2 < 90) return VitalStatus.critical;
    if (spo2 < 95) return VitalStatus.borderline;
    return VitalStatus.normal;
  }

  /// Evaluates temperature status (Celsius)
  static VitalStatus temperatureStatus(double tempC) {
    if (tempC > 39.5 || tempC < 35.0) return VitalStatus.critical;
    if (tempC > 37.5 || tempC < 36.1) return VitalStatus.borderline;
    return VitalStatus.normal;
  }

  /// Evaluates blood glucose (mg/dL)
  static VitalStatus glucoseStatus(double glucose) {
    if (glucose < 54 || glucose > 300) return VitalStatus.critical;
    if (glucose < 70 || glucose > 140) return VitalStatus.borderline;
    return VitalStatus.normal;
  }

  /// Severity color for symptoms (1-10)
  static Color severityColor(int severity) {
    if (severity <= 3) return const Color(AppConstants.primaryGreenValue);
    if (severity <= 6) return const Color(AppConstants.borderlineAmberValue);
    return const Color(AppConstants.criticalRedValue);
  }

  /// BMI calculation
  static double bmi(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// BMI label
  static String bmiLabel(double bmiValue) {
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25.0) return 'Normal';
    if (bmiValue < 30.0) return 'Overweight';
    return 'Obese';
  }
}

