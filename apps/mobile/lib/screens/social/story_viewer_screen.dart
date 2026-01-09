import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/social.dart';
import '../../providers/social_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Full-screen story viewer
class StoryViewerScreen extends ConsumerStatefulWidget {
  final List<StoryGroup> storyGroups;
  final int initialGroupIndex;
  final int initialStoryIndex;

  const StoryViewerScreen({
    super.key,
    required this.storyGroups,
    this.initialGroupIndex = 0,
    this.initialStoryIndex = 0,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _groupPageController;
  late int _currentGroupIndex;
  late int _currentStoryIndex;
  late AnimationController _progressController;
  Timer? _autoAdvanceTimer;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isLoading = true;

  static const _storyDuration = Duration(seconds: 5);
  static const _videoDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _currentStoryIndex = widget.initialStoryIndex;
    _groupPageController = PageController(initialPage: _currentGroupIndex);
    _progressController = AnimationController(vsync: this);

    // Enter fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _loadCurrentStory();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _progressController.dispose();
    _autoAdvanceTimer?.cancel();
    _videoController?.dispose();
    _groupPageController.dispose();
    super.dispose();
  }

  StoryGroup get _currentGroup => widget.storyGroups[_currentGroupIndex];
  Story get _currentStory => _currentGroup.stories[_currentStoryIndex];

  void _loadCurrentStory() async {
    setState(() => _isLoading = true);
    _progressController.reset();
    _autoAdvanceTimer?.cancel();
    _videoController?.dispose();
    _videoController = null;

    // Mark story as viewed
    ref.read(storyNotifierProvider.notifier).viewStory(_currentStory.id);

    if (_currentStory.mediaType == StoryType.video) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(_currentStory.mediaUrl),
      );
      await _videoController!.initialize();
      _videoController!.play();

      final duration = _currentStory.duration != null
          ? Duration(seconds: _currentStory.duration!)
          : _videoController!.value.duration.inSeconds > _videoDuration.inSeconds
              ? _videoDuration
              : _videoController!.value.duration;

      _startProgress(duration);
    } else {
      _startProgress(_storyDuration);
    }

    setState(() => _isLoading = false);
  }

  void _startProgress(Duration duration) {
    _progressController.duration = duration;
    _progressController.forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isPaused) {
        _nextStory();
      }
    });
  }

  void _nextStory() {
    if (_currentStoryIndex < _currentGroup.stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _loadCurrentStory();
    } else if (_currentGroupIndex < widget.storyGroups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _groupPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadCurrentStory();
    } else {
      _close();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _loadCurrentStory();
    } else if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentStoryIndex = widget.storyGroups[_currentGroupIndex].stories.length - 1;
      });
      _groupPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadCurrentStory();
    }
  }

  void _pauseStory() {
    setState(() => _isPaused = true);
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeStory() {
    setState(() => _isPaused = false);
    _progressController.forward();
    _videoController?.play();
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _showViewers() {
    final currentUser = ref.read(authProvider).user;
    if (_currentStory.authorId != currentUser?.id) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => _StoryViewersSheet(storyId: _currentStory.id),
    );
  }

  void _deleteStory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la story'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(storyNotifierProvider.notifier).deleteStory(_currentStory.id);
      if (success && mounted) {
        _nextStory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isOwnStory = _currentStory.authorId == currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story content
            _buildStoryContent(),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(_currentGroup.stories.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _ProgressBar(
                        progress: index < _currentStoryIndex
                            ? 1.0
                            : index == _currentStoryIndex
                                ? _progressController
                                : 0.0,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/profile/${_currentGroup.userId}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: _currentGroup.userPhotoUrl != null
                              ? CachedNetworkImageProvider(_currentGroup.userPhotoUrl!)
                              : null,
                          child: _currentGroup.userPhotoUrl == null
                              ? Text(_currentGroup.userName[0])
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentGroup.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatTimeAgo(_currentStory.createdAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (isOwnStory) ...[
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.white),
                      onPressed: _showViewers,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: _deleteStory,
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _close,
                  ),
                ],
              ),
            ),

            // Views count for own stories
            if (isOwnStory)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _showViewers,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${_currentStory.viewsCount} vues',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent() {
    if (_currentStory.mediaType == StoryType.video && _videoController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: _currentStory.mediaUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.error, color: Colors.white, size: 48),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}

/// Progress bar for story
class _ProgressBar extends StatelessWidget {
  final dynamic progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 3,
        color: Colors.white.withValues(alpha: 0.3),
        child: progress is AnimationController
            ? AnimatedBuilder(
                animation: progress as AnimationController,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (progress as AnimationController).value,
                    child: Container(color: Colors.white),
                  );
                },
              )
            : FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (progress as double).clamp(0.0, 1.0),
                child: Container(color: Colors.white),
              ),
      ),
    );
  }
}

/// Story viewers bottom sheet
class _StoryViewersSheet extends ConsumerWidget {
  final String storyId;

  const _StoryViewersSheet({required this.storyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewersAsync = ref.watch(storyViewersProvider(storyId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Vues',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: viewersAsync.when(
              data: (viewers) {
                if (viewers.isEmpty) {
                  return const Center(
                    child: Text('Aucune vue pour le moment'),
                  );
                }
                return ListView.builder(
                  itemCount: viewers.length,
                  itemBuilder: (context, index) {
                    final viewer = viewers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: viewer.photoUrl != null
                            ? CachedNetworkImageProvider(viewer.photoUrl!)
                            : null,
                        child: viewer.photoUrl == null
                            ? Text(viewer.name[0])
                            : null,
                      ),
                      title: Text(viewer.name),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile/${viewer.id}');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
