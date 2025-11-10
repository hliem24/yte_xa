// lib/src/services/settings_repo.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepo {
  static const _kNoKey = 'ai.no_key_mode';
  static const _kBase  = 'ai.base_url';
  static const _kModel = 'ai.model';
  static const _kKey   = 'ai.api_key';

  Future<void> setNoKeyMode(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kNoKey, v);
  }

  Future<bool> getNoKeyMode() async {
    final sp = await SharedPreferences.getInstance();
    // Mặc định bật "No-Key" (dành cho Ollama)
    return sp.getBool(_kNoKey) ?? true;
  }

  Future<void> setBaseUrl(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kBase, v);
  }

  Future<String> getBaseUrl() async {
    final sp = await SharedPreferences.getInstance();
    // Android emulator -> máy tính host
    return sp.getString(_kBase) ?? 'http://10.0.2.2:11434';
  }

  Future<void> setModel(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kModel, v);
  }

  Future<String> getModel() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kModel) ?? 'llama3.2';
  }

  Future<void> setApiKey(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kKey, v);
  }

  Future<String> getApiKey() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kKey) ?? '';
  }
}
