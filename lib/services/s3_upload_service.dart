import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class S3UploadService {
  /// Picks an image from gallery/camera (caller provides the File),
  /// gets a presigned URL from the backend, uploads to S3, returns the public URL.
  static Future<String> uploadImage(File imageFile) async {
    final filename = imageFile.path.split('/').last;
    final ext = filename.split('.').last.toLowerCase();
    final contentType = _contentType(ext);

    // 1. Get presigned URL from our backend
    final presignRes = await http.post(
      Uri.parse('${ApiService.baseUrl}/upload/presign'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'filename': filename, 'contentType': contentType}),
    );

    if (presignRes.statusCode != 200) {
      throw Exception('Failed to get upload URL');
    }

    final presignData = jsonDecode(presignRes.body);
    final String uploadUrl = presignData['uploadUrl'];
    final String fileUrl = presignData['fileUrl'];

    // 2. PUT the image bytes directly to S3
    final imageBytes = await imageFile.readAsBytes();
    final uploadRes = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: imageBytes,
    );

    if (uploadRes.statusCode != 200) {
      throw Exception('S3 upload failed (${uploadRes.statusCode})');
    }

    return fileUrl;
  }

  static String _contentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}