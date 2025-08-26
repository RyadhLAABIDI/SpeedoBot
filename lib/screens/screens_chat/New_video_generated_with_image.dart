import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speedobot/controllers/ThemeController.dart';
import 'package:speedobot/services/api_imageVideo_service.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoGeneratedWithImageScreen extends StatefulWidget {
  @override
  State<VideoGeneratedWithImageScreen> createState() => _VideoGeneratedWithImageScreenState();
}

class _VideoGeneratedWithImageScreenState extends State<VideoGeneratedWithImageScreen> {
  final Color textColor = const Color(0xFF3ECAA7);
  final AudioPlayer _clickPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
  final ThemeController _themeController = Get.find();
  final ScrollController _scrollController = ScrollController();

  XFile? _selectedImage;
  File? _selectedAudio;
  bool _isGenerating = false;
  bool _showResult = false;
  bool _isPlaying = false;
  bool _isDownloading = false;
  bool _isCancelled = false; // Added to track cancellation

  final GlobalKey _videoKey = GlobalKey();
  final ApiService _apiService = ApiService();
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
  }

  @override
  void dispose() {
    _clickPlayer.dispose();
    _scrollController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _playClickSound() async {
    await _clickPlayer.play(AssetSource('sounds/click.wav'));
  }

  Future<void> _pickImage() async {
    await _playClickSound();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _showResult = false;
      });
    }
  }

  Future<void> _pickAudio() async {
    await _playClickSound();
    final typeGroup = file_selector.XTypeGroup(
      label: 'Audio files'.tr,
      extensions: ['mp3', 'wav', 'aac'],
    );
    final file = await file_selector.openFile(
      acceptedTypeGroups: [typeGroup],
    );
    if (file != null) {
      setState(() {
        _selectedAudio = File(file.path);
        _showResult = false;
      });
    }
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      var photosStatus = await Permission.photos.status;
      if (!photosStatus.isGranted) {
        await Permission.photos.request();
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.tr), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.tr), backgroundColor: textColor),
    );
  }

  Future<void> _downloadVideo(String videoUrl) async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);
    await _playClickSound();

    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      String fileName = 'generated_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      String savePath = '${tempDir.path}/$fileName';

      await dio.download(videoUrl, savePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          print('Progress: ${(received / total * 100).toStringAsFixed(0)}%');
        }
      });

      final result = await ImageGallerySaverPlus.saveFile(
        savePath,
        isReturnPathOfIOS: true,
      );

      if (result['isSuccess']) {
        _showSuccess('video_downloaded_label');
      } else {
        _showError('gallery_save_failed_label');
      }
    } catch (e) {
      _showError('download_failed_label');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  void _cancelGeneration() async {
    await _playClickSound();
    if (!mounted) return;

    setState(() {
      _isCancelled = true;
      _isGenerating = false;
      _showError('generation_cancelled');
    });
  }

  void _startGeneration() async {
    await _playClickSound();
    if (_selectedImage == null || _selectedAudio == null) {
      _showError('select_image_audio_error');
      return;
    }
    setState(() {
      _isGenerating = true;
      _showResult = false;
      _isCancelled = false;
    });
    try {
      final response = await _apiService.generateVideoFromImageAndAudio(
        imageFile: File(_selectedImage!.path),
        audioFile: _selectedAudio!,
        preprocess: true,
        stillMode: false,
      );

      if (_isCancelled) {
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _showError('generation_cancelled');
          });
        }
        return;
      }

      if (response.success && response.videoUrl != null) {
        setState(() {
          _isGenerating = false;
          _showResult = true;
          _videoController = VideoPlayerController.network(
            'https://imgaudiotovideo.virtalya.com/${response.videoUrl}',
          )..initialize().then((_) {
            setState(() {
              _isPlaying = true;
              _videoController?.play();
            });
            _showSuccess('video_generation_success');
          }).catchError((error) {
            _showError('video_init_failed_label');
            print('Erreur lors de l\'initialisation de la vidéo: $error');
          });
        });

        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted && _videoKey.currentContext != null) {
            Scrollable.ensureVisible(
              _videoKey.currentContext!,
              duration: Duration(seconds: 2),
              curve: Curves.easeInOutCubic,
              alignment: 0.0,
            );
          }
        });
      } else {
        setState(() {
          _isGenerating = false;
        });
        _showError('video_generation_failed_label');
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _showError('video_generation_failed_label');
      print('Erreur pendant la génération: $e');
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _videoController?.play();
      } else {
        _videoController?.pause();
      }
    });
  }

  void _replayVideo() {
    if (_videoController == null) return;
    _videoController?.seekTo(Duration.zero);
    setState(() => _isPlaying = true);
    _videoController?.play();
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
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildImageSection(),
                const SizedBox(height: 16),
                _buildAudioSection(),
                const SizedBox(height: 24),
                Row(
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
                            color: Colors.red,
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
                if (_showResult) _buildResultSection(),
              ],
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

  Widget _buildImageSection() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isGenerating ? null : _pickImage, // Désactive la sélection d'image si _isGenerating est vrai
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
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor),
          ),
          child: _selectedImage == null
              ? Center(
                  child: Text(
                    'select_image_placeholder'.tr,
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                ),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              await _playClickSound();
              setState(() => _selectedImage = null);
            },
            child: Text(
              'hide_image_label'.tr,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAudioSection() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isGenerating ? null : _pickAudio, // Désactive la sélection d'audio si _isGenerating est vrai
          style: ElevatedButton.styleFrom(
            backgroundColor: textColor,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: Text(
            'select_audio_placeholder'.tr,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor),
          ),
          child: _selectedAudio == null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.audiotrack_rounded, color: textColor),
                    const SizedBox(width: 10),
                    Text(
                      'select_audio_placeholder'.tr,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedAudio!.path.split('/').last.tr,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await _playClickSound();
                        setState(() => _selectedAudio = null);
                      },
                      child: Icon(Icons.close, color: textColor),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: (_isGenerating || _selectedImage == null || _selectedAudio == null) ? null : _startGeneration,
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

  Widget _buildResultSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        key: _videoKey,
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
              child: _videoController != null && _videoController!.value.isInitialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: VideoPlayer(_videoController!),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: textColor,
                                  size: 40,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.replay,
                                  color: textColor,
                                  size: 40,
                                ),
                                onPressed: _replayVideo,
                              ),
                              IconButton(
                                icon: _isDownloading
                                    ? CircularProgressIndicator(color: textColor)
                                    : Icon(Icons.download, color: textColor, size: 40),
                                onPressed: _isDownloading
                                    ? null
                                    : () {
                                        if (_videoController != null) {
                                          _downloadVideo(_videoController!.dataSource);
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Center(child: CircularProgressIndicator(color: textColor)),
            ),
            const SizedBox(height: 8),
            Text(
              'generated_video_preview'.tr,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                await _playClickSound();
                setState(() {
                  _showResult = false;
                  _videoController?.dispose();
                  _videoController = null;
                  _isPlaying = false;
                });
              },
              child: Text(
                'hide_preview_label'.tr,
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