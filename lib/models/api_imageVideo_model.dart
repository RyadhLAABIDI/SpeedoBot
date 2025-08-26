import 'dart:convert';

class ApiResponse {
  final bool success;
  final String? message;
  final double? durationSec; // Changé de 'duration' à 'durationSec'
  final String? videoUrl;

  ApiResponse({
    required this.success,
    this.message,
    this.durationSec,
    this.videoUrl,
  });

  factory ApiResponse.fromJson(int statusCode, String jsonString) {
    if (statusCode >= 200 && statusCode < 300) {
      try {
        final json = jsonDecode(jsonString);
        return ApiResponse(
          success: json['status'] == 'success',
          durationSec: json['duration_sec'] is double ? json['duration_sec'] : (json['duration_sec'] is int ? json['duration_sec'].toDouble() : null),
          videoUrl: json['video_url'] as String?,
        );
      } catch (e) {
        return ApiResponse(success: false, message: 'Invalid JSON response: $e');
      }
    } else {
      return ApiResponse(success: false, message: 'API request failed with status: $statusCode');
    }
  }
}