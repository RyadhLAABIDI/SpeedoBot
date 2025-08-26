import 'package:logger/logger.dart';

class TranscriptionResponse {
  final String text;

  TranscriptionResponse({required this.text});

  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    final logger = Logger();
    final text = json['text'] as String? ?? '';
    logger.i('Parsed TranscriptionResponse: text=$text');
    return TranscriptionResponse(text: text);
  }

  Map<String, dynamic> toJson() => {'text': text};
}

class ChatResponse {
  final String response;

  ChatResponse({required this.response});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final logger = Logger();
    final response = json['response'] as String? ?? '';
    logger.i('Parsed ChatResponse: response=$response');
    return ChatResponse(response: response);
  }

  Map<String, dynamic> toJson() => {'response': response};
}

class SpeakResponse {
  final String audioUrl;

  SpeakResponse({required this.audioUrl});

  factory SpeakResponse.fromJson(Map<String, dynamic> json) {
    final logger = Logger();
    final audioUrl = json['audio_url'] as String? ?? '';
    logger.i('Parsed SpeakResponse: audioUrl=$audioUrl');
    return SpeakResponse(audioUrl: audioUrl);
  }

  Map<String, dynamic> toJson() => {'audio_url': audioUrl};
}
