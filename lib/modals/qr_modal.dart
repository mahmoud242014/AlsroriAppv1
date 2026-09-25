import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
// Import App Files
import '../providers/system_provider.dart';
import '../providers/user_provider.dart';
import '../utilities/functions.dart';
import '../widgets/profile_avatar.dart';

class QRCodeModal extends ConsumerWidget {
  const QRCodeModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final $user = ref.watch(userProvider);
    final $system = ref.watch(systemProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          tr("QR Code"),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: SizedBox(width: 0),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              ProfileAvatar(
                imageUrl: $user['user_picture'],
                radius: 50,
              ),
              const SizedBox(height: 10),
              Text(
                decodeHtmlEntities($user['user_fullname']),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              // QR Code
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: (Theme.of(context).brightness == Brightness.light) ? Colors.grey[300]! : Colors.grey[800]!,
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: QrImageView(
                    data: '${$system['system_url']}/${$user['user_name']}',
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                    padding: const EdgeInsets.all(30),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                tr("When you share your QR code, People can message and call you"),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  final box = context.findRenderObject() as RenderBox?;
                  SharePlus.instance.share(
                    ShareParams(
                      text: '${$system['system_url']}/${$user['user_name']}',
                      subject: '${$system['system_title']} - ${decodeHtmlEntities($user['user_fullname'])}',
                      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(tr("Share")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
