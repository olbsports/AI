import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/models.dart';
import '../../providers/social_provider.dart';
import '../../theme/app_theme.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          _buildNotificationButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pour toi'),
            Tab(text: 'Abonnements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(forYouFeedProvider),
          _buildFeedTab(followingFeedProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotificationButton() {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(context),
        ),
        unreadCount.when(
          data: (count) => count > 0
              ? Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFeedTab(FutureProvider<List<PublicNote>> feedProvider) {
    final feedAsync = ref.watch(feedProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(feedProvider);
      },
      child: feedAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return _buildEmptyFeed();
          }
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Trending tags section
              SliverToBoxAdapter(
                child: _buildTrendingTags(),
              ),
              const SliverToBoxAdapter(child: Divider()),
              // Feed posts
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPostCard(posts[index]),
                  childCount: posts.length,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error, feedProvider),
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Aucune publication',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à partager !',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreatePostSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Créer une publication'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error, FutureProvider<List<PublicNote>> provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text('Erreur de chargement'),
          const SizedBox(height: 8),
          Text(
            error.toString().length > 100
                ? '${error.toString().substring(0, 100)}...'
                : error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(provider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTags() {
    final tagsAsync = ref.watch(trendingTagsProvider);

    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text('#${tag.tag}'),
                  onPressed: () => _showTagPosts(context, tag.tag),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 50),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPostCard(PublicNote post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: post.authorPhotoUrl != null
                  ? NetworkImage(post.authorPhotoUrl!)
                  : null,
              child: post.authorPhotoUrl == null
                  ? Text(post.authorName.isNotEmpty ? post.authorName[0] : '?')
                  : null,
            ),
            title: Text(
              post.authorName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Row(
              children: [
                if (post.horseName != null) ...[
                  Icon(Icons.pets, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    post.horseName!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _formatTimeAgo(post.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(
                  _getVisibilityIcon(post.visibility),
                  size: 12,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showPostOptions(context, post),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(post.content),
          ),
          // Media
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMediaGrid(post.mediaUrls),
          ],
          // Tags
          if (post.tags.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 4,
                children: post.tags.map((tag) => InkWell(
                  onTap: () => _showTagPosts(context, tag),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Like
                _buildActionButton(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: post.likeCount > 0 ? '${post.likeCount}' : '',
                  color: post.isLiked ? Colors.red : null,
                  onTap: () => _toggleLike(post),
                ),
                const SizedBox(width: 16),
                // Comment
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: post.commentCount > 0 ? '${post.commentCount}' : '',
                  onTap: () => _showComments(context, post),
                ),
                const SizedBox(width: 16),
                // Share
                if (post.allowSharing)
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: post.shareCount > 0 ? '${post.shareCount}' : '',
                    onTap: () => _sharePost(post),
                  ),
                const Spacer(),
                // Save
                IconButton(
                  icon: Icon(
                    post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: post.isSaved ? AppColors.primary : null,
                  ),
                  onPressed: () => _toggleSave(post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(List<String> urls) {
    if (urls.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          urls[0],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.image, size: 48)),
          ),
        ),
      );
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: urls.take(4).map((url) => Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.image)),
        ),
      )).toList(),
    );
  }

  IconData _getVisibilityIcon(ContentVisibility visibility) {
    switch (visibility) {
      case ContentVisibility.private:
        return Icons.lock;
      case ContentVisibility.organization:
        return Icons.home;
      case ContentVisibility.followers:
        return Icons.people;
      case ContentVisibility.public:
        return Icons.public;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}j';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _toggleLike(PublicNote post) async {
    final notifier = ref.read(socialNotifierProvider.notifier);
    if (post.isLiked) {
      await notifier.unlikeNote(post.id);
    } else {
      await notifier.likeNote(post.id);
    }
    ref.invalidate(forYouFeedProvider);
    ref.invalidate(followingFeedProvider);
  }

  void _toggleSave(PublicNote post) async {
    final notifier = ref.read(socialNotifierProvider.notifier);
    if (post.isSaved) {
      await notifier.unsaveNote(post.id);
    } else {
      await notifier.saveNote(post.id);
    }
    ref.invalidate(forYouFeedProvider);
    ref.invalidate(followingFeedProvider);
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _FeedSearchDelegate(ref),
    );
  }

  void _showTagPosts(BuildContext context, String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TagPostsScreen(tag: tag),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _NotificationsSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateNoteSheet(
        onPost: (noteData) async {
          final notifier = ref.read(socialNotifierProvider.notifier);
          final result = await notifier.createNote(noteData);
          if (result != null) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Publication créée !')),
            );
          }
        },
      ),
    );
  }

  void _showPostOptions(BuildContext context, PublicNote post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(post.isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
            title: Text(post.isSaved ? 'Retirer des favoris' : 'Enregistrer'),
            onTap: () {
              Navigator.pop(context);
              _toggleSave(post);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Copier le lien'),
            onTap: () {
              Navigator.pop(context);
              // Copy link functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_outlined),
            title: const Text('Signaler'),
            onTap: () {
              Navigator.pop(context);
              _showReportDialog(context, post);
            },
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, PublicNote post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler cette publication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Contenu inapproprié'),
              onTap: () => _submitReport(context, post.id, 'inappropriate'),
            ),
            ListTile(
              title: const Text('Spam'),
              onTap: () => _submitReport(context, post.id, 'spam'),
            ),
            ListTile(
              title: const Text('Harcèlement'),
              onTap: () => _submitReport(context, post.id, 'harassment'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _submitReport(BuildContext context, String noteId, String reason) async {
    Navigator.pop(context);
    final notifier = ref.read(socialNotifierProvider.notifier);
    final success = await notifier.reportNote(noteId, reason, null);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement envoyé')),
      );
    }
  }

  void _showComments(BuildContext context, PublicNote post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentsSheet(noteId: post.id),
    );
  }

  void _sharePost(PublicNote post) async {
    final notifier = ref.read(socialNotifierProvider.notifier);
    await notifier.shareNote(post.id);
    Share.share(
      '${post.content}\n\n- ${post.authorName}',
      subject: 'Partage de ${post.authorName}',
    );
  }
}

class _FeedSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _FeedSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.startsWith('#')) {
      return TagPostsScreen(tag: query.substring(1));
    }
    return _buildUserResults();
  }

  Widget _buildUserResults() {
    return Consumer(
      builder: (context, ref, child) {
        final usersAsync = ref.watch(searchUsersProvider(query));
        return usersAsync.when(
          data: (users) => ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null ? Text(user.name[0]) : null,
                ),
                title: Text(user.name),
                onTap: () {
                  // Navigate to user profile
                },
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Erreur de recherche')),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final tagsAsync = ref.watch(trendingTagsProvider);
        return tagsAsync.when(
          data: (tags) {
            final suggestions = tags
                .where((t) => t.tag.toLowerCase().contains(query.toLowerCase()))
                .take(10)
                .toList();
            return ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.tag),
                title: Text('#${suggestions[index].tag}'),
                trailing: Text('${suggestions[index].postCount} posts'),
                onTap: () {
                  query = '#${suggestions[index].tag}';
                  showResults(context);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }
}

class TagPostsScreen extends ConsumerWidget {
  final String tag;

  const TagPostsScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsByTagProvider(tag));

    return Scaffold(
      appBar: AppBar(title: Text('#$tag')),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('Aucune publication avec ce tag'));
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              // Simplified post card for tag view
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(post.authorName),
                  subtitle: Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _NotificationsSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const _NotificationsSheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ref.read(socialNotifierProvider.notifier).markAllNotificationsRead();
                },
                child: const Text('Tout marquer lu'),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return const Center(child: Text('Aucune notification'));
              }
              return ListView.builder(
                controller: scrollController,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: notif.actorPhotoUrl != null
                          ? NetworkImage(notif.actorPhotoUrl!)
                          : null,
                      child: notif.actorPhotoUrl == null
                          ? Text(notif.actorName[0])
                          : null,
                    ),
                    title: Text(notif.message),
                    subtitle: Text(_formatTimeAgo(notif.createdAt)),
                    tileColor: notif.isRead ? null : Colors.blue.withOpacity(0.1),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}

class CommentsSheet extends ConsumerStatefulWidget {
  final String noteId;

  const CommentsSheet({super.key, required this.noteId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(noteCommentsProvider(widget.noteId));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Commentaires',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(),
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('Aucun commentaire'),
                        const Text('Soyez le premier à commenter !'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment.authorPhotoUrl != null
                            ? NetworkImage(comment.authorPhotoUrl!)
                            : null,
                        child: comment.authorPhotoUrl == null
                            ? Text(comment.authorName[0])
                            : null,
                      ),
                      title: Text(comment.authorName),
                      subtitle: Text(comment.content),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: AppColors.primary),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final notifier = ref.read(socialNotifierProvider.notifier);
    final result = await notifier.addComment(widget.noteId, content);

    if (result != null) {
      _commentController.clear();
    }
  }
}

class CreateNoteSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onPost;

  const CreateNoteSheet({super.key, required this.onPost});

  @override
  State<CreateNoteSheet> createState() => _CreateNoteSheetState();
}

class _CreateNoteSheetState extends State<CreateNoteSheet> {
  final _contentController = TextEditingController();
  ContentVisibility _visibility = ContentVisibility.public;
  bool _allowComments = true;
  bool _allowSharing = true;
  String? _selectedHorseId;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Nouvelle publication',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Partagez votre expérience...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Visibilité :'),
                const SizedBox(width: 8),
                DropdownButton<ContentVisibility>(
                  value: _visibility,
                  items: ContentVisibility.values.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Row(
                        children: [
                          Text(v.icon),
                          const SizedBox(width: 8),
                          Text(v.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _visibility = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Commentaires', style: TextStyle(fontSize: 14)),
                    value: _allowComments,
                    onChanged: (v) => setState(() => _allowComments = v ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Partage', style: TextStyle(fontSize: 14)),
                    value: _allowSharing,
                    onChanged: (v) => setState(() => _allowSharing = v ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () {},
                  tooltip: 'Ajouter une photo',
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: () {},
                  tooltip: 'Ajouter une vidéo',
                ),
                IconButton(
                  icon: const Icon(Icons.pets),
                  onPressed: () {},
                  tooltip: 'Associer un cheval',
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isLoading || _contentController.text.trim().isEmpty
                      ? null
                      : _submitPost,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Publier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitPost() {
    setState(() => _isLoading = true);
    widget.onPost({
      'content': _contentController.text.trim(),
      'visibility': _visibility.name,
      'allowComments': _allowComments,
      'allowSharing': _allowSharing,
      if (_selectedHorseId != null) 'horseId': _selectedHorseId,
    });
  }
}
