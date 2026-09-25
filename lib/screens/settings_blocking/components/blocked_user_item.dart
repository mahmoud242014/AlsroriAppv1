import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:easy_localization/easy_localization.dart';

// Import App Files
import '../../../utilities/functions.dart';
import '../../../widgets/profile_avatar.dart';
import '../../../widgets/snackbar.dart';

class BlockedUserItem extends StatefulWidget {
  final Map<String, dynamic> user;
  final void Function(Map<String, dynamic> user) onUnblocked;

  const BlockedUserItem({
    super.key,
    required this.user,
    required this.onUnblocked,
  });

  @override
  State<BlockedUserItem> createState() => _BlockedUserItemState();
}

class _BlockedUserItemState extends State<BlockedUserItem> {
  bool isLoading = false;

  // API Call: unblockUser
  Future<void> unblockUser() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    final response = await sendAPIRequest(
      'user/connect',
      method: 'POST',
      body: {
        'do': 'unblock',
        'id': int.parse(widget.user['user_id'].toString()),
      },
    );
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    if (response['statusCode'] == 200) {
      widget.onUnblocked(widget.user);
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(snackBarError(response['body']['message']));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ProfileAvatar(
        imageUrl: widget.user['user_picture'],
        isOnline: widget.user['user_is_online'] == '1',
      ),
      title: Text(decodeHtmlEntities(widget.user['user_fullname'])),
      trailing: ElevatedButton(
        onPressed: unblockUser,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(tr("Unblock")),
      ),
    );
  }
}
