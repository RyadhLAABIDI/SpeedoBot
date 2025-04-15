import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreen();
}

class _ImageGenerationScreen extends State<ImageGenerationScreen> {
  final TextEditingController _imageGenPromptController = TextEditingController();
  String? _generatedImageUrl; // Variable pour stocker l'URL de l'image générée
  bool _isLoading = false; // Indicateur de chargement

  // Définir les couleurs principales
  final Color textColor = const Color(0xFF3ECAA7); // Texte en #3ecaa7
  final Color hintTextColor = const Color(0xFF3ECAA7); // HintText en #3ecaa7

  // Fonction pour appeler l'API et générer l'image
  Future<void> _generateImage() async {
  final prompt = _imageGenPromptController.text;
  if (prompt.isEmpty) return;

  setState(() => _isLoading = true);

  try {
    final response = await http.post(
      Uri.parse('https://imagespeedo.speedobot.com/generate-image'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'inputs': prompt}),
    ).timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final imageUrl = data['image_url']?.toString(); // Utilisation de la bonne clé

      if (imageUrl?.isEmpty ?? true) {
        throw Exception('URL d\'image vide');
      }

      setState(() => _generatedImageUrl = imageUrl);
    } else {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }
  } catch (e) {
    _showErrorMessage('Erreur: ${e.toString().replaceAll('Exception: ', '')}');
    setState(() => _generatedImageUrl = null);
  } finally {
    setState(() => _isLoading = false);
  }
}
  // Afficher un message d'erreur
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(isDarkMode),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'enter_prompt'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,  // Appliquer la couleur pour le texte
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImageGenPromptField(),
                  const SizedBox(height: 16),
                  _buildGenerateButton(),
                  const SizedBox(height: 24),
                  _buildImageGenResult(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildImageGenPromptField() {
  return TextFormField(
    controller: _imageGenPromptController,
    style: const TextStyle(color: Colors.white), // Texte entré en blanc
    decoration: InputDecoration(
      labelText: 'describe_generate'.tr,
      labelStyle: TextStyle(color: textColor), // Label en #3ecaa7
      hintText: 'describe_generate'.tr,
      hintStyle: TextStyle(color: hintTextColor), // HintText en #3ecaa7
      // Définir la couleur de fond
      filled: true,
      fillColor: Colors.black, // Fond noir
      // Ajout de la bordure et de la couleur de bordure
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // Bordure arrondie
        borderSide: BorderSide(
          color: textColor, // Couleur de la bordure (identique au texte)
          width: 2.0, // Largeur de la bordure
        ),
      ),
      // Bordure active lorsque le champ est sélectionné
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: textColor, // Même couleur pour la bordure lorsqu'elle est active
          width: 2.0,
        ),
      ),
      // Bordure lors du survol du champ (lorsqu'il est "hovered")
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: textColor, // Couleur de la bordure (identique au texte)
          width: 2.0,
        ),
      ),
    ),
    maxLines: 3,  // Permet d'afficher jusqu'à 3 lignes
  );
}


  // Bouton pour générer l'image
  Widget _buildGenerateButton() {
    return ElevatedButton(
      onPressed: _generateImage, // Appel de la fonction pour générer l'image
      child: Text('generated_image'.tr),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3ECAA7), // Couleur du bouton
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }


// Conteneur pour afficher le résultat de la génération
Widget _buildImageGenResult() {
  return _isLoading
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: textColor),
              const SizedBox(height: 16),
              Text(
                'please_wait'.tr,
                style: TextStyle(color: textColor, fontSize: 18),
              ),
            ],
          ),
        )
      : (_generatedImageUrl != null && _generatedImageUrl!.isNotEmpty)
          ? Column(
              children: [
                Image.network(
                  _generatedImageUrl!,
                  height: 300,
                  width: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Gestion d'erreur
                    return Icon(Icons.error, color: Colors.red);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'generated_image'.tr,
                  style: TextStyle(color: textColor, fontSize: 18),
                ),
              ],
            )
          : Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: textColor),
              ),
              child: Text(
                'generated_image_here'.tr,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
}


  // Fond avec dégradé
  Widget _buildBackground(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode 
              ? [Color(0xFF02111a), Color(0xFF0a0e17)] // Mode sombre
              : [Colors.white, Colors.grey[100]!], // Mode clair
        ),
      ),
    );
  }
}
