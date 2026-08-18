class BarcodeItem {
  final int? id;
  final String barcode;
  final int quantity;
  final DateTime timestamp;
  final int sessionId;

  BarcodeItem({
    this.id,
    required this.barcode,
    required this.quantity,
    required this.timestamp,
    required this.sessionId,
  });

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'quantity': quantity,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'session_id': sessionId,
    };
  }

  // Create from Map (SQLite result)
  factory BarcodeItem.fromMap(Map<String, dynamic> map) {
    return BarcodeItem(
      id: map['id'] as int?,
      barcode: map['barcode'] as String,
      quantity: map['quantity'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      sessionId: map['session_id'] as int,
    );
  }

  // Create copy with updated fields
  BarcodeItem copyWith({
    int? id,
    String? barcode,
    int? quantity,
    DateTime? timestamp,
    int? sessionId,
  }) {
    return BarcodeItem(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  String toString() {
    return 'BarcodeItem(id: $id, barcode: $barcode, quantity: $quantity, sessionId: $sessionId)';
  }
}
