import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/models.dart';
import '../../providers/social_provider.dart';
import '../../providers/horses_provider.dart';
import '../../providers/auth_provider.dart';
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

  Widget _buildFeedTab(AutoDisposeFutureProvider<List<PublicNote>> feedProvider) {
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

  Widget _buildErrorWidget(Object error, AutoDisposeFutureProvider<List<PublicNote>> provider) {
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
            leading: post.authorPhotoUrl != null
                ? CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(post.authorPhotoUrl!),
                  )
                : CircleAvatar(
                    child: Text(post.authorName.isNotEmpty ? post.authorName[0] : '?'),
                  ),
            title: Text(
              post.authorName,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                if (post.horseName != null) ...[
                  Icon(Icons.pets, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      post.horseName!,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
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
            child: Text(
              post.content,
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
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
        child: CachedNetworkImage(
          imageUrl: urls[0],
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Container(
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
      children: urls.take(4).map((url) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => Container(
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
      builder: (sheetContext) => CreateNoteSheet(
        onPost: (noteData) async {
          final notifier = ref.read(socialNotifierProvider.notifier);
          final result = await notifier.createNote(noteData);
          if (result != null && mounted) {
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Publication créée !')),
            );
          }
        },
      ),
    );
  }

  void _showPostOptions(BuildContext context, PublicNote post) {
    final currentUserId = ref.read(authProvider).user?.id;
    final isOwnPost = currentUserId != null && currentUserId == post.authorId;

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
              final postLink = 'https://horsetempo.app/posts/${post.id}';
              Clipboard.setData(ClipboardData(text: postLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lien copié dans le presse-papiers'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          if (isOwnPost) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, post);
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Signaler'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context, post);
              },
            ),
          ],
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

  void _showDeleteConfirmation(BuildContext context, PublicNote post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette publication ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(context, post);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _deletePost(BuildContext context, PublicNote post) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Suppression en cours...'),
        duration: Duration(seconds: 2),
      ),
    );

    final notifier = ref.read(socialNotifierProvider.notifier);
    final success = await notifier.deleteNote(post.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publication supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the feeds
        ref.invalidate(forYouFeedProvider);
        ref.invalidate(followingFeedProvider);
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    await SharePlus.instance.share(
      ShareParams(
        text: '${post.content}\n\n- ${post.authorName}',
        subject: 'Partage de ${post.authorName}',
      ),
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
                leading: user.photoUrl != null
                    ? CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(user.photoUrl!),
                      )
                    : CircleAvatar(
                        child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                      ),
                title: Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  close(context, '');
                  context.push('/profile/${user.id}');
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
                    leading: notif.actorPhotoUrl != null
                        ? CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(notif.actorPhotoUrl!),
                          )
                        : CircleAvatar(
                            child: Text(notif.actorName.isNotEmpty ? notif.actorName[0] : '?'),
                          ),
                    title: Text(
                      notif.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_formatTimeAgo(notif.createdAt)),
                    tileColor: notif.isRead ? null : Colors.blue.withValues(alpha: 0.1),
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
                      leading: comment.authorPhotoUrl != null
                          ? CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(comment.authorPhotoUrl!),
                            )
                          : CircleAvatar(
                              child: Text(comment.authorName.isNotEmpty ? comment.authorName[0] : '?'),
                            ),
                      title: Text(
                        comment.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        comment.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
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

class CreateNoteSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onPost;

  const CreateNoteSheet({super.key, required this.onPost});

  @override
  ConsumerState<CreateNoteSheet> createState() => _CreateNoteSheetState();
}

class _CreateNoteSheetState extends ConsumerState<CreateNoteSheet> {
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  ContentVisibility _visibility = ContentVisibility.public;
  bool _allowComments = true;
  bool _allowSharing = true;
  Horse? _selectedHorse;
  bool _isLoading = false;
  bool _isUploading = false;
  List<File> _selectedMediaFiles = [];
  String? _mediaType;
  String _uploadStatus = '';

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedMediaFiles.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 médias par publication')),
      );
      return;
    }

    // Request photo permission
    PermissionStatus status;
    if (Platform.isAndroid) {
      // Android 13+ uses photos instead of storage
      if (await Permission.photos.isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.photos.request();
        // Fallback for Android < 13
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
      }
    } else {
      // iOS
      status = await Permission.photos.request();
    }

    if (!status.isGranted) {
      if (mounted) {
        if (status.isPermanentlyDenied) {
          _showPermissionDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission d\'accès aux photos refusée')),
          );
        }
      }
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedMediaFiles.add(File(image.path));
          _mediaType = 'image';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'L\'accès aux photos est nécessaire pour ajouter des images. '
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

  Future<void> _pickVideo() async {
    if (_selectedMediaFiles.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une seule vidéo par publication')),
      );
      return;
    }

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        final file = File(video.path);
        final fileSize = await file.length();

        // Check file size (max 100MB)
        if (fileSize > 100 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('La vidéo ne doit pas dépasser 100MB')),
            );
          }
          return;
        }

        setState(() {
          _selectedMediaFiles.add(file);
          _mediaType = 'video';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  void _showHorsePicker() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, child) {
          final horsesAsync = ref.watch(horsesNotifierProvider);

          return horsesAsync.when(
            data: (horses) {
              if (horses.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(
                    child: Text('Aucun cheval disponible'),
                  ),
                );
              }

              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Sélectionner un cheval',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          if (_selectedHorse != null)
                            TextButton(
                              onPressed: () {
                                setState(() => _selectedHorse = null);
                                Navigator.pop(sheetContext);
                              },
                              child: const Text('Retirer'),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: horses.length,
                        itemBuilder: (context, index) {
                          final horse = horses[index];
                          final isSelected = _selectedHorse?.id == horse.id;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: horse.photoUrl != null
                                  ? NetworkImage(horse.photoUrl!)
                                  : null,
                              child: horse.photoUrl == null
                                  ? const Icon(Icons.pets)
                                  : null,
                            ),
                            title: Text(
                              horse.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              horse.breed ?? 'Race inconnue',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check, color: AppColors.primary)
                                : null,
                            onTap: () {
                              setState(() => _selectedHorse = horse);
                              Navigator.pop(sheetContext);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Erreur: ${e.toString()}'),
              ),
            ),
          );
        },
      ),
    );
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMediaFiles.removeAt(index);
      if (_selectedMediaFiles.isEmpty) {
        _mediaType = null;
      }
    });
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
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Partagez votre expérience...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Selected horse indicator
            if (_selectedHorse != null) ...[
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: _selectedHorse!.photoUrl != null
                        ? NetworkImage(_selectedHorse!.photoUrl!)
                        : null,
                    child: _selectedHorse!.photoUrl == null
                        ? const Icon(Icons.pets, size: 20)
                        : null,
                  ),
                  title: Text(
                    _selectedHorse!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading ? null : () {
                      setState(() => _selectedHorse = null);
                    },
                  ),
                  dense: true,
                ),
              ),
              const SizedBox(height: 8),
            ],

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
                  onChanged: _isLoading ? null : (v) {
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
                    onChanged: _isLoading ? null : (v) => setState(() => _allowComments = v ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Partage', style: TextStyle(fontSize: 14)),
                    value: _allowSharing,
                    onChanged: _isLoading ? null : (v) => setState(() => _allowSharing = v ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Selected media preview
            if (_selectedMediaFiles.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMediaFiles.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _mediaType == 'image'
                                ? Image.file(
                                    _selectedMediaFiles[index],
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.videocam,
                                      size: 40,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                          ),
                        ),
                        if (!_isLoading)
                          Positioned(
                            right: 12,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => _removeMedia(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Upload status
            if (_isUploading && _uploadStatus.isNotEmpty) ...[
              LinearProgressIndicator(),
              const SizedBox(height: 4),
              Text(
                _uploadStatus,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _isLoading || _mediaType == 'video' ? null : _pickImage,
                  tooltip: 'Ajouter une photo',
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: _isLoading || _selectedMediaFiles.isNotEmpty ? null : _pickVideo,
                  tooltip: 'Ajouter une vidéo',
                ),
                IconButton(
                  icon: Icon(
                    Icons.pets,
                    color: _selectedHorse != null ? AppColors.primary : null,
                  ),
                  onPressed: _isLoading ? null : _showHorsePicker,
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

  Future<void> _submitPost() async {
    setState(() {
      _isLoading = true;
      _isUploading = _selectedMediaFiles.isNotEmpty;
      _uploadStatus = 'Préparation...';
    });

    try {
      List<String> mediaUrls = [];

      // Upload media files if any
      if (_selectedMediaFiles.isNotEmpty) {
        final notifier = ref.read(socialNotifierProvider.notifier);

        for (int i = 0; i < _selectedMediaFiles.length; i++) {
          if (mounted) {
            setState(() {
              _uploadStatus = 'Upload ${i + 1}/${_selectedMediaFiles.length}...';
            });
          }

          final url = await notifier.uploadMedia(
            _selectedMediaFiles[i],
            type: _mediaType ?? 'image',
          );

          if (url != null) {
            mediaUrls.add(url);
          } else {
            throw Exception('Échec de l\'upload du média ${i + 1}');
          }
        }
      }

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = 'Publication...';
        });
      }

      // Submit the post with uploaded media URLs
      widget.onPost({
        'content': _contentController.text.trim(),
        'visibility': _visibility.name,
        'allowComments': _allowComments,
        'allowSharing': _allowSharing,
        if (_selectedHorse != null) 'horseId': _selectedHorse!.id,
        if (mediaUrls.isNotEmpty) 'mediaUrls': mediaUrls,
        if (_mediaType != null) 'mediaType': _mediaType,
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
          _uploadStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
