import 'dart:convert';

/// How model values are stored in the local database (see schema.drift).
/// Every conversion round-trips exactly.
abstract final class StorageCodecs {
  /// A local wall-clock time as 'YYYY-MM-DDTHH:MM:SS.ffffff'.
  ///
  /// Fixed width, so text order is time order. Stored without a time zone,
  /// so an appointment at 10:00 stays at 10:00 after a DST or time zone
  /// change. A UTC value is converted to local time first.
  static String encodeLocalDateTime(DateTime value) {
    final local = value.toLocal();
    final fraction = local.millisecond * 1000 + local.microsecond;
    return '${_digits(local.year, 4)}-${_digits(local.month, 2)}-'
        '${_digits(local.day, 2)}T${_digits(local.hour, 2)}:'
        '${_digits(local.minute, 2)}:${_digits(local.second, 2)}.'
        '${_digits(fraction, 6)}';
  }

  static final RegExp _localDateTime = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d{6})$',
  );

  static DateTime decodeLocalDateTime(String text) {
    final match = _localDateTime.firstMatch(text);
    if (match == null) throw FormatException('Not a stored date and time');
    final fraction = int.parse(match[7]!);
    return DateTime(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
      int.parse(match[4]!),
      int.parse(match[5]!),
      int.parse(match[6]!),
      fraction ~/ 1000,
      fraction % 1000,
    );
  }

  /// A calendar date as 'YYYY-MM-DD'.
  static String encodeDate(DateTime value) =>
      '${_digits(value.year, 4)}-${_digits(value.month, 2)}-'
      '${_digits(value.day, 2)}';

  static final RegExp _date = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static DateTime decodeDate(String text) {
    final match = _date.firstMatch(text);
    if (match == null) throw FormatException('Not a stored date');
    return DateTime(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  /// A moment in time, as microseconds since the Unix epoch.
  static int encodeInstant(DateTime value) => value.microsecondsSinceEpoch;

  /// Returned in local time.
  static DateTime decodeInstant(int micros) =>
      DateTime.fromMicrosecondsSinceEpoch(micros);

  static String encodeStringList(List<String> values) => jsonEncode(values);

  static List<String> decodeStringList(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List || decoded.any((v) => v is! String)) {
      throw FormatException('Not a stored list of text');
    }
    return List.unmodifiable(decoded.cast<String>());
  }

  static String _digits(int value, int width) =>
      value.toString().padLeft(width, '0');
}
