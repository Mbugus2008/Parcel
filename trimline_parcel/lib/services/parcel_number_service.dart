import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import 'auth_service.dart';

/// Service for generating unique parcel numbers
///
/// Parcel numbers follow the format: TLP-YYMMDD-XXX-NNNN (max 20 chars)
/// where:
/// - TLP: Trimline Parcel prefix (3 chars)
/// - YYMMDD: Date in year-month-day format (6 chars)
/// - XXX: First 3 chars of agent code (3 chars)
/// - NNNN: 4-digit sequential number (0001-9999) per agent per day
///
/// Example: TLP-251125-ADM-0001 (19 characters)
class ParcelNumberService extends GetxService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Generate the next parcel number for the current user
  ///
  /// Returns a unique parcel number in format: TLP-YYMMDD-AGENTCODE-NNNN
  ///
  /// Throws [Exception] if no user is logged in or user has no agent code
  Future<String> getNextParcelNumber() async {
    // Get current logged-in user
    final authService = Get.find<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      throw Exception('No user logged in. Cannot generate parcel number.');
    }

    // Get agent code, truncate to 3 chars for 20-char limit
    final fullAgentCode = user.agentCode ?? 'UNK';
    final agentCode = fullAgentCode.length > 3
        ? fullAgentCode.substring(0, 3).toUpperCase()
        : fullAgentCode.toUpperCase();

    // Get today's date in YYMMDD format
    final today = DateFormat('yyMMdd').format(DateTime.now());

    // Get next sequence number from database
    final sequenceNumber =
        await _dbHelper.getNextSequenceNumber(agentCode, today);

    // Format the parcel number
    final parcelNumber = _formatParcelNumber(today, agentCode, sequenceNumber);

    if (kDebugMode) {
      debugPrint('📦 Generated parcel number: $parcelNumber');
      debugPrint('   Agent: ${user.name} ($agentCode)');
      debugPrint('   Date: $today');
      debugPrint('   Sequence: $sequenceNumber');
    }

    return parcelNumber;
  }

  /// Preview what the next parcel number would be without incrementing the counter
  ///
  /// Useful for displaying in UI before the parcel is actually created
  Future<String> previewNextParcelNumber() async {
    // Get current logged-in user
    final authService = Get.find<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return 'TLP-XXXXXX-XXX-0000'; // Placeholder when no user
    }

    // Truncate agent code to 3 chars for 20-char limit
    final fullAgentCode = user.agentCode ?? 'UNK';
    final agentCode = fullAgentCode.length > 3
        ? fullAgentCode.substring(0, 3).toUpperCase()
        : fullAgentCode.toUpperCase();
    final today = DateFormat('yyMMdd').format(DateTime.now());

    // Get current counter (without incrementing)
    final currentCounter =
        await _dbHelper.getCurrentSequenceNumber(agentCode, today);
    final nextCounter = currentCounter + 1;

    return _formatParcelNumber(today, agentCode, nextCounter);
  }

  /// Format the parcel number string
  String _formatParcelNumber(String date, String agentCode, int sequence) {
    final paddedSequence = sequence.toString().padLeft(4, '0');
    return 'TLP-$date-$agentCode-$paddedSequence';
  }

  /// Parse a parcel number to extract its components
  ///
  /// Returns a map with keys: date, agentCode, sequence
  /// Returns null if the format is invalid
  Map<String, dynamic>? parseParcelNumber(String parcelNumber) {
    // Expected format: TLP-YYMMDD-XXX-NNNN (max 20 chars)
    final regex = RegExp(r'^TLP-(\d{6})-([A-Z0-9]{1,3})-(\d{4})$');
    final match = regex.firstMatch(parcelNumber);

    if (match == null) {
      return null;
    }

    return {
      'date': match.group(1),
      'agentCode': match.group(2),
      'sequence': int.parse(match.group(3)!),
    };
  }

  /// Check if a parcel number follows the valid format
  bool isValidParcelNumber(String parcelNumber) {
    return parseParcelNumber(parcelNumber) != null;
  }

  /// Get statistics for parcel numbers created today
  Future<Map<String, dynamic>> getTodayStatistics() async {
    final authService = Get.find<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return {'error': 'No user logged in'};
    }

    final agentCode = user.agentCode ?? 'UNK';
    final today = DateFormat('yyMMdd').format(DateTime.now());

    final currentCounter =
        await _dbHelper.getCurrentSequenceNumber(agentCode, today);

    return {
      'agentCode': agentCode,
      'date': today,
      'parcelsCreatedToday': currentCounter,
      'nextSequence': currentCounter + 1,
    };
  }
}
