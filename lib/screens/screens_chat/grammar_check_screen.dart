import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/services.dart';

class GrammarCheckScreen extends StatefulWidget {
  const GrammarCheckScreen({super.key});

  @override
  _GrammarCheckScreen createState() => _GrammarCheckScreen();
}

class _GrammarCheckScreen extends State<GrammarCheckScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // Fonction pour envoyer le message
  Future<void> _sendMessage() async {
    final message = _controller.text;
    if (message.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'Vous', 'message': message});
      _isLoading = true;
      _controller.clear();
    });

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    // Ajout du message de chargement
    setState(() {
      _messages.add({'sender': 'Speedobot', 'message': 'speedobot_response'.tr});
    });

    try {
      final response = await http.post(
        Uri.parse('https://chat.speedobot.com/verifier_grammaire'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': message}),
      ).timeout(const Duration(seconds: 120));

      // Retirer le message de chargement
      setState(() => _messages.removeLast());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String reply = data['response']?.toString() ?? '';  // Si la réponse est vide, la valeur est une chaîne vide

        // Si la réponse est vide, ajouter un message d'erreur
        if (reply.isEmpty) {
          reply = "error_no_reply".tr;  // Message d'erreur traduit
        } else {
          // Nettoyer la réponse avant de l'afficher
          reply = _cleanResponse(reply);
        }

        setState(() {
          _messages.add({'sender': 'speedobot'.tr, 'message': reply});
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({'sender': 'speedobot'.tr, 'message': 'Erreur HTTP ${response.statusCode}'.tr});
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();  // Retirer le message de chargement en cas d'erreur
        _messages.add({'sender': 'speedobot'.tr, 'message': 'Erreur de connexion: ${e.toString()}'.tr});
        _isLoading = false;
      });
    }
  }

  // Fonction pour nettoyer la réponse
  String _cleanResponse(String response) {
    return response
      .replaceAll(RegExp(r'<\|(begin|end)_of_solution\|>'), '')
      .replaceAll(RegExp(r'\*{1,2}|#+'), '')
      .replaceAll(RegExp(r'(\d+\.|\- )'), '• ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .split('\n')
      .map((line) => line.trim())
      .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF0a0e17), const Color(0xFF02111a)]
                    : [const Color(0xFFffffff), const Color(0xFFf1f1f1)],
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessage(_messages[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildMessageInputField(), // Remplacement ici
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fonction de message personnalisée avec le style d'input
  Widget _buildMessageInputField() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _controller,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black, // Texte en fonction du thème
      ),
      decoration: InputDecoration(
        hintText: 'compose_grammar_check_sentence'.tr,
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
          onPressed: _isLoading ? null : _sendMessage, // Désactiver l'envoi pendant le chargement
        ),
      ),
    );
  }

Widget _buildMessage(Map<String, String> messageData) {
  String message = messageData['message'] ?? '';  // Récupère le message
  String sender = messageData['sender'] ?? '';   // Récupère le nom de l'expéditeur

  bool isSentByUser = sender == "Vous";  // Si l'expéditeur est 'Vous', il s'agit de l'utilisateur

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
        if (!isSentByUser)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Affichage du nom de l'envoyeur (Bot)
              Text(
                sender,
                style: TextStyle(
                  color: const Color(0xFF17c9ef),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              // Icône de copie uniquement si c'est un message du bot
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
}