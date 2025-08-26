import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:speedobot/controllers/ThemeController.dart';
import 'package:speedobot/services/tts_api_service.dart';
import 'package:speedobot/models/tts_response.dart';

class SpeechToAudioScreen extends StatefulWidget {
  @override
  State<SpeechToAudioScreen> createState() => _SpeechToAudioScreenState();
}

class _SpeechToAudioScreenState extends State<SpeechToAudioScreen> {
  final Color textColor = const Color(0xFF3ECAA7);
  final TextEditingController _textController = TextEditingController();
  bool _isGenerating = false;
  bool _showGenerated = false;
  bool _isCancelled = false; // Added to track cancellation
  String? _generatedAudioUrl;
  String? _errorMessage;
  String? _selectedLanguage;
  String? _selectedSpeaker;
  double _speed = 1.0;
  List<Language> _languages = [];
  List<Speaker> _speakers = [];

  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ThemeController _themeController = Get.find();
  final TtsApiService _apiService = TtsApiService();

  @override
  void initState() {
    super.initState();
    _loadLanguagesAndSpeakers();
  }

  @override
  void dispose() {
    _clickPlayer.dispose();
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _playClickSound() async {
    await _clickPlayer.play(AssetSource('sounds/click.wav'));
  }

  Future<void> _loadLanguagesAndSpeakers() async {
    try {
      final languages = await _apiService.getLanguages();
      final speakers = await _apiService.getSpeakers();
      setState(() {
        _languages = languages;
        _speakers = speakers;
        _selectedLanguage = languages.isNotEmpty ? languages[0].code : null;
        _selectedSpeaker = speakers.isNotEmpty ? speakers[0].id : null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'load_languages_speakers_error'.tr;
      });
      _showError('load_languages_speakers_error'.tr);
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
    setState(() {
      _isGenerating = true;
      _showGenerated = false;
      _errorMessage = null;
      _isCancelled = false;
    });

    try {
      if (_textController.text.isEmpty) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'empty_text_error'.tr;
        });
        _showError('empty_text_error'.tr);
        return;
      }
      if (_selectedLanguage == null || _selectedSpeaker == null) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'select_language_speaker_error'.tr;
        });
        _showError('select_language_speaker_error'.tr);
        return;
      }

      final response = await _apiService.generateAudio(
        text: _textController.text.trim(),
        language: _selectedLanguage!,
        speaker: _selectedSpeaker!,
        speed: _speed,
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

      if (response.success) {
        setState(() {
          _isGenerating = false;
          _showGenerated = true;
          _generatedAudioUrl = response.audioUrl;
        });
        _showSuccess('audio_generation_success');
      } else {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'audio_generation_failed'.tr;
        });
        _showError('audio_generation_failed'.tr);
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'generic_error'.tr;
      });
      _showError('generic_error'.tr);
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
                  const SizedBox(height: 16),
                  _buildLanguageDropdown(),
                  const SizedBox(height: 16),
                  _buildSpeakerDropdown(),
                  const SizedBox(height: 16),
                  _buildSpeedSlider(),
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
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  if (_showGenerated && _generatedAudioUrl != null) _buildResponseSection(),
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
        controller: _textController,
        maxLines: 4,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'speech_text_hint'.tr,
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
      child: DropdownButton<String>(
        value: _selectedLanguage,
        hint: Text('select_language_hint'.tr, style: const TextStyle(color: Colors.white70)),
        isExpanded: true,
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        underline: const SizedBox(),
        items: _languages.map((lang) {
          return DropdownMenuItem<String>(
            value: lang.code,
            child: Text(lang.name.tr),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedLanguage = value;
          });
        },
      ),
    );
  }

  Widget _buildSpeakerDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor),
      ),
      child: DropdownButton<String>(
        value: _selectedSpeaker,
        hint: Text('select_speaker_hint'.tr, style: const TextStyle(color: Colors.white70)),
        isExpanded: true,
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        underline: const SizedBox(),
        items: _speakers.map((speaker) {
          return DropdownMenuItem<String>(
            value: speaker.id,
            child: Text(speaker.name.tr),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedSpeaker = value;
          });
        },
      ),
    );
  }

  Widget _buildSpeedSlider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'speed_label'.tr + ' ${_speed.toStringAsFixed(1)}',
          style: TextStyle(color: textColor, fontSize: 16),
        ),
        const SizedBox(width: 10),
        Slider(
          value: _speed,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          activeColor: textColor,
          inactiveColor: textColor.withOpacity(0.3),
          onChanged: (value) {
            setState(() {
              _speed = value;
            });
          },
        ),
      ],
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
                'generate_audio_button'.tr,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: textColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.play_arrow, color: textColor, size: 32),
                    onPressed: () async {
                      await _playClickSound();
                      await _audioPlayer.play(UrlSource(_generatedAudioUrl!));
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.stop, color: textColor, size: 32),
                    onPressed: () async {
                      await _playClickSound();
                      await _audioPlayer.stop();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'generated_audio_preview'.tr,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                await _playClickSound();
                await _audioPlayer.stop();
                setState(() {
                  _showGenerated = false;
                  _generatedAudioUrl = null;
                  _errorMessage = null;
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