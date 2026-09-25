import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import App Files
import '../../utilities/functions.dart';
import '../../widgets/no_data.dart';
import 'components/blocked_user_item.dart';

@RoutePage()
class SettingsBlockingScreen extends ConsumerStatefulWidget {
  static const routeName = 'blocking';

  const SettingsBlockingScreen({super.key});

  @override
  ConsumerState<SettingsBlockingScreen> createState() => _SettingsBlockingScreenState();
}

class _SettingsBlockingScreenState extends ConsumerState<SettingsBlockingScreen> {
  var users = [];
  int offset = 0;
  bool initialLoadDone = false;
  bool isLoading = false;
  bool hasMore = true;

  // API Call: loadBlocked
  Future<void> loadBlocked() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    final response = await sendAPIRequest(
      'user/blocked',
      queryParameters: {
        'offset': offset.toString(),
      },
    );
    if (response['statusCode'] == 200) {
      final List data = response['body']['data'] ?? [];
      setState(() {
        users.addAll(data);
        offset++;
        hasMore = response['body']['has_more'] == true;
      });
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

  // Pull-to-refresh: reset paging state then reload from page 0.
  Future<void> refresh() async {
    if (isLoading) return;
    setState(() {
      users.clear();
      offset = 0;
      hasMore = true;
      initialLoadDone = false;
    });
    await loadBlocked();
  }

  @override
  void initState() {
    super.initState();
    loadBlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("Blocking")),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: Builder(
            builder: (context) {
              if (!initialLoadDone) {
                return const Center(child: CircularProgressIndicator());
              } else if (users.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: NoData(text: tr("No blocked users")),
                    ),
                  ],
                );
              }
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: users.length + 1,
                itemBuilder: (context, index) {
                  if (index < users.length) {
                    return BlockedUserItem(
                      user: Map<String, dynamic>.from(users[index]),
                      onUnblocked: (_) {
                        setState(() {
                          users.removeAt(index);
                        });
                      },
                    );
                  }
                  if (isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (hasMore) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: loadBlocked,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text(tr("Load More")),
                        ),
                      ),
                    );
                  }
                  if (offset > 1) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          tr("No more data to load"),
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
