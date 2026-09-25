import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import Third Party Packages
import 'package:audioplayers/audioplayers.dart';

// Import App Files
import 'hero_dialog_route.dart';
import 'hero_dialog_message.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;
  final Widget child;
  final Map<String, dynamic> reactions;
  final bool hasReactions;
  final Function onReact;
  final Function? onCopy;
  final Function? onDelete;
  final GlobalKey bubbleKey = GlobalKey();
  final AudioPlayer player = AudioPlayer();

  MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.child,
    required this.reactions,
    required this.hasReactions,
    required this.onReact,
    this.onCopy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: bubbleKey,
      onLongPress: () async {
        final RenderBox? renderBox = bubbleKey.currentContext?.findRenderObject() as RenderBox?;
        final Offset originalPosition = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
        final Size originalSize = renderBox?.size ?? Size.zero;
        HapticFeedback.lightImpact();
        await player.play(AssetSource('sounds/bubble.mp3'));
        Navigator.of(context).push(
          HeroDialogRoute(
            builder: (context) => HeroDialogMessage(
              message: message,
              isCurrentUser: isCurrentUser,
              reactions: reactions,
              onReact: onReact,
              onCopy: onCopy,
              onDelete: onDelete,
              originalPosition: originalPosition,
              originalSize: originalSize,
              child: child,
            ),
          ),
        );
      },
      child: Hero(
        tag: message['message_id'],
        child: child,
      ),
    );
  }
}
