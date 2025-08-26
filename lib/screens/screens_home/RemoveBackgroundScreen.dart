import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:speedobot/services/remove_background.dart';

class RemoveBackgroundScreen extends StatefulWidget {
  const RemoveBackgroundScreen({super.key});

  @override
  State<RemoveBackgroundScreen> createState() => _RemoveBackgroundScreenState();
}

class _RemoveBackgroundScreenState extends State<RemoveBackgroundScreen> {
  final Color textColor = const Color(0xFF3ECAA7);
  File? _selectedVideo;
  bool _isProcessing = false;
  bool _showProcessed = false;
  String? _processedVideoUrl;
  String? _errorMessage;

  final AudioPlayer _clickPlayer = AudioPlayer();
  final ApiService _apiService = ApiService();
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _clickPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _playClickSound() async {
    try {
      await _clickPlayer.play(AssetSource('sounds/click.wav'));
    } catch (e) {
      print('Erreur lors de la lecture du son: $e');
    }
  }

  Future<void> _pickVideo() async {
    await _playClickSound();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null && mounted) {
        setState(() {
          _selectedVideo = File(result.files.single.path!);
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la sélection de la vidéo : $e'.tr;
        });
      }
      print('Erreur lors de la sélection de la vidéo : $e');
    }
  }

  void _startProcessing() async {
    await _playClickSound();
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _showProcessed = false;
      _errorMessage = null;
    });

    try {
      if (_selectedVideo == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _errorMessage = 'Aucune vidéo sélectionnée'.tr;
          });
        }
        return;
      }

      print('RemoveBackgroundScreen: Envoi de la requête pour la vidéo : ${_selectedVideo!.path}');
      final videoResponse = await _apiService.removeBackgroundVideo(
        videoFile: _selectedVideo!,
        color: '#000000', // Valeur par défaut
        mode: 'Fast',     // Valeur par défaut
      );

      if (!mounted) return;

      if (videoResponse.status == 'ok') {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoResponse.downloadUrl))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {});
            }
          });
        setState(() {
          _isProcessing = false;
          _showProcessed = true;
          _processedVideoUrl = videoResponse.downloadUrl;
        });
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'video_processing_failed'.tr;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Erreur réseau : $e'.tr;
      });
      print('RemoveBackgroundScreen: Erreur lors du traitement : $e');
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
              color: isDarkMode ? const Color(0xFF02111a) : Colors.white,
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32), // Déplacer le titre vers le bas
                  _buildHeader(),
                  const SizedBox(height: 32), // Déplacer le sélecteur de vidéo vers le bas
                  _buildVideoPicker(),
                  const SizedBox(height: 40), // Déplacer le bouton vers le bas
                  _buildActionButton(),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  if (_showProcessed && _processedVideoUrl != null) _buildResponseSection(),
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
      children: [
        Text(
          'remove_background_title'.tr,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        
      ],
    );
  }

  Widget _buildVideoPicker() {
    return GestureDetector(
      onTap: _pickVideo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedVideo == null
                    ? 'Sélectionner une vidéo'.tr
                    : _selectedVideo!.path.split('/').last,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.videocam, color: textColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _startProcessing,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 180,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: textColor.withOpacity(_isProcessing ? 0.4 : 1.0),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: textColor.withOpacity(0.5), blurRadius: 12)],
        ),
        child: _isProcessing
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
                'process_button'.tr,
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
                child: _videoController != null && _videoController!.value.isInitialized
                    ? VideoPlayer(_videoController!)
                    : Center(child: CircularProgressIndicator(color: textColor)),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                await _playClickSound();
                if (mounted) {
                  _videoController?.pause();
                  setState(() {
                    _showProcessed = false;
                    _processedVideoUrl = null;
                    _errorMessage = null;
                  });
                  _videoController?.dispose();
                  _videoController = null;
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
          ],
        ),
      ),
    );
  }
}