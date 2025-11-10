import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFlyer(Uint8List imageBytes) async {
    final String fileName = 'flyers/${DateTime.now().millisecondsSinceEpoch}.png';
    final Reference ref = _storage.ref().child(fileName);
    final UploadTask uploadTask = ref.putData(imageBytes);
    final TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
