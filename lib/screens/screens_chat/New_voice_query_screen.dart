import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:speedobot/services/voice_to_voice.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speedobot/controllers/ThemeController.dart';

class VoiceQueryScreen extends StatefulWidget {
  @override
  State<VoiceQueryScreen> createState() => _VoiceQueryScreenState();
}

class _VoiceQueryScreenState extends State<VoiceQueryScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  final Logger _logger = Logger();
  final Color textColor = const Color(0xFF3ECAA7);
  final ApiService _apiService = ApiService();
  final ThemeController _themeController = Get.find();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _responseSectionKey = GlobalKey();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isProcessingResponse = false;
  bool _isCancelled = false;
  File? _recordedFile;
  File? _responseFile;
  String _statusText = 'presser_pour_enregistrer'.tr;
  List<String> _videoUrls = [];
  int _selectedVideoIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  final Map<int, VideoPlayerController> _carouselControllers = {};

  final String _fallbackVideoUrl = 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_1MB.mp4';

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _loadVideoAvatars();
  }

  Future<void> _loadVideoAvatars({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });
    await _fetchVideoAvatars();
  }

  Future<void> _fetchVideoAvatars() async {
    try {
      final videoUrls = await _apiService.fetchVideoAvatars();
      setState(() {
        _videoUrls = videoUrls;
        _isLoading = false;
        if (_videoUrls.isNotEmpty) {
          _initializeVideoController(_videoUrls[0]);
          _initializeCarouselControllers();
        }
      });
      _logger.i('Fetched ${_videoUrls.length} video_synced avatars');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('failed_to_fetch_video_avatars'.tr);
    }
  }

  Future<void> _playRefreshSound() async {
    try {
      await _clickPlayer.play(AssetSource('sounds/refresh.mp3'));
      _logger.i('Refresh sound played');
    } catch (e) {
      _logger.e('Failed to play refresh sound: $e');
    }
  }

  Future<void> _initializeCarouselControllers() async {
    for (int i = 0; i < _videoUrls.length; i++) {
      if (!_carouselControllers.containsKey(i)) {
        final controller = VideoPlayerController.networkUrl(Uri.parse(_videoUrls[i]));
        try {
          await controller.initialize();
          controller.setLooping(true);
          _carouselControllers[i] = controller;
          _logger.i('Carousel controller initialized for index $i');
        } catch (e) {
          _logger.e('Failed to initialize carousel controller for index $i: $e');
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeVideoController(String videoUrl) async {
    _logger.i('Attempting to initialize video controller with URL: $videoUrl');
    try {
      if (_videoController != null) {
        await _videoController!.dispose();
      }
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
      await _videoController!.setLooping(true);
      _logger.i('Video initialized successfully: $videoUrl');
    } catch (e) {
      _logger.e('Error initializing video controller for $videoUrl: $e');
      _showError('impossible_de_charger_la_video'.tr);
      try {
        _logger.i('Trying fallback video URL: $_fallbackVideoUrl');
        _videoController = VideoPlayerController.networkUrl(Uri.parse(_fallbackVideoUrl));
        await _videoController!.initialize();
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
        await _videoController!.setLooping(true);
        _logger.i('Fallback video initialized successfully: $_fallbackVideoUrl');
      } catch (fallbackError) {
        _logger.e('Error initializing fallback video: $fallbackError');
        try {
          _logger.i('Trying local asset video as final fallback');
          _videoController = VideoPlayerController.asset('assets/fallback_video.mp4');
          await _videoController!.initialize();
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
          }
          await _videoController!.setLooping(true);
          _logger.i('Local asset video initialized successfully');
        } catch (localError) {
          _logger.e('Error initializing local asset video: $localError');
          if (mounted) {
            setState(() {
              _isVideoInitialized = false;
            });
          }
        }
      }
    }
  }

  Future<void> _initializeRecorder() async {
    _logger.i('Initializing recorder...');
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _logger.e('Microphone permission denied');
      _showError('permission_microphone_refusee'.tr);
      setState(() {
        _statusText = 'permission_microphone_refusee'.tr;
      });
      return;
    }
    try {
      await _recorder.openRecorder();
      _recorder.setSubscriptionDuration(Duration(milliseconds: 100));
      _logger.i('Recorder initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize recorder: $e');
      _showError('echec_initialisation_enregistreur'.tr);
    }
  }

  Future<String> _getTempFilePath() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/recorded_message_${DateTime.now().millisecondsSinceEpoch}.aac';
    _logger.i('Generated temp file path: $path');
    return path;
  }

  Future<void> _playClickSound() async {
    try {
      await _clickPlayer.play(AssetSource('sounds/click.wav'));
      _logger.i('Click sound played');
    } catch (e) {
      _logger.e('Failed to play click sound: $e');
    }
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.isGranted) {
      try {
        await _playClickSound();
        final path = await _getTempFilePath();
        await _recorder.startRecorder(toFile: path, codec: Codec.aacADTS);
        _logger.i('Recording started, path: $path');
        setState(() {
          _isRecording = true;
          _isPlaying = false;
          _recordedFile = null;
          _statusText = 'enregistrement_en_cours'.tr;
        });
      } catch (e) {
        _logger.e('Failed to start recording: $e');
        _showError('echec_enregistrement'.tr);
      }
    } else {
      _logger.e('Microphone permission not granted');
      _showError('permission_microphone_refusee'.tr);
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _playClickSound();
      final path = await _recorder.stopRecorder();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          _logger.i('Recording saved at: $path, size: ${await file.length()} bytes');
          setState(() {
            _isRecording = false;
            _recordedFile = file;
            _statusText = 'enregistrement_termine'.tr;
          });
        } else {
          _logger.e('Recording file does not exist at: $path');
          _showError('fichier_enregistrement_non_trouve'.tr);
        }
      }
    } catch (e) {
      _logger.e('Failed to stop recording: $e');
      _showError('echec_arret_enregistrement'.tr);
    }
  }

  Future<void> _playRecording(File? file) async {
    if (file == null) {
      _logger.e('No recording file available to play');
      _showError('aucun_enregistrement_disponible'.tr);
      return;
    }

    try {
      if (_isPlaying) {
        await _playClickSound();
        await _player.stop();
        if (_videoController != null && _isVideoInitialized && file == _responseFile) {
          await _videoController!.pause();
          _logger.i('Video paused when stopping playback manually');
        }
        _logger.i('Recording playback stopped manually');
        setState(() {
          _isPlaying = false;
          _statusText = _recordedFile != null ? 'enregistrement_termine'.tr : 'presser_pour_enregistrer'.tr;
        });
      } else {
        await _playClickSound();
        await _player.play(DeviceFileSource(file.path));
        if (file == _responseFile && _videoController != null && _isVideoInitialized) {
          await _videoController!.setLooping(true);
          await _videoController!.play();
          _logger.i('Video started playing in loop during _playRecording for response');
        }
        _logger.i('Playing recording from: ${file.path}');
        setState(() {
          _isPlaying = true;
          _statusText = file == _responseFile ? 'lecture_reponse'.tr : 'lecture_enregistrement'.tr;
        });
        _player.onPlayerComplete.listen((event) {
          _logger.i('Recording playback completed');
          if (file == _responseFile && _videoController != null && _isVideoInitialized) {
            _videoController!.pause();
            _logger.i('Video paused after audio completion in _playRecording');
          }
          setState(() {
            _isPlaying = false;
            _statusText = _recordedFile != null ? 'enregistrement_termine'.tr : 'presser_pour_enregistrer'.tr;
          });
        });
      }
    } catch (e) {
      _logger.e('Failed to play recording: $e');
      _showError('echec_lecture_enregistrement'.tr);
      setState(() {
        _isPlaying = false;
        _statusText = _recordedFile != null ? 'enregistrement_termine'.tr : 'presser_pour_enregistrer'.tr;
      });
    }
  }

  void _cancelGeneration() async {
    await _playClickSound();
    if (!mounted) return;

    _logger.i('Cancelling response generation');
    setState(() {
      _isCancelled = true;
      _isProcessingResponse = false;
      _statusText = _recordedFile != null ? 'enregistrement_termine'.tr : 'presser_pour_enregistrer'.tr;
      _showError('generation_cancelled'.tr);
    });
  }

  Future<void> _generateResponse() async {
    if (_recordedFile == null) {
      _logger.e('No recording available for processing');
      _showError('aucun_enregistrement_disponible'.tr);
      return;
    }

    await _playClickSound();
    setState(() {
      _isProcessingResponse = true;
      _isCancelled = false;
      _statusText = 'traiter_requete'.tr;
    });

    try {
      _logger.i('Starting API chain for audio processing...');

      _logger.i('Transcribing audio file: ${_recordedFile!.path}');
      final transcription = await _apiService.transcribeAudio(_recordedFile!);
      _logger.i('Transcription received: $transcription');

      _logger.i('Sending transcribed text to chat API: $transcription');
      final chatResponse = await _apiService.sendChatMessage(transcription);
      _logger.i('Chat response received: $chatResponse');

      _logger.i('Converting chat response to audio: $chatResponse');
      final audioUrl = await _apiService.textToSpeech(chatResponse);
      _logger.i('Audio URL received: $audioUrl');

      if (_isCancelled) {
        if (mounted) {
          _logger.i('Generation cancelled');
          setState(() {
            _isProcessingResponse = false;
            _statusText = _recordedFile != null ? 'enregistrement_termine'.tr : 'presser_pour_enregistrer'.tr;
            _showError('generation_cancelled'.tr);
          });
        }
        return;
      }

      _logger.i('Downloading audio from: $audioUrl');
      final tempDir = await getTemporaryDirectory();
      final responsePath = '${tempDir.path}/response_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final responseFile = await _apiService.downloadAudio(audioUrl, responsePath);
      _logger.i('Audio file downloaded and saved at: $responsePath');

      setState(() {
        _responseFile = responseFile;
        _isProcessingResponse = false;
        _isPlaying = false;
        _statusText = 'reponse_prete'.tr;
      });
      _showSuccess('reponse_recue'.tr);

      await Future.delayed(Duration(milliseconds: 200));

      if (_videoController != null && _isVideoInitialized) {
        await _videoController!.setLooping(true);
        await _videoController!.pause();
        _logger.i('Video initialized and paused after response generation');
      } else {
        _logger.w('Video controller not initialized, reinitializing...');
        if (_videoUrls.isNotEmpty) {
          await _initializeVideoController(_videoUrls[_selectedVideoIndex]);
          if (_videoController != null && _isVideoInitialized) {
            await _videoController!.setLooping(true);
            await _videoController!.pause();
            _logger.i('Video reinitialized and paused: ${_videoUrls[_selectedVideoIndex]}');
          }
        }
      }

      _scrollToResponseSection();
    } catch (e) {
      _logger.e('Failed to process API chain: $e');
      _showError('echec_generation_reponse'.tr);
      setState(() {
        _isProcessingResponse = false;
        _statusText = _recordedFile != null ? 'enregistrement_termine'.tr : 'presser_pour_enregistrer'.tr;
      });
    }
  }

  void _scrollToResponseSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _responseSectionKey.currentContext != null) {
        final RenderBox renderBox = _responseSectionKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero).dy;
        final scrollPosition = position - MediaQuery.of(context).padding.top - 50;
        _scrollController.animateTo(
          scrollPosition.clamp(0, _scrollController.position.maxScrollExtent),
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _logger.i('Scrolled to response section at position: $scrollPosition');
      } else {
        _logger.w('ScrollController or response section not ready, retrying...');
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) _scrollToResponseSection();
        });
      }
    });
  }

  Future<void> _hideResponse() async {
    try {
      await _playClickSound();
      if (_responseFile != null) {
        final file = File(_responseFile!.path);
        if (await file.exists()) {
          await file.delete();
          _logger.i('Response deleted: ${_responseFile!.path}');
        }
      }
      if (_videoController != null && _isVideoInitialized) {
        await _videoController!.pause();
        _logger.i('Video paused in _hideResponse');
      }
      _logger.i('Response hidden');
      setState(() {
        _responseFile = null;
        _isPlaying = false;
        _statusText = _recordedFile != null ? 'enregistrement_termine'.tr : 'presser_pour_enregistrer'.tr;
      });
    } catch (e) {
      _logger.e('Failed to hide response: $e');
      _showError('echec_suppression_reponse'.tr);
    }
  }

  Future<void> _hideRecording() async {
    try {
      await _playClickSound();
      if (_recordedFile != null) {
        final file = File(_recordedFile!.path);
        if (await file.exists()) {
          await file.delete();
          _logger.i('Recording deleted: ${_recordedFile!.path}');
        }
      }
      setState(() {
        _recordedFile = null;
        _isPlaying = false;
        _statusText = 'presser_pour_enregistrer'.tr;
      });
    } catch (e) {
      _logger.e('Failed to hide recording: $e');
      _showError('echec_suppression_enregistrement'.tr);
    }
  }

  void _showError(String message) {
    _logger.i('Showing error: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    _logger.i('Showing success: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: textColor),
    );
  }

  @override
  void dispose() {
    _logger.i('Disposing VoiceQueryScreen...');
    _recorder.closeRecorder();
    _player.dispose();
    _clickPlayer.dispose();
    _videoController?.dispose();
    _carouselControllers.forEach((_, controller) => controller.dispose());
    _scrollController.dispose();
    if (_recordedFile != null) {
      try {
        File(_recordedFile!.path).delete();
        _logger.i('Recording file deleted on dispose');
      } catch (e) {
        _logger.e('Failed to delete recording on dispose: $e');
      }
    }
    if (_responseFile != null) {
      try {
        File(_responseFile!.path).delete();
        _logger.i('Response file deleted on dispose');
      } catch (e) {
        _logger.e('Failed to delete response on dispose: $e');
      }
    }
    super.dispose();
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
            RefreshIndicator(
              onRefresh: () async {
                await _playRefreshSound();
                await _loadVideoAvatars();
              },
              color: textColor,
              backgroundColor: Colors.black,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildVideoAvatarSection(),
                    const SizedBox(height: 16),
                    _buildRecordingSection(),
                    if (_buildRecordingControls != null) _buildRecordingControls(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildActionButton(),
                        if (_isProcessingResponse) ...[
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
                    if (_responseFile != null && !_isProcessingResponse) _buildResponseSection(),
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

  Widget _buildVideoAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'selectionner_avatar'.tr,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoading && _videoUrls.isEmpty)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textColor),
            ),
            child: Center(
              child: CircularProgressIndicator(color: textColor),
            ),
          )
        else if (_videoUrls.isNotEmpty)
          Container(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _videoUrls.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedVideoIndex == index;
                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedVideoIndex = index;
                      _initializeVideoController(_videoUrls[index]);
                    });
                    await _playClickSound();
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    width: isSelected ? 160 : 120,
                    height: isSelected ? 200 : 160,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? textColor : Colors.white70,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _carouselControllers[index] != null
                          ? VideoPlayer(_carouselControllers[index]!)
                          : Center(
                              child: CircularProgressIndicator(color: textColor),
                            ),
                    ),
                  ),
                );
              },
            ),
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textColor),
            ),
            child: Center(
              child: Text(
                'aucun_avatar_disponible'.tr,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecordingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _statusText,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: textColor,
              padding: const EdgeInsets.all(20),
              shape: CircleBorder(),
            ),
            child: Icon(
              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingControls() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: textColor,
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(
                _isPlaying ? 'lecture_enregistrement'.tr : 'jouer_enregistrement'.tr,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _playRecording(_recordedFile),
          child: Text(
            _isPlaying ? 'arreter_enregistrement'.tr : 'jouer_enregistrement'.tr,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _hideRecording,
          child: Text(
            'supprimer_enregistrement'.tr,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: (_recordedFile != null && !_isProcessingResponse) ? _generateResponse : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 180,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: textColor.withOpacity(_isProcessingResponse ? 0.4 : 1.0),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: textColor.withOpacity(0.5), blurRadius: 12)],
        ),
        child: _isProcessingResponse
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
                'traiter_requete'.tr,
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
        key: _responseSectionKey,
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
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: textColor),
              ),
              child: _isVideoInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: VideoPlayer(_videoController!),
                    )
                  : Center(
                      child: Text(
                        'video_indisponible'.tr,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: textColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
                    color: textColor,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isPlaying ? 'lecture_reponse'.tr : 'jouer_reponse'.tr,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _playRecording(_responseFile),
              child: Text(
                _isPlaying ? 'arreter_reponse'.tr : 'jouer_reponse'.tr,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _hideResponse,
              child: Text(
                'supprimer_reponse'.tr,
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