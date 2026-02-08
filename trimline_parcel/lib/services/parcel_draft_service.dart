import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/parcel_form_constants.dart';

/// Service for auto-saving and restoring parcel form drafts
class ParcelDraftService {
  static const String _draftKey = ParcelFormConstants.draftStorageKey;
  static const String _timestampKey = ParcelFormConstants.draftTimestampKey;

  /// Saves current form state as a draft
  static Future<bool> saveDraft(Map<String, dynamic> formData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(formData);
      final timestamp = DateTime.now().toIso8601String();

      await prefs.setString(_draftKey, jsonString);
      await prefs.setString(_timestampKey, timestamp);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Loads the most recent draft
  static Future<Map<String, dynamic>?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_draftKey);

      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Gets the timestamp of the last saved draft
  static Future<DateTime?> getDraftTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_timestampKey);

      if (timestamp == null) return null;

      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Checks if a draft exists
  static Future<bool> hasDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_draftKey);
  }

  /// Clears the saved draft
  static Future<bool> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
      await prefs.remove(_timestampKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the draft is older than the specified duration
  static Future<bool> isDraftStale(Duration staleDuration) async {
    final timestamp = await getDraftTimestamp();
    if (timestamp == null) return true;

    return DateTime.now().difference(timestamp) > staleDuration;
  }
}
