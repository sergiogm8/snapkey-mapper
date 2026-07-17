import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class KofiButton extends StatelessWidget {
  const KofiButton({super.key});

  static final Uri _kofiUri = Uri.parse('https://ko-fi.com/sgmdev');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => launchUrl(_kofiUri, mode: LaunchMode.externalApplication),
      child: Image.asset(
        'assets/ko-fi/support_me_on_kofi_beige.png',
        height: 40,
      ),
    );
  }
}
