import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:sngine_messenger/utilities/functions.dart';

class ImagePreview extends StatelessWidget {
  final String imageUrl;

  const ImagePreview({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: Colors.white),
            onPressed: () async {
              final saved = await saveImageToGallery(imageUrl);
              if (saved) {
                showMessageOverlay(context, tr("Saved"));
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(8),

        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          loadingBuilder: (context, loadingProgress) => const Center(child: CircularProgressIndicator(color: Colors.white)),
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error, color: Colors.white)),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }
}
