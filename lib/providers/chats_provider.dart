// Import Third Party Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatsRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() => state++;
}

final chatsRefreshProvider = NotifierProvider<ChatsRefreshNotifier, int>(ChatsRefreshNotifier.new);
