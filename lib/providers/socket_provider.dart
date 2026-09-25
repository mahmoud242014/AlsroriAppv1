// Import Third Party Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import App Files
import '../utilities/socket.dart';

// Socket Provider
final socketProvider = Provider<SocketService>((ref) => SocketService());
