import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/sync/local_records.dart';

/// The result of merging two versions of one record.
sealed class MergeResult {
  const MergeResult();
}

/// Both versions say the same.
class MergeSame extends MergeResult {
  const MergeSame();
}

/// The versions changed different fields, and [payload] holds both changes.
class MergeCombined extends MergeResult {
  const MergeCombined(this.payload);

  final Map<String, Object?> payload;
}

/// Both versions changed [fields] differently: the user must choose.
class MergeConflict extends MergeResult {
  const MergeConflict(this.fields);

  final List<String> fields;
}

/// Three-way merge of a record edited on two devices. Pure and synchronous.
///
/// A field changed on one side only takes that change; a field changed on
/// both sides to the same value is fine; a field changed on both sides to
/// different values is a conflict, never settled silently, because these
/// are medical records. With no common [base] (the same record created on
/// two devices, e.g. one scheduled dose marked on both), every differing
/// field is a conflict.
///
/// The one rule-based field is a dose record's `recordedAt`: when both
/// devices recorded the same status, the later time of recording is kept.
abstract final class SyncMerge {
  /// Fields settled by keeping the larger value.
  static const Map<SyncKind, Set<String>> latestWins = {
    SyncKind.dose: {'recordedAt'},
  };

  static Set<String> _ignored(SyncKind kind) =>
      LocalRecords.ignoredFields[kind] ?? const {};

  static Set<String> _latest(SyncKind kind) => latestWins[kind] ?? const {};

  /// Whether [a] and [b] are the same record content.
  static bool same(
    SyncKind kind,
    Map<String, Object?> a,
    Map<String, Object?> b,
  ) {
    final ignored = _ignored(kind);
    for (final key in {...a.keys, ...b.keys}) {
      if (ignored.contains(key)) continue;
      if (!jsonEquals(a[key], b[key])) return false;
    }
    return true;
  }

  static MergeResult threeWay(
    SyncKind kind, {
    required Map<String, Object?>? base,
    required Map<String, Object?> local,
    required Map<String, Object?> remote,
  }) {
    final ignored = _ignored(kind);
    final latest = _latest(kind);
    // Fields only one side has (a photo's upload description) are kept;
    // this device's own (e.g. a dose record's local id) win.
    final merged = <String, Object?>{...remote, ...local};
    final conflicts = <String>[];
    var changed = false;

    for (final key in {...local.keys, ...remote.keys}) {
      if (ignored.contains(key)) continue;
      final mine = local[key];
      final theirs = remote[key];
      if (jsonEquals(mine, theirs)) continue;
      changed = true;
      if (latest.contains(key) && mine is int && theirs is int) {
        merged[key] = mine > theirs ? mine : theirs;
      } else if (base != null && jsonEquals(mine, base[key])) {
        merged[key] = theirs;
      } else if (base != null && jsonEquals(theirs, base[key])) {
        merged[key] = mine;
      } else {
        conflicts.add(key);
      }
    }
    if (conflicts.isNotEmpty) return MergeConflict(conflicts..sort());
    if (!changed) return const MergeSame();
    return MergeCombined(Map.unmodifiable(merged));
  }
}
