class TtsResponse {
  final String audioUrl;
  final bool success;

  TtsResponse({
    required this.audioUrl,
    required this.success,
  });

  factory TtsResponse.fromJson(Map<String, dynamic> json) {
    return TtsResponse(
      audioUrl: json['audio_url'] as String,
      success: json['status'] == 'success', // Convertit "success" en true
    );
  }
}

class Language {
  final String code;
  final String name;

  Language({required this.code, required this.name});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}

class Speaker {
  final String id;
  final String name;

  Speaker({required this.id, required this.name});

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}