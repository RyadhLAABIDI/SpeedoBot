import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreen();
}

class _TranslateScreen extends State<TranslateScreen> {
  final TextEditingController _sourceTextController = TextEditingController();
  String? _selectedLanguage = 'en'; // Valeur par défaut
  String _translatedText = '';
  bool _isLoading = false; // Nouvelle variable d'état pour le loading
  bool isUser = false; // Définir si l'utilisateur est un utilisateur spécifique ou non (à modifier selon ta logique)

  final Color primaryColor = const Color(0xFF3ecaa7);
  final Color textColor = Colors.white;
  final Color hintTextColor = const Color(0xFF3ecaa7);

  Future<void> _translateText() async {
    setState(() {
      _isLoading = true;
    });

    if (_sourceTextController.text.isEmpty) {
      setState(() {
        _translatedText = 'please_enter_text_to_translate'.tr;
        _isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse('https://chat.speedobot.com/translate');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': _sourceTextController.text, 'lang': _selectedLanguage}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _translatedText = data['translation'];
        });
      } else {
        setState(() {
          _translatedText = 'Error: Unable to translate text';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode 
                    ? [const Color(0xFF02111a), const Color(0xFF0a0e17)]
                    : [Colors.white, Colors.grey[100]!],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'source_text'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _sourceTextController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      labelText: 'enter_the_text_to_translate'.tr,
                      labelStyle: TextStyle(color: primaryColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2)),
                      hintText: 'enter_the_text_to_translate'.tr,
                      hintStyle: TextStyle(color: hintTextColor),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'target_language'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    dropdownColor: Colors.black,
                    style: TextStyle(color: Colors.white),
                    items: [
                      DropdownMenuItem(
                        child: Text('english'.tr, 
                          style: TextStyle(color: Colors.white)),
                        value: 'en',
                      ),
                      DropdownMenuItem(
                        child: Text('arabic'.tr, 
                          style: TextStyle(color: Colors.white)),
                        value: 'ar',
                      ),
                      DropdownMenuItem(
                        child: Text('french'.tr, 
                          style: TextStyle(color: Colors.white)),
                        value: 'fr',
                      ),
                      DropdownMenuItem(
                        child: Text('spanish'.tr, 
                          style: TextStyle(color: Colors.white)),
                        value: 'es',
                      ),
                      DropdownMenuItem(
                        child: Text('german'.tr, 
                          style: TextStyle(color: Colors.white)),
                        value: 'de',
                      ),
                      DropdownMenuItem(
                        child: Text('russian'.tr, 
                          style: TextStyle(color: Colors.white)),
                        value: 'ru',
                      ),
                      DropdownMenuItem(
                        child: Text('chinese'.tr, 
                          style: TextStyle(color: Colors.white)),
                        value: 'zh',
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLanguage = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      labelStyle: TextStyle(color: primaryColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _translateText,
                    child: Text('translate'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor, width: 2)),
                    child: _isLoading // Condition pour afficher le loading
                        ? SizedBox(
                            height: 40,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Afficher l'icône de copie seulement si il y a une réponse
                              if (_translatedText.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: Icon(Icons.copy, size: 16),
                                    color: const Color(0xFF17c9ef),
                                    padding: EdgeInsets.only(left: 8.0),
                                    constraints: BoxConstraints(),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: _translatedText)); // Copie le texte dans le presse-papiers
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('response_copied'.tr), // Message de confirmation
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              // Affichage du texte traduit
                              Text(
                                _translatedText.isEmpty 
                                    ? 'translated_text_will_appear_here'.tr 
                                    : _translatedText,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
