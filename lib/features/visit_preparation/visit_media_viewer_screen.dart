import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/visit_media.dart';
import 'package:mydr/features/visit_preparation/widgets/visit_media_dialogs.dart';
import 'package:video_player/video_player.dart';

/// Shows one photo (zoomable) or plays one video, with its description.
///
/// Receives only the id and reads the current item from the shared
/// controller, so it reflects edits and closes cleanly after a deletion.
class VisitMediaViewerScreen extends StatelessWidget {
  const VisitMediaViewerScreen({super.key, required this.mediaId});

  final String mediaId;

  static Route<void> route(String mediaId) => MaterialPageRoute<void>(
    builder: (_) => VisitMediaViewerScreen(mediaId: mediaId),
  );

  Future<void> _delete(BuildContext context, VisitMedia media) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (!await DeleteVisitMediaDialog.show(context, media)) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.visitMediaDeleted)),
      );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).visitMediaController;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final media = controller.mediaById(mediaId);
        final description = media?.description?.trim() ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              media == null
                  ? ''
                  : media.kind == VisitMediaKind.photo
                  ? AppStrings.visitMediaPhoto
                  : AppStrings.visitMediaVideo,
            ),
            actions: [
              if (media != null) ...[
                IconButton(
                  tooltip: AppStrings.editVisitMediaDescription,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      VisitMediaDescriptionDialog.show(context, media),
                ),
                IconButton(
                  tooltip: AppStrings.deleteVisitMedia,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, media),
                ),
              ],
            ],
          ),
          body: media == null
              ? (controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : const NotFoundView(
                        icon: Icons.image_not_supported_outlined,
                        title: AppStrings.visitMediaNotFoundTitle,
                        message: AppStrings.visitMediaNotFoundMessage,
                        backLabel: AppStrings.backToAppointment,
                      ))
              : SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: media.kind == VisitMediaKind.photo
                            ? _PhotoView(key: ValueKey(media.id), media: media)
                            : _VideoView(key: ValueKey(media.id), media: media),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          description.isEmpty
                              ? AppStrings.visitMediaNoDescription
                              : description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

/// Explains that the file is missing or damaged; the record can still be
/// deleted from the app bar.
class _FileProblem extends StatelessWidget {
  const _FileProblem();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 12),
              const Text(
                AppStrings.mediaFileMissing,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoView extends StatefulWidget {
  const _PhotoView({super.key, required this.media});

  final VisitMedia media;

  @override
  State<_PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<_PhotoView> {
  Future<Uint8List?>? _bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bytes ??= AppScope.of(
      context,
    ).visitMediaController.readPhoto(widget.media);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bytes = snapshot.data;
        if (bytes == null) return const _FileProblem();
        return InteractiveViewer(
          maxScale: 6,
          child: Center(
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              semanticLabel: widget.media.description ?? '',
              errorBuilder: (_, _, _) => const _FileProblem(),
            ),
          ),
        );
      },
    );
  }
}

class _VideoView extends StatefulWidget {
  const _VideoView({super.key, required this.media});

  final VisitMedia media;

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  VideoPlayerController? _player;
  bool _failed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _open();
  }

  Future<void> _open() async {
    final File? file = await AppScope.of(
      context,
    ).visitMediaController.videoFile(widget.media);
    if (!mounted) return;
    if (file == null) {
      setState(() => _failed = true);
      return;
    }
    final player = VideoPlayerController.file(file);
    try {
      await player.initialize();
      await player.setLooping(false);
    } catch (_) {
      // A damaged or unsupported file. The error is not logged: it may
      // include the file's path.
      await player.dispose();
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) {
      await player.dispose();
      return;
    }
    setState(() => _player = player);
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _FileProblem();
    final player = _player;
    if (player == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: player.value.aspectRatio,
              child: VideoPlayer(player),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // Progress runs left to right like the video's own timeline.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: VideoProgressIndicator(player, allowScrubbing: true),
          ),
        ),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: player,
          builder: (context, value, _) {
            final isPlaying = value.isPlaying;
            return IconButton.filledTonal(
              iconSize: 32,
              tooltip: isPlaying ? AppStrings.pauseVideo : AppStrings.playVideo,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () async {
                if (isPlaying) {
                  await player.pause();
                } else {
                  if (value.position >= value.duration) {
                    await player.seekTo(Duration.zero);
                  }
                  await player.play();
                }
              },
            );
          },
        ),
      ],
    );
  }
}
