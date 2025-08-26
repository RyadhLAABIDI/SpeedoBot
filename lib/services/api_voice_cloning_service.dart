import 'dart:io';
import 'package:dio/dio.dart';

class VoiceCloningApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://voicecloning.virtalya.com';

  Future<Map<String, dynamic>> cloneVoice({
    required String text,
    required String language,
    required File references,
  }) async {
    print('VoiceCloningApiService: Starting cloneVoice with text="$text", language="$language", references="${references.path}"');
    try {
      print('VoiceCloningApiService: Creating FormData');
      final formData = FormData.fromMap({
        'text': text,
        'language': language,
        'references': await MultipartFile.fromFile(
          references.path,
          filename: references.path.split('/').last,
        ),
      });
      print('VoiceCloningApiService: FormData created with fields: ${formData.fields}, files: ${formData.files.map((e) => e.key).toList()}');

      print('VoiceCloningApiService: Sending POST request to $_baseUrl/api/clone');
      final response = await _dio.post(
        '$_baseUrl/api/clone',
        data: formData,
      );
      print('VoiceCloningApiService: Response received with status code: ${response.statusCode}');
      print('VoiceCloningApiService: Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        print('VoiceCloningApiService: API call successful');
        // Transformer l'URL pour remplacer http://127.0.0.1:5303 par _baseUrl
        String originalUrl = response.data['url'];
        String transformedUrl = originalUrl.replaceFirst(
          RegExp(r'http://127\.0\.0\.1:5303'),
          _baseUrl,
        );
        print('VoiceCloningApiService: Original URL: $originalUrl, Transformed URL: $transformedUrl');
        return {
          'success': true,
          'url': transformedUrl,
        };
      } else {
        print('VoiceCloningApiService: API returned non-success status or invalid response: ${response.data}');
        return {
          'success': false,
          'error': 'API returned an error: ${response.data}',
        };
      }
    } catch (e) {
      print('VoiceCloningApiService: Exception caught: $e');
      return {
        'success': false,
        'error': 'Failed to clone voice: $e',
      };
    }
  }
}