import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:easy_localization/easy_localization.dart';
import 'package:pinput/pinput.dart';

// commons properties
const xPrimaryColor = Color(0xFF5e72e4);
const xBackgroundColor = Color(0xFFFFFFFF);
const xBackgroundColorDark = Color(0xFF000000);
const xTextColor = Color(0xFF000000);
const xTextColorDark = Color(0xFFFFFFFF);
const xTextLinkColor = Color(0xFF5e72e4);
const xBorderColor = Color(0xFFE6E6E6);
const xBorderColorDark = Color(0xFF545454);
const xButtonPrimaryColor = Color(0xFF000000);
const xButtonPrimaryColorDark = Color(0xFFFFFFFF);

// app theme
ThemeData appTheme({bool isDark = false, BuildContext? context}) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      primary: xTextLinkColor,
      seedColor: xPrimaryColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ),
    fontFamily: context?.locale == const Locale('ar', 'SA') ? "Tajawal" : "Poppins",
    scaffoldBackgroundColor: isDark ? xBackgroundColorDark : xBackgroundColor,
    textTheme: textTheme(isDark: isDark, context: context),
    appBarTheme: appBarTheme(isDark: isDark, context: context),
    inputDecorationTheme: inputDecorationTheme(isDark: isDark, context: context),
    textButtonTheme: textButtonTheme(isDark: isDark, context: context),
    elevatedButtonTheme: elevatedButtonTheme(isDark: isDark, context: context),
    outlinedButtonTheme: outlinedButtonTheme(isDark: isDark, context: context),
    bottomSheetTheme: bottomSheetTheme(isDark: isDark, context: context),
    dialogTheme: dialogTheme(isDark: isDark, context: context),
    progressIndicatorTheme: progressIndicatorTheme(isDark: isDark, context: context),
    dividerTheme: dividerTheme(isDark: isDark, context: context),
  );
}

// app bar theme
AppBarTheme appBarTheme({bool isDark = false, BuildContext? context}) {
  return AppBarTheme().copyWith(
    backgroundColor: isDark ? xBackgroundColorDark : xBackgroundColor,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: context?.locale == const Locale('ar', 'SA') ? "Tajawal" : "Quicksand",
      fontSize: 24,
      color: isDark ? xTextColorDark : xTextColor,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(
      color: isDark ? xTextColorDark : xTextColor,
      size: 24,
    ),
  );
}

// text theme
TextTheme textTheme({bool isDark = false, BuildContext? context}) {
  return TextTheme().copyWith(
    bodyLarge: TextStyle(
      color: isDark ? xTextColorDark : xTextColor,
    ),
    bodyMedium: TextStyle(
      color: isDark ? xTextColorDark : xTextColor,
    ),
    bodySmall: TextStyle(
      color: isDark ? xTextColorDark : xTextColor,
    ),
    titleSmall: TextStyle(
      color: isDark ? xTextColorDark : xTextColor,
    ),
    titleMedium: TextStyle(
      color: isDark ? xTextColorDark : xTextColor,
    ),
    titleLarge: TextStyle(
      color: isDark ? xTextColorDark : xTextColor,
      fontWeight: FontWeight.bold,
    ),
  );
}

// input decoration theme
InputDecorationTheme inputDecorationTheme({bool isDark = false, BuildContext? context}) {
  var outlineInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(
      color: (isDark) ? xBorderColorDark : xBorderColor,
    ),
  );
  var outlineInputBorderFocused = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(
      color: (isDark) ? Color(0xFFFFFFFF) : Color(0xFF000000),
    ),
  );
  var outlineInputErrorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(
      color: Color(0xFFB91E1E),
    ),
  );
  return InputDecorationTheme(
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    labelStyle: isDark ? TextStyle(color: xTextColorDark) : TextStyle(color: Color(0xFF5D5D5D), fontSize: 14),
    floatingLabelStyle: isDark ? TextStyle(color: Color(0xFFFFFFFF)) : TextStyle(color: Color(0xFF000000)),
    suffixIconColor: isDark ? xTextColorDark : Color(0xFF5D5D5D),
    enabledBorder: outlineInputBorder,
    focusedBorder: outlineInputBorderFocused,
    errorBorder: outlineInputErrorBorder,
    focusedErrorBorder: outlineInputErrorBorder,
  );
}

// text button theme
TextButtonThemeData textButtonTheme({bool isDark = false, BuildContext? context}) {
  return TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: xTextLinkColor,
      textStyle: TextStyle(
        fontFamily: context?.locale == const Locale('ar', 'SA') ? "Tajawal" : "Quicksand",
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// elevated button theme
ElevatedButtonThemeData elevatedButtonTheme({bool isDark = false, BuildContext? context}) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: (isDark) ? xButtonPrimaryColorDark : xButtonPrimaryColor,
      foregroundColor: (isDark) ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      textStyle: TextStyle(
        fontFamily: context?.locale == const Locale('ar', 'SA') ? "Tajawal" : "Quicksand",
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// outlined button theme
OutlinedButtonThemeData outlinedButtonTheme({bool isDark = false, BuildContext? context}) {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: (isDark) ? xTextColorDark : xTextColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      side: BorderSide(color: (isDark) ? xBorderColorDark : xBorderColor),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
      textStyle: TextStyle(
        color: (isDark) ? xTextColorDark : xTextColor,
        fontFamily: context?.locale == const Locale('ar', 'SA') ? "Tajawal" : "Quicksand",
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// modal bottom sheet theme
BottomSheetThemeData bottomSheetTheme({bool isDark = false, BuildContext? context}) {
  return BottomSheetThemeData(
    backgroundColor: (isDark) ? Color(0xFF333333) : Colors.white,
  );
}

// dialog theme
DialogThemeData dialogTheme({bool isDark = false, BuildContext? context}) {
  return DialogThemeData(
    backgroundColor: (isDark) ? Color(0xFF333333) : Colors.white,
  );
}

// progress indicator theme
ProgressIndicatorThemeData progressIndicatorTheme({bool isDark = false, BuildContext? context}) {
  return ProgressIndicatorThemeData(
    color: xPrimaryColor,
  );
}

// divider theme
DividerThemeData dividerTheme({bool isDark = false, BuildContext? context}) {
  return DividerThemeData(
    color: isDark ? xBorderColorDark : xBorderColor,
    thickness: 1,
    indent: 10,
    endIndent: 10,
  );
}

// pinput theme
PinTheme defaultPinputTheme({bool isDark = false}) {
  return PinTheme(
    width: 56,
    height: 56,
    textStyle: TextStyle(fontSize: 20),
    decoration: BoxDecoration(
      border: (isDark) ? Border.all(color: xBorderColorDark) : Border.all(color: xBorderColor),
      borderRadius: BorderRadius.circular(18),
    ),
  );
}
