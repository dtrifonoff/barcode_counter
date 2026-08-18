import 'package:flutter/foundation.dart';
import '../models/barcode_item.dart';
import '../models/scanning_session.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class SessionProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  ScanningSession? _currentSession;
  bool _isLoading = false;

  ScanningSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  bool get hasActiveSession => _currentSession != null;
  List<BarcodeItem> get currentItems => _currentSession?.items ?? [];

  /// Create a new session
  Future<void> createNewSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');
      final sessionName = 'Заявка ${dateFormatter.format(DateTime.now())}';
      
      final newSession = ScanningSession(
        name: sessionName,
        createdDate: DateTime.now(),
      );

      final sessionId = await _dbService.createSession(newSession);
      _currentSession = newSession.copyWith(id: sessionId);
    } catch (e) {
      debugPrint('Error creating session: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load existing session by ID
  Future<void> loadSession(int sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentSession = await _dbService.getSession(sessionId);
    } catch (e) {
      debugPrint('Error loading session: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add item to current session
  Future<void> addItem(String barcode, int quantity) async {
    if (_currentSession == null) {
      throw Exception('No active session');
    }

    try {
      final newItem = BarcodeItem(
        barcode: barcode,
        quantity: quantity,
        timestamp: DateTime.now(),
        sessionId: _currentSession!.id!,
      );

      final itemId = await _dbService.addItem(newItem);
      final itemWithId = newItem.copyWith(id: itemId);

      // Update current session items list
      final updatedItems = [..._currentSession!.items, itemWithId];
      _currentSession = _currentSession!.copyWith(items: updatedItems);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding item: $e');
      rethrow;
    }
  }

  /// Update item quantity
  Future<void> updateItemQuantity(int itemId, int newQuantity) async {
    if (_currentSession == null) return;

    try {
      await _dbService.updateItemQuantity(itemId, newQuantity);

      // Update local state
      final updatedItems = _currentSession!.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(quantity: newQuantity);
        }
        return item;
      }).toList();

      _currentSession = _currentSession!.copyWith(items: updatedItems);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating item quantity: $e');
      rethrow;
    }
  }

  /// Delete item from session
  Future<void> deleteItem(int itemId) async {
    if (_currentSession == null) return;

    try {
      await _dbService.deleteItem(itemId);

      // Update local state
      final updatedItems = _currentSession!.items
          .where((item) => item.id != itemId)
          .toList();

      _currentSession = _currentSession!.copyWith(items: updatedItems);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting item: $e');
      rethrow;
    }
  }

  /// Update session notes
  Future<void> updateSessionNotes(String notes) async {
    if (_currentSession == null) return;

    try {
      final updatedSession = _currentSession!.copyWith(notes: notes);
      await _dbService.updateSession(updatedSession);
      
      _currentSession = updatedSession;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating session notes: $e');
      rethrow;
    }
  }

  /// Complete current session (keeps it in database but clears from memory)
  Future<void> completeSession() async {
    _currentSession = null;
    notifyListeners();
  }

  /// Clear current session (used when starting fresh)
  void clearCurrentSession() {
    _currentSession = null;
    notifyListeners();
  }
}
