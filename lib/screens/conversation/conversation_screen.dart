import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import Third Party Packages
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:timeago_flutter/timeago_flutter.dart' as timeago;

// Import App Files
import '../../common/config.dart';
import '../../routes/router.gr.dart';
import '../../common/themes.dart';
import '../../providers/system_provider.dart';
import '../../providers/user_provider.dart';
import '../../utilities/functions.dart';
import '../../utilities/load_state.dart';
import '../../utilities/timeago_locale/timeago_locale.dart';
import '../../widgets/error.dart';
import '../../widgets/loading.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/profile_avatars_overlapping.dart';
import '../../widgets/snackbar.dart';
import 'components/chat_message.dart';
import 'components/chat_composer.dart';
import '../../widgets/voice_note.dart';

@RoutePage()
class ConversationScreen extends ConsumerStatefulWidget {
  static const routeName = '/conversation';

  final String? conversationId;
  final String? userId;
  final Map<String, dynamic>? user;

  const ConversationScreen({
    super.key,
    this.conversationId,
    this.userId,
    this.user,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final scrollController = ScrollController();
  Timer? heartbeatTimer;
  Map<String, dynamic> conversation = {};
  bool isRecipientsTyping = false;
  String isRecipientsTypingName = '';
  bool isRecipientsSeen = false;
  String isRecipientsSeenName = '';
  LoadState loadState = LoadState.loading;
  int offset = 1;
  bool isLoading = false;
  bool hasMore = true;

  // API Call: getConversation
  Future<void> getConversation() async {
    final $user = ref.read(userProvider);
    try {
      final response = await sendAPIRequest(
        'chat/conversation',
        queryParameters: {
          'user_id': widget.userId,
          'conversation_id': widget.conversationId,
        },
      );
      if (response['statusCode'] == 200) {
        if (response['body']['data'] is Map && response['body']['data'].isNotEmpty) {
          setState(() {
            conversation = response['body']['data'];
            hasMore = isTrue(conversation['has_more']);
            if (conversation['seen_name_list'] != null && conversation['messages'].last['user_id'] == $user['user_id']) {
              isRecipientsSeen = true;
              isRecipientsSeenName = conversation['seen_name_list'];
            }
            loadState = LoadState.loaded;
          });
        } else {
          setState(() {
            loadState = LoadState.loaded;
          });
        }
      } else {
        setState(() {
          loadState = LoadState.error;
        });
      }
    } catch (e) {
      setState(() {
        loadState = LoadState.error;
      });
    }
  }

  // API Call: getMessages
  Future<void> getMessages() async {
    if (isLoading) return;
    if (conversation.isEmpty) return;
    setState(() {
      isLoading = true;
    });
    final response = await sendAPIRequest(
      'chat/messages',
      queryParameters: {
        'conversation_id': widget.conversationId,
        'offset': offset.toString(),
      },
    );
    if (response['statusCode'] == 200) {
      if (response['body']['data'] is Map && response['body']['data'].isNotEmpty) {
        final newMessages = response['body']['data']['messages'] ?? [];
        if (newMessages.isNotEmpty) {
          setState(() {
            conversation['messages'].insertAll(0, newMessages);
            offset++;
            hasMore = isTrue(response['body']['data']['has_more']);
          });
        } else {
          setState(() {
            hasMore = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(tr("There is something that went wrong!")),
          ),
        );
    }
    setState(() {
      isLoading = false;
    });
  }

  // API Call: chatHeartbeat
  Future<void> chatHeartbeat() async {
    if (conversation.isEmpty) return;
    final $user = ref.read(userProvider);
    try {
      final response = await sendAPIRequest(
        'chat/messages',
        queryParameters: {
          'conversation_id': conversation['conversation_id'],
          'last_message_id': conversation['messages'].last['message_id'],
        },
      );
      if (response['statusCode'] == 200) {
        if (response['body']['data'] is Map && response['body']['data'].isNotEmpty) {
          final newMessages = response['body']['data']['messages'] ?? [];
          final typingNameList = response['body']['data']['typing_name_list'] ?? '';
          final seenNameList = response['body']['data']['seen_name_list'] ?? '';
          final userIsOnline = response['body']['data']['user_is_online'];
          final userLastSeen = response['body']['data']['user_last_seen'];
          setState(() {
            /* check for a new messages for this conversation */
            if (newMessages.isNotEmpty) {
              conversation['messages'].addAll(newMessages);
            }
            /* check single user's chat status (online|offline) */
            if (!isTrue(conversation['multiple_recipients']) && userIsOnline != null) {
              if (conversation['user_is_online'] != userIsOnline) {
                conversation['user_is_online'] = userIsOnline;
                conversation['user_last_seen'] = userLastSeen;
              }
            }
            /* check for typing status */
            if (typingNameList != '') {
              isRecipientsTyping = true;
              isRecipientsTypingName = typingNameList;
            } else {
              isRecipientsTyping = false;
              isRecipientsTypingName = '';
            }
            /* check for seen status */
            if (seenNameList != '' && conversation['messages'].last['user_id'] == $user['user_id']) {
              isRecipientsSeen = true;
              isRecipientsSeenName = seenNameList;
            } else {
              isRecipientsSeen = false;
              isRecipientsSeenName = '';
            }
            updateSeenStatus();
          });
        }
      } else {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(tr("There is something that went wrong!")),
            ),
          );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(tr("There is something that went wrong!")),
          ),
        );
    }
  }

  // API Call: updateSeenStatus
  Future<void> updateSeenStatus() async {
    final $system = ref.read(systemProvider);
    if (!isTrue($system['chat_seen_enabled'])) return;
    if (conversation.isEmpty) return;
    try {
      await sendAPIRequest(
        'chat/actions/seen',
        method: 'POST',
        body: {
          'ids': conversation['conversation_id'],
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(tr("There is something that went wrong!")),
          ),
        );
    }
  }

  // API Call: deleteMessage
  Future<void> deleteMessage(String messageId) async {
    final response = await sendAPIRequest(
      'chat/message/$messageId',
      method: 'DELETE',
    );
    if (response['statusCode'] == 200) {
      setState(() {
        conversation['messages'].removeWhere((message) => message['message_id'] == messageId);
      });
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          snackBarMessage(tr("Message deleted")),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          snackBarError(response['body']['message']),
        );
    }
  }

  // copy message
  void copyMessage(String message) {
    Clipboard.setData(ClipboardData(text: message));
    showMessageOverlay(context, tr("Copied"));
  }

  // API Call: react message
  Future<void> reactMessage(String messageId, Map<String, dynamic> reaction) async {
    int messageIndex = conversation['messages'].indexWhere((message) => message['message_id'] == messageId);
    String reactionType = reaction['reaction'];
    if (messageIndex != -1) {
      var message = conversation['messages'][messageIndex];
      var action = (message['i_react'] == true && message['i_reaction'] == reactionType) ? 'unreact' : 'react';
      final response = await sendAPIRequest(
        'chat/reactions/react',
        method: 'POST',
        body: {
          'do': action,
          'message_id': messageId,
          'reaction': reactionType,
        },
      );
      if (response['statusCode'] == 200) {
        // check if the user add or remove or change reaction
        if (message['i_react'] == true) {
          if (message['i_reaction'] == reactionType) {
            // remove reaction
            /* decrease total reaction count */
            message['reactions_total_count'] -= 1;
            /* decrease reaction count */
            String countKey = 'reaction_${reactionType}_count';
            int reactionCount = int.parse(message[countKey]);
            reactionCount--;
            message[countKey] = reactionCount.toString();
            message['reactions'][reactionType] = reactionCount.toString();
            /* set reaction [removed reaction] */
            message['i_reaction'] = null;
            /* set user reaction [removed reaction] */
            message['i_react'] = false;
          } else {
            // change reaction from message
            /* decrease reaction count [old reaction] */
            String oldCountKey = 'reaction_${message['i_reaction']}_count';
            int oldReactionCount = int.parse(message[oldCountKey]);
            oldReactionCount--;
            message[oldCountKey] = oldReactionCount.toString();
            message['reactions'][message['i_reaction']] = oldReactionCount.toString();
            /* increase reaction count [new reaction] */
            String newCountKey = 'reaction_${reactionType}_count';
            int newReactionCount = int.parse(message[newCountKey]);
            newReactionCount++;
            message[newCountKey] = newReactionCount.toString();
            message['reactions'][reactionType] = newReactionCount.toString();
            /* set reaction [new reaction] */
            message['i_reaction'] = reactionType;
          }
        } else {
          // add reaction to message
          /* increase total reaction count */
          message['reactions_total_count'] += 1;
          /* increase reaction count */
          String countKey = 'reaction_${reactionType}_count';
          int reactionCount = int.parse(message[countKey]);
          reactionCount++;
          message[countKey] = reactionCount.toString();
          message['reactions'][reactionType] = reactionCount.toString();
          /* set reaction [added reaction] */
          message['i_reaction'] = reactionType;
          /* set user reaction [added reaction] */
          message['i_react'] = true;
        }
        setState(() {
          conversation['messages'][messageIndex] = message;
        });
      } else {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            snackBarError(response['body']['message']),
          );
      }
    }
  }

  // Heartbeat: initHeartbeat
  void initHeartbeat() {
    final $system = ref.read(systemProvider);
    final heartbeatSeconds = ($system['chat_heartbeat'] != null) ? int.parse($system['chat_heartbeat']) : 10;
    heartbeatTimer = Timer.periodic(Duration(seconds: heartbeatSeconds), (timer) {
      chatHeartbeat();
    });
  }

  // Scroll Listener
  void onScroll() {
    if ((scrollController.position.maxScrollExtent - scrollController.position.pixels) <= 50) {
      if (!isLoading && hasMore) {
        getMessages();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getConversation();
    initHeartbeat();
    scrollController.addListener(onScroll);
  }

  @override
  void dispose() {
    super.dispose();
    heartbeatTimer?.cancel();
    scrollController.removeListener(onScroll);
    scrollController.dispose();
    VoiceNotesControllerManager.disposeAllControllers();
  }

  @override
  Widget build(BuildContext context) {
    final $system = ref.read(systemProvider);
    final $user = ref.read(userProvider);
    final languageCode = Localizations.localeOf(context).languageCode;
    setLocaleMessagesForLocale(languageCode);
    switch (loadState) {
      case LoadState.loading:
        return Loading();
      case LoadState.error:
        return Error(
          callback: () {
            setState(() {
              loadState = LoadState.loading;
            });
            getConversation();
          },
        );
      case LoadState.loaded:
        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: conversation.isNotEmpty
                  ? () => context.router.push(
                      ConversationInfoRoute(
                        conversation: {
                          ...conversation,
                          if (widget.userId != null && conversation['user_id'] == null) 'user_id': widget.userId,
                        },
                      ),
                    )
                  : null,
              child: (conversation.isEmpty)
                  ? Row(
                      children: [
                        ProfileAvatar(
                          imageUrl: widget.user!['user_picture']!,
                          isOnline: isTrue(widget.user!['user_is_online']),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              decodeHtmlEntities(widget.user!['user_fullname']),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              (isTrue(widget.user!['user_is_online']))
                                  ? context.tr("Online")
                                  : timeago.format(convertedTime(widget.user!['user_last_seen']), locale: languageCode),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        (isTrue(conversation['multiple_recipients']) && conversation['picture_left'] != null && conversation['picture_right'] != null)
                            ? ProfileAvatarsOverlapping(
                                leftImageUrl: conversation['picture_left'],
                                rightImageUrl: conversation['picture_right'],
                              )
                            : ProfileAvatar(
                                imageUrl: conversation['picture']!,
                                isOnline: isTrue(conversation['user_is_online']),
                              ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conversation['name'],
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            (!isTrue(conversation['multiple_recipients']))
                                ? Text(
                                    (isTrue(conversation['user_is_online']))
                                        ? context.tr("Online")
                                        : timeago.format(convertedTime(conversation['user_last_seen']), locale: languageCode),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                                  )
                                : SizedBox(width: 0),
                          ],
                        ),
                      ],
                    ),
            ),
            actions: [
              if ((conversation.isNotEmpty && !isTrue(conversation['multiple_recipients'])) || widget.user != null) ...[
                if (audioVideoCallEnabled && isTrue($system['audio_call_enabled']) && isTrue($user['can_start_audio_call']))
                  IconButton(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      "assets/images/icons/chat/call_audio.svg",
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(xPrimaryColor, BlendMode.srcIn),
                    ),
                  ),
                if (audioVideoCallEnabled && isTrue($system['video_call_enabled']) && isTrue($user['can_start_video_call']))
                  IconButton(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      "assets/images/icons/chat/call_video.svg",
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(xPrimaryColor, BlendMode.srcIn),
                    ),
                  ),
              ],
            ],
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: (conversation.isEmpty)
                    ? ListView.builder(
                        reverse: true,
                        itemCount: 0,
                        itemBuilder: (context, index) {
                          return SizedBox(width: 0);
                        },
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.only(bottom: 20),
                        reverse: true,
                        itemCount: conversation['messages'].length + (isLoading && hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == conversation['messages'].length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final message = conversation['messages'][conversation['messages'].length - 1 - index];
                          return ChatMessage(
                            key: ValueKey<String>(message['message_id']),
                            message: message,
                            isCurrentUser: message['user_id'] == $user['user_id'],
                            isMultipleRecipients: conversation['multiple_recipients'],
                            onReact: reactMessage,
                            onCopy: copyMessage,
                            onDelete: deleteMessage,
                          );
                        },
                      ),
              ),
              // Seen Status
              if (isRecipientsSeen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SvgPicture.asset(
                        "assets/images/icons/chat/seen.svg",
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(xPrimaryColor, BlendMode.srcIn),
                      ),
                      SizedBox(width: 5),
                      Text(context.tr("Seen by"), style: TextStyle(fontSize: 12)),
                      SizedBox(width: 5),
                      Text(isRecipientsSeenName),
                    ],
                  ),
                ),
              // Typing Indicator
              if (isRecipientsTyping)
                Row(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.all(Radius.circular(40)),
                          ),
                          child: IntrinsicWidth(
                            child: SpinKitThreeBounce(
                              color: Colors.grey,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      isRecipientsTypingName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(context.tr("typing")),
                  ],
                ),
              // Chat Composer
              ChatComposer(
                conversationId: widget.conversationId,
                conversation: conversation as Map<String, dynamic>?,
                user: widget.user,
                onNewMessage: (data) {
                  if (conversation.isEmpty) {
                    setState(() {
                      conversation = data;
                      conversation['messages'] = [];
                      conversation['messages'].add(data['last_message']);
                      isRecipientsSeen = false;
                      isRecipientsSeenName = '';
                    });
                  } else {
                    setState(() {
                      conversation['messages'].add(data['last_message']);
                      isRecipientsSeen = false;
                      isRecipientsSeenName = '';
                    });
                  }
                },
              ),
            ],
          ),
        );
    }
  }
}
