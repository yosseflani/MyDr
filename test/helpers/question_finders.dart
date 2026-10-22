import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/l10n/strings.dart';

/// The handled/not handled toggle of a question card, not its copy button.
final Finder questionStatusToggle = find.byWidgetPredicate(
  (widget) =>
      widget is IconButton &&
      (widget.tooltip == AppStrings.markQuestionResolved ||
          widget.tooltip == AppStrings.markQuestionUnresolved),
);
