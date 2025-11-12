import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final String extension = image.path.split('.').last.toLowerCase();
      if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
        return File(image.path);
      }
    }
    return null;
  }
}
