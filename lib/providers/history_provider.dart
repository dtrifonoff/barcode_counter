import 'package:flutter/foundation.dart';
import '../models/scanning_session.dart';
import '../services/database_service.dart';

class HistoryProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  List<ScanningSession> _sessions = [];
  bool _isLoading = false;

  List<ScanningSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  bool get hasSessions => _sessions.isNotEmpty;

  /// Load all sessions from database
  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _dbService.getAllSessions();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a session
  Future<void> deleteSession(int sessionId) async {
    try {
      await _dbService.deleteSession(sessionId);
      _sessions.removeWhere((session) => session.id == sessionId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting session: $e');
      rethrow;
    }
  }

  /// Delete all sessions
  Future<void> deleteAllSessions() async {
    try {
      // Delete each session individually
      for (var session in _sessions) {
        if (session.id != null) {
          await _dbService.deleteSession(session.id!);
        }
      }
      _sessions.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting all sessions: $e');
      rethrow;
    }
  }

  /// Get session by ID
  ScanningSession? getSessionById(int sessionId) {
    try {
      return _sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  /// Refresh sessions (used after completing a new session)
  Future<void> refresh() async {
    await loadSessions();
  }
}
