import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // Mock data - will be replaced with API
    final posts = _getMockPosts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh feed
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Story-style highlights (like Instagram)
            SliverToBoxAdapter(
              child: _buildStoriesSection(),
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStoriesSection() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Add story button
          _buildAddStoryButton(),
          // Mock stories
          _buildStoryAvatar('Marie', 'assets/avatar1.jpg', true),
          _buildStoryAvatar('Thomas', 'assets/avatar2.jpg', true),
          _buildStoryAvatar('Sophie', 'assets/avatar3.jpg', false),
          _buildStoryAvatar('Lucas', 'assets/avatar4.jpg', true),
          _buildStoryAvatar('Emma', 'assets/avatar5.jpg', false),
        ],
      ),
    );
  }

  Widget _buildAddStoryButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: Icon(Icons.add, color: AppColors.primary, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Votre story',
            style: TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryAvatar(String name, String imageUrl, bool hasUnread) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasUnread
                  ? LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    )
                  : null,
              border: hasUnread
                  ? null
                  : Border.all(color: Colors.grey.shade300, width: 2),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade300,
                child: Text(name[0]),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
                  ? Text(post.authorName[0])
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
                children: post.tags.map((tag) => Text(
                      '#$tag',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
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
                  onTap: () {},
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
                  onPressed: () {},
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
        child: Container(
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.image, size: 48)),
        ),
      );
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: urls.take(4).map((url) => Container(
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.image)),
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

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _FeedSearchDelegate(),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateNoteSheet(
        onPost: (note) {
          // Create post
          Navigator.pop(context);
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
            leading: const Icon(Icons.bookmark_add),
            title: const Text('Enregistrer'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Copier le lien'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Partager en story'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.report_outlined),
            title: const Text('Signaler'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showComments(BuildContext context, PublicNote post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Commentaires (${post.commentCount})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(),
            Expanded(
              child: post.commentCount == 0
                  ? Center(
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
                    )
                  : ListView(
                      controller: scrollController,
                      children: const [
                        // Comments would go here
                      ],
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
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost(PublicNote post) {
    Share.share(
      '${post.content}\n\n- ${post.authorName} sur Horse Vision AI',
      subject: 'Partage de ${post.authorName}',
    );
  }

  List<PublicNote> _getMockPosts() {
    return [
      PublicNote(
        id: '1',
        authorId: 'u1',
        authorName: 'Marie Dupont',
        horseName: 'Étoile du Matin',
        content:
            'Superbe séance de dressage aujourd\'hui ! 🐴 Belle progression sur les changements de pied. L\'analyse IA m\'a vraiment aidé à corriger ma position.',
        visibility: ContentVisibility.public,
        likeCount: 24,
        commentCount: 5,
        shareCount: 2,
        isLiked: true,
        tags: ['dressage', 'progression', 'analyse'],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      PublicNote(
        id: '2',
        authorId: 'u2',
        authorName: 'Thomas Martin',
        horseName: 'Spirit',
        content:
            'Premier parcours sans faute ! 🏆 6 mois de travail et d\'analyses pour en arriver là. Merci à toute l\'équipe !',
        mediaUrls: ['image1.jpg'],
        visibility: ContentVisibility.public,
        likeCount: 156,
        commentCount: 23,
        shareCount: 8,
        tags: ['cso', 'victoire', 'sansfaute'],
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      PublicNote(
        id: '3',
        authorId: 'u3',
        authorName: 'Sophie Leroux',
        horseName: 'Tornado',
        content:
            'Analyse de locomotion très intéressante aujourd\'hui. L\'IA a détecté une légère irrégularité que je n\'avais pas vue. On va pouvoir travailler dessus ! 💪',
        visibility: ContentVisibility.followers,
        likeCount: 12,
        commentCount: 3,
        tags: ['locomotion', 'santé', 'prévention'],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PublicNote(
        id: '4',
        authorId: 'u4',
        authorName: 'Club Équestre du Parc',
        content:
            '🎉 Nouveau record du club ! Notre classement leaderboard ne cesse de grimper. Bravo à tous nos cavaliers et leurs montures !',
        visibility: ContentVisibility.public,
        likeCount: 89,
        commentCount: 15,
        shareCount: 12,
        tags: ['club', 'leaderboard', 'fierté'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}

class _FeedSearchDelegate extends SearchDelegate<String> {
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
    return Center(child: Text('Résultats pour "$query"'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = [
      '#dressage',
      '#cso',
      '#hobbyHorse',
      'Marie Dupont',
      'Club du Parc',
    ].where((s) => s.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) => ListTile(
        leading: Icon(
          suggestions[index].startsWith('#') ? Icons.tag : Icons.person,
        ),
        title: Text(suggestions[index]),
        onTap: () {
          query = suggestions[index];
          showResults(context);
        },
      ),
    );
  }
}

class CreateNoteSheet extends StatefulWidget {
  final Function(PublicNote) onPost;

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
            // Visibility selector
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
            // Options
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
            // Action buttons
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
                IconButton(
                  icon: const Icon(Icons.analytics),
                  onPressed: () {},
                  tooltip: 'Lier une analyse',
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _contentController.text.isEmpty
                      ? null
                      : () {
                          // Create post
                        },
                  child: const Text('Publier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
