class Checkin {
  Checkin({
    required this.id,
    required this.date,
    this.mood,
    this.energy,
    this.focus,
    this.notes,
  });

  final String id;
  final String date;
  final int? mood;
  final int? energy;
  final int? focus;
  final String? notes;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'mood': mood,
      'energy': energy,
      'focus': focus,
      'notes': notes,
    };
  }

  static Checkin fromMap(Map<String, Object?> map) {
    return Checkin(
      id: map['id'] as String,
      date: map['date'] as String,
      mood: map['mood'] as int?,
      energy: map['energy'] as int?,
      focus: map['focus'] as int?,
      notes: map['notes'] as String?,
    );
  }
}
