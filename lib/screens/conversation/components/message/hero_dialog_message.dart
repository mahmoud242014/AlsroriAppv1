import 'dart:ui';
import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:easy_localization/easy_localization.dart' show tr;

// Import App Files
import '../../../../widgets/reaction_icon_button.dart';
import '../../../../modals/report_modal.dart';

class HeroDialogMessage extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;
  final Widget child;
  final Map<String, dynamic> reactions;
  final Offset originalPosition;
  final Size originalSize;
  final double reactionsHeight = 55.0;
  final double spacing = 5.0;
  final double menuHeight = 200.0;
  final double bottomPadding = 20.0;
  final Function onReact;
  final Function? onCopy;
  final Function? onDelete;

  const HeroDialogMessage({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.child,
    required this.reactions,
    required this.originalPosition,
    required this.originalSize,
    required this.onReact,
    this.onCopy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final isRTL = (Directionality.of(context) == TextDirection.rtl) ? true : false;
    double columnTop = originalPosition.dy - (reactionsHeight + spacing);
    final double contentHeight = reactionsHeight + spacing + originalSize.height + spacing + menuHeight;
    final double bottomEdge = columnTop + contentHeight;
    final double availableBottom = screenSize.height - safeBottom - bottomPadding;
    if (bottomEdge > availableBottom) {
      final double shiftUp = bottomEdge - availableBottom;
      columnTop -= shiftUp;
      if (columnTop < 0) {
        columnTop = 0;
      }
    }
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Stack(
        children: [
          Positioned(
            top: columnTop,
            child: Material(
              color: Colors.transparent,
              child: Container(
                alignment: isRTL
                    ? (isCurrentUser ? Alignment.centerLeft : Alignment.centerRight)
                    : (isCurrentUser ? Alignment.centerRight : Alignment.centerLeft),
                width: isCurrentUser ? screenSize.width : screenSize.width - 50.0,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                margin: EdgeInsets.only(
                  left: isRTL ? (isCurrentUser ? 50.0 : 0) : (isCurrentUser ? 0 : 50.0),
                  right: isRTL ? (isCurrentUser ? 0 : 50.0) : (isCurrentUser ? 50.0 : 0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Reactions
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3a3b3b) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var reaction in reactions.values) ReactionIconButton(message: message, reaction: reaction, onReact: onReact),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing),
                    // Message
                    Hero(
                      tag: message['message_id'],
                      child: child,
                    ),
                    SizedBox(height: spacing),
                    // Context Menu
                    Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3a3b3b) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: ListTile.divideTiles(
                          context: context,
                          tiles: [
                            // Copy
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              minVerticalPadding: 0,
                              visualDensity: VisualDensity.compact,
                              title: Text(tr("Copy")),
                              trailing: Icon(Icons.copy),
                              onTap: () {
                                if (onCopy != null) {
                                  Navigator.of(context).pop();
                                  onCopy!(message['message_decoded']);
                                }
                              },
                            ),
                            // Delete
                            if (isCurrentUser)
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                minVerticalPadding: 0,
                                visualDensity: VisualDensity.compact,
                                title: Text(tr("Delete"), style: TextStyle(color: Colors.red)),
                                trailing: Icon(Icons.delete, color: Colors.red),
                                onTap: () async {
                                  bool? confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(tr('Delete Message')),
                                      content: Text(tr('Are you sure you want to delete this message?')),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: Text(tr("Cancel")),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: Text(tr("Delete"), style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && onDelete != null) {
                                    Navigator.of(context).pop();
                                    onDelete!(message['message_id']);
                                  }
                                },
                              ),
                            // Report
                            if (!isCurrentUser)
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                minVerticalPadding: 0,
                                visualDensity: VisualDensity.compact,
                                title: Text(tr("Report")),
                                trailing: Icon(Icons.report),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return ReportContentModal(id: message['message_id'], handle: 'message');
                                    },
                                  );
                                },
                              ),
                          ],
                        ).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
