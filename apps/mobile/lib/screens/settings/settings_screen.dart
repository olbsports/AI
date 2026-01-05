import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

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
            subtitle: 'Français',
            onTap: () => _showLanguageDialog(context),
          ),
          _buildThemeTile(context, ref),
          const SizedBox(height: 24),

          // Support section
          _buildSectionHeader(context, 'Support'),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Aide',
            subtitle: 'Centre d\'aide et FAQ',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.mail_outline,
            title: 'Nous contacter',
            subtitle: 'support@horsevision.ai',
            onTap: () {},
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
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            onTap: () {},
          ),
          const SizedBox(height: 24),

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
                    '${authState.user?.firstName ?? ''} ${authState.user?.lastName ?? ''}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authState.user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.dark_mode_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Thème'),
        subtitle: const Text('Automatique'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showThemeDialog(context),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'fr',
              groupValue: 'fr',
              title: const Text('Français'),
              onChanged: (_) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: 'fr',
              title: const Text('English'),
              onChanged: (_) => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'auto',
              groupValue: 'auto',
              title: const Text('Automatique'),
              onChanged: (_) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              value: 'light',
              groupValue: 'auto',
              title: const Text('Clair'),
              onChanged: (_) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              value: 'dark',
              groupValue: 'auto',
              title: const Text('Sombre'),
              onChanged: (_) => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Horse Vision AI',
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(context);
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
