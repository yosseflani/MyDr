/// Whether a symptom is still present.
enum SymptomStatus { ongoing, resolved }

/// A symptom recorded by the user for one family member.
///
/// All values are exactly what the user reported. The app never interprets
/// them or draws medical conclusions from them.
class SymptomEntry {
  SymptomEntry({
    required this.id,
    required this.memberId,
    required this.name,
    required this.startedAt,
    required this.severity,
    this.status = SymptomStatus.ongoing,
    this.duration,
    this.notes,
  }) {
    RangeError.checkValueInInterval(
      severity,
      minSeverity,
      maxSeverity,
      'severity',
    );
  }

  static const int minSeverity = 1;
  static const int maxSeverity = 5;

  final String id;

  /// Id of the [FamilyMember] this entry belongs to.
  final String memberId;
  final String name;
  final DateTime startedAt;

  /// The user's own rating of how strong it felt, from [minSeverity] to
  /// [maxSeverity]. Subjective, never a medical assessment.
  final int severity;
  final SymptomStatus status;

  /// How long the symptom lasted (if resolved) or has lasted so far
  /// (if ongoing). Null when unknown.
  final Duration? duration;
  final String? notes;

  bool get isOngoing => status == SymptomStatus.ongoing;

  /// The form in which symptom names are compared: trimmed, with single
  /// spaces, in lower case (for names written in Latin letters). Records
  /// whose names give the same key are the same symptom.
  static String nameKey(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// Nullable fields take a function so they can be cleared:
  /// `copyWith(duration: () => null)`.
  SymptomEntry copyWith({
    String? memberId,
    String? name,
    DateTime? startedAt,
    int? severity,
    SymptomStatus? status,
    Duration? Function()? duration,
    String? Function()? notes,
  }) {
    return SymptomEntry(
      id: id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      duration: duration != null ? duration() : this.duration,
      notes: notes != null ? notes() : this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SymptomEntry &&
      other.id == id &&
      other.memberId == memberId &&
      other.name == name &&
      other.startedAt == startedAt &&
      other.severity == severity &&
      other.status == status &&
      other.duration == duration &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    name,
    startedAt,
    severity,
    status,
    duration,
    notes,
  );

  /// Shows only the id so medical details never end up in logs.
  @override
  String toString() => 'SymptomEntry(id: $id)';
}
