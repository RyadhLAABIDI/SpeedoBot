import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:speedobot/models/remove_background.dart';
import 'dart:convert';


class ApiService {
  static const String _baseUrl = 'https://removebackgroundd.virtalya.com';

  Future<VideoResponse> removeBackgroundVideo({
    required File videoFile,
    required String color,
    required String mode,
  }) async {
    print('ApiService: Envoi de la requête pour supprimer l\'arrière-plan de la vidéo');
    print('ApiService: URL cible : $_baseUrl/remove_bg');
    print('ApiService: Paramètres - color: "$color", mode: "$mode"');

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/remove_bg'),
      );

      // Ajouter les headers
      
      request.headers['Accept'] = 'application/json';
      request.headers['Connection'] = 'keep-alive';

      // Ajouter les champs
      request.fields['color'] = color;
      request.fields['mode'] = mode;

      // Ajouter le fichier vidéo
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          filename: videoFile.path.split('/').last,
        ),
      );

      print('ApiService: Envoi du fichier vidéo : ${videoFile.path}');

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('ApiService: Réponse reçue - Code de statut : ${response.statusCode}');
      print('ApiService: Corps de la réponse : ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        print('ApiService: JSON décodé : $json');
        final videoResponse = VideoResponse.fromJson(json);
        // Concaténer l'URL de base avec le download_url
        videoResponse.downloadUrl = '$_baseUrl${videoResponse.downloadUrl}';
        print('ApiService: URL finale : ${videoResponse.downloadUrl}');
        return videoResponse;
      } else {
        print('3ApiService: Erreur - Code HTTP inattendu : ${response.statusCode}');
        throw Exception('Échec de la suppression d\'arrière-plan : Code HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService: Erreur lors de la requête API : $e');
      if (e is http.ClientException) {
        throw Exception('Erreur réseau : Connexion interrompue - $e');
      } else {
        throw Exception('Erreur réseau : $e');
      }
    }
  }
}