import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago_flutter/timeago_flutter.dart' as timeago;

// Import App Files
import 'message/message_bubble.dart';
import '../../../common/themes.dart';
import '../../../providers/system_provider.dart';
import '../../../utilities/functions.dart';
import '../../../utilities/timeago_locale/timeago_locale.dart';
import '../../../widgets/profile_avatar.dart';
import '../../../widgets/video_preview.dart';
import '../../../widgets/voice_note.dart';
import '../../../widgets/product_preview.dart';
import '../../../widgets/image_preview.dart';
import '../../../modals/who_reacts_modal.dart';

class ChatMessage extends ConsumerWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;
  final bool isMultipleRecipients;
  final Function onReact;
  final Function? onCopy;
  final Function? onDelete;

  const ChatMessage({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.isMultipleRecipients,
    required this.onReact,
    this.onCopy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final $system = ref.read(systemProvider);
    final languageCode = Localizations.localeOf(context).languageCode;
    setLocaleMessagesForLocale(languageCode);
    final double avatarRadius = 20;
    final double avatarDiameter = avatarRadius * 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser && isMultipleRecipients)
            Padding(
              padding: EdgeInsets.only(bottom: 2, left: avatarDiameter + 10),
              child: Column(
                children: [
                  Text(
                    '${message['user_fullname']}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                  ),
                  SizedBox(height: 4),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCurrentUser) ...[
                ProfileAvatar(
                  imageUrl: message['user_picture'],
                  radius: avatarRadius,
                ),
                SizedBox(width: 10),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Message Bubble
                    MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      onReact: onReact,
                      onCopy: onCopy,
                      onDelete: onDelete,
                      reactions: $system['reactions_enabled'],
                      hasReactions: message['reactions_total_count'] > 0,
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // Text Message
                            if (message['message_decoded'].isNotEmpty)
                              Container(
                                // constraints: (message['reactions_total_count'] > 0) ? BoxConstraints(minWidth: 140) : null,
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? xPrimaryColor
                                      : Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF3a3b3b)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: parsedChatMessage(context, message['message_decoded'], isCurrentUser, 17),
                              ),
                            // Image Message
                            if (message['image'].isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(top: (message['message_decoded'].isNotEmpty) ? 5 : 0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        insetPadding: EdgeInsets.zero,
                                        child: ImagePreview(imageUrl: "${$system['system_uploads']}/${message['image']}"),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: CachedNetworkImage(
                                      imageUrl: "${$system['system_uploads']}/${message['image']}",
                                      width: 200,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 50),
                                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3a3b3b) : Colors.grey.shade200,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              ),
                            // Video Message
                            if (message['video'].isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(top: (message['message_decoded'].isNotEmpty) ? 5 : 0),
                                child: VideoPreview(
                                  videoUrl: "${$system['system_uploads']}/${message['video']}",
                                ),
                              ),
                            // Voice Message
                            if (message['voice_note'].isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(top: (message['message_decoded'].isNotEmpty) ? 5 : 0),
                                child: VoiceNote(
                                  audioSrc: "${$system['system_uploads']}/${message['voice_note']}",
                                  maxDuration: Duration(seconds: int.parse($system['voice_notes_durtaion'])),
                                  isCurrentUser: isCurrentUser,
                                  context: context,
                                  innerPadding: 12,
                                  cornerRadius: 18,
                                  backgroundColor: isCurrentUser
                                      ? xPrimaryColor
                                      : Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF3a3b3b)
                                      : Colors.grey.shade200,
                                  activeSliderColor: isCurrentUser
                                      ? Colors.white
                                      : Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  circlesColor: isCurrentUser
                                      ? xPrimaryColor
                                      : Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF3a3b3b)
                                      : Colors.grey.shade200,
                                  playIcon: Icon(
                                    Icons.play_arrow_rounded,
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  pauseIcon: Icon(
                                    Icons.pause_rounded,
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  size: 40,
                                  counterTextStyle: TextStyle(
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 10,
                                  ),
                                  circlesTextStyle: TextStyle(
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            // Product Message
                            if (message['post'] != null && message['post'].isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(top: (message['message_decoded'].isNotEmpty) ? 5 : 0),
                                child: ProductPreview(
                                  title: message['post']['product']['name'],
                                  imageUrl: "${$system['system_uploads']}/${message['post']['photos'][0]['source']}",
                                  price: message['post']['product']['price_formatted'],
                                ),
                              ),
                            if (message['reactions_total_count'] > 0)
                              Transform.translate(
                                offset: Offset(0, -5),
                                child: InkWell(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return WhoReactsModal(messageId: message['message_id']);
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3a3b3b) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        width: 2,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Theme.of(context).scaffoldBackgroundColor
                                            : Colors.white,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ...message['reactions'].entries
                                            .where((reaction) => int.parse(reaction.value) > 0)
                                            .take(3)
                                            .map(
                                              (reaction) => Container(
                                                margin: const EdgeInsets.only(right: 1),
                                                child: CachedNetworkImage(
                                                  imageUrl: $system['reactions_enabled'][reaction.key]['image_url'],
                                                  width: 14,
                                                  height: 14,
                                                ),
                                              ),
                                            ),
                                        SizedBox(width: 2),
                                        Text(
                                          message['reactions_total_count'].toString(),
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Timeago
                    Text(
                      timeago.format(convertedTime(message['time']), locale: languageCode),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
