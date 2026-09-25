import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import App Files
import '../../providers/chats_provider.dart';
import '../../utilities/functions.dart';
import '../../widgets/profile_avatars_overlapping.dart';
import '../../widgets/snackbar.dart';
import '../../modals/report_modal.dart';
import '../settings/components/menu_tile.dart';

@RoutePage()
class ConversationInfoScreen extends ConsumerStatefulWidget {
  static const routeName = '/conversation-info';

  final Map<String, dynamic> conversation;

  const ConversationInfoScreen({super.key, required this.conversation});

  @override
  ConsumerState<ConversationInfoScreen> createState() => _ConversationInfoScreenState();
}

class _ConversationInfoScreenState extends ConsumerState<ConversationInfoScreen> {
  bool isBlocking = false;
  bool isDeleting = false;
  bool isLeaving = false;

  Future<void> blockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Block User')),
        content: Text(tr('Are you sure you want to block this user?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Block'))),
        ],
      ),
    );
    if (confirmed != true) return;
    final rawUserId = widget.conversation['user_id'];
    if (rawUserId == null) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(snackBarError(tr('Unable to block: user not found')));
      return;
    }
    setState(() => isBlocking = true);
    final response = await sendAPIRequest(
      'user/connect',
      method: 'POST',
      body: {
        'do': 'block',
        'id': int.parse(rawUserId.toString()),
      },
    );
    setState(() => isBlocking = false);
    if (!mounted) return;
    if (response['statusCode'] == 200) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(snackBarMessage(tr('User blocked')));
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(snackBarError(response['body']['message']));
    }
  }

  Future<void> deleteChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Delete Conversation')),
        content: Text(tr('Are you sure you want to delete this conversation?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Delete'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => isDeleting = true);
    final response = await sendAPIRequest(
      'chat/conversation/${widget.conversation['conversation_id']}',
      method: 'DELETE',
    );
    setState(() => isDeleting = false);
    if (!mounted) return;
    if (response['statusCode'] == 200) {
      ref.read(chatsRefreshProvider.notifier).refresh();
      context.router.popUntilRoot();
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(snackBarError(response['body']['message']));
    }
  }

  void reportConversation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => ReportContentModal(
          id: widget.conversation['conversation_id'].toString(),
          handle: 'conversation',
        ),
      ),
    );
  }

  Future<void> leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Leave Group')),
        content: Text(tr('Are you sure you want to leave this group?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Leave'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => isLeaving = true);
    final response = await sendAPIRequest(
      'chat/actions/leave',
      method: 'POST',
      body: {
        'conversation_id': widget.conversation['conversation_id'],
      },
    );
    setState(() => isLeaving = false);
    if (!mounted) return;
    if (response['statusCode'] == 200) {
      ref.read(chatsRefreshProvider.notifier).refresh();
      context.router.popUntilRoot();
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(snackBarError(response['body']['message']));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = isTrue(widget.conversation['multiple_recipients']);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              // Profile section
              Center(
                child: Column(
                  children: [
                    if (isGroup && widget.conversation['picture_left'] != null && widget.conversation['picture_right'] != null)
                      ProfileAvatarsOverlapping(
                        leftImageUrl: widget.conversation['picture_left'],
                        rightImageUrl: widget.conversation['picture_right'],
                        radius: 40,
                      )
                    else
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(widget.conversation['picture'] ?? ''),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      decodeHtmlEntities(widget.conversation['name']),
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Privacy section label
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  tr('Privacy'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
              // Privacy actions
              if (!isGroup)
                MenuTile(
                  onTab: isBlocking ? () {} : blockUser,
                  title: isBlocking ? tr('Blocking...') : tr('Block User'),
                  icon: Icon(
                    Icons.block_rounded,
                    size: 24,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              if (isGroup)
                MenuTile(
                  onTab: isLeaving ? () {} : leaveGroup,
                  title: isLeaving ? tr('Leaving...') : tr('Leave Group'),
                  icon: Icon(
                    Icons.logout_rounded,
                    size: 24,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              MenuTile(
                onTab: reportConversation,
                title: tr('Report Conversation'),
                icon: Icon(
                  Icons.report_outlined,
                  size: 24,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              MenuTile(
                onTab: isDeleting ? () {} : deleteChat,
                title: isDeleting ? tr('Deleting...') : tr('Delete Chat'),
                textColor: Colors.red,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 24,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
