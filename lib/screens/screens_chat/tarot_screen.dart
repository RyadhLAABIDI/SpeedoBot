import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart'; // Assurez-vous d'avoir GetX dans votre pubspec.yaml
import 'package:flutter/services.dart';


class TarotScreen extends StatefulWidget {
  const TarotScreen({super.key});

  @override
  State<TarotScreen> createState() => _TarotScreenState();
}

class _TarotScreenState extends State<TarotScreen> {
  String? _selectedLanguage = 'ar'; // Langue par défaut
  String? _tarotResponse;
  String? _imageUrl;
  bool _isLoading = false;

  final Color primaryTextColor = const Color(0xFF3ECAA7); // Texte principal
  final Color whiteTextColor = Colors.white; // Texte en blanc
  final Color hintTextColor = const Color(0xFF17c9ef); // Couleur des hintText
  final Color borderColor = const Color(0xFF3ECAA7); // Bordure
  

  // Fonction pour nettoyer la réponse (adaptée à ton exemple)
  String _cleanResponse(String response) {
    response = response
      .replaceAll(RegExp(r'<\|begin_of_solution\|>'), '')
      .replaceAll(RegExp(r'<\|end_of_solution\|>'), '');
    response = response
      .replaceAll(RegExp(r'\*{1,2}'), '') // Retirer les *
      .replaceAll(RegExp(r'#+'), '')       // Retirer les #
      .replaceAll(RegExp(r'\d+\.'), '•')   // Remplacer les listes numérotées par des puces
      .replaceAll(RegExp(r'\- '), '• ')    // Uniformiser les listes
      .replaceAll(RegExp(r'\n{3,}'), '\n\n'); // Réduire les sauts de ligne multiples
    return response;
  }

  // Fonction pour décoder les caractères Unicode (si nécessaire)
  String _decodeUnicode(String text) {
    return text.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
      return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
    });
  }

  // Fonction pour récupérer la réponse du tarot
  Future<void> _getTarotResponse() async {
    setState(() {
      _isLoading = true;
      _tarotResponse = null;  // Réinitialise la réponse
      _imageUrl = null; // Réinitialise l'image
    });

    final url = Uri.parse('https://tarotai.elitesportholding.com/api/random-tarot?lang=${_selectedLanguage}');  // Correction ici

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String rawResponse = data['description'] ?? 'Pas de réponse disponible'; // Utiliser 'description' comme dans la réponse de Postman
        String cleanedResponse = _cleanResponse(rawResponse);
        String imageUrl = data['image_url'] ?? ''; // Ajout de l'image

        setState(() {
          _tarotResponse = cleanedResponse;  // Mets à jour la réponse du tarot
          _imageUrl = imageUrl; // Mets à jour l'URL de l'image
        });
      } else {
        setState(() {
          _tarotResponse = 'Erreur HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _tarotResponse = 'Erreur de connexion: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

Widget _buildTarotResponse() {
  if (_isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryTextColor),
          const SizedBox(height: 16),
          Text(
            'please_wait_drawing'.tr,
            style: TextStyle(color: primaryTextColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.black,  // Utilisation de la couleur noire pour le fond
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: primaryTextColor, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ajouter l'icône de copie en haut si la réponse existe
        if (_tarotResponse != null && _tarotResponse!.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.copy, size: 16, color: const Color(0xFF17c9ef)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _tarotResponse!)); // Utilisation de `!` car on a vérifié que _tarotResponse != null
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('response_copied'.tr), // Affiche un message indiquant que la réponse a été copiée
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        // Affichage de la réponse du tarot
        if (_tarotResponse != null && _tarotResponse!.isNotEmpty)
          Text(
            _tarotResponse!,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 16),
        // Affichage de l'image si elle existe
        if (_imageUrl != null && _imageUrl!.isNotEmpty)
          Image.network(
            _imageUrl!,
            height: 200,
            width: 200,
          ),
        // Si la réponse est vide, afficher un message
        if (_tarotResponse == null || _tarotResponse!.isEmpty)
          Center(
            child: Text(
              'press_start_for_draw'.tr,
              style: TextStyle(
                color: Color(0xFF3ECAA7),
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    ),
  );
}



  // Construction du menu déroulant pour sélectionner la langue
  Widget _buildLanguageSelect() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedLanguage,
        dropdownColor: Colors.black,
       items: [
  DropdownMenuItem(
    child: Text('arabic'.tr, style: TextStyle(color: Colors.white)),
    value: 'ar',
  ),
  DropdownMenuItem(
    child: Text('english'.tr, style: TextStyle(color: Colors.white)),
    value: 'en',
  ),
  DropdownMenuItem(
    child: Text('french'.tr, style: TextStyle(color: Colors.white)),
    value: 'fr',
  ),
],

        onChanged: (String? newValue) {
          setState(() {
            _selectedLanguage = newValue;
          });
        },
        decoration: InputDecoration(
          labelText: 'Language'.tr,
          labelStyle: TextStyle(color: primaryTextColor),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.black,
        ),
      ),
    );
  }

  // Construction du bouton pour lancer l'action
  Widget _buildLaunchButton() {
    return ElevatedButton(
      onPressed: _getTarotResponse, // Appel à la méthode pour récupérer la réponse
      child: Text('Lancer'.tr),

      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTextColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  // Construction du fond dégradé
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
                    'select_language'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLanguageSelect(),
                  const SizedBox(height: 24),
                  _buildLaunchButton(),
                  const SizedBox(height: 16),
                  _buildTarotResponse(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
