import 'package:dio/dio.dart';
import 'package:speedobot/models/video_generation_response.dart';

class ApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://vidgen.virtalya.com/api';
  final String _videoBaseUrl = 'https://vidgen.virtalya.com';

  Future<VideoGenerationResponse> generateVideo({
    required String prompt,
    int frames = 20,
    int fps = 15,
    String extra = 'studio lighting',
  }) async {
    final defaultPrompt = 'Slow-motion footage of ';
    final fullPrompt = '$defaultPrompt$prompt';
    print('Starting video generation with parameters:');
    print('  Full Prompt: $fullPrompt');
    print('  Frames: $frames');
    print('  FPS: $fps');
    print('  Extra: $extra');
    print('Request URL: $_baseUrl/generate');

    try {
      final response = await _dio.post(
        '$_baseUrl/generate',
        data: {
          'prompt': fullPrompt,
          'frames': frames,
          'fps': fps,
          'extra': extra,
        },
      );

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('Parsed Response Data: $data');
        if (data['video_url'] != null) {
          String videoUrl = data['video_url'];
          // Vérifier si l'URL est déjà complète ou relative
          if (videoUrl.startsWith('http')) {
            // URL complète, pas de concaténation nécessaire
            data['video_url'] = videoUrl;
          } else {
            // URL relative (par exemple, "/results/..."), concaténer avec _videoBaseUrl
            String videoPath = videoUrl.startsWith('/') ? videoUrl : '/$videoUrl';
            data['video_url'] = '$_videoBaseUrl$videoPath';
          }
          print('Concatenated Video URL: ${data['video_url']}');
        } else {
          print('Warning: video_url is null in response');
        }
        final videoResponse = VideoGenerationResponse.fromJson(data);
        print('Generated VideoResponse: status=${videoResponse.status}, message=${videoResponse.message}, videoUrl=${videoResponse.videoUrl}');
        return videoResponse;
      } else {
        print('API Request Failed with Status Code: ${response.statusCode}');
        print('API Response Body: ${response.data}');
        throw Exception('Failed to generate video: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error during video generation: $e');
      throw Exception('Error during video generation: $e');
    }
  }
}