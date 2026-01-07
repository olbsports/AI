import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/analysis.dart';
import '../../models/horse.dart';
import '../../providers/analyses_provider.dart';
import '../../providers/horses_provider.dart';
import '../../widgets/loading_button.dart';

class NewAnalysisScreen extends ConsumerStatefulWidget {
  final String? horseId;

  const NewAnalysisScreen({super.key, this.horseId});

  @override
  ConsumerState<NewAnalysisScreen> createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends ConsumerState<NewAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedHorseId;
  AnalysisType _selectedType = AnalysisType.locomotion;
  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedHorseId = widget.horseId;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (video != null) {
      _videoController?.dispose();
      final file = File(video.path);
      _videoController = VideoPlayerController.file(file);
      try {
        await _videoController!.initialize();
        if (mounted) {
          setState(() {
            _selectedVideo = file;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du chargement de la vidéo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _recordVideo() async {
    // Request camera permission
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      if (mounted) {
        if (status.isPermanentlyDenied) {
          _showPermissionDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission caméra refusée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      return;
    }

    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 5),
    );

    if (video != null) {
      _videoController?.dispose();
      final file = File(video.path);
      _videoController = VideoPlayerController.file(file);
      try {
        await _videoController!.initialize();
        if (mounted) {
          setState(() {
            _selectedVideo = file;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du chargement de la vidéo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'L\'accès à la caméra est nécessaire pour enregistrer une vidéo. '
          'Veuillez autoriser l\'accès dans les paramètres de l\'application.',
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
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une vidéo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedHorseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un cheval'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final analysis = await ref.read(analysesNotifierProvider.notifier).createAnalysis(
        horseId: _selectedHorseId!,
        type: _selectedType.name.toUpperCase(),
        videoFile: _selectedVideo!,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        if (analysis != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Analyse créée avec succès')),
          );
          context.go('/analyses/${analysis.id}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la création'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horsesAsync = ref.watch(horsesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle analyse'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Video selection
              _buildVideoSection(),
              const SizedBox(height: 24),

              // Horse selection
              _buildHorseSelection(horsesAsync),
              const SizedBox(height: 16),

              // Analysis type
              _buildTypeSelection(),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLength: 500,
              ),
              const SizedBox(height: 24),

              // Submit button
              LoadingButton(
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                text: 'Lancer l\'analyse',
                icon: Icons.analytics,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vidéo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_selectedVideo != null && _videoController?.value.isInitialized == true)
          _buildVideoPreview()
        else
          _buildVideoPlaceholder(),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    size: 64,
                    color: Colors.white70,
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickVideo,
          icon: const Icon(Icons.refresh),
          label: const Text('Changer de vidéo'),
        ),
      ],
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez une vidéo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _recordVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('Filmer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorseSelection(AsyncValue<List<Horse>> horsesAsync) {
    return horsesAsync.when(
      data: (horses) {
        if (horses.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.pets,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text('Aucun cheval enregistré'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/horses/add'),
                    child: const Text('Ajouter un cheval'),
                  ),
                ],
              ),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedHorseId,
          decoration: const InputDecoration(
            labelText: 'Cheval *',
            prefixIcon: Icon(Icons.pets),
          ),
          items: horses.map((horse) {
            return DropdownMenuItem(
              value: horse.id,
              child: Text(horse.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedHorseId = value);
          },
          validator: (value) {
            if (value == null) {
              return 'Veuillez sélectionner un cheval';
            }
            return null;
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Erreur de chargement des chevaux'),
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type d\'analyse',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTypeChip(
              AnalysisType.locomotion,
              'Locomotion',
              Icons.directions_walk,
            ),
            _buildTypeChip(
              AnalysisType.jump,
              'Saut',
              Icons.sports,
            ),
            _buildTypeChip(
              AnalysisType.posture,
              'Posture',
              Icons.accessibility_new,
            ),
            _buildTypeChip(
              AnalysisType.conformation,
              'Conformation',
              Icons.straighten,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(AnalysisType type, String label, IconData icon) {
    final isSelected = _selectedType == type;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) {
        setState(() => _selectedType = type);
      },
    );
  }
}
