import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speedobot/controllers/ThemeController.dart';
import 'package:speedobot/services/image_enhancer_service.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ImageEnhancerScreen extends StatefulWidget {
  @override
  State<ImageEnhancerScreen> createState() => _ImageEnhancerScreenState();
}

class _ImageEnhancerScreenState extends State<ImageEnhancerScreen> {
  final Color textColor = const Color(0xFF3ECAA7);
  final AudioPlayer _clickPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
  final ThemeController _themeController = Get.find();
  final ScrollController _scrollController = ScrollController();

  XFile? _selectedImage;
  String? _enhancedImageUrl;
  bool _isGenerating = false;
  bool _showResult = false;
  bool _isDownloading = false;
  bool _isCancelled = false; // Added to track cancellation

  final GlobalKey _imageKey = GlobalKey();
  final ImageEnhancerService _enhancerService = ImageEnhancerService();

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
  }

  @override
  void dispose() {
    _clickPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _playClickSound() async {
    await _clickPlayer.play(AssetSource('sounds/click.wav'));
  }

  Future<void> _pickImage() async {
    await _playClickSound();
    if (Platform.isAndroid) {
      if (await _isAndroid13OrAbove()) {
        var status = await Permission.photos.status;
        if (!status.isGranted) {
          var result = await Permission.photos.request();
          if (result.isPermanentlyDenied) {
            _showPermissionDeniedDialog();
            return;
          }
          if (!result.isGranted) {
            _showError('image_permission_denied');
            return;
          }
        }
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          var result = await Permission.storage.request();
          if (result.isPermanentlyDenied) {
            _showPermissionDeniedDialog();
            return;
          }
          if (!result.isGranted) {
            _showError('image_permission_denied');
            return;
          }
        }
      }
    } else if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        var result = await Permission.photos.request();
        if (result.isPermanentlyDenied) {
          _showPermissionDeniedDialog();
          return;
        }
        if (!result.isGranted) {
          _showError('image_permission_denied');
          return;
        }
      }
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _showResult = false;
        _enhancedImageUrl = null;
      });
    } else {
      _showError('image_selection_failed');
    }
  }

  Future<bool> _isAndroid13OrAbove() async {
    if (Platform.isAndroid) {
      var deviceInfo = await DeviceInfoPlugin().androidInfo;
      return deviceInfo.version.sdkInt >= 33;
    }
    return false;
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrAbove()) {
        var status = await Permission.photos.status;
        if (!status.isGranted) {
          var result = await Permission.photos.request();
          if (result.isPermanentlyDenied) {
            _showPermissionDeniedDialog();
          }
        }
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          var result = await Permission.storage.request();
          if (result.isPermanentlyDenied) {
            _showPermissionDeniedDialog();
          }
        }
      }
    } else if (Platform.isIOS) {
      var photosStatus = await Permission.photos.status;
      if (!photosStatus.isGranted) {
        var result = await Permission.photos.request();
        if (result.isPermanentlyDenied) {
          _showPermissionDeniedDialog();
        }
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('permission_required'.tr),
        content: Text('please_enable_storage_permission'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              Navigator.of(context).pop();
            },
            child: Text('settings'.tr),
          ),
        ],
      ),
    );
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

  Future<void> _downloadImage(String imageUrl) async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);
    await _playClickSound();

    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      String fileName = 'enhanced_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String savePath = '${tempDir.path}/$fileName';

      await dio.download(imageUrl, savePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          print('ImageEnhancerScreen: Téléchargement - Progrès: ${(received / total * 100).toStringAsFixed(0)}%');
        }
      });

      final result = await ImageGallerySaverPlus.saveFile(
        savePath,
        isReturnPathOfIOS: true,
      );

      if (result['isSuccess']) {
        _showSuccess('image_downloaded_label');
      } else {
        _showError('gallery_save_failed_label');
      }
    } catch (e) {
      _showError('download_failed_label');
      print('ImageEnhancerScreen: Erreur lors du téléchargement: $e');
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

  void _startEnhancement() async {
    await _playClickSound();
    if (_selectedImage == null) {
      _showError('no_image_selected_label');
      return;
    }
    setState(() {
      _isGenerating = true;
      _showResult = false;
      _isCancelled = false;
    });
    try {
      print('ImageEnhancerScreen: Début de l\'amélioration de l\'image');
      final imageUrl = await _enhancerService.enhanceImage(
        imageFile: File(_selectedImage!.path),
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
      print('ImageEnhancerScreen: URL de l\'image améliorée reçue: $imageUrl');
      if (imageUrl != null) {
        setState(() {
          _isGenerating = false;
          _showResult = true;
          _enhancedImageUrl = imageUrl;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _imageKey.currentContext != null) {
            final RenderBox? renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final position = renderBox.localToGlobal(Offset.zero).dy;
              final scrollPosition = position - MediaQuery.of(context).padding.top - 50;
              _scrollController.animateTo(
                scrollPosition.clamp(0, _scrollController.position.maxScrollExtent),
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
              print('ImageEnhancerScreen: Défilement vers position: $scrollPosition');
            } else {
              print('ImageEnhancerScreen: RenderBox est null');
            }
          } else {
            print('ImageEnhancerScreen: _imageKey.currentContext est null');
          }
        });
      } else {
        setState(() {
          _isGenerating = false;
        });
        _showError('enhancement_failed_label');
        print('ImageEnhancerScreen: Échec - URL de l\'image améliorée est null');
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _showError('enhancement_failed_label');
      print('ImageEnhancerScreen: Erreur pendant l\'amélioration: $e');
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
                color: isDarkMode ? Color(0xFF02111a) : Colors.white,
              ),
            ),
            SingleChildScrollView(
              controller: _scrollController,
              physics: AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildImageSection(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_image_label'.tr,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isGenerating ? null : _pickImage, // Désactive la sélection d'image si _isGenerating est vrai
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textColor),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.contain,
                    ),
                  )
                : Center(
                    child: Text(
                      'select_image_placeholder'.tr,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
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

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: (_isGenerating || _selectedImage == null) ? null : _startEnhancement,
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
                'enhance_button'.tr,
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
        key: _imageKey,
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
              child: _enhancedImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _enhancedImageUrl!,
                        fit: BoxFit.contain,
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
                    )
                  : Center(child: CircularProgressIndicator(color: textColor)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    await _playClickSound();
                    setState(() {
                      _showResult = false;
                      _enhancedImageUrl = null;
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
                const SizedBox(width: 20),
                if (_enhancedImageUrl != null)
                  IconButton(
                    icon: _isDownloading
                        ? CircularProgressIndicator(color: textColor)
                        : Icon(Icons.download, color: textColor, size: 24),
                    onPressed: _isDownloading ? null : () => _downloadImage(_enhancedImageUrl!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}