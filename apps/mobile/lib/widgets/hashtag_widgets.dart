import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/social.dart';
import '../providers/social_provider.dart';
import '../theme/app_theme.dart';

/// Clickable hashtag chip widget
class HashtagChip extends StatelessWidget {
  final String tag;
  final int? postCount;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showIcon;

  const HashtagChip({
    super.key,
    required this.tag,
    this.postCount,
    this.onTap,
    this.isSelected = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: showIcon
          ? Icon(
              Icons.tag,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            )
          : null,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag),
          if (postCount != null) ...[
            const SizedBox(width: 4),
            Text(
              '($postCount)',
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ],
      ),
      backgroundColor: isSelected ? AppColors.primary : null,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
      ),
      onPressed: onTap,
    );
  }
}

/// Inline clickable hashtag text span
class ClickableHashtagText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Function(String tag)? onHashtagTap;
  final int? maxLines;

  const ClickableHashtagText({
    super.key,
    required this.text,
    this.style,
    this.onHashtagTap,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final hashtagStyle = defaultStyle?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w500,
    );

    // Parse text for hashtags
    final spans = _parseHashtags(text, defaultStyle, hashtagStyle);

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }

  List<InlineSpan> _parseHashtags(
    String text,
    TextStyle? defaultStyle,
    TextStyle? hashtagStyle,
  ) {
    final List<InlineSpan> spans = [];
    final hashtagRegex = RegExp(r'#(\w+)');
    int lastEnd = 0;

    for (final match in hashtagRegex.allMatches(text)) {
      // Add text before hashtag
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      // Add hashtag as a tappable span
      final hashtag = match.group(1)!;
      spans.add(WidgetSpan(
        child: GestureDetector(
          onTap: () => onHashtagTap?.call(hashtag),
          child: Text(
            '#$hashtag',
            style: hashtagStyle,
          ),
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return spans;
  }
}

/// Horizontal scrollable list of trending hashtags
class TrendingHashtagsRow extends ConsumerWidget {
  final int maxItems;
  final Function(String tag)? onHashtagTap;

  const TrendingHashtagsRow({
    super.key,
    this.maxItems = 10,
    this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingTagsProvider);

    return trendingAsync.when(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();

        final displayTags = tags.take(maxItems).toList();

        return SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: displayTags.length,
            itemBuilder: (context, index) {
              final tag = displayTags[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: HashtagChip(
                  tag: tag.tag,
                  showIcon: false,
                  onTap: () => onHashtagTap?.call(tag.tag),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 42),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Compact trending hashtags card for sidebar
class TrendingHashtagsCard extends ConsumerWidget {
  final int maxItems;
  final Function(String tag)? onHashtagTap;
  final VoidCallback? onSeeAll;

  const TrendingHashtagsCard({
    super.key,
    this.maxItems = 5,
    this.onHashtagTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingTagsProvider);

    return Card(
      child: trendingAsync.when(
        data: (tags) {
          if (tags.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune tendance'),
            );
          }

          final displayTags = tags.take(maxItems).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tendances',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (onSeeAll != null)
                      TextButton(
                        onPressed: onSeeAll,
                        child: const Text('Voir tout'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Tags list
              ...displayTags.asMap().entries.map((entry) {
                final index = entry.key;
                final tag = entry.value;
                return ListTile(
                  dense: true,
                  leading: _buildRankBadge(index + 1),
                  title: Text('#${tag.tag}'),
                  subtitle: Text('${tag.postCount} publications'),
                  trailing: _buildTrendIndicator(tag.trendScore),
                  onTap: () => onHashtagTap?.call(tag.tag),
                );
              }),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Erreur de chargement'),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    final isTop3 = rank <= 3;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isTop3 ? AppColors.primaryContainer : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isTop3 ? AppColors.primary : Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget? _buildTrendIndicator(double trendScore) {
    if (trendScore <= 0) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_upward, size: 14, color: Colors.green.shade600),
        Text(
          '${trendScore.toStringAsFixed(0)}%',
          style: TextStyle(
            color: Colors.green.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Hashtag input field with suggestions
class HashtagInputField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Function(List<String> tags)? onTagsChanged;
  final String? hintText;

  const HashtagInputField({
    super.key,
    required this.controller,
    this.onTagsChanged,
    this.hintText,
  });

  @override
  ConsumerState<HashtagInputField> createState() => _HashtagInputFieldState();
}

class _HashtagInputFieldState extends ConsumerState<HashtagInputField> {
  List<String> _extractedTags = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final hashtagRegex = RegExp(r'#(\w+)');
    final tags = hashtagRegex
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();

    if (tags.length != _extractedTags.length ||
        !tags.every((t) => _extractedTags.contains(t))) {
      setState(() => _extractedTags = tags);
      widget.onTagsChanged?.call(tags);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingTagsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          maxLines: null,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Ecrivez et utilisez #hashtags...',
            border: const OutlineInputBorder(),
          ),
        ),

        // Show extracted tags
        if (_extractedTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _extractedTags.map((tag) => Chip(
              label: Text('#$tag'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                final newText = widget.controller.text.replaceAll('#$tag', '');
                widget.controller.text = newText;
              },
            )).toList(),
          ),
        ],

        // Hashtag suggestions
        trendingAsync.when(
          data: (tags) {
            if (tags.isEmpty) return const SizedBox.shrink();

            final suggestions = tags
                .where((t) => !_extractedTags.contains(t.tag))
                .take(5)
                .toList();

            if (suggestions.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Hashtags populaires',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: suggestions.map((tag) => ActionChip(
                    label: Text('#${tag.tag}'),
                    onPressed: () {
                      final currentText = widget.controller.text;
                      final needsSpace = currentText.isNotEmpty &&
                          !currentText.endsWith(' ') &&
                          !currentText.endsWith('\n');
                      widget.controller.text =
                          '$currentText${needsSpace ? ' ' : ''}#${tag.tag} ';
                      widget.controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: widget.controller.text.length),
                      );
                    },
                  )).toList(),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Follow/unfollow hashtag button
class HashtagFollowButton extends ConsumerWidget {
  final String tag;
  final bool isCompact;

  const HashtagFollowButton({
    super.key,
    required this.tag,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hashtagAsync = ref.watch(hashtagDetailProvider(tag));

    return hashtagAsync.when(
      data: (hashtag) {
        final isFollowing = hashtag.isFollowing;

        if (isCompact) {
          return IconButton(
            icon: Icon(
              isFollowing ? Icons.notifications_active : Icons.notifications_none,
              color: isFollowing ? AppColors.primary : null,
            ),
            onPressed: () => _toggleFollow(ref, hashtag),
            tooltip: isFollowing ? 'Ne plus suivre' : 'Suivre',
          );
        }

        return isFollowing
            ? OutlinedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Suivi'),
                onPressed: () => _toggleFollow(ref, hashtag),
              )
            : FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Suivre'),
                onPressed: () => _toggleFollow(ref, hashtag),
              );
      },
      loading: () => isCompact
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const OutlinedButton(
              onPressed: null,
              child: SizedBox(
                width: 60,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _toggleFollow(WidgetRef ref, Hashtag hashtag) async {
    final notifier = ref.read(storyNotifierProvider.notifier);
    if (hashtag.isFollowing) {
      await notifier.unfollowHashtag(tag);
    } else {
      await notifier.followHashtag(tag);
    }
    ref.invalidate(hashtagDetailProvider(tag));
    ref.invalidate(followedHashtagsProvider);
  }
}
