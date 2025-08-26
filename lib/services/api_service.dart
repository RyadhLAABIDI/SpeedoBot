import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speedobot/models/image_response.dart';

class ApiService {
  static const String _baseUrl = 'https://texttoimg.virtalya.com/api';

  Future<ImageResponse> generateImage(String prompt) async {
    print('ApiService: Envoi de la requête avec le prompt : "$prompt"');
    print('ApiService: URL cible : $_baseUrl/generate');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'prompt': prompt}),
      );

      print('ApiService: Réponse reçue - Code de statut : ${response.statusCode}');
      print('ApiService: Corps de la réponse : ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        print('ApiService: JSON décodé : $json');
        return ImageResponse.fromJson(json);
      } else {
        print('ApiService: Erreur - Code HTTP inattendu : ${response.statusCode}');
        throw Exception('Échec de la génération d\'image : Code HTTP ${response.statusCode}');
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