import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart'; // Assurez-vous d'avoir GetX dans votre pubspec.yaml
import 'package:flutter/services.dart';

class PdfFormScreen extends StatefulWidget {
  const PdfFormScreen({super.key});

  @override
  State<PdfFormScreen> createState() => _PdfFormScreenState();
}

class _PdfFormScreenState extends State<PdfFormScreen> {
  final Color textColor = const Color(0xFF3ecaa7);
  final Color hintTextColor = const Color(0xFF17c9ef);
  List<PlatformFile> selectedFiles = [];
  String? selectedAction;
  String? selectedMode;
  TextEditingController questionController = TextEditingController();
  bool isLoading = false;
  String? responseText;

  String _cleanResponse(String response) {
    response = response
        .replaceAll(RegExp(r'<\|begin_of_solution\|>'), '')
        .replaceAll(RegExp(r'<\|end_of_solution\|>'), '')
        .replaceAll(RegExp(r'\*{1,2}'), '')
        .replaceAll(RegExp(r'#+'), '')
        .replaceAll(RegExp(r'\d+\.'), '•')
        .replaceAll(RegExp(r'\- '), '• ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');

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

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() => selectedFiles = result.files);
    }
  }

  Future<void> _submitForm() async {
    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un fichier PDF')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://chat.speedobot.com/pdf'));
      
      for (var file in selectedFiles) {
        request.files.add(await http.MultipartFile.fromPath('pdf', file.path!));
      }

      request.fields.addAll({
        'action': selectedAction ?? 'qa',
        'mode': selectedMode ?? 'combined',
        'question': questionController.text,
      });

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      try {
        var jsonResponse = json.decode(responseData);
        setState(() {
          responseText = _cleanResponse(jsonResponse['response'] ?? 'Réponse vide');
        });
      } catch (e) {
        setState(() => responseText = 'Erreur de format de réponse: $responseData');
      }
    } on SocketException {
      _showErrorDialog('Erreur de connexion');
    } catch (e) {
      _showErrorDialog('Erreur inattendue: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          )
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
                    'select_pdf_files'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFileInput(),
                  const SizedBox(height: 16),
                  Text(
                    'enter_your_question'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildQuestionInput(),
                  const SizedBox(height: 16),
                  Text(
                    'choose_action'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildActionSelect(),
                  const SizedBox(height: 16),
                  Text(
                    'processing_mode'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildModeSelect(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                  _buildApiResponse(),
                ],
              ),
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildFileInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.attach_file, color: textColor),
          label: Text('select_pdf_files'.tr, style: TextStyle(color: textColor)),
          onPressed: _pickFiles,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            side: BorderSide(color: textColor),
          ),
        ),
        if (selectedFiles.isNotEmpty)
          Wrap(
            spacing: 8,
            children: selectedFiles
                .map((file) => Chip(
                      label: Text(file.name),
                      deleteIcon: Icon(Icons.close, color: textColor),
                      onDeleted: () => setState(() => selectedFiles.remove(file)),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildQuestionInput() {
    return TextFormField(
      controller: questionController,
      decoration: InputDecoration(
        labelText: 'enter_your_question'.tr,
        labelStyle: TextStyle(color: textColor),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor)),
        hintText: 'optional_question_related_to_pdf_content'.tr,
        hintStyle: TextStyle(color: hintTextColor),
      ),
      maxLines: 3,
    );
  }

  Widget _buildActionSelect() {
    return DropdownButtonFormField<String>(
      value: selectedAction,
      items: [
        DropdownMenuItem<String>(value: 'qa', child: Text('question_answering'.tr)),
        DropdownMenuItem<String>(value: 'summary', child: Text('summary'.tr)),
      ],
      onChanged: (value) => setState(() => selectedAction = value),
      decoration: InputDecoration(
        labelText: 'choose_action'.tr,
        labelStyle: TextStyle(color: textColor),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor)),
        filled: true,
        fillColor: Colors.black,
      ),
      dropdownColor: Colors.black,
      style: TextStyle(color: Colors.white),
    );
  }

  Widget _buildModeSelect() {
    return DropdownButtonFormField<String>(
      value: selectedMode,
      items: [
        DropdownMenuItem<String>(value: 'combined', child: Text('combined'.tr)),
        DropdownMenuItem<String>(value: 'separate', child: Text('separate'.tr)),
      ],
      onChanged: (value) => setState(() => selectedMode = value),
      decoration: InputDecoration(
        labelText: 'processing_mode'.tr,
        labelStyle: TextStyle(color: textColor),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor)),
        filled: true,
        fillColor: Colors.black,
      ),
      dropdownColor: Colors.black,
      style: TextStyle(color: Colors.white),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'process_pdfs'.tr,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

Widget _buildApiResponse() {
  if (isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: textColor),
          const SizedBox(height: 16),
          Text(
            'processing_pdfs'.tr,
            style: TextStyle(color: textColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.black,  // Fond noir pour le champ de réponse
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: textColor, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ajouter l'icône de copie en haut
        if (responseText?.isNotEmpty ?? false)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.copy, size: 16, color: const Color(0xFF17c9ef)),
              onPressed: () {
                if (responseText != null) {
                  Clipboard.setData(ClipboardData(text: responseText!)); // Copie le texte dans le presse-papiers
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
        SelectableText(
          responseText?.isEmpty ?? true
              ? 'processed_response'.tr
              : responseText!,
          style: TextStyle(
            color: Color(0xFF3ecaa7), // Couleur noire pour le texte de la réponse API
            fontSize: 16,
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
              ? [Color(0xFF02111a), Color(0xFF0a0e17)] // Mode sombre
              : [Colors.white, Colors.grey[100]!], // Mode clair
        ),
      ),
    );
  }
}
