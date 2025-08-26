import 'package:dio/dio.dart';
import 'dart:io';

class ImageEnhancerService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://enhancer.virtalya.com';

  Future<String?> enhanceImage({
    required File imageFile,
  }) async {
    try {
      print('ImageEnhancerService: Début de enhanceImage');
      print('ImageEnhancerService: Chemin du fichier image: ${imageFile.path}');

      // Créer le FormData avec les paramètres requis
      print('ImageEnhancerService: Création du FormData');
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
        'version': '1.3',
        'upscale': 2,
        'bg_tile': 400,
      });
      print('ImageEnhancerService: FormData créé avec succès');

      // Envoyer la requête POST à l'API
      print('ImageEnhancerService: Envoi de la requête POST à https://enhancer.virtalya.com/enhance');
      final response = await _dio.post(
        'https://enhancer.virtalya.com/enhance_api',
        data: formData,
        options: Options(
          responseType: ResponseType.json,
        ),
      );
      print('ImageEnhancerService: Requête envoyée, statut HTTP: ${response.statusCode}');
      print('ImageEnhancerService: Réponse complète: ${response.data}');

      // Vérifier la réponse
      if (response.statusCode == 200 && response.data != null) {
        print('ImageEnhancerService: Réponse valide reçue, traitement des données');
        // Extraire l'URL de l'image
        final imageUrl = response.data['image_url'] as String?;
        print('ImageEnhancerService: Valeur extraite pour image_url: $imageUrl');
        if (imageUrl != null) {
          // Remplacer dynamiquement http://127.0.0.1:5088 par https://enhancer.virtalya.com
          final path = imageUrl.replaceFirst('http://127.0.0.1:5088', '');
          final fullUrl = '$_baseUrl$path';
          print('ImageEnhancerService: URL finale de l\'image améliorée: $fullUrl');
          return fullUrl;
        }
        print('ImageEnhancerService: Erreur - URL de l\'image non trouvée dans la réponse');
        throw Exception('URL de l\'image non trouvée dans la réponse');
      } else {
        print('ImageEnhancerService: Échec de la requête, statut: ${response.statusCode}, données: ${response.data}');
        throw Exception('Échec de la requête: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('ImageEnhancerService: Erreur lors de l\'amélioration de l\'image: $e');
      print('ImageEnhancerService: Stack trace: $stackTrace');
      throw Exception('Échec de l\'amélioration de l\'image: $e');
    }
  }
}