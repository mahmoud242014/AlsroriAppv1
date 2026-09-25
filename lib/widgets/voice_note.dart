import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:voice_message_package/voice_message_package.dart';

class _VoiceNotesControllerCache {
  static final Map<String, VoiceController> _controllerCache = {};

  static VoiceController? getController(String audioSrc) => _controllerCache[audioSrc];

  static void setController(String audioSrc, VoiceController controller) {
    _controllerCache[audioSrc] = controller;
  }

  static void disposeController(String audioSrc) {
    final controller = _controllerCache.remove(audioSrc);
    controller?.dispose();
  }

  static void disposeAll() {
    for (final controller in _controllerCache.values) {
      controller.dispose();
    }
    _controllerCache.clear();
  }
}

class VoiceNotesControllerManager {
  static void disposeAllControllers() {
    _VoiceNotesControllerCache.disposeAll();
  }

  static void disposeController(String audioSrc) {
    _VoiceNotesControllerCache.disposeController(audioSrc);
  }
}

class VoiceNote extends StatefulWidget {
  final String audioSrc;
  final Duration maxDuration;
  final bool isCurrentUser;
  final BuildContext context;
  final double innerPadding;
  final double cornerRadius;
  final Color backgroundColor;
  final Color activeSliderColor;
  final Color circlesColor;
  final Icon playIcon;
  final Icon pauseIcon;
  final double size;
  final TextStyle counterTextStyle;
  final TextStyle circlesTextStyle;

  const VoiceNote({
    super.key,
    required this.audioSrc,
    required this.maxDuration,
    required this.isCurrentUser,
    required this.context,
    this.innerPadding = 12,
    this.cornerRadius = 18,
    required this.backgroundColor,
    required this.activeSliderColor,
    required this.circlesColor,
    required this.playIcon,
    required this.pauseIcon,
    this.size = 40,
    required this.counterTextStyle,
    required this.circlesTextStyle,
  });

  @override
  State<VoiceNote> createState() => _VoiceNoteState();
}

class _VoiceNoteState extends State<VoiceNote> {
  VoiceController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(VoiceNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only recreate controller if audio source has changed
    if (oldWidget.audioSrc != widget.audioSrc) {
      _initializeController();
    }
  }

  void _initializeController() {
    // Check if we already have a controller for this audio source
    final existingController = _VoiceNotesControllerCache.getController(widget.audioSrc);

    if (existingController != null) {
      _controller = existingController;
    } else {
      // Create new controller and cache it
      _controller = VoiceController(
        audioSrc: widget.audioSrc,
        maxDuration: widget.maxDuration,
        isFile: false,
        onComplete: () {},
        onPause: () {},
        onPlaying: () {},
      );
      _VoiceNotesControllerCache.setController(widget.audioSrc, _controller!);
    }
  }

  @override
  void dispose() {
    // Don't dispose the controller here as it's cached and might be used by other instances
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Container(
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.cornerRadius),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return VoiceMessageView(
      controller: _controller!,
      innerPadding: widget.innerPadding,
      cornerRadius: widget.cornerRadius,
      backgroundColor: widget.backgroundColor,
      activeSliderColor: widget.activeSliderColor,
      circlesColor: widget.circlesColor,
      playIcon: widget.playIcon,
      pauseIcon: widget.pauseIcon,
      size: widget.size,
      counterTextStyle: widget.counterTextStyle,
      circlesTextStyle: widget.circlesTextStyle,
    );
  }
}
