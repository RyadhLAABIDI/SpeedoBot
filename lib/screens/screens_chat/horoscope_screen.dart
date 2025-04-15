import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/services.dart';

class HoroscopeScreen extends StatefulWidget {
  const HoroscopeScreen({super.key});

  @override
  State<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen> {
  final TextEditingController _horoscopeDayController = TextEditingController(text: 'today');
  String? _selectedHoroscopeType = 'daily';
  String? _selectedHoroscopeSign = 'virgo';
  String? _selectedLanguage = 'en';
  String? _horoscopeResult;
  bool _isLoading = false;

  final Color primaryTextColor = const Color(0xFF3ECAA7);
  final Color whiteTextColor = Colors.white;
  final Color hintTextColor = const Color(0xFF17c9ef);
  final Color borderColor = const Color(0xFF3ECAA7);

  Future<void> _fetchHoroscope() async {
    setState(() {
      _isLoading = true; // Commence à charger
    });

    final url = Uri.parse(
      'https://horoscope.elitesportholding.com/api/v1/get-horoscope/${_selectedHoroscopeType}?sign=${_selectedHoroscopeSign}&day=${_horoscopeDayController.text}&lang=${_selectedLanguage}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _horoscopeResult = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _horoscopeResult = '${'error_code'.tr} ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _horoscopeResult = 'Failed to fetch horoscope';
        _isLoading = false;
      });
    }
  }

  Widget _buildHoroscopeResponse() {
  if (_isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryTextColor),
          const SizedBox(height: 16),
          Text(
            'loading_message'.tr, // Message de chargement traduit
            style: TextStyle(color: primaryTextColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  // Si l'API n'a pas encore renvoyé de données et que _horoscopeResult est nul ou vide, afficher un message par défaut
  if (_horoscopeResult == null || _horoscopeResult!.isEmpty) {
    return Center(
      child: Text(
        'no_horoscope_data'.tr, // Afficher le message traduit pour "No horoscope data available"
        style: TextStyle(color: primaryTextColor, fontSize: 18),
      ),
    );
  }

  // Lorsque les données du horoscope sont récupérées avec succès
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: primaryTextColor, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ajouter le bouton de copie en haut
        if (_horoscopeResult != null && _horoscopeResult!.isNotEmpty) 
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.copy, size: 16, color: const Color(0xFF17c9ef)),
              onPressed: () {
                // Vérification que _horoscopeResult n'est pas null
                if (_horoscopeResult != null) {
                  Clipboard.setData(ClipboardData(text: _horoscopeResult!)); // Copie le texte dans le presse-papiers
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('response_copied'.tr), // Affiche un message indiquant que la réponse a été copiée
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ),
        // Affichage de la réponse de l'API
        Text(
          _horoscopeResult!.isEmpty ? 'horoscope_default'.tr : _horoscopeResult!,
          style: TextStyle(
            color: Color(0xFF3ECAA7),
            fontSize: 16,
          ),
        ),
      ],
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
                    'select_horoscope_type'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHoroscopeTypeSelect(),
                  const SizedBox(height: 16),
                  if (_selectedHoroscopeType == 'daily') ...[ 
                    Text(
                      'day_daily_horoscope'.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHoroscopeDayField(),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'select_zodiac_sign'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHoroscopeSignSelect(),
                  const SizedBox(height: 16),
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
                  _buildGetHoroscopeButton(),
                  const SizedBox(height: 24),
                  _buildHoroscopeResponse(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Champ de sélection du type de horoscope
  Widget _buildHoroscopeTypeSelect() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedHoroscopeType,
        dropdownColor: Colors.black,
        items: [
          DropdownMenuItem(
            child: Text('daily'.tr, style: TextStyle(color: Colors.white)),
            value: 'daily',
          ),
          DropdownMenuItem(
            child: Text('monthly'.tr, style: TextStyle(color: Colors.white)),
            value: 'monthly',
          ),
        ],
        onChanged: (String? newValue) {
          setState(() {
            _selectedHoroscopeType = newValue;
          });
        },
        decoration: InputDecoration(
          labelText: 'horoscope_type'.tr,
          labelStyle: TextStyle(color: primaryTextColor),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor, width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.black,
        ),
      ),
    );
  }

  // Le champ du jour du horoscope (Today/Tomorrow/Yesterday)
  Widget _buildHoroscopeDayField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _horoscopeDayController.text,  // La valeur actuelle dans le contrôleur
        dropdownColor: Colors.black,
        items: [
          DropdownMenuItem(
            child: Text('yesterday'.tr, style: TextStyle(color: Colors.white)),
            value: 'yesterday',
          ),
          DropdownMenuItem(
            child: Text('today'.tr, style: TextStyle(color: Colors.white)),
            value: 'today',
          ),
          DropdownMenuItem(
            child: Text('tomorrow'.tr, style: TextStyle(color: Colors.white)),
            value: 'tomorrow',
          ),
        ],
        onChanged: (String? newValue) {
          setState(() {
            _horoscopeDayController.text = newValue ?? 'today';  // Mettre à jour la valeur sélectionnée
          });
        },
        decoration: InputDecoration(
          labelText: 'day_for_horoscope'.tr,  // Titre de l'input, ajuster la traduction
          labelStyle: TextStyle(color: primaryTextColor),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          filled: true,
          fillColor: Colors.black,
        ),
      ),
    );
  }

  Widget _buildHoroscopeSignSelect() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedHoroscopeSign,
        dropdownColor: Colors.black,
        items: [
          DropdownMenuItem(
            child: Text('Aries'.tr, style: TextStyle(color: Colors.white)),
            value: 'aries',
          ),
          DropdownMenuItem(
            child: Text('Taurus'.tr, style: TextStyle(color: Colors.white)),
            value: 'taurus',
          ),
          DropdownMenuItem(
            child: Text('Gemini'.tr, style: TextStyle(color: Colors.white)),
            value: 'gemini',
          ),
          DropdownMenuItem(
            child: Text('Cancer'.tr, style: TextStyle(color: Colors.white)),
            value: 'cancer',
          ),
          DropdownMenuItem(
            child: Text('leo'.tr, style: TextStyle(color: Colors.white)),
            value: 'leo',
          ),
          DropdownMenuItem(
            child: Text('virgo'.tr, style: TextStyle(color: Colors.white)),
            value: 'virgo',
          ),
          DropdownMenuItem(
            child: Text('libra'.tr, style: TextStyle(color: Colors.white)),
            value: 'libra',
          ),
          DropdownMenuItem(
            child: Text('scorpio'.tr, style: TextStyle(color: Colors.white)),
            value: 'scorpio',
          ),
          DropdownMenuItem(
            child: Text('sagittarius'.tr, style: TextStyle(color: Colors.white)),
            value: 'sagittarius',
          ),
          DropdownMenuItem(
            child: Text('capricorn'.tr, style: TextStyle(color: Colors.white)),
            value: 'capricorn',
          ),
          DropdownMenuItem(
            child: Text('aquarius'.tr, style: TextStyle(color: Colors.white)),
            value: 'aquarius',
          ),
          DropdownMenuItem(
            child: Text('pisces'.tr, style: TextStyle(color: Colors.white)),
            value: 'pisces',
          ),
        ],
        onChanged: (String? newValue) {
          setState(() {
            _selectedHoroscopeSign = newValue;
          });
        },
        decoration: InputDecoration(
          labelText: 'zodiac_sign'.tr,
          labelStyle: TextStyle(color: primaryTextColor),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          filled: true,
          fillColor: Colors.black,
        ),
      ),
    );
  }

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
            child: Text('english'.tr, style: TextStyle(color: Colors.white)),
            value: 'en',
          ),
          DropdownMenuItem(
            child: Text('french'.tr, style: TextStyle(color: Colors.white)),
            value: 'fr',
          ),
          DropdownMenuItem(
            child: Text('arabic'.tr, style: TextStyle(color: Colors.white)),
            value: 'ar',
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
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          filled: true,
          fillColor: Colors.black,
        ),
      ),
    );
  }

  Widget _buildGetHoroscopeButton() {
    return ElevatedButton(
      onPressed: _fetchHoroscope,
      child: Text('get_horoscope'.tr),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTextColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
      ),
    );
  }

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
