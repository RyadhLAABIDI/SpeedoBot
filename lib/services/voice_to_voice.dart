import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:speedobot/models/voice_to_voice.dart';

class ApiService {
  final Logger _logger = Logger();
  final String _baseUrl = 'https://voicetovoice.virtalya.com';
  // Utiliser la même base URL pour l'audio par défaut
  final String _audioBaseUrl = 'https://voicetovoice.virtalya.com';
  final int _maxRetries = 3;
  final Duration _retryDelay = Duration(seconds: 2);


  Future<List<String>> fetchVideoAvatars() async {
  try {
    _logger.i('Fetching video avatars from API');
    final uri = Uri.parse('https://fullavatar.virtalya.com/api/videos');
    final response = await http.get(uri);
    _logger.i('Video avatars request sent, status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<String> videoUrls = List<String>.from(jsonResponse['videos']);
      _logger.i('Fetched ${videoUrls.length} video avatars');
      return videoUrls;
    } else {
      _logger.e('Failed to fetch video avatars: ${response.statusCode}');
      throw Exception('Failed to fetch video avatars: ${response.statusCode}');
    }
  } catch (e) {
    _logger.e('Error fetching video avatars: $e');
    rethrow;
  }
}

  Future<String> transcribeAudio(File audioFile) async {
    try {
      _logger.i('Preparing to transcribe audio: ${audioFile.path}');
      final uri = Uri.parse('$_baseUrl/api/transcribe');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
      
      final response = await request.send();
      _logger.i('Transcription request sent, status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        final transcription = TranscriptionResponse.fromJson(jsonResponse);
        _logger.i('Transcription response: ${transcription.text}');
        return transcription.text;
      } else {
        _logger.e('Transcription failed with status: ${response.statusCode}');
        throw Exception('Failed to transcribe audio: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error during transcription: $e');
      rethrow;
    }
  }

  Future<String> sendChatMessage(String text) async {
    try {
      _logger.i('Sending chat message: $text');
      final uri = Uri.parse('$_baseUrl/api/chat');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      _logger.i('Chat request sent, status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final chatResponse = ChatResponse.fromJson(jsonResponse);
        _logger.i('Chat response: ${chatResponse.response}');
        return chatResponse.response;
      } else {
        _logger.e('Chat request failed with status: ${response.statusCode}');
        throw Exception('Failed to send chat message: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error during chat request: $e');
      rethrow;
    }
  }

  Future<String> textToSpeech(String text) async {
    try {
      _logger.i('Converting text to speech: $text');
      final uri = Uri.parse('$_baseUrl/api/speak');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      _logger.i('Text-to-speech request sent, status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final speakResponse = SpeakResponse.fromJson(jsonResponse);
        if (speakResponse.audioUrl.isEmpty) {
          _logger.e('Empty audio URL received from speak API');
          throw Exception('Empty audio URL received');
        }
        final fullAudioUrl = '$_audioBaseUrl${speakResponse.audioUrl}';
        _logger.i('Text-to-speech audio URL: $fullAudioUrl');
        // Vérifier si l'URL est valide
        if (!Uri.parse(fullAudioUrl).isAbsolute || !fullAudioUrl.endsWith('.mp3')) {
          _logger.e('Invalid audio URL: $fullAudioUrl');
          throw Exception('Invalid audio URL format');
        }
        return fullAudioUrl;
      } else {
        _logger.e('Text-to-speech failed with status: ${response.statusCode}');
        throw Exception('Failed to convert text to speech: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error during text-to-speech: $e');
      rethrow;
    }
  }

  Future<File> downloadAudio(String audioUrl, String destinationPath) async {
    try {
      _logger.i('Preparing to download audio from: $audioUrl');
      // Essayer plusieurs fois en cas de délai serveur
      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        _logger.i('Download attempt #$attempt for audio: $audioUrl');
        final uri = Uri.parse(audioUrl);
        final response = await http.get(uri);
        _logger.i('Audio download request sent, status code: ${response.statusCode}');

        if (response.statusCode == 200) {
          final file = File(destinationPath);
          await file.writeAsBytes(response.bodyBytes);
          _logger.i('Audio file saved at: $destinationPath, size: ${await file.length()} bytes');
          return file;
        } else {
          _logger.w('Audio download failed with status: ${response.statusCode}');
          if (attempt < _maxRetries) {
            _logger.i('Retrying after ${_retryDelay.inSeconds} seconds...');
            await Future.delayed(_retryDelay);
          } else {
            _logger.e('All download attempts failed for: $audioUrl');
            throw Exception('Failed to download audio: ${response.statusCode}');
          }
        }
      }
      throw Exception('Failed to download audio after $_maxRetries attempts');
    } catch (e) {
      _logger.e('Error during audio download: $e');
      rethrow;
    }
  }
}