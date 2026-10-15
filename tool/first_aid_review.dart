// Writes docs/first_aid_medical_review.md from the first-aid draft file,
// the app's content and the trusted approvals.
//
// Run from the project root: dart run tool/first_aid_review.dart

import 'dart:io';

import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/first_aid/first_aid_review_document.dart';

const String draftPath = 'assets/first_aid/review/he.draft.json';
const String publishedPath = 'assets/first_aid/he.json';
const String documentPath = 'docs/first_aid_medical_review.md';

void main() {
  final drafts = const FirstAidContentParser(
    mode: FirstAidContentMode.review,
  ).parse(File(draftPath).readAsStringSync());
  final published = const FirstAidContentParser().parse(
    File(publishedPath).readAsStringSync(),
  );
  File(documentPath).writeAsStringSync(
    buildFirstAidReviewDocument(drafts: drafts, published: published),
  );
  stdout.writeln('Wrote $documentPath');
}
