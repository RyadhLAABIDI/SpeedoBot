import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speedobot/models/tts_response.dart';

class TtsApiService {
  final String _baseUrl = 'https://speechtoaudio.virtalya.com/api/v1';
  final String _baseDomain = 'https://speechtoaudio.virtalya.com'; // Ajouté pour les URL absolues

  // Données de secours basées sur le speaker_map fourni
  final Map<String, int> _speakerMap = {
    "KR": 0,
    "ES": 1,
    "FR": 2,
    "ZH": 3,
    "EN-US": 4,
    "EN-BR": 5,
    "EN-INDIA": 6,
    "EN-AU": 7,
    "EN-Default": 8,
  };

  // Générer un audio à partir du texte
  Future<TtsResponse> generateAudio({
    required String text,
    required String language,
    required String speaker,
    required double speed,
  }) async {
    print('Envoi de la requête TTS avec : text="$text", language="$language", speaker="$speaker", speed=$speed');
    print('URL cible : $_baseUrl/tts');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'language': language,
          'speaker': speaker,
          'speed': speed,
          'format': 'mp3',
        }),
      );

      print('Réponse reçue - Code de statut : ${response.statusCode}');
      print('Corps de la réponse : ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        print('JSON décodé : $json');
        // Transformer l'URL relative en URL absolue
        final audioUrl = json['audio_url'].startsWith('/')
            ? '$_baseDomain${json['audio_url']}'
            : json['audio_url'];
        return TtsResponse.fromJson({
          ...json,
          'audio_url': audioUrl, // Remplacer l'URL relative par l'URL absolue
        });
      } else {
        print('Erreur : Code HTTP inattendu : ${response.statusCode}');
        throw Exception('Échec de la génération audio : Code HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la requête TTS : $e');
      throw Exception('Erreur réseau : $e');
    }
  }

  // Récupérer la liste des langues disponibles
  Future<List<Language>> getLanguages() async {
    print('Envoi de la requête pour récupérer les langues');
    print('URL cible : $_baseUrl/language');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/language'),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('Réponse reçue - Code de statut : ${response.statusCode}');
      print('Corps de la réponse : ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json.map((item) => Language.fromJson(item)).toList();
      } else {
        print('Erreur : Code HTTP inattendu : ${response.statusCode}');
        // Solution de secours : utiliser les clés du speaker_map comme langues
        return _speakerMap.keys.map((code) {
          return Language(
            code: code,
            name: _getLanguageName(code),
          );
        }).toList();
      }
    } catch (e) {
      print('Erreur lors de la requête des langues : $e');
      // Solution de secours en cas d'erreur réseau
      return _speakerMap.keys.map((code) {
        return Language(
          code: code,
          name: _getLanguageName(code),
        );
      }).toList();
    }
  }

  // Récupérer la liste des locateurs disponibles
  Future<List<Speaker>> getSpeakers() async {
    print('Envoi de la requête pour récupérer les locateurs');
    print('URL cible : $_baseUrl/speaker');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/speaker'),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('Réponse reçue : ${response.statusCode}');
      print('Corps de la réponse : ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json.map((item) => Speaker.fromJson(item)).toList();
      } else {
        print('Erreur : Code HTTP inattendu : ${response.statusCode}');
        // Solution de secours : utiliser le speaker_map
        return _speakerMap.keys.map((id) {
          return Speaker(
            id: id,
            name: id,
          );
        }).toList();
      }
    } catch (e) {
      print('Erreur lors de la requête des locuteurs : $e');
      // Solution de secours
      return _speakerMap.keys.map((speaker) {
        return Speaker(
          id: speaker,
          name: speaker,
        );
      }).toList();
    }
  }

  // Fonction utilitaire pour obtenir un nom de langue lisible
  String _getLanguageName(String code) {
    switch (code) {
      case 'KR':
        return 'Coréen';
      case 'ES':
        return 'Espagnol';
      case 'FR':
        return 'Français';
      case 'ZH':
        return 'Chinois';
      case 'EN-US':
        return 'Anglais (US)';
      case 'EN-BR':
        return 'Anglais (Britannique)';
      case 'EN-INDIA':
        return 'Anglais (Inde)';
      case 'EN-AU':
        return 'Anglais (Australie)';
      case 'EN-Default':
        return 'Anglais (Défaut)';
      default:
        return code;
    }
  }
}