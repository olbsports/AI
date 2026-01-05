import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/analysis.dart';
import '../../providers/analyses_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_view.dart';

class AnalysisDetailScreen extends ConsumerStatefulWidget {
  final String analysisId;

  const AnalysisDetailScreen({super.key, required this.analysisId});

  @override
  ConsumerState<AnalysisDetailScreen> createState() =>
      _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends ConsumerState<AnalysisDetailScreen> {
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initVideoPlayer(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    final analysisAsync = ref.watch(analysisProvider(widget.analysisId));

    return analysisAsync.when(
      data: (analysis) {
        if (_videoController == null && analysis.videoUrl != null) {
          _initVideoPlayer(analysis.videoUrl!);
        }
        return _buildContent(context, analysis);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(analysisProvider(widget.analysisId)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Analysis analysis) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_typeLabel(analysis.type)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                _showDeleteDialog(context, analysis);
              } else if (value == 'report') {
                context.push('/reports/new?analysisId=${analysis.id}');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.description),
                    SizedBox(width: 8),
                    Text('Créer un rapport'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video player
            _buildVideoPlayer(context, analysis),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  _buildStatusSection(context, analysis),
                  const SizedBox(height: 24),

                  // Horse info
                  if (analysis.horseName != null) ...[
                    _buildHorseSection(context, analysis),
                    const SizedBox(height: 24),
                  ],

                  // Results
                  if (analysis.status == AnalysisStatus.completed) ...[
                    _buildResultsSection(context, analysis),
                    const SizedBox(height: 24),
                  ],

                  // Processing status
                  if (analysis.status == AnalysisStatus.processing) ...[
                    _buildProcessingSection(context),
                    const SizedBox(height: 24),
                  ],

                  // Notes
                  if (analysis.notes != null && analysis.notes!.isNotEmpty) ...[
                    _buildNotesSection(context, analysis),
                    const SizedBox(height: 24),
                  ],

                  // Date info
                  _buildDateSection(context, analysis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context, Analysis analysis) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        height: 220,
        color: Colors.black,
        child: Center(
          child: analysis.thumbnailUrl != null
              ? Image.network(analysis.thumbnailUrl!, fit: BoxFit.cover)
              : const Icon(Icons.videocam, color: Colors.white54, size: 48),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_videoController!),
          _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
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
          Expanded(
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: () {
              // TODO: Fullscreen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, Analysis analysis) {
    return Row(
      children: [
        _buildStatusChip(context, analysis.status),
        const Spacer(),
        Text(
          _typeLabel(analysis.type),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildHorseSection(BuildContext context, Analysis analysis) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.pets,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(analysis.horseName!),
        subtitle: const Text('Cheval analysé'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (analysis.horseId != null) {
            context.push('/horses/${analysis.horseId}');
          }
        },
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context, Analysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Résultats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (analysis.results != null) ...[
          // Score global
          if (analysis.results!['globalScore'] != null)
            _buildScoreCard(
              context,
              'Score global',
              analysis.results!['globalScore'].toDouble(),
              Icons.star,
              AppColors.primary,
            ),
          const SizedBox(height: 12),

          // Other scores
          if (analysis.results!['symmetry'] != null)
            _buildScoreCard(
              context,
              'Symétrie',
              analysis.results!['symmetry'].toDouble(),
              Icons.balance,
              AppColors.secondary,
            ),
          if (analysis.results!['rhythm'] != null) ...[
            const SizedBox(height: 12),
            _buildScoreCard(
              context,
              'Rythme',
              analysis.results!['rhythm'].toDouble(),
              Icons.music_note,
              AppColors.success,
            ),
          ],

          // Recommendations
          if (analysis.results!['recommendations'] != null) ...[
            const SizedBox(height: 24),
            Text(
              'Recommandations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...List<String>.from(analysis.results!['recommendations'])
                .map((rec) => _buildRecommendationItem(context, rec)),
          ],
        ] else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Résultats non disponibles',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScoreCard(
    BuildContext context,
    String label,
    double score,
    IconData icon,
    Color color,
  ) {
    final percentage = (score * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: score,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingSection(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Analyse en cours...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez patienter, l\'analyse peut prendre quelques minutes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, Analysis analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(analysis.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(BuildContext context, Analysis analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(context, 'Créé le', _formatDate(analysis.createdAt)),
            if (analysis.completedAt != null)
              _buildInfoRow(
                  context, 'Terminé le', _formatDate(analysis.completedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, AnalysisStatus status) {
    Color color;
    String label;

    switch (status) {
      case AnalysisStatus.pending:
        color = AppColors.warning;
        label = 'En attente';
        break;
      case AnalysisStatus.processing:
        color = AppColors.secondary;
        label = 'En cours';
        break;
      case AnalysisStatus.completed:
        color = AppColors.success;
        label = 'Terminé';
        break;
      case AnalysisStatus.failed:
        color = AppColors.error;
        label = 'Erreur';
        break;
      case AnalysisStatus.cancelled:
        color = AppColors.textSecondary;
        label = 'Annulé';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _typeLabel(AnalysisType type) {
    switch (type) {
      case AnalysisType.videoPerformance:
        return 'Performance vidéo';
      case AnalysisType.videoCourse:
        return 'Parcours CSO';
      case AnalysisType.radiological:
        return 'Radiologique';
      case AnalysisType.locomotion:
        return 'Analyse locomotion';
      case AnalysisType.jump:
        return 'Analyse saut';
      case AnalysisType.posture:
        return 'Analyse posture';
      case AnalysisType.conformation:
        return 'Analyse conformation';
      case AnalysisType.course:
        return 'Analyse parcours';
      case AnalysisType.video:
        return 'Analyse vidéo';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BuildContext context, Analysis analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'analyse'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette analyse ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await ref
                  .read(analysesNotifierProvider.notifier)
                  .deleteAnalysis(analysis.id);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  context.go('/analyses');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Analyse supprimée')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
