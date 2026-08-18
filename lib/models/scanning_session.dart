import 'barcode_item.dart';

class ScanningSession {
  final int? id;
  final String name;
  final DateTime createdDate;
  final String notes;
  final List<BarcodeItem> items;

  ScanningSession({
    this.id,
    required this.name,
    required this.createdDate,
    this.notes = '',
    List<BarcodeItem>? items,
  }) : items = items ?? [];

  // Convert to Map for SQLite (without items)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdDate.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  // Create from Map (SQLite result, without items)
  factory ScanningSession.fromMap(Map<String, dynamic> map) {
    return ScanningSession(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      notes: map['notes'] as String? ?? '',
    );
  }

  // Create copy with updated fields
  ScanningSession copyWith({
    int? id,
    String? name,
    DateTime? createdDate,
    String? notes,
    List<BarcodeItem>? items,
  }) {
    return ScanningSession(
      id: id ?? this.id,
      name: name ?? this.name,
      createdDate: createdDate ?? this.createdDate,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }

  // Get total item count
  int get itemCount => items.length;

  // Get total quantity across all items
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  String toString() {
    return 'ScanningSession(id: $id, name: $name, itemCount: $itemCount)';
  }
}
