import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/core/widgets/section_header.dart';
import 'package:mydr/data/media/media_file_validator.dart';
import 'package:mydr/data/media/media_picker.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/visit_media.dart';
import 'package:mydr/features/symptoms/symptom_formatting.dart';
import 'package:mydr/features/visit_preparation/visit_media_viewer_screen.dart';
import 'package:mydr/features/visit_preparation/widgets/visit_media_dialogs.dart';

/// The photos and videos attached to an appointment: each can be opened,
/// described or deleted, and new ones can be captured or chosen from the
/// gallery.
class VisitMediaSection extends StatelessWidget {
  const VisitMediaSection({super.key, required this.appointment});

  final Appointment appointment;

  Future<void> _add(BuildContext context, MediaSource source) async {
    final controller = AppScope.of(context).visitMediaController;
    final messenger = ScaffoldMessenger.of(context);
    final report = await controller.addFrom(appointment, source);
    if (report.cancelled || !context.mounted) return;

    final messages = <String>[
      if (report.addedIds.isNotEmpty)
        AppStrings.visitMediaAdded(report.addedIds.length),
      if (report.pickError case final error?)
        switch (error) {
          MediaPickError.permissionDenied => AppStrings.cameraPermissionDenied,
          MediaPickError.cameraUnavailable => AppStrings.cameraUnavailable,
          MediaPickError.failed => AppStrings.mediaPickFailed,
        },
      if (report.appointmentMissing) AppStrings.mediaAppointmentMissing,
      if (report.rejectedFor(MediaFileError.unsupportedType) case final n
          when n > 0)
        AppStrings.mediaRejectedUnsupported(n),
      if (report.rejectedFor(MediaFileError.tooLarge) case final n when n > 0)
        AppStrings.mediaRejectedTooLarge(n),
      if (report.rejectedFor(MediaFileError.unreadable) +
              report.rejectedFor(MediaFileError.storageFailed)
          case final n when n > 0)
        AppStrings.mediaSaveFailed(n),
    ];
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(messages.join('\n')),
          duration: Duration(seconds: report.addedIds.isEmpty ? 6 : 4),
        ),
      );

    // A single new photo or video: ask right away what it shows.
    if (report.addedIds.length == 1 && report.rejected.isEmpty) {
      final media = controller.mediaById(report.addedIds.single);
      if (media != null && context.mounted) {
        await VisitMediaDescriptionDialog.show(context, media);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).visitMediaController;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final items = controller.forAppointment(appointment);
        final isAdding = controller.isAdding(appointment.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: AppStrings.visitMediaTitle),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppStrings.visitMediaPrivacyNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (controller.hasLoadError) ...[
              const InlineErrorMessage(message: AppStrings.visitMediaLoadError),
              const SizedBox(height: 12),
            ],
            if (items.isEmpty && !controller.isLoading)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Text(
                  AppStrings.visitMediaEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final (index, media) in items.indexed) ...[
              if (index > 0) const SizedBox(height: 12),
              VisitMediaTile(key: ValueKey(media.id), media: media),
            ],
            const SizedBox(height: 12),
            if (isAdding)
              Semantics(
                liveRegion: true,
                child: const Row(
                  children: [
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text(AppStrings.visitMediaAdding)),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _add(context, MediaSource.cameraPhoto),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text(AppStrings.takePhoto),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _add(context, MediaSource.cameraVideo),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text(AppStrings.recordVideo),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _add(context, MediaSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text(AppStrings.chooseFromGallery),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

enum _TileAction { describe, delete }

/// One photo or video: thumbnail, description and when it was added.
class VisitMediaTile extends StatelessWidget {
  const VisitMediaTile({super.key, required this.media});

  final VisitMedia media;

  Future<void> _onAction(BuildContext context, _TileAction action) async {
    switch (action) {
      case _TileAction.describe:
        await VisitMediaDescriptionDialog.show(context, media);
      case _TileAction.delete:
        final messenger = ScaffoldMessenger.of(context);
        if (await DeleteVisitMediaDialog.show(context, media)) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text(AppStrings.visitMediaDeleted)),
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = media.description?.trim() ?? '';
    final kindLabel = media.kind == VisitMediaKind.photo
        ? AppStrings.visitMediaPhoto
        : AppStrings.visitMediaVideo;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppCard.borderRadius),
          onTap: () => Navigator.of(
            context,
          ).push(VisitMediaViewerScreen.route(media.id)),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
            child: Row(
              children: [
                VisitMediaThumbnail(media: media),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description.isEmpty
                            ? AppStrings.visitMediaNoDescription
                            : description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: description.isEmpty
                              ? FontStyle.italic
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$kindLabel · ${AppStrings.visitMediaAddedAt(formatSymptomDateTime(media.createdAt, MaterialLocalizations.of(context)))}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_TileAction>(
                  tooltip: AppStrings.visitMediaMoreActions,
                  onSelected: (action) => _onAction(context, action),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _TileAction.describe,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text(AppStrings.editVisitMediaDescription),
                      ),
                    ),
                    PopupMenuItem(
                      value: _TileAction.delete,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text(AppStrings.deleteVisitMedia),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small preview: the photo itself, or a video symbol (no frames are
/// extracted from videos).
class VisitMediaThumbnail extends StatefulWidget {
  const VisitMediaThumbnail({super.key, required this.media});

  final VisitMedia media;

  static const double size = 64;

  @override
  State<VisitMediaThumbnail> createState() => _VisitMediaThumbnailState();
}

class _VisitMediaThumbnailState extends State<VisitMediaThumbnail> {
  Future<Uint8List?>? _bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.media.kind == VisitMediaKind.photo) {
      _bytes ??= AppScope.of(
        context,
      ).visitMediaController.readPhoto(widget.media);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget symbol(IconData icon) => Center(
      child: Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
    );

    final Widget content;
    if (widget.media.kind == VisitMediaKind.video) {
      content = symbol(Icons.play_circle_outline);
    } else {
      content = FutureBuilder<Uint8List?>(
        future: _bytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          final bytes = snapshot.data;
          if (bytes == null) return symbol(Icons.broken_image_outlined);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            cacheWidth: 192,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => symbol(Icons.broken_image_outlined),
          );
        },
      );
    }

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: colorScheme.surfaceContainerHigh,
          child: SizedBox.square(
            dimension: VisitMediaThumbnail.size,
            child: content,
          ),
        ),
      ),
    );
  }
}
