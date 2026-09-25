import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import Third Party Packages
import 'package:cached_network_image/cached_network_image.dart';

class ReactionIconButton extends StatelessWidget {
  final Map<String, dynamic> message;
  final Map<String, dynamic> reaction;
  final Function onReact;

  const ReactionIconButton({
    super.key,
    required this.message,
    required this.reaction,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    bool isUserReaction = (message['i_react'] == true && message['i_reaction'] == reaction['reaction']) ? true : false;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
        onReact(message['message_id'], reaction);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Row(
          children: [
            Column(
              children: [
                CachedNetworkImage(imageUrl: '${reaction['image_url']}', width: 30, height: 30),
                (isUserReaction)
                    ? Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(Icons.circle, size: 5, color: Theme.of(context).colorScheme.primary),
                      )
                    : const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
