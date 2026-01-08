import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          _buildProfileCard(context, authState),
          const SizedBox(height: 24),

          // Account section
          _buildSectionHeader(context, 'Compte'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: 'Profil',
            subtitle: 'Modifier vos informations personnelles',
            onTap: () => context.push('/settings/profile'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.business_outlined,
            title: 'Organisation',
            subtitle: authState.user?.organizationName ?? 'Non défini',
            onTap: () => context.push('/settings/organization'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: 'Cavaliers',
            subtitle: 'Gérer les cavaliers',
            onTap: () => context.push('/riders'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.payment_outlined,
            title: 'Abonnement',
            subtitle: 'Gérer votre abonnement',
            onTap: () => context.push('/settings/billing'),
          ),
          const SizedBox(height: 24),

          // Preferences section
          _buildSectionHeader(context, 'Préférences'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Gérer les notifications',
            onTap: () => context.push('/settings/notifications'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.language_outlined,
            title: 'Langue',
            subtitle: settings.languageDisplayName,
            onTap: () => _showLanguageDialog(context, ref, settings.language),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Thème',
            subtitle: settings.themeDisplayName,
            onTap: () => _showThemeDialog(context, ref, settings.themeMode),
          ),
          const SizedBox(height: 24),

          // Support section
          _buildSectionHeader(context, 'Support'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Aide',
            subtitle: 'Centre d\'aide et FAQ',
            onTap: () => _launchUrl('https://horsetempo.app/help'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.mail_outline,
            title: 'Nous contacter',
            subtitle: 'support@horsetempo.app',
            onTap: () => _launchUrl('mailto:support@horsetempo.app'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'À propos',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 24),

          // Legal section
          _buildSectionHeader(context, 'Légal'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialité',
            onTap: () => _launchUrl('https://horsetempo.app/privacy'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            onTap: () => _launchUrl('https://horsetempo.app/terms'),
          ),
          const SizedBox(height: 24),

          // Danger zone
          _buildSectionHeader(context, 'Zone de danger'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.delete_forever_outlined,
            title: 'Supprimer mon compte',
            subtitle: 'Action irréversible',
            onTap: () => _showDeleteAccountDialog(context, ref),
            isDestructive: true,
          ),
          const SizedBox(height: 16),

          // Logout button
          FilledButton.icon(
            onPressed: () => _showLogoutDialog(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildProfileCard(BuildContext context, AuthState authState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: authState.user?.avatarUrl != null
                  ? NetworkImage(authState.user!.avatarUrl!)
                  : null,
              child: authState.user?.avatarUrl == null
                  ? Text(
                      _getInitials(authState.user),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${authState.user?.firstName ?? ''} ${authState.user?.lastName ?? ''}'.trim(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authState.user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/settings/profile'),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(dynamic user) {
    if (user == null) return '?';
    final firstName = user.firstName ?? '';
    final lastName = user.lastName ?? '';
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: isDestructive
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, String currentLanguage) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Langue'),
        content: RadioGroup<String>(
          groupValue: currentLanguage,
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsProvider.notifier).setLanguage(value);
              Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              RadioListTile<String>(
                value: 'fr',
                title: Text('Français'),
              ),
              RadioListTile<String>(
                value: 'en',
                title: Text('English'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentTheme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thème'),
        content: RadioGroup<ThemeMode>(
          groupValue: currentTheme,
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsProvider.notifier).setThemeMode(value);
              Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                title: Text('Automatique'),
                subtitle: Text('Suit les paramètres système'),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                title: Text('Clair'),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                title: Text('Sombre'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Horse Tempo',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.pets,
        size: 48,
        color: AppColors.primary,
      ),
      children: [
        const Text(
          'Application d\'analyse IA pour le suivi et l\'amélioration des performances équestres.',
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Supprimer le compte'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est irréversible. Toutes vos données seront définitivement supprimées :',
            ),
            SizedBox(height: 12),
            Text(
              '• Vos chevaux et leur historique',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '• Vos analyses et statistiques',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '• Vos plannings et événements',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '• Votre abonnement',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            Text(
              'Êtes-vous sûr de vouloir continuer ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // TODO: Implement account deletion API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pour supprimer votre compte, contactez support@horsetempo.app'),
                  duration: Duration(seconds: 5),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(dialogContext);
                context.go('/login');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
