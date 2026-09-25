import 'dart:io';
import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// Video Preview Widget
class VideoPreview extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const VideoPreview({
    super.key,
    required this.videoUrl,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  String? thumbnailPath;
  Duration? videoDuration;
  double? aspectRatio;
  bool isLoading = true;
  bool hasError = false;
  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  @override
  void didUpdateWidget(VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // regenerate thumbnail if video URL has changed
    if (oldWidget.videoUrl != widget.videoUrl) {
      _generateThumbnail();
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      // check cache first
      final cachedThumbnail = _VideoThumbnailCache.getThumbnail(widget.videoUrl);
      final cachedDuration = _VideoThumbnailCache.getDuration(widget.videoUrl);
      final cachedAspectRatio = _VideoThumbnailCache.getAspectRatio(widget.videoUrl);
      if (cachedThumbnail != null && cachedDuration != null && cachedAspectRatio != null) {
        if (mounted) {
          setState(() {
            thumbnailPath = cachedThumbnail;
            videoDuration = cachedDuration;
            aspectRatio = cachedAspectRatio;
            isLoading = false;
          });
        }
        return;
      }
      // generate thumbnail
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: (await Directory.systemTemp.createTemp()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );
      // get video duration and aspect ratio using VideoPlayerController
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await controller.initialize();
      final duration = controller.value.duration;
      final videoAspectRatio = controller.value.aspectRatio;
      await controller.dispose();
      // cache the results
      if (thumbnail != null) {
        _VideoThumbnailCache.setThumbnail(widget.videoUrl, thumbnail);
      }
      _VideoThumbnailCache.setDuration(widget.videoUrl, duration);
      _VideoThumbnailCache.setAspectRatio(widget.videoUrl, videoAspectRatio);
      if (mounted) {
        setState(() {
          thumbnailPath = thumbnail;
          videoDuration = duration;
          aspectRatio = videoAspectRatio;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Size _calculateDimensions() {
    const double defaultWidth = 220;
    const double defaultHeight = 160;
    const double minWidth = 220;
    const double minHeight = 160;
    double calculatedWidth = 0;
    double calculatedHeight = 0;
    /* if aspect ratio not available yet, use provided or default dimensions */
    if (aspectRatio == null) {
      final width = (widget.width ?? defaultWidth).clamp(220, double.infinity).toDouble();
      return Size(width, widget.height ?? defaultHeight);
    }
    /* if both width and height are explicitly provided, ensure min width */
    if (widget.width != null && widget.height != null) {
      if (widget.width! < 220) {
        /* if width is less than 220, use 220 and recalculate height to maintain aspect ratio */
        calculatedWidth = 220;
        calculatedHeight = 220 / aspectRatio!;
      } else {
        calculatedWidth = widget.width!;
        calculatedHeight = widget.height!;
      }
    } else if (widget.width != null) {
      /* if only width is provided, calculate height based on aspect ratio */
      calculatedWidth = widget.width!.clamp(220, double.infinity);
      calculatedHeight = calculatedWidth / aspectRatio!;
    } else if (widget.height != null) {
      /* if only height is provided, calculate width based on aspect ratio */
      calculatedWidth = widget.height! * aspectRatio!;
      /* if calculated width is less than 220, recalculate using 220 as base */
      if (calculatedWidth < 220) {
        calculatedWidth = 220;
        calculatedHeight = 220 / aspectRatio!;
      } else {
        calculatedHeight = widget.height!;
      }
    } else {
      /* if neither is provided, use aspect ratio with default base dimension */
      if (aspectRatio! > 1.0) {
        /* landscape/wide video (e.g., 16:9) - use default width */
        calculatedWidth = defaultWidth;
        calculatedHeight = defaultWidth / aspectRatio!;
      } else {
        /* portrait video (e.g., 9:16) - ensure width is at least 220 */
        calculatedWidth = defaultWidth;
        calculatedHeight = defaultWidth / aspectRatio!;
      }
    }
    /* ensure minimum dimensions */
    calculatedWidth = calculatedWidth.clamp(minWidth, double.infinity);
    calculatedHeight = calculatedHeight.clamp(minHeight, double.infinity);
    return Size(calculatedWidth, calculatedHeight);
  }

  @override
  Widget build(BuildContext context) {
    final size = _calculateDimensions();
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            insetPadding: EdgeInsets.zero,
            child: FullScreenVideoPlayer(videoUrl: widget.videoUrl),
          ),
        );
      },
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // thumbnail or placeholder
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else if (hasError)
                Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.videocam_off,
                      color: Colors.white54,
                      size: 32,
                    ),
                  ),
                )
              else if (thumbnailPath != null)
                Image.file(
                  File(thumbnailPath!),
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.videocam,
                      color: Colors.white54,
                      size: 32,
                    ),
                  ),
                ),
              // play button overlay
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withValues(alpha: 0.6),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              // duration badge
              if (videoDuration != null && videoDuration!.inSeconds > 0)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(videoDuration!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Full Screen Video Player
class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoPlayer({super.key, required this.videoUrl});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController videoPlayerController;
  ChewieController? chewieController;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  // initialize video
  Future<void> _initializeVideo() async {
    videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    await videoPlayerController.initialize();
    if (mounted) {
      setState(() {
        isInitialized = true;
        final double aspectRatio = videoPlayerController.value.aspectRatio;
        chewieController = ChewieController(
          aspectRatio: aspectRatio,
          videoPlayerController: videoPlayerController,
          autoInitialize: true,
          showControls: true,
          showOptions: false,
          allowFullScreen: true,
          allowMuting: true,
          allowPlaybackSpeedChanging: true,
          showControlsOnInitialize: true,
        );
      });
    }
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ),
      body: (isInitialized && chewieController != null)
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Chewie(controller: chewieController!),
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

// Video Thumbnail Cache
class _VideoThumbnailCache {
  static final Map<String, String> _thumbnailCache = {};
  static final Map<String, Duration> _durationCache = {};
  static final Map<String, double> _aspectRatioCache = {};

  static String? getThumbnail(String videoUrl) => _thumbnailCache[videoUrl];
  static Duration? getDuration(String videoUrl) => _durationCache[videoUrl];
  static double? getAspectRatio(String videoUrl) => _aspectRatioCache[videoUrl];

  static void setThumbnail(String videoUrl, String thumbnailPath) {
    _thumbnailCache[videoUrl] = thumbnailPath;
  }

  static void setDuration(String videoUrl, Duration duration) {
    _durationCache[videoUrl] = duration;
  }

  static void setAspectRatio(String videoUrl, double aspectRatio) {
    _aspectRatioCache[videoUrl] = aspectRatio;
  }
}
