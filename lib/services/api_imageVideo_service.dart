import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:speedobot/models/api_imageVideo_model.dart';

class ApiService {
  static const String _baseUrl = 'https://imgaudiotovideo.virtalya.com/api/v1';

  Future<ApiResponse> generateVideoFromImageAndAudio({
    required File imageFile,
    required File audioFile,
    bool preprocess = true,
    bool stillMode = false,
  }) async {
    print('Starting video generation request to $_baseUrl/generate');
    
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/generate'));

    // Ajouter les fichiers
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
    print('Added files - Image: ${imageFile.path}, Audio: ${audioFile.path}');

    // Ajouter les paramètres internes
    request.fields['preprocess'] = preprocess.toString();
    request.fields['still_mode'] = stillMode.toString();
    print('Request fields - preprocess: $preprocess, still_mode: $stillMode');

    try {
      var response = await request.send();
      print('API response status code: ${response.statusCode}');
      var responseBody = await response.stream.bytesToString();
      print('API response body: $responseBody');
      return ApiResponse.fromJson(response.statusCode, responseBody);
    } catch (e) {
      print('Error during API request: $e');
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }
}