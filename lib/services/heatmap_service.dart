import 'package:shared_preferences/shared_preferences.dart';

class FretStats {
  final int attempts;
  final int correct;

  const FretStats({required this.attempts, required this.correct});

  bool get hasData => attempts > 0;
  double get accuracy => attempts == 0 ? 0.0 : correct / attempts;
}

class HeatmapService {
  static const String _attPrefix = 'hm_att_';
  static const String _corPrefix = 'hm_cor_';
  static const int _fretCount = 96;

  static Future<void> recordAttempt(int fretIndex, bool correct) async {
    if (fretIndex < 0 || fretIndex >= _fretCount) return;
    final prefs = await SharedPreferences.getInstance();
    final attKey = '$_attPrefix$fretIndex';
    final corKey = '$_corPrefix$fretIndex';
    final att = (prefs.getInt(attKey) ?? 0) + 1;
    final cor = (prefs.getInt(corKey) ?? 0) + (correct ? 1 : 0);
    await prefs.setInt(attKey, att);
    await prefs.setInt(corKey, cor);
  }

  static Future<Map<int, FretStats>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <int, FretStats>{};
    for (int i = 0; i < _fretCount; i++) {
      final att = prefs.getInt('$_attPrefix$i') ?? 0;
      final cor = prefs.getInt('$_corPrefix$i') ?? 0;
      result[i] = FretStats(attempts: att, correct: cor);
    }
    return result;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _fretCount; i++) {
      await prefs.remove('$_attPrefix$i');
      await prefs.remove('$_corPrefix$i');
    }
  }
}
