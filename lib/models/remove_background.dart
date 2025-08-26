class VideoResponse {
  String downloadUrl;
  String status;

  VideoResponse({
    required this.downloadUrl,
    required this.status,
  });

  factory VideoResponse.fromJson(Map<String, dynamic> json) {
    return VideoResponse(
      downloadUrl: json['download_url'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'download_url': downloadUrl,
      'status': status,
    };
  }
}