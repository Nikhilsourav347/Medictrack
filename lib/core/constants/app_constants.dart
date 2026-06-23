class AppConstants {
  // Brand colors (mirrors AppTheme for use outside widget tree)
  static const int primaryGreenValue = 0xFF1D9E75;
  static const int criticalRedValue = 0xFFE53935;
  static const int borderlineAmberValue = 0xFFFFC107;

  // Vital normal ranges
  static const Map<String, Map<String, double>> vitalRanges = {
    'systolic': {'min': 90, 'max': 120},
    'diastolic': {'min': 60, 'max': 80},
    'heartRate': {'min': 60, 'max': 100},
    'temperature': {'min': 36.1, 'max': 37.2},
    'oxygenSaturation': {'min': 95, 'max': 100},
    'bloodGlucose': {'min': 70, 'max': 140},
    'weight': {'min': 0, 'max': 9999},
  };

  // Blood groups
  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  // Medicine frequency options
  static const List<String> frequencyOptions = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every 6 hours',
    'Every 8 hours',
    'Every 12 hours',
    'Once weekly',
    'As needed',
  ];

  // Symptom severity labels (1-10)
  static const Map<int, String> severityLabels = {
    1: 'Minimal',
    2: 'Very Mild',
    3: 'Mild',
    4: 'Mild-Moderate',
    5: 'Moderate',
    6: 'Moderate-Severe',
    7: 'Severe',
    8: 'Very Severe',
    9: 'Extreme',
    10: 'Unbearable',
  };

  static String getSeverityLabel(int severity) {
    return severityLabels[severity] ?? 'Unknown';
  }
}
