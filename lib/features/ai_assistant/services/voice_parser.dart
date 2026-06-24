// lib/features/ai_assistant/services/voice_parser.dart

class VoiceParser {
  static int? extractFirstInt(String text) {
    final cleaned = text.toLowerCase()
      .replaceAll('one', '1').replaceAll('two', '2').replaceAll('three', '3')
      .replaceAll('four', '4').replaceAll('five', '5').replaceAll('six', '6')
      .replaceAll('seven', '7').replaceAll('eight', '8').replaceAll('nine', '9')
      .replaceAll('ten', '10').replaceAll('zero', '0').replaceAll('hundred', '00');
    final match = RegExp(r'\d+').firstMatch(cleaned);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  static double? extractFirstDouble(String text) {
    final cleaned = text.replaceAll('point', '.').replaceAll('dot', '.');
    final match = RegExp(r'\d+\.?\d*').firstMatch(cleaned);
    return match != null ? double.tryParse(match.group(0)!) : null;
  }

  static List<int> extractTwoInts(String text) {
    final cleaned = text.replaceAll('over', ' ').replaceAll('by', ' ').replaceAll('slash', ' ');
    final matches = RegExp(r'\d+').allMatches(cleaned);
    final nums = matches.map((m) => int.parse(m.group(0)!)).toList();
    return nums.length >= 2 ? [nums[0], nums[1]] : [];
  }

  static bool isFasting(String text) {
    return text.toLowerCase().contains('fasting') || text.toLowerCase().contains('empty');
  }
}
