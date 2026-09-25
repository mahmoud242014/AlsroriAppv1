import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../common/themes.dart';
import '../../../providers/system_provider.dart';
import '../../../utilities/functions.dart';
import '../../../utilities/voice_recorder.dart';
import '../../../widgets/snackbar.dart';
import '../../../widgets/timer.dart';

class ChatComposer extends ConsumerStatefulWidget {
  final String? conversationId;
  final Map<String, dynamic>? conversation;
  final Map<String, dynamic>? user;
  final List<dynamic>? selectedContacts;
  final Function(Map<String, dynamic>)? onSendMessage;
  final Function(Map<String, dynamic>)? onNewMessage;

  const ChatComposer({
    super.key,
    this.conversationId,
    this.conversation,
    this.user,
    this.selectedContacts,
    this.onSendMessage,
    this.onNewMessage,
  });

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  final textMessageController = TextEditingController();
  Timer? typingTimer;
  bool isTyping = false;
  bool uploadingImage = false;
  String imageUrl = '';
  bool uploadingVideo = false;
  String videoUrl = '';
  Uint8List? videoThumbnail;
  bool isRecording = false;
  String voiceNoteUrl = '';

  // API Call: sendMessage
  Future<void> sendMessage() async {
    final response = await sendAPIRequest(
      'chat/message',
      method: 'POST',
      body: {
        'message': textMessageController.text,
        if (imageUrl.isNotEmpty) 'photo': imageUrl,
        if (videoUrl.isNotEmpty) 'video': videoUrl,
        if (voiceNoteUrl.isNotEmpty) 'voice_note': voiceNoteUrl,
        if (widget.conversation != null && widget.conversation!.isNotEmpty) 'conversation_id': widget.conversation!['conversation_id'],
        if ((widget.conversation == null || widget.conversation!.isEmpty) && widget.user != null) 'recipients': [widget.user!['user_id']].toString(),
        if (widget.selectedContacts != null && widget.selectedContacts!.isNotEmpty)
          'recipients': widget.selectedContacts!.map((e) => e['user_id']).toList().toString(),
      },
    );
    if (response['statusCode'] == 200) {
      if (response['body']['data'] is Map && response['body']['data'].isNotEmpty) {
        widget.onNewMessage?.call(response['body']['data']);
        widget.onSendMessage?.call(response['body']['data']);
        setState(() {
          isTyping = false;
          imageUrl = '';
          videoUrl = '';
          uploadingImage = false;
          uploadingVideo = false;
          voiceNoteUrl = '';
          isRecording = false;
          textMessageController.clear();
        });
      }
    } else if (response['statusCode'] != 500) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          snackBarWarning(response['body']['message']),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(tr("There is something that went wrong!")),
          ),
        );
    }
  }

  // API Call: updateTypingStatus
  Future<void> updateTypingStatus(bool isTyping) async {
    final $system = ref.read(systemProvider);
    if (!isTrue($system['chat_typing_enabled'])) return;
    if (widget.conversation == null || widget.conversation!.isEmpty) return;
    await sendAPIRequest(
      'chat/actions/typing',
      method: 'POST',
      body: {
        'is_typing': isTyping,
        'conversation_id': widget.conversation!['conversation_id'],
      },
    );
  }

  // Handle typing status
  void handleTyping(String value) {
    setState(() {
      isTyping = value.isNotEmpty;
    });
    /* cancel existing timer if any */
    typingTimer?.cancel();
    /* set new timer */
    typingTimer = Timer(const Duration(milliseconds: 500), () {
      updateTypingStatus(value.isNotEmpty);
    });
  }

  // Handle Delete Image
  Future<void> handleDeleteImage() async {
    var src = imageUrl;
    setState(() {
      imageUrl = '';
    });
    await sendAPIRequest(
      'data/delete',
      method: 'POST',
      body: {
        'src': src,
      },
    );
  }

  // Handle Delete Video
  Future<void> handleDeleteVideo() async {
    var src = videoUrl;
    setState(() {
      videoUrl = '';
      videoThumbnail = null;
    });
    await sendAPIRequest(
      'data/delete',
      method: 'POST',
      body: {
        'src': src,
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    typingTimer?.cancel();
    textMessageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final $system = ref.read(systemProvider);
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: Row(
          children: [
            /* Attach Image Button */
            if (isTrue($system['chat_photos_enabled']))
              if ((imageUrl.isEmpty && !uploadingImage) && (videoUrl.isEmpty && !uploadingVideo))
                IconButton(
                  onPressed: () async {
                    final response = await showImageUploadOptions(
                      context: context,
                      setUploadingState: (isUploading) {
                        setState(() {
                          uploadingImage = isUploading;
                        });
                      },
                    );
                    if (response != null) {
                      setState(() {
                        imageUrl = response;
                      });
                    }
                  },
                  icon: SvgPicture.asset(
                    "assets/images/icons/chat/image.svg",
                    colorFilter: ColorFilter.mode(xPrimaryColor, BlendMode.srcIn),
                  ),
                ),
            if (imageUrl.isNotEmpty)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: xPrimaryColor, width: 1),
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage("${$system['system_uploads']}/$imageUrl"),
                    ),
                  ),
                  IconButton(
                    onPressed: handleDeleteImage,
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ],
              ),
            if (uploadingImage)
              Container(
                margin: const EdgeInsets.only(right: 10),
                child: SpinKitDoubleBounce(
                  color: xPrimaryColor,
                  size: 40,
                ),
              ),
            /* Attach Video Button */
            if (isTrue($system['chat_videos_enabled']))
              if ((imageUrl.isEmpty && !uploadingImage) && (videoUrl.isEmpty && !uploadingVideo))
                IconButton(
                  onPressed: () async {
                    final response = await showVideoUploadOptions(
                      context: context,
                      setUploadingState: (isUploading) {
                        setState(() {
                          uploadingVideo = isUploading;
                        });
                      },
                    );
                    if (response != null) {
                      setState(() {
                        videoUrl = response['videoUrl'];
                        videoThumbnail = Uint8List.fromList(response['videoThumbnail']);
                      });
                    }
                  },
                  icon: SvgPicture.asset(
                    "assets/images/icons/chat/video.svg",
                    colorFilter: ColorFilter.mode(xPrimaryColor, BlendMode.srcIn),
                  ),
                ),
            if (videoUrl.isNotEmpty)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: xPrimaryColor, width: 1),
                    ),
                    child: CircleAvatar(
                      backgroundImage: videoThumbnail != null && videoThumbnail!.isNotEmpty
                          ? MemoryImage(videoThumbnail!)
                          : const AssetImage("assets/images/icons/video_placeholder.png"),
                    ),
                  ),
                  IconButton(
                    onPressed: handleDeleteVideo,
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ],
              ),
            if (uploadingVideo)
              Container(
                margin: const EdgeInsets.only(right: 10),
                child: SpinKitDoubleBounce(
                  color: xPrimaryColor,
                  size: 40,
                ),
              ),
            /* Text Message Input */
            Expanded(
              child: Container(
                padding: EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3a3b3b) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: TextField(
                  controller: textMessageController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    hintText: context.tr("Write a message"),
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onChanged: handleTyping,
                ),
              ),
            ),
            /* Send Message Button */
            if (isTyping || imageUrl.isNotEmpty || videoUrl.isNotEmpty)
              IconButton(
                onPressed: sendMessage,
                icon: SvgPicture.asset(
                  "assets/images/icons/chat/send.svg",
                  colorFilter: ColorFilter.mode(xPrimaryColor, BlendMode.srcIn),
                ),
              ),
            /* Voice Note Button */
            if (isTrue($system['voice_notes_chat_enabled']) && !isTyping && imageUrl.isEmpty && videoUrl.isEmpty)
              Row(
                children: [
                  if (isRecording) ...[
                    const TimerWidget(),
                  ],
                  IconButton(
                    onPressed: () async {
                      if (!isRecording) {
                        await VoiceRecorder().startRecording(
                          context: context,
                          setRecordingState: (isRecording) {
                            setState(() {
                              isRecording = isRecording;
                            });
                          },
                        );
                      } else {
                        final response = await VoiceRecorder().stopRecording(
                          context: context,
                          setRecordingState: (isRecording) {
                            setState(() {
                              isRecording = isRecording;
                            });
                          },
                        );
                        if (response != null) {
                          setState(() {
                            voiceNoteUrl = response;
                          });
                          await sendMessage();
                        }
                      }
                    },
                    icon: SvgPicture.asset(
                      "assets/images/icons/chat/mic.svg",
                      colorFilter: ColorFilter.mode(
                        isRecording ? Colors.red : xPrimaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
