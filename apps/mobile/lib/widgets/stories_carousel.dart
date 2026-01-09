import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../models/social.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Stories carousel widget displayed at top of feed
class StoriesCarousel extends ConsumerWidget {
  final VoidCallback? onCreateStory;
  final Function(StoryGroup group, int initialIndex)? onViewStories;

  const StoriesCarousel({
    super.key,
    this.onCreateStory,
    this.onViewStories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);
    final myStoriesAsync = ref.watch(myStoriesProvider);
    final currentUser = ref.watch(authProvider).user;

    return SizedBox(
      height: 100,
      child: storiesAsync.when(
        data: (storyGroups) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: storyGroups.length + 1, // +1 for "Add Story" button
            itemBuilder: (context, index) {
              if (index == 0) {
                // Current user's story / Add story button
                return myStoriesAsync.when(
                  data: (myStories) => _buildMyStoryItem(
                    context,
                    ref,
                    currentUser,
                    myStories,
                  ),
                  loading: () => _buildMyStoryItem(context, ref, currentUser, []),
                  error: (_, __) => _buildMyStoryItem(context, ref, currentUser, []),
                );
              }

              final group = storyGroups[index - 1];
              return _StoryGroupItem(
                group: group,
                onTap: () => onViewStories?.call(group, 0),
              );
            },
          );
        },
        loading: () => _buildLoadingState(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMyStoryItem(
    BuildContext context,
    WidgetRef ref,
    dynamic currentUser,
    List<Story> myStories,
  ) {
    final hasStories = myStories.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          if (hasStories) {
            // View own stories
            final group = StoryGroup(
              userId: currentUser?.id ?? '',
              userName: currentUser?.name ?? 'Moi',
              userPhotoUrl: currentUser?.photoUrl,
              stories: myStories,
            );
            onViewStories?.call(group, 0);
          } else {
            // Create new story
            onCreateStory?.call();
          }
        },
        onLongPress: hasStories ? onCreateStory : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStories
                        ? LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: hasStories
                        ? null
                        : Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage: currentUser?.photoUrl != null
                          ? CachedNetworkImageProvider(currentUser!.photoUrl!)
                          : null,
                      child: currentUser?.photoUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ),
                ),
                if (!hasStories)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ma story',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 48,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual story group item
class _StoryGroupItem extends StatelessWidget {
  final StoryGroup group;
  final VoidCallback onTap;

  const _StoryGroupItem({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: group.hasUnviewed
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: group.hasUnviewed
                    ? null
                    : Border.all(color: Colors.grey.shade400, width: 2),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: group.userPhotoUrl != null
                      ? CachedNetworkImageProvider(group.userPhotoUrl!)
                      : null,
                  child: group.userPhotoUrl == null
                      ? Text(
                          group.userName.isNotEmpty ? group.userName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 18),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                group.userName.split(' ').first,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact stories indicator for profile headers
class StoryIndicator extends StatelessWidget {
  final bool hasStory;
  final bool isViewed;
  final Widget child;
  final double size;

  const StoryIndicator({
    super.key,
    required this.hasStory,
    this.isViewed = false,
    required this.child,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasStory) return child;

    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: !isViewed
            ? LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: isViewed
            ? Border.all(color: Colors.grey.shade400, width: 2)
            : null,
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        padding: const EdgeInsets.all(2),
        child: child,
      ),
    );
  }
}
