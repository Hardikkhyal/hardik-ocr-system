import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/ocr/models/scan_result.dart';

class LocalDatabase {
  static const String _scansBoxName = 'ocr_scans_box';
  static const String _settingsBoxName = 'ocr_settings_box';
  static const String _themeKey = 'theme_mode';

  late Box _scansBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _scansBox = await Hive.openBox(_scansBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // --- Scan History Operations ---

  List<ScanResult> getScans() {
    final List<ScanResult> results = [];
    for (var key in _scansBox.keys) {
      final value = _scansBox.get(key);
      if (value != null) {
        try {
          // If stored as JSON map/string, parse it
          final Map<String, dynamic> map = Map<String, dynamic>.from(value);
          results.add(ScanResult.fromJson(map));
        } catch (e) {
          // Ignore corrupt entries
          print('Error loading scan: $e');
        }
      }
    }
    // Sort by timestamp descending (newest first)
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  Future<void> saveScan(ScanResult scan) async {
    await _scansBox.put(scan.id, scan.toJson());
  }

  Future<void> deleteScan(String id) async {
    await _scansBox.delete(id);
  }

  Future<void> clearHistory() async {
    await _scansBox.clear();
  }

  // --- Theme Mode Operations ---

  String getThemeMode() {
    return _settingsBox.get(_themeKey, defaultValue: 'system') as String;
  }

  Future<void> saveThemeMode(String mode) async {
    await _settingsBox.put(_themeKey, mode);
  }
}
