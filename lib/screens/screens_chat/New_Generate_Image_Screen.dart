import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speedobot/services/api_service.dart';
import 'package:speedobot/widgets/mini_game_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class GenerateImageScreen extends StatefulWidget {
  @override
  State<GenerateImageScreen> createState() => _GenerateImageScreenState();
}

class _GenerateImageScreenState extends State<GenerateImageScreen> {
  final Color textColor = const Color(0xFF3ECAA7);
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  bool _showGenerated = false;
  bool _showMiniQuizGame = false;
  String? _generatedImageUrl;
  String? _errorMessage;
  final AudioPlayer _clickPlayer = AudioPlayer();
  final ApiService _apiService = ApiService();
  bool _isCancelled = false; // Added to track cancellation

  @override
  void dispose() {
    _clickPlayer.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _playClickSound() async {
    try {
      await _clickPlayer.play(AssetSource('sounds/click.wav'));
    } catch (e) {
      print('Erreur lors de la lecture du son: $e');
    }
  }

  String _fixImageUrl(String url) {
    final regex = RegExp(r'http://127\.0\.0\.1:\d+');
    if (url.contains(regex)) {
      return url.replaceFirst(regex, 'https://texttoimg.virtalya.com');
    }
    return url;
  }

  Future<void> _downloadImage(String url) async {
    try {
      // Demander la permission appropriée pour Android
      if (Platform.isAndroid) {
        // Pour Android 13+ (API 33+), utiliser Permission.photos
        Permission permission = Permission.photos;
        // Pour Android < 13, utiliser Permission.storage (si nécessaire)
        if (Platform.isAndroid && (await _getAndroidVersion()) < 33) {
          permission = Permission.storage;
        }

        var status = await permission.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('permission_denied'.tr),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Ouvrir Paramètres',
                textColor: textColor,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
          return;
        }
      }
      // Pas de permission nécessaire pour iOS dans le répertoire des documents

      // Télécharger l'image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('download_failed'.tr),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Obtenir le répertoire de sauvegarde
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/generated_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);

      // Sauvegarder l'image
      await file.writeAsBytes(response.bodyBytes);

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('image_downloaded'.tr),
          backgroundColor: textColor,
        ),
      );
    } catch (e) {
      print('Erreur lors du téléchargement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('download_failed'.tr),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper pour obtenir la version d'Android
  Future<int> _getAndroidVersion() async {
    try {
      final String? version = await Platform.version;
      final RegExp regex = RegExp(r'API (\d+)');
      final match = regex.firstMatch(version ?? '');
      return int.parse(match?.group(1) ?? '0');
    } catch (e) {
      return 0;
    }
  }

  void _startGeneration() async {
    await _playClickSound();
    if (!mounted) return;

    setState(() {
      _isGenerating = true;
      _showGenerated = false;
      _showMiniQuizGame = true;
      _errorMessage = null;
      _isCancelled = false; // Reset cancellation flag
    });

    try {
      if (_promptController.text.isEmpty) {
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _showMiniQuizGame = false;
            _errorMessage = 'empty_prompt_error'.tr;
          });
        }
        return;
      }

      final prompt = "${_promptController.text.trim()} 8k";
      print('GenerateImageScreen: Envoi du prompt "$prompt" à l\'API');
      final imageResponse = await _apiService.generateImage(prompt);

      if (_isCancelled) { // Check if generation was cancelled
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _showMiniQuizGame = false;
            _errorMessage = 'generation_cancelled'.tr;
          });
        }
        return;
      }

      if (!mounted) return;

      if (imageResponse.success) {
        final correctedUrl = _fixImageUrl(imageResponse.imageUrl);
        setState(() {
          _isGenerating = false;
          _showGenerated = true;
          _showMiniQuizGame = false;
          _generatedImageUrl = correctedUrl;
        });
      } else {
        setState(() {
          _isGenerating = false;
          _showMiniQuizGame = false;
          _errorMessage = 'image_generation_failed'.tr;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _showMiniQuizGame = false;
        _errorMessage = 'Erreur réseau : $e'.tr;
      });
      print('GenerateImageScreen: Erreur lors de la génération : $e');
    }
  }

  void _cancelGeneration() async { // Added cancel function
    await _playClickSound();
    if (!mounted) return;

    setState(() {
      _isCancelled = true;
      _isGenerating = false;
      _showMiniQuizGame = false;
      _errorMessage = 'generation_cancelled'.tr;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF02111a) : Colors.white,
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
                  _buildTextInputField(),
                  const SizedBox(height: 24),
                  Row( // Modified to add Cancel button
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildActionButton(),
                      if (_isGenerating) ...[
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: _cancelGeneration,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: 180,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(1.0),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 12)],
                            ),
                            child: Text(
                              'cancel'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_showMiniQuizGame) ...[
                    const SizedBox(height: 16),
                    MiniQuizGame(),
                  ],
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  if (_showGenerated && _generatedImageUrl != null) _buildResponseSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [],
    );
  }

  Widget _buildTextInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor),
      ),
      child: TextField(
        controller: _promptController,
        maxLines: 4,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'prompt_hint'.tr,
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: _isGenerating ? null : _startGeneration, // Désactive le bouton si _isGenerating est vrai
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 180,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: textColor.withOpacity(_isGenerating ? 0.4 : 1.0),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: textColor.withOpacity(0.5), blurRadius: 12)],
        ),
        child: _isGenerating
            ? Image.asset(
                'assets/RobotAIloading.gif',
                fit: BoxFit.cover,
                width: 180,
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  print('Erreur lors du chargement du GIF: $error');
                  return const Icon(Icons.error, color: Colors.white, size: 20);
                },
              )
            : Text(
                'generate_button'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Orbitron',
                ),
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
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: textColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _generatedImageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator(color: textColor));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        'error_loading_image'.tr,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () async {
                    await _playClickSound();
                    if (mounted) {
                      setState(() {
                        _showGenerated = false;
                        _generatedImageUrl = null;
                        _errorMessage = null;
                      });
                    }
                  },
                  child: Text(
                    'hide_preview'.tr,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await _playClickSound();
                    if (_generatedImageUrl != null) {
                      await _downloadImage(_generatedImageUrl!);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                      border: Border.all(color: textColor, width: 1.5),
                    ),
                    child: Icon(
                      Icons.download,
                      color: textColor,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}