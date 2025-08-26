class VideoGenerationResponse {
  final String status;
  final String message;
  final String? videoUrl;

  VideoGenerationResponse({
    required this.status,
    required this.message,
    this.videoUrl,
  });

  factory VideoGenerationResponse.fromJson(Map<String, dynamic> json) {
    return VideoGenerationResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      videoUrl: json['video_url'] as String?,
    );
  }

  bool get success => status.toLowerCase() == 'ok';
}