import 'dart:convert';  // Pour la gestion du JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;  // Pour envoyer la requête HTTP
import 'package:get/get.dart'; // Assurez-vous d'avoir GetX dans votre pubspec.yaml
import 'package:flutter/services.dart';

class DreamInterpreterScreen extends StatefulWidget {
  const DreamInterpreterScreen({super.key});

  @override
  _DreamInterpreterScreen createState() => _DreamInterpreterScreen();
}

class _DreamInterpreterScreen extends State<DreamInterpreterScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Contrôleur de scroll
  List<Map<String, String>> _messages = [];  // Liste pour stocker les messages envoyés et reçus
  bool _isLoading = false;  // Indicateur de chargement

  // Fonction pour envoyer un message et récupérer la réponse de l'API
Future<void> _sendMessage() async {
  final message = _controller.text;
  if (message.isNotEmpty) {
    setState(() {
      _messages.add({
        'sender': 'Vous'.tr,  // Utilisez .tr pour la traduction
        'message': message,
      });
      _isLoading = true;
      _controller.clear();
    });

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    // Ajout du message temporaire de réponse en attente
    setState(() {
      _messages.add({
        'sender': 'Speedobot'.tr,  // Utilisez .tr pour la traduction
        'message': 'speedobot_response'.tr,  // Utilisez .tr pour la traduction
      });
    });

    final url = Uri.parse('https://chat.speedobot.com/interpreter_reve');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'dream': message}),  // Envoi du rêve dans le corps de la requête
      ).timeout(const Duration(seconds: 120));  // Timeout après 120 secondes

      print('Status Code: ${response.statusCode}');  // Debug
      print('Response Body: ${response.body}');  // Debug

      setState(() {
        // Retirer le message temporaire quelle que soit la réponse
        _messages.removeLast();
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Récupérer la réponse et appliquer le nettoyage
        String reply = data['response'] ?? '';  // Si la réponse est vide, on met une chaîne vide

        // Si la réponse est vide, ajouter un message d'erreur professionnel
        if (reply.isEmpty) {
          reply = "error_no_reply".tr;  // Message d'erreur traduit
        } else {
          // Appliquer la méthode de nettoyage de la réponse ici si elle n'est pas vide
          reply = _cleanResponse(reply);
        }

        setState(() {
          _messages.add({
            'sender': 'speedobot'.tr,  // Utilisez .tr pour la traduction
            'message': reply,  // Affichage de la réponse nettoyée ou du message d'erreur
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'Speedobot'.tr,  // Utilisez .tr pour la traduction
            'message': 'Erreur HTTP ${response.statusCode}'.tr,  // Utilisez .tr pour la traduction
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();  // Retirer le message temporaire en cas d'erreur
        _messages.add({
          'sender': 'Speedobot'.tr,  // Utilisez .tr pour la traduction
          'message': 'Erreur de connexion: ${e.toString()}'.tr,  // Utilisez .tr pour la traduction
        });
        _isLoading = false;
      });
    }
  }
}


  /// Fonction améliorée pour nettoyer la réponse de l'API
  String _cleanResponse(String response) {
    // Suppression des balises spécifiques
    response = response
      .replaceAll(RegExp(r'<\|begin_of_solution\|>'), '')
      .replaceAll(RegExp(r'<\|end_of_solution\|>'), '');

    // Suppression des caractères spéciaux et formatage markdown
    response = response
      .replaceAll(RegExp(r'\*{1,2}'), '') // Supprime les *
      .replaceAll(RegExp(r'#+'), '')       // Supprime les #
      .replaceAll(RegExp(r'\d+\.'), '•')   // Remplace les listes numérotées par des puces
      .replaceAll(RegExp(r'\- '), '• ')    // Uniformise les listes
      .replaceAll(RegExp(r'\n{3,}'), '\n\n'); // Réduit les sauts de ligne multiples

    // Conversion des caractères Unicode
    response = _decodeUnicode(response);

    // Formatage final
    return response
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n\n');
  }

  // Fonction pour décoder les caractères Unicode (ex : \u00e9 devient é)
  String _decodeUnicode(String text) {
    return text.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
      return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Fond transparent pour le Scaffold
      body: Stack(
        children: [
          // Fond dégradé de base
          _buildBackground(),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(_messages[index]['message']!, index);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildMessageInputField(),
              ),
            ],
          ),
        ],
      ),
    );
  }

 // Fonction pour créer un fond dégradé
 Widget _buildBackground() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: Theme.of(context).brightness == Brightness.dark
            ? [
                const Color(0xFF0a0e17), // Couleur sombre pour le thème sombre
                const Color(0xFF02111a), // Autre couleur sombre pour le thème sombre
              ]
            : [
                const Color(0xFFffffff), // Couleur claire pour le thème clair
                const Color(0xFFf1f1f1), // Autre couleur claire pour le thème clair
              ],
      ),
    ),
  );
}


  // Fonction pour construire un message avec un fond spécifique
Widget _buildMessage(String message, int index) {
  bool isSentByUser = index % 2 == 0; // Alternance pour identifier l'envoyeur
  String sender = isSentByUser ? "sender_you".tr : "sender_speedobot".tr; // Le nom de l'envoyeur

  // Déterminez la couleur du texte en fonction du mode (clair ou sombre)
  Color textColor = Theme.of(context).brightness == Brightness.dark
      ? Colors.white70 // En mode sombre, texte plus léger
      : Colors.black;  // En mode clair, texte noir

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: Column(
      crossAxisAlignment: isSentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Affichage du nom de l'envoyeur et icône de copie (uniquement pour le bot)
        Row(
          mainAxisAlignment: isSentByUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Text(
              sender,
              style: TextStyle(
                color: const Color(0xFF17c9ef),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            // Icône de copie uniquement si c'est un message du bot
            if (!isSentByUser) 
              IconButton(
                icon: Icon(Icons.copy, size: 16),
                color: const Color(0xFF17c9ef),
                padding: EdgeInsets.only(left: 8.0), // Espacement entre le nom et l'icône
                constraints: BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message)); // Copie le texte dans le presse-papiers
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('response_copied'.tr), // Affiche un message indiquant que la réponse a été copiée
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
          ],
        ),
        Align(
          alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: isSentByUser ? const Color(0xFF3ECAA7) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: isSentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Le texte du message
                Text(
                  message,
                  style: TextStyle(
                    color: textColor,  // Applique la couleur du texte en fonction du mode
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                  textDirection: Get.locale?.languageCode == 'ar' // Vérifie si la langue est l'arabe
                      ? TextDirection.rtl
                      : TextDirection.ltr, // Définit la direction du texte
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF17c9ef).withOpacity(0.3),
                  const Color(0xFF17c9ef).withOpacity(0.8),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


 Widget _buildMessageInputField() {
  // Déterminez si le thème actuel est sombre ou clair
  final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return TextField(
    controller: _controller,
    style: TextStyle(
      color: isDarkMode
          ? Colors.white // Texte en blanc pour le mode sombre
          : Colors.black, // Texte en noir pour le mode clair
    ),
    decoration: InputDecoration(
      hintText: 'compose_dream_interpreter'.tr,
       hintStyle: TextStyle(
        color: Color(0xFF3ECAA7), // Couleur personnalisée pour le texte d'invite
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.7), // Fond transparent avec l'opacité
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0), // Coins arrondis
        borderSide: BorderSide.none, // Pas de bordure quand non focus
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0), // Coins arrondis quand focus
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary, // Utiliser la couleur du thème
          width: 2.0, // Largeur de la bordure quand focus
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0), // Coins arrondis quand activé
        borderSide: BorderSide(
          color: Colors.grey.withOpacity(0.5), // Couleur de la bordure par défaut
          width: 1.0, // Largeur de la bordure par défaut
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0), // Padding
      suffixIcon: IconButton(
        icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary), // Icône d'envoi avec la couleur du thème
        onPressed: _sendMessage,
      ),
    ),
  );
}
}