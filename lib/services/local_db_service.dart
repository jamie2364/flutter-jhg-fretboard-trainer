import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  static final SharedPrefHelper instance = SharedPrefHelper._init();
  static SharedPreferences? _prefs;

  SharedPrefHelper._init();

  Future<SharedPreferences> get preferences async {
    _prefs ??= await _initPrefs();
    return _prefs!;
  }

  Future<SharedPreferences> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  // Keys
  static const String defaultTimerTypeKey = 'defaultTimerTypeKey';
  static const String defaultTimerIntervalKey = 'defaultTimerIntervalKey';
  static const String defaultTimerMinutesKey = 'defaultTimerMinutesKey';
  static const String string1Key = 'string1';
  static const String string2Key = 'string2';
  static const String string3Key = 'string3';
  static const String string4Key = 'string4';
  static const String string5Key = 'string5';
  static const String string6Key = 'string6';

  // Timer type operations
  Future<bool> storeDefaultTimerType(String value) async {
    final prefs = await preferences;
    return await prefs.setString(defaultTimerTypeKey, value);
  }

  Future<String?> getDefaultTimerType() async {
    final prefs = await preferences;
    final value = prefs.getString(defaultTimerTypeKey);
    return value;
  }

  // Timer minutes operations
  Future<bool> storeDefaultTimerMinutes(int value) async {
    final prefs = await preferences;
    return await prefs.setInt(defaultTimerMinutesKey, value);
  }

  Future<int> getDefaultTimerMinutes() async {
    final prefs = await preferences;
    final value = prefs.getInt(defaultTimerMinutesKey) ?? 2;
    return value;
  }

  // Timer interval operations
  Future<bool> storeTimerInterval(int value) async {
    final prefs = await preferences;
    return await prefs.setInt(defaultTimerIntervalKey, value);
  }

  Future<int> getTimerInterval() async {
    final prefs = await preferences;
    final value = prefs.getInt(defaultTimerIntervalKey) ?? 1;
    return value;
  }

  Future<void> saveStrings(bool string1, bool string2, bool string3,
      bool string4, bool string5, bool string6) async {
    final prefs = await preferences;
    await prefs.setBool(string1Key, string1);
    await prefs.setBool(string2Key, string2);
    await prefs.setBool(string3Key, string3);
    await prefs.setBool(string4Key, string4);
    await prefs.setBool(string5Key, string5);
    await prefs.setBool(string6Key, string6);
  }

  // Clear all preferences
  Future<bool> clearAll() async {
    final prefs = await preferences;
    return await prefs.clear();
  }

  Future<bool> getString1() async {
    final prefs = await preferences;
    return prefs.getBool(string1Key) ?? true;
  }

  Future<bool> getString2() async {
    final prefs = await preferences;
    return prefs.getBool(string2Key) ?? true;
  }

  Future<bool> getString3() async {
    final prefs = await preferences;
    return prefs.getBool(string3Key) ?? true;
  }

  Future<bool> getString4() async {
    final prefs = await preferences;
    return prefs.getBool(string4Key) ?? true;
  }

  Future<bool> getString5() async {
    final prefs = await preferences;
    return prefs.getBool(string5Key) ?? true;
  }

  Future<bool> getString6() async {
    final prefs = await preferences;
    return prefs.getBool(string6Key) ?? true;
  }
}
