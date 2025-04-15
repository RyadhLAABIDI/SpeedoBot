import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class AnalyzeImageScreen extends StatefulWidget {
  const AnalyzeImageScreen({super.key});

  @override
  State<AnalyzeImageScreen> createState() => _AnalyzeImageScreen();
}

class _AnalyzeImageScreen extends State<AnalyzeImageScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String? _apiResponse;
  bool _isLoading = false;
  final Color textColor = const Color(0xFF3ecaa7);
  String _textInput = 'give me a detailed description';

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
      }
    } catch (e) {
      _showError('Image pick error: ${e.toString()}');
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) {
      _showError('please_select_an_image'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
      _apiResponse = null;
    });

    try {
      final uri = Uri.parse('https://chat.speedobot.com/analyze_image');
      final request = http.MultipartRequest('POST', uri);

      String taskPrompt = '<MORE_DETAILED_CAPTION>';
      String textInput = _textInput;

      request.fields['task_prompt'] = taskPrompt;
      request.fields['text_input'] = textInput;

      final mimeType = lookupMimeType(_image!.path) ?? 'image/jpeg';
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _image!.path,
        contentType: MediaType.parse(mimeType),
      ));

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString) as Map<String, dynamic>;
        final responseText = jsonResponse.values.first;
        setState(() => _apiResponse = _cleanResponse(responseText.toString()));
      } else {
        _showError('api_error (${response.statusCode}): $responseString'.tr);
      }
    } catch (e) {
      _showError('request_failed: ${e.toString()}'.tr);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _cleanResponse(String response) {
    response = response
      .replaceAll(RegExp(r'<\|begin_of_solution\|>'), '')
      .replaceAll(RegExp(r'<\|end_of_solution\|>'), '')
      .replaceAll(RegExp(r'\*{1,2}'), '')
      .replaceAll(RegExp(r'#+'), '')
      .replaceAll(RegExp(r'\d+\.'), '•')
      .replaceAll(RegExp(r'\- '), '• ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return _decodeUnicode(response)
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan adaptatif en fonction du mode sombre ou clair
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF02111a) : Colors.white, // Utilisation de la couleur souhaitée pour le fond en mode sombre
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildImageSection(),
                  const SizedBox(height: 16),
                  _buildTextInputField(),
                  const SizedBox(height: 24),
                  _buildActionButton(),
                  if (_apiResponse != null) _buildResponseSection(),
                ],
              ),
            ),
          ),
          if (_isLoading) _buildLoader(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'image_analysis_tool'.tr,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _pickImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: textColor,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: Text(
            'select_image'.tr, 
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black, // Fond noir forcé
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor),
          ),
          child: _image == null
              ? Center(
                  child: Text(
                    'no_image_selected'.tr,
                    style: const TextStyle(color: Colors.white70), // Texte blanc
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!, fit: BoxFit.cover),
                ),
        ),
      ],
    );
  }

  Widget _buildTextInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black, // Fond noir forcé
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _textInput = value),
        maxLines: 4,
        style: const TextStyle(color: Colors.white, fontSize: 16), // Texte blanc
        decoration: InputDecoration(
          hintText: 'enter_description_prompt'.tr,
          hintStyle: const TextStyle(color: Colors.white70), // Hint en gris clair
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _analyzeImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'analyze_image'.tr,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }

Widget _buildResponseSection() {
  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black, // Fond noir forcé
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor, width: 2),
      ),
      child: Column(  // Utilisation de Column pour empiler les éléments verticalement
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône de copie au-dessus du texte
          if (_apiResponse != null && _apiResponse!.isNotEmpty)
            IconButton(
              icon: Icon(Icons.copy, size: 16),
              color: const Color(0xFF17c9ef),
              padding: EdgeInsets.only(bottom: 8.0), // Ajout d'un espace sous l'icône
              constraints: BoxConstraints(),
              onPressed: () {
                // Vérifie si _apiResponse n'est pas nul avant de copier
                if (_apiResponse != null) {
                  Clipboard.setData(ClipboardData(text: _apiResponse!)); // Utilisation du "!" pour garantir que ce n'est pas null
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('response_copied'.tr), // Message affiché une fois la réponse copiée
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          // Texte de la réponse
          Text(
            _apiResponse ?? '', // Affiche une chaîne vide si _apiResponse est null
            style: const TextStyle(
              color: Color(0xFF3ECAA7),
              fontSize: 16
            ), // Texte vert
          ),
        ],
      ),
    ),
  );
}



  Widget _buildLoader() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: CircularProgressIndicator(color: textColor),
      ),
    );
  }
}
