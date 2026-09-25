import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:flutter_svg/svg.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final String image;
  final VoidCallback onTap;

  const SocialLoginButton({
    required this.text,
    required this.image,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            image,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}
