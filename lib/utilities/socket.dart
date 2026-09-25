import 'package:socket_io_client/socket_io_client.dart' as IO;

// Import App Files
import '../common/config.dart' as config;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late final IO.Socket socket;

  Future<void> connect(String token) async {
    socket = IO.io(
      "${config.apiURL}:3000",
      IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().setQuery({'jwt': token}).build(),
    );
    socket.connect();

    socket.onConnect((_) {
      print("✅ Connected to socket.io 🥳");
    });

    socket.on("event", (data) {
      print("📩 Event: $data");
    });

    socket.onDisconnect((_) {
      print("❌ Disconnected");
    });

    socket.onConnect((_) => print("✅ Connected event fired"));
    socket.onConnectError((data) => print("🚨 Connect error: $data"));

    socket.onError((err) {
      print("⚠️ Error: $err");
    });
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void on(String event, Function(dynamic data) callback) {
    socket.on(event, callback);
  }

  void disconnect() {
    socket.disconnect();
  }
}
