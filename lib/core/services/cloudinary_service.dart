import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'rx0u8fhd',      // cloud name
    'upload_pictures',  // upload preset (must be UNSIGNED)
    cache: false,
  );

  Future<String> uploadImage(XFile image) async {
    try {
      CloudinaryResponse response;

      // 🌐 WEB SUPPORT
      if (kIsWeb) {
        final bytes = await image.readAsBytes();

        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            bytes,
            identifier: image.name,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
      }

      // 📱 MOBILE SUPPORT
      else {
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            image.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
      }

      return response.secureUrl;
    } catch (e) {
      throw Exception("Cloudinary Upload Failed: $e");
    }
  }
}