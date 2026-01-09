import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import '../../providers/social_provider.dart';
import '../../theme/app_theme.dart';

/// Screen for creating a new story
class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  String? _mediaType;
  VideoPlayerController? _videoController;
  bool _isUploading = false;
  String _uploadStatus = '';

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final status = await _requestPhotoPermission();
    if (!status.isGranted) {
      _showPermissionDenied();
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _mediaType = 'image';
          _videoController?.dispose();
          _videoController = null;
        });
      }
    } catch (e) {
      _showError('Erreur lors de la selection: $e');
    }
  }

  Future<void> _pickVideo() async {
    final status = await _requestPhotoPermission();
    if (!status.isGranted) {
      _showPermissionDenied();
      return;
    }

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        final file = File(video.path);
        final fileSize = await file.length();

        // Check file size (max 50MB for stories)
        if (fileSize > 50 * 1024 * 1024) {
          _showError('La video ne doit pas depasser 50MB');
          return;
        }

        setState(() {
          _selectedFile = file;
          _mediaType = 'video';
        });

        _videoController = VideoPlayerController.file(file);
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.play();
        setState(() {});
      }
    } catch (e) {
      _showError('Erreur lors de la selection: $e');
    }
  }

  Future<void> _takePhoto() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showPermissionDenied();
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _mediaType = 'image';
          _videoController?.dispose();
          _videoController = null;
        });
      }
    } catch (e) {
      _showError('Erreur lors de la capture: $e');
    }
  }

  Future<void> _recordVideo() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showPermissionDenied();
      return;
    }

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        setState(() {
          _selectedFile = File(video.path);
          _mediaType = 'video';
        });

        _videoController = VideoPlayerController.file(File(video.path));
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.play();
        setState(() {});
      }
    } catch (e) {
      _showError('Erreur lors de l\'enregistrement: $e');
    }
  }

  Future<PermissionStatus> _requestPhotoPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      }
      return status;
    } else {
      return await Permission.photos.request();
    }
  }

  void _showPermissionDenied() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'L\'acces aux photos/camera est necessaire pour creer une story.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Parametres'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _mediaType = null;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  Future<void> _publishStory() async {
    if (_selectedFile == null || _mediaType == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Preparation...';
    });

    try {
      setState(() => _uploadStatus = 'Upload en cours...');

      int? duration;
      if (_mediaType == 'video' && _videoController != null) {
        duration = _videoController!.value.duration.inSeconds;
      }

      final story = await ref.read(storyNotifierProvider.notifier).createStory(
        mediaFile: _selectedFile!,
        mediaType: _mediaType!,
        duration: duration,
      );

      if (story != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story publiee !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, story);
      } else {
        throw Exception('Echec de la publication');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Nouvelle story'),
        actions: [
          if (_selectedFile != null && !_isUploading)
            TextButton(
              onPressed: _publishStory,
              child: const Text(
                'Publier',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _selectedFile == null
          ? _buildMediaPicker()
          : _buildPreview(),
    );
  }

  Widget _buildMediaPicker() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 80,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Creer une story',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Partagez un moment qui disparait apres 24h',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Photo options
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MediaOptionButton(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: _pickImage,
                ),
                const SizedBox(width: 24),
                _MediaOptionButton(
                  icon: Icons.camera_alt,
                  label: 'Photo',
                  onTap: _takePhoto,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Video options
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MediaOptionButton(
                  icon: Icons.video_library,
                  label: 'Video',
                  onTap: _pickVideo,
                ),
                const SizedBox(width: 24),
                _MediaOptionButton(
                  icon: Icons.videocam,
                  label: 'Filmer',
                  onTap: _recordVideo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Media preview
        if (_mediaType == 'video' && _videoController != null)
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          )
        else if (_selectedFile != null)
          Image.file(
            _selectedFile!,
            fit: BoxFit.contain,
          ),

        // Clear button
        if (!_isUploading)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
              onPressed: _clearSelection,
            ),
          ),

        // Video controls
        if (_mediaType == 'video' && _videoController != null && !_isUploading)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
              ),
            ),
          ),

        // Upload progress
        if (_isUploading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _uploadStatus,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

        // Info text
        if (!_isUploading)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre story sera visible pendant 24h',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MediaOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
