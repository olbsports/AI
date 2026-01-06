import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';

/// Plus category home screen
/// Contains: Settings, Breeding, Services, Gamification, Profile
class PlusHomeScreen extends ConsumerWidget {
  const PlusHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            _ProfileCard(),

            const SizedBox(height: 24),

            // Theme switcher
            _ThemeSwitcher(currentMode: themeMode, ref: ref),

            const SizedBox(height: 24),

            // Main sections
            Text(
              'Services',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            _SectionGrid(
              items: [
                _SectionItem(
                  icon: Icons.child_care,
                  label: 'Élevage',
                  subtitle: 'Suivi reproduction',
                  color: AppColors.categoryEcurie,
                  onTap: () => context.go('/breeding'),
                ),
                _SectionItem(
                  icon: Icons.business,
                  label: 'Services pro',
                  subtitle: 'Maréchal, vétérinaire',
                  color: AppColors.secondary,
                  onTap: () => context.go('/services'),
                ),
                _SectionItem(
                  icon: Icons.emoji_events,
                  label: 'Gamification',
                  subtitle: 'Défis & récompenses',
                  color: AppColors.tertiary,
                  onTap: () => context.go('/gamification'),
                ),
                _SectionItem(
                  icon: Icons.payment,
                  label: 'Abonnement',
                  subtitle: 'Gérer mon plan',
                  color: AppColors.primary,
                  onTap: () => context.go('/subscription'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick settings
            Text(
              'Réglages rapides',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            _SettingsList(),

            const SizedBox(height: 24),

            // Help & Support
            Text(
              'Aide & Support',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            _HelpSection(),

            const SizedBox(height: 24),

            // App info
            _AppInfoCard(),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => context.go('/profile'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon Profil',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Voir et modifier mon profil',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PRO',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSwitcher extends StatelessWidget {
  final ThemeMode currentMode;
  final WidgetRef ref;

  const _ThemeSwitcher({required this.currentMode, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Apparence',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ThemeOption(
                    icon: Icons.light_mode,
                    label: 'Clair',
                    isSelected: currentMode == ThemeMode.light,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeOption(
                    icon: Icons.dark_mode,
                    label: 'Sombre',
                    isSelected: currentMode == ThemeMode.dark,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeOption(
                    icon: Icons.settings_suggest,
                    label: 'Auto',
                    isSelected: currentMode == ThemeMode.system,
                    onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? AppColors.primary : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionGrid extends StatelessWidget {
  final List<_SectionItem> items;

  const _SectionGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: items,
    );
  }
}

class _SectionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SectionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Gérer les alertes',
            onTap: () => context.go('/settings/notifications'),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.language,
            title: 'Langue',
            subtitle: 'Français',
            onTap: () {
              // TODO: Language settings
            },
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.security,
            title: 'Confidentialité',
            subtitle: 'Données & sécurité',
            onTap: () => context.go('/settings/privacy'),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.cloud_sync,
            title: 'Synchronisation',
            subtitle: 'Dernière: il y a 5 min',
            onTap: () {
              // TODO: Sync settings
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _HelpSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Centre d\'aide',
            subtitle: 'FAQ et tutoriels',
            onTap: () {
              // TODO: Help center
            },
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.chat_bubble_outline,
            title: 'Contacter le support',
            subtitle: 'Assistance en direct',
            onTap: () {
              // TODO: Support chat
            },
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.feedback_outlined,
            title: 'Donner mon avis',
            subtitle: 'Améliorer l\'application',
            onTap: () {
              // TODO: Feedback
            },
          ),
        ],
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withGreen(180),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.pets,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Horse Vision AI',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    // TODO: Terms
                  },
                  child: const Text('CGU'),
                ),
                const Text('•'),
                TextButton(
                  onPressed: () {
                    // TODO: Privacy
                  },
                  child: const Text('Confidentialité'),
                ),
                const Text('•'),
                TextButton(
                  onPressed: () {
                    // TODO: Licenses
                  },
                  child: const Text('Licences'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
