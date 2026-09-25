import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import App Files
import '../utilities/functions.dart';
import '../widgets/profile_avatar.dart';

class WhoReactsModal extends ConsumerStatefulWidget {
  final String messageId;

  const WhoReactsModal({
    required this.messageId,
    super.key,
  });

  @override
  ConsumerState<WhoReactsModal> createState() => _WhoReactsModalState();
}

class _WhoReactsModalState extends ConsumerState<WhoReactsModal> {
  final scrollController = ScrollController();
  var usersReactions = [];
  int offset = 0;
  bool initialLoadDone = false;
  bool isLoading = false;
  bool hasMore = true;

  // API Call: getUsersReactions
  Future<void> getUsersReactions({bool replace = false}) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    final response = await sendAPIRequest(
      'chat/reactions/who_reacts',
      queryParameters: {
        'message_id': widget.messageId,
        'offset': offset.toString(),
      },
    );
    if (response['statusCode'] == 200) {
      if (response['body']['data'] is List && response['body']['data'].isNotEmpty) {
        setState(() {
          if (replace == true) usersReactions.clear();
          usersReactions.addAll(response['body']['data']);
          offset++;
          if (isTrue(response['body']['has_more'])) {
            hasMore = true;
          } else {
            hasMore = false;
          }
        });
      } else {
        setState(() {
          hasMore = false;
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
    setState(() {
      isLoading = false;
      initialLoadDone = true;
    });
  }

  // Scroll Listener
  void onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isLoading && hasMore) {
        getUsersReactions();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getUsersReactions();
    scrollController.addListener(onScroll);
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.removeListener(onScroll);
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          tr("Reactions"),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: SizedBox(width: 0),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (!initialLoadDone) {
              return Center(child: CircularProgressIndicator());
            } else if (usersReactions.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: Text(tr("No reactions found")),
                    ),
                  ),
                ],
              );
            } else {
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: scrollController,
                itemCount: usersReactions.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < usersReactions.length) {
                    return ListTile(
                      leading: ProfileAvatar(
                        imageUrl: usersReactions[index]['user_picture'],
                        isOnline: isTrue(usersReactions[index]['user_is_online']),
                      ),
                      title: Text(decodeHtmlEntities(usersReactions[index]['user_fullname'])),
                      trailing: CachedNetworkImage(
                        imageUrl: usersReactions[index]['reaction_image_url'],
                        width: 24,
                        height: 24,
                      ),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }
}
