import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Wraps image_picker so widgets never talk to the platform image APIs
/// directly. Every call can legitimately return null (user cancelled),
/// which callers must treat as a normal outcome, not an error.
class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> captureFromCamera() async {
    final XFile? shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // basic client-side compression, see README bonus notes
      maxWidth: 1600,
    );
    if (shot == null) return null; // user cancelled — not an error
    return File(shot.path);
  }

  Future<File?> pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return null;
    return File(picked.path);
  }
}
