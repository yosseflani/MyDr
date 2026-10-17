/// Whether a [VisitMedia] item is a photo or a video.
enum VisitMediaKind { photo, video }

/// A photo or short video documenting a symptom, prepared for a doctor
/// visit. It always belongs to one appointment and to that appointment's
/// family member.
///
/// Only metadata lives here and in the database; the file itself is kept in
/// the app's private storage under [fileName].
class VisitMedia {
  const VisitMedia({
    required this.id,
    required this.memberId,
    required this.appointmentId,
    required this.kind,
    required this.fileName,
    required this.byteSize,
    required this.createdAt,
    this.description,
  });

  final String id;

  /// Id of the [FamilyMember] the documentation is about. Always the member
  /// of [appointmentId].
  final String memberId;

  /// Id of the [Appointment] it was prepared for.
  final String appointmentId;
  final VisitMediaKind kind;

  /// The file's name in private storage: a bare name, never a path.
  final String fileName;
  final int byteSize;
  final DateTime createdAt;

  /// What the user wrote about it, e.g. when the symptom appeared.
  final String? description;

  /// Only the description can change; the file, appointment and member are
  /// fixed once added.
  VisitMedia copyWith({String? Function()? description}) {
    return VisitMedia(
      id: id,
      memberId: memberId,
      appointmentId: appointmentId,
      kind: kind,
      fileName: fileName,
      byteSize: byteSize,
      createdAt: createdAt,
      description: description != null ? description() : this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VisitMedia &&
      other.id == id &&
      other.memberId == memberId &&
      other.appointmentId == appointmentId &&
      other.kind == kind &&
      other.fileName == fileName &&
      other.byteSize == byteSize &&
      other.createdAt == createdAt &&
      other.description == description;

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    appointmentId,
    kind,
    fileName,
    byteSize,
    createdAt,
    description,
  );

  /// Shows only the id so medical details and file names never end up in
  /// logs.
  @override
  String toString() => 'VisitMedia(id: $id)';
}
