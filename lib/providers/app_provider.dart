// Import Third Party Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import App Files
import '../utilities/functions.dart';

// App Provider
final appProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await sendAPIRequest('app/settings');
    if (response['statusCode'] == 200) {
      return response['body']['data'];
    } else {
      throw "Something went wrong!";
    }
  } catch (e) {
    throw "Something went wrong!";
  }
});
