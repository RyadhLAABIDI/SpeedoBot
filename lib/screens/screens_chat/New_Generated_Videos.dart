import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:speedobot/controllers/ThemeController.dart';
import 'package:speedobot/services/video_generation_service.dart';
import 'package:video_player/video_player.dart';
import 'package:speedobot/widgets/mini_game_widget.dart';

class VideoGenerationScreen extends StatefulWidget {
  @override
  State<VideoGenerationScreen> createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  final Color textColor = const Color(0xFF3ECAA7);
  final TextEditingController _promptController = TextEditingController();

  bool _isGenerating = false;
  bool _showGenerated = false;
  bool _isPlaying = false;
  bool _showMiniQuizGame = false;
  bool _isCancelled = false; // Added to track cancellation

  final AudioPlayer _clickPlayer = AudioPlayer();
  final ThemeController _themeController = Get.find();
  final ApiService _apiService = ApiService();
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _clickPlayer.dispose();
    _promptController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _playClickSound() async {
    await _clickPlayer.play(AssetSource('sounds/click.wav'));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.tr),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.tr),
        backgroundColor: textColor, // Vert (0xFF3ECAA7)
      ),
    );
  }

  void _startGeneration() async {
    await _playClickSound();
    if (_promptController.text.isEmpty) {
      _showError('prompt_empty_label');
      return;
    }

    setState(() {
      _isGenerating = true;
      _showGenerated = false;
      _showMiniQuizGame = true;
      _videoController?.dispose();
      _videoController = null;
      _isPlaying = false;
      _isCancelled = false; // Reset cancellation flag
    });

    try {
      final response = await _apiService.generateVideo(
        prompt: _promptController.text.trim(),
      );

      if (_isCancelled) { // Check if generation was cancelled
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _showMiniQuizGame = false;
            _showError('generation_cancelled');
          });
        }
        return;
      }

      if (response.success && response.videoUrl != null) {
        setState(() {
          _isGenerating = false;
          _showGenerated = true;
          _showMiniQuizGame = false;
          _videoController = VideoPlayerController.network(response.videoUrl!)
            ..initialize().then((_) {
              _videoController?.setPlaybackSpeed(0.5);
              _videoController?.setLooping(true);
              setState(() {
                _isPlaying = true;
                _videoController?.play();
              });
              _showSuccess('video_generation_success'); // Message de succès
            }).catchError((error) {
              _showError('video_init_failed_label');
            });
        });
      } else {
        setState(() {
          _isGenerating = false;
          _showMiniQuizGame = false;
        });
        _showError(response.message.tr);
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _showMiniQuizGame = false;
      });
      _showError('video_generation_failed_label'.tr);
    }
  }

  void _cancelGeneration() async { // Added cancel function
    await _playClickSound();
    if (!mounted) return;

    setState(() {
      _isCancelled = true;
      _isGenerating = false;
      _showMiniQuizGame = false;
      _showError('generation_cancelled');
    });
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

    return Directionality(
      textDirection: Get.locale?.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
                    if (_showMiniQuizGame) ...[
                      const SizedBox(height: 16),
                      MiniQuizGame(),
                    ],
                    if (_showGenerated) _buildResponseSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          hintText: 'enter_exercise_name'.tr,
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: _isGenerating ? null : _startGeneration,
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
                  _showGenerated = false;
                  _videoController?.dispose();
                  _videoController = null;
                  _isPlaying = false;
                });
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