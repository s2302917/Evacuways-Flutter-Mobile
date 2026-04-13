import 'package:shared_preferences/shared_preferences.dart';

/// StorageService handles local data persistence
class StorageService {
  static final StorageService _instance = StorageService._internal();
  late SharedPreferences _prefs;

  StorageService._internal();

  // Singleton pattern
  factory StorageService() {
    return _instance;
  }

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // String operations
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  // Integer operations
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Boolean operations
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Double operations
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  // List operations
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  // General remove
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // Clear all
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  // Check if key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // User-specific methods
  Future<void> saveUserSession(int userId, String token) async {
    await setInt('user_id', userId);
    await setString('auth_token', token);
  }

  void clearUserSession() async {
    await remove('user_id');
    await remove('auth_token');
  }

  int? getUserId() {
    return getInt('user_id');
  }

  String? getAuthToken() {
    return getString('auth_token');
  }

  bool isUserLoggedIn() {
    return containsKey('user_id') && containsKey('auth_token');
  }
}
