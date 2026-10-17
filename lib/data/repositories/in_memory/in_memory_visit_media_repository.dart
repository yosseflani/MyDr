import 'package:mydr/data/models/visit_media.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_repository.dart';
import 'package:mydr/data/repositories/visit_media_repository.dart';

class InMemoryVisitMediaRepository extends InMemoryRepository<VisitMedia>
    implements VisitMediaRepository {
  InMemoryVisitMediaRepository([Iterable<VisitMedia> initialItems = const []])
    : super(
        idPrefix: 'media',
        idOf: (media) => media.id,
        initialItems: initialItems,
      );

  @override
  Future<List<VisitMedia>> getAll({
    String? memberId,
    String? appointmentId,
  }) async {
    final items =
        storedItems
            .where((m) => memberId == null || m.memberId == memberId)
            .where(
              (m) => appointmentId == null || m.appointmentId == appointmentId,
            )
            .toList()
          ..sort((a, b) {
            final byTime = a.createdAt.compareTo(b.createdAt);
            return byTime != 0 ? byTime : a.id.compareTo(b.id);
          });
    return List.unmodifiable(items);
  }

  @override
  Future<void> update(VisitMedia item) async {
    final stored = await getById(item.id);
    if (stored == null) {
      throw StateError('Item with id "${item.id}" does not exist');
    }
    await super.update(stored.copyWith(description: () => item.description));
  }

  @override
  Future<void> deleteByAppointment(String appointmentId) async {
    removeWhere((m) => m.appointmentId == appointmentId);
  }

  @override
  Future<void> deleteByMember(String memberId) async {
    removeWhere((m) => m.memberId == memberId);
  }
}
