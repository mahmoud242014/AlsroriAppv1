import 'package:flutter/material.dart';

// SnackBar Types
enum SnackBarType { message, error, warning, info, success }

// Normal SnackBar
SnackBar snackBarMessage(String message) {
  return SnackBar(
    content: SnackBarContent(message: message, type: SnackBarType.message),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
  );
}

// Error SnackBar
SnackBar snackBarError(String message) {
  return SnackBar(
    content: SnackBarContent(message: message, type: SnackBarType.error),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
  );
}

// Success SnackBar
SnackBar snackBarSuccess(String message) {
  return SnackBar(
    content: SnackBarContent(message: message, type: SnackBarType.success),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
  );
}

// Warning SnackBar
SnackBar snackBarWarning(String message) {
  return SnackBar(
    content: SnackBarContent(message: message, type: SnackBarType.warning),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
  );
}

// Info SnackBar
SnackBar snackBarInfo(String message) {
  return SnackBar(
    content: SnackBarContent(message: message, type: SnackBarType.info),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
  );
}

// SnackBarContent
class SnackBarContent extends StatelessWidget {
  final String message;
  final SnackBarType type;

  const SnackBarContent({
    super.key,
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (type) {
      case SnackBarType.message:
        color = const Color(0xFF545454);
        break;
      case SnackBarType.error:
        color = const Color(0xFFc72c41);
        break;
      case SnackBarType.warning:
        color = const Color(0xFFef8d32);
        break;
      case SnackBarType.info:
        color = const Color(0xFF0070e0);
        break;
      case SnackBarType.success:
        color = const Color(0xFF0d7040);
        break;
    }
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
