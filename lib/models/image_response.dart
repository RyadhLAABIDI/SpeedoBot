class ImageResponse {
  final String filename;
  final String imageUrl;
  final bool success;

  ImageResponse({
    required this.filename,
    required this.imageUrl,
    required this.success,
  });

  factory ImageResponse.fromJson(Map<String, dynamic> json) {
    return ImageResponse(
      filename: json['filename'] as String,
      imageUrl: json['image_url'] as String,
      success: json['success'] as bool,
    );
  }
}