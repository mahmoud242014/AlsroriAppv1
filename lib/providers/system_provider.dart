// Import Third Party Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import App Files
import 'app_provider.dart';

// System Provider
final systemProvider = Provider<Map<String, dynamic>>((ref) => ref.watch(appProvider).value?['system']);
