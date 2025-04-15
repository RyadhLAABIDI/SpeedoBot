import 'dart:convert';  
import 'package:flutter/material.dart';  
import 'package:http/http.dart' as http;
import 'package:get/get.dart'; 
import 'package:flutter/services.dart';

class RecipeGeneratorScreen extends StatefulWidget {
  const RecipeGeneratorScreen({super.key});

  @override
  State<RecipeGeneratorScreen> createState() => _RecipeGeneratorScreenState();
}

class _RecipeGeneratorScreenState extends State<RecipeGeneratorScreen> {
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _preferencesController = TextEditingController();
  final TextEditingController _recipePromptController = TextEditingController();

  String? _selectedGender = 'homme';
  String _recipeResponse = '';
  bool _isLoading = false;

  final Color primaryTextColor = const Color(0xFF3ECAA7); 
  final Color whiteTextColor = Colors.white;
  final Color hintTextColor = const Color(0xFF3ECAA7);  // Utilisation de la couleur spécifiée pour le hintText

 // Fonction améliorée pour nettoyer la réponse
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

  String _decodeUnicode(String text) {
    return text.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
      return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
    });
  }

  Future<void> _generateRecipe() async {
    setState(() => _isLoading = true);

    final Map<String, dynamic> requestBody = {
      'calories': _caloriesController.text,
      'poids': _weightController.text,
      'sexe': _selectedGender ?? 'homme',
      'objectif': _recipePromptController.text,
      'preferences': _preferencesController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('https://chat.speedobot.com/generer_recette'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      setState(() {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _recipeResponse = _cleanResponse(data['response'] ?? 'Aucune réponse valide');
        } else {
          _recipeResponse = 'Erreur HTTP ${response.statusCode}';
        }
      });
    } catch (e) {
      setState(() => _recipeResponse = 'Erreur de connexion: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
@override
Widget build(BuildContext context) {
  final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
  return Scaffold(
    body: Stack(
      children: [
        _buildBackground(isDarkMode),  // On passe le paramètre isDarkMode à la fonction de fond
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('calories_label'.tr),
                const SizedBox(height: 16),
                _buildTextField(_caloriesController, 'calories_hint'.tr, hintTextColor),
                const SizedBox(height: 16),
                _buildLabel('weight_label'.tr),
                const SizedBox(height: 16),
                _buildTextField(_weightController, 'weight_hint'.tr, hintTextColor),
                const SizedBox(height: 16),
                _buildLabel('gender_label'.tr),
                const SizedBox(height: 8),
                _buildGenderSelect(),
                const SizedBox(height: 16),
                _buildLabel('diet_preferences_label'.tr),
                const SizedBox(height: 16),
                _buildTextField(_preferencesController, 'diet_preferences_hint'.tr, hintTextColor),
                const SizedBox(height: 16),
                _buildLabel('recipe_objective_label'.tr),
                const SizedBox(height: 8),
                _buildRecipePromptField(),
                const SizedBox(height: 24),
                _buildGenerateButton(),
                const SizedBox(height: 16),
                _buildRecipeResponse(),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
    );
  }

  // Fonction pour afficher le champ de texte avec un hintText professionnel
 // Fonction pour afficher le champ de texte avec un fond noir
Widget _buildTextField(TextEditingController controller, String hint, Color hintColor) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.black, // Fond noir
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: primaryTextColor, width: 2),
    ),
    child: TextFormField(
      controller: controller,
      style: TextStyle(color: whiteTextColor), // Texte en blanc
      decoration: InputDecoration(
        labelStyle: TextStyle(color: primaryTextColor), // Couleur du label
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(color: hintColor), // Couleur du hintText
      ),
    ),
  );
}

  // Sélecteur de genre
 // Sélecteur de genre avec un fond noir
Widget _buildGenderSelect() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.black, // Fond noir
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: primaryTextColor, width: 2),
    ),
    child: DropdownButtonFormField<String>(
      value: _selectedGender,
      items: [
        DropdownMenuItem(
          child: Container(
            color: Colors.black, // Fond noir pour chaque item
            child: Text('male'.tr, style: TextStyle(color: Color(0xFF3ECAA7))),
          ),
          value: 'homme',
        ),
        DropdownMenuItem(
          child: Container(
            color: Colors.black, // Fond noir pour chaque item
            child: Text('female'.tr, style: TextStyle(color:Color(0xFF3ECAA7))),
          ),
          value: 'femme',
        ),
      ],
      onChanged: (String? newValue) {
        setState(() {
          _selectedGender = newValue;
        });
      },
      decoration: InputDecoration(
        labelText: 'gender_label'.tr,
        labelStyle: TextStyle(color: Color(0xFF3ECAA7)),
        border: InputBorder.none,
      ),
      dropdownColor: Colors.black,
    ),
  );
}

// Champ de texte pour l'objectif de la recette avec un fond noir
Widget _buildRecipePromptField() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.black, // Fond noir
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: primaryTextColor, width: 2),
    ),
    child: TextFormField(
      controller: _recipePromptController,
      style: TextStyle(color: whiteTextColor), // Texte en blanc
      decoration: InputDecoration(
        labelText: 'recipe_objective_label'.tr,
        labelStyle: TextStyle(color: primaryTextColor), // Couleur du label
        border: InputBorder.none,
        hintText: 'diet_preferences_hint'.tr,
        hintStyle: TextStyle(color: hintTextColor), // Couleur du hintText
      ),
      maxLines: 3,
    ),
  );
}


  // Bouton pour générer la recette
  Widget _buildGenerateButton() {
    return ElevatedButton(
      onPressed: _generateRecipe,
      child:  Text('generate_button'.tr),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTextColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Affichage de la réponse de la recette avec le style de texte et l'indicateur de chargement
Widget _buildRecipeResponse() {
  if (_isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryTextColor), // Utilisation de la même couleur
          const SizedBox(height: 16),
          Text(
            'please_wait_generating_recipe'.tr, // Message similaire à celui pour l'image
            style: TextStyle(color: primaryTextColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.black, // Fond noir complet
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: primaryTextColor, width: 2), // Utilisation de la même couleur pour la bordure
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ajouter l'icône de copie en haut
        if (_recipeResponse.isNotEmpty) 
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.copy, size: 16, color: const Color(0xFF17c9ef)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _recipeResponse)); // Copie le texte dans le presse-papiers
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('response_copied'.tr), // Affiche un message indiquant que la réponse a été copiée
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        // Affichage de la réponse de la recette
        Text(
          _recipeResponse.isEmpty 
              ? 'generated_recipe_will_appear_here'.tr 
              : _recipeResponse,
          style: TextStyle(
            color: Color(0xFF3ECAA7), // Couleur du texte (peut être ajustée si nécessaire)
            fontSize: 16, // Taille du texte
          ),
        ),
      ],
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
            ? [Color(0xFF0a0e17), Color(0xFF02111a)]  // Dégradé pour le mode sombre
            : [Color(0xFFffffff), Color(0xFFf2f2f2)],  // Dégradé pour le mode clair
      ),
    ),
  );
}}
