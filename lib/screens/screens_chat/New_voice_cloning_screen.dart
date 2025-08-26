import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:get/get.dart';
import 'package:speedobot/controllers/ThemeController.dart';
import 'package:speedobot/services/api_voice_cloning_service.dart';

class VoiceCloningScreen extends StatefulWidget {
  const VoiceCloningScreen({super.key});

  @override
  State<VoiceCloningScreen> createState() => _VoiceCloningScreenState();
}

class _VoiceCloningScreenState extends State<VoiceCloningScreen> {
  final TextEditingController _promptController = TextEditingController();
  final AudioPlayer _clickPlayer = AudioPlayer();
  final ThemeController _themeController = Get.find();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();
  final VoiceCloningApiService _apiService = VoiceCloningApiService();
  final Color textColor = const Color(0xFF3ECAA7);
  String? _selectedLanguage = 'English'.tr;
  final List<String> _languages = ['English'.tr, 'French'.tr, 'Arabic'.tr];
  File? _selectedAudio;
  String? _generatedAudioUrl;
  bool _isGenerating = false;
  bool _showResult = false;
  bool _isCancelled = false; // Added to track cancellation

  @override
  void initState() {
    super.initState();
    print('VoiceCloningScreen: initState called');
    _requestStoragePermission();
  }

  @override
  void dispose() {
    print('VoiceCloningScreen: dispose called');
    _promptController.dispose();
    _clickPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _playClickSound() async {
    print('VoiceCloningScreen: Playing click sound');
    await _clickPlayer.play(AssetSource('sounds/click.wav'));
  }

  Future<void> _requestStoragePermission() async {
    print('VoiceCloningScreen: Requesting storage permission');
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      print('VoiceCloningScreen: Storage permission status: $status');
      if (!status.isGranted) {
        var result = await Permission.storage.request();
        print('VoiceCloningScreen: permission request result: $result');
      }
    } else if (Platform.isIOS) {
      var photosStatus = await Permission.photos.status;
      print('VoiceCloningScreen: Photos permission status: $photosStatus');
      if (!photosStatus.isGranted) {
        var result = await Permission.photos.request();
        print('VoiceCloningScreen: Photos permission request result: $result');
      }
    }
  }

  Future<void> _pickAudio() async {
    print('VoiceCloningScreen: Picking audio file');
    await _playClickSound();
    final typeGroup = file_selector.XTypeGroup(
      label: 'Audio files'.tr,
      extensions: ['mp3', 'wav', 'aac'],
    );
    final file = await file_selector.openFile(
      acceptedTypeGroups: [typeGroup],
    );
    if (file != null) {
      print('VoiceCloningScreen: Audio file selected: ${file.path}');
      setState(() {
        _selectedAudio = File(file.path);
        _showResult = false;
        _generatedAudioUrl = null;
      });
    } else {
      print('VoiceCloningScreen: No audio file selected');
    }
  }

  void _showError(String message) {
    print('VoiceCloningScreen: Showing error - Message: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.tr), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    print('VoiceCloningScreen: Showing success - Message: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.tr), backgroundColor: textColor),
    );
  }

  void _cancelGeneration() async {
    await _playClickSound();
    if (!mounted) return;

    print('VoiceCloningScreen: Cancelling generation');
    setState(() {
      _isCancelled = true;
      _isGenerating = false; // Corrigé de true à false
      _showError('generation_cancelled');
    });
  }

  void _startGeneration() async {
    if (_promptController.text.isEmpty || _selectedAudio == null) {
      print('VoiceCloningScreen: Generation failed - Missing prompt or audio');
      _showError('please_enter_prompt_and_audio');
      return;
    }
    print('VoiceCloningScreen: Starting generation - Prompt: ${_promptController.text}, Language: $_selectedLanguage, Audio: ${_selectedAudio!.path}');
    await _playClickSound();

    setState(() {
      _isGenerating = true;
      _showResult = false;
      _generatedAudioUrl = null;
      _isCancelled = false;
    });

    // Map the selected language to language code
    final languageMap = {
      'English'.tr: 'en',
      'French'.tr: 'fr',
      'Arabic'.tr: 'ar',
    };
    final languageCode = languageMap[_selectedLanguage] ?? 'en';
    print('VoiceCloningScreen: Language mapped to code: $languageCode');

    try {
      final response = await _apiService.cloneVoice(
        text: _promptController.text,
        language: languageCode,
        references: _selectedAudio!,
      );

      if (_isCancelled) {
        if (mounted) {
          print('VoiceCloningScreen: Generation cancelled');
          setState(() {
            _isGenerating = false;
            _showError('generation_cancelled');
          });
        }
        return;
      }

      if (response['success']) {
        print('VoiceCloningScreen: Generation successful - URL: ${response['url']}');
        setState(() {
          _isGenerating = false;
          _showResult = true;
          _generatedAudioUrl = response['url'];
        });
        _showSuccess('voice_cloning_success');

        await Future.delayed(Duration(milliseconds: 800));
        if (_resultKey.currentContext != null) {
          print('VoiceCloningScreen: Scrolling to result');
          Scrollable.ensureVisible(
            _resultKey.currentContext!,
            duration: Duration(seconds: 2),
            curve: Curves.easeInOut,
            alignment: 0.0,
          );
        }
      } else {
        print('VoiceCloningScreen: Generation failed - Error: ${response['error']}');
        setState(() {
          _isGenerating = false;
        });
        _showError('server_pressure_error');
      }
    } catch (e) {
      print('VoiceCloningScreen: Generation error - Exception: $e');
      setState(() {
        _isGenerating = false;
      });
      _showError('server_pressure_error');
    }
  }

  Future<void> _playResponse() async {
    print('VoiceCloningScreen: Playing response audio - URL: $_generatedAudioUrl');
    await _playClickSound();
    if (_generatedAudioUrl != null) {
      await _clickPlayer.play(UrlSource(_generatedAudioUrl!));
    } else {
      print('VoiceCloningScreen: No audio URL to play');
    }
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
                color: isDarkMode ? Colors.black : Colors.white,
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
                  _buildTextInputField(),
                  const SizedBox(height: 16),
                  _buildLanguageDropdown(),
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
                              'cancel_button'.tr,
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
          hintText: 'enter_prompt_label'.tr,
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor),
      ),
      child: DropdownButton2<String>(
        value: _selectedLanguage,
        items: _languages
            .map((language) => DropdownMenuItem(
                  value: language,
                  child: Text(
                    language.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ))
            .toList(),
        onChanged: (value) {
          print('VoiceCloningScreen: Language changed to: $value');
          setState(() {
            _selectedLanguage = value;
          });
          _playClickSound();
        },
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        buttonStyleData: ButtonStyleData(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        iconStyleData: IconStyleData(
          icon: Icon(Icons.arrow_drop_down, color: textColor),
        ),
      ),
    );
  }

  Widget _buildAudioSection() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isGenerating ? null : _pickAudio, // Disable button when generating
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
                      _selectedAudio!.path.split('/').last, // Display only file name
                      style: const TextStyle(color: Colors.white70),
                    ),
                    GestureDetector(
                      onTap: () async {
                        print('VoiceCloningScreen: Removing selected audio: ${_selectedAudio!.path}');
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
      onTap: (_isGenerating || _promptController.text.isEmpty || _selectedAudio == null) ? null : _startGeneration,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 180,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: textColor.withOpacity(_isGenerating ? 0.4 : 1.0),
          borderRadius: BorderRadius.circular(12),
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
        key: _resultKey,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: textColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.audiotrack, color: textColor, size: 50),
                  const SizedBox(width: 10),
                  Text(
                    'cloned_voice_result'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _playResponse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'play_button'.tr,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                print('VoiceCloningScreen: Hiding result preview');
                setState(() => _showResult = false);
              },
              child: Text(
                'hide_preview_label'.tr,
                style: const TextStyle(
                  color: Colors.white,
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