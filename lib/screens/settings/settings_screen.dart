import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

// Import App Files
import '../../providers/system_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/router.gr.dart';
import '../../utilities/functions.dart';
import '../../widgets/snackbar.dart';
import 'components/menu_tile.dart';
import '../../modals/qr_modal.dart';

@RoutePage()
class SettingsScreen extends StatelessWidget {
  static const routeName = 'settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(context.tr("Settings")),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                useRootNavigator: true,
                isScrollControlled: true,
                builder: (context) {
                  return QRCodeModal();
                },
              );
            },
            icon: SvgPicture.asset(
              'assets/images/icons/settings/qr.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
      body: _Body(),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body();

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool uploadingImage = false;

  // API Call: deleteProfilePicture
  Future<void> deleteProfilePicture() async {
    if (uploadingImage) return;
    setState(() {
      uploadingImage = true;
    });
    // delete the image
    final response = await sendAPIRequest(
      'user/image_delete',
      method: 'POST',
      body: {
        'handle': 'picture-user',
      },
    );
    setState(() {
      uploadingImage = false;
    });
    if (response['statusCode'] == 200) {
      var userPicture = "${response['body']['data']}";
      // update user provider data
      ref.read(userProvider.notifier).update('user_picture', userPicture);
      ref.read(userProvider.notifier).update('user_picture_default', true);
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          snackBarError(response['body']['message']),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final $system = ref.watch(systemProvider);
    final $user = ref.watch(userProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Profile Card
            Column(
              children: [
                Stack(
                  children: [
                    (uploadingImage)
                        ? const SizedBox(
                            height: 160,
                            width: 160,
                            child: CircularProgressIndicator(),
                          )
                        : CircleAvatar(
                            radius: 80,
                            backgroundImage: NetworkImage($user['user_picture']),
                          ),
                    // Upload Button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () async {
                            final response = await showImageUploadOptions(
                              context: context,
                              handle: 'picture-user',
                              setUploadingState: (isUploading) {
                                setState(() {
                                  uploadingImage = isUploading;
                                });
                              },
                            );
                            if (response != null) {
                              var userPicture = "${$system['system_uploads']}/$response";
                              ref.read(userProvider.notifier).update('user_picture', userPicture);
                              ref.read(userProvider.notifier).update('user_picture_default', false);
                            }
                          },
                          icon: const Icon(Icons.camera_alt_rounded),
                        ),
                      ),
                    ),
                    // Delete Button
                    if (!isTrue($user['user_picture_default']))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: deleteProfilePicture,
                            icon: const Icon(Icons.delete_rounded),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  decodeHtmlEntities($user['user_fullname']),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  '@${$user['user_name']}',
                ),
              ],
            ),
            const SizedBox(height: 40),
            // language Menu Tile
            MenuTile(
              onTab: () {
                context.router.push(const SettingsLanguagesRoute());
              },
              title: tr("Language"),
              icon: SvgPicture.asset(
                'assets/images/icons/settings/translation.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
            // Theme Menu Tile
            MenuTile(
              onTab: () {
                context.router.push(const SettingsThemeRoute());
              },
              title: tr("Appearance"),
              icon: SvgPicture.asset(
                'assets/images/icons/settings/appearance.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
            // Delete Account Menu Tile
            MenuTile(
              onTab: () {
                context.router.push(const SettingsDeleteRoute());
              },
              title: tr("Delete Account"),
              icon: SvgPicture.asset(
                'assets/images/icons/settings/delete.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
            // Blocking Menu Tile
            MenuTile(
              onTab: () {
                context.router.push(const SettingsBlockingRoute());
              },
              title: tr("Blocking"),
              icon: SvgPicture.asset(
                'assets/images/icons/settings/user_block.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
            // Sign Out Menu Tile
            MenuTile(
              onTab: () async {
                final response = await sendAPIRequest(
                  'auth/signout',
                  method: 'POST',
                );
                if (response['statusCode'] == 200) {
                  await removeSharedPref('x-auth-token');
                  context.router.replaceAll([const SignInRoute()]);
                }
              },
              title: tr("Sign Out"),
              icon: SvgPicture.asset(
                'assets/images/icons/settings/signout.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
