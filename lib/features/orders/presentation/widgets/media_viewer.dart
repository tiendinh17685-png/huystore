import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:huystore/features/orders/data/models/order_model.dart'; 

class MediaViewer { 
  static void show({
    required BuildContext context,
    required List<RepairMediaModel> medias,
    required int initialIndex,
  }) { 
    final viewableMedias = medias
        .where((m) => m.fileUrl != null && m.fileUrl!.isNotEmpty)
        .toList();

    if (viewableMedias.isEmpty) return;  
    final int initialPage = viewableMedias.indexWhere(
      (m) => m.id == medias[initialIndex].id,
    );

    final controller = PageController(
      initialPage: initialPage >= 0 ? initialPage : 0,
    );
 
    int currentPage = initialPage >= 0 ? initialPage : 0;

    showDialog(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: controller,
                    itemCount: viewableMedias.length, 
                    onPageChanged: (index) {
                      setStateModal(() {
                        currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final media = viewableMedias[index];
                      final isImage = media.fileType == 'image';

                      if (isImage) { 
                        return InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: CachedNetworkImage(
                            imageUrl: media.fileUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 50,
                              ),
                            ),
                          ),
                        );
                      } else { 
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.videocam,
                                  color: Colors.white70,
                                  size: 100,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Tệp Video không thể phát nhúng",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "Vui lòng mở bằng ứng dụng bên ngoài",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text("Mở Video"),
                                  onPressed: () async {
                                    final url = media.fileUrl;
                                    if (url == null) return;
                                    
                                    final uri = Uri.tryParse(url);
                                    if (uri != null && await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Không thể mở video URL",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ), 
                  // ====== HIỂN THỊ SỐ THỨ TỰ (1/N) ======
                  Positioned(
                    top: 30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          // Số hiện tại là currentPage + 1
                          "${currentPage + 1}/${viewableMedias.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Nút đóng (X)
                  Positioned(
                    top: 30,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}