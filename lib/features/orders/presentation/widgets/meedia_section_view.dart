import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:huystore/features/orders/data/models/order_full_model.dart' show RepairMediaModel; 

class MediaViewSection extends StatelessWidget {
  final String? title;
  final List<RepairMediaModel> medias; 
  final Function(BuildContext, List<RepairMediaModel>, int) onMediaTap;
  final MainAxisAlignment axisAlignment; //  
    
  const MediaViewSection({
    Key? key,
    this.title,
    required this.medias, 
    required this.onMediaTap, 
    this.axisAlignment = MainAxisAlignment.start, //  
  }) : super(key: key);
 
  AlignmentGeometry _getAlignment() {
    switch (axisAlignment) {
      case MainAxisAlignment.center:
        return Alignment.center;
      case MainAxisAlignment.end:
        return Alignment.centerRight;
      case MainAxisAlignment.start:
      default:
        return Alignment.centerLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // Giữ nguyên CrossAxisAlignment.center
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Text(title!, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
        ],
          
        if (medias.isNotEmpty) ...[
          const SizedBox(height: 10),
          
          // Dùng Align để căn chỉnh ListView cuộn được
          Align(
            alignment: _getAlignment(), // <-- CĂN CHỈNH DỰA TRÊN THAM SỐ GỐC
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: medias.length,
                shrinkWrap: true, // <-- Bắt buộc để ListView co lại kích thước
                padding: EdgeInsets.zero, // Loại bỏ padding mặc định
                itemBuilder: (context, index) {
                  final media = medias[index];
                  final isImage = media.fileType == 'image';
                  return GestureDetector(
                    onTap: () {
                      if (media.fileUrl != null) {
                        onMediaTap(context, medias, index);
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50, // Cần định nghĩa rõ chiều cao
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image:
                            isImage &&
                                media.fileUrl != null &&
                                media.fileUrl!.isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(media.fileUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!isImage)
                            const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 5,
                              ), 
                              // ),
                              child: Text(
                                isImage ? "" : "",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}