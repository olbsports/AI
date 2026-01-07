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
            _ThemeSwitcher(currentMode: themeMode),

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
                  onTap: () => context.go('/settings/billing'),
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
        onTap: () => context.go('/settings/profile'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
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

class _ThemeSwitcher extends ConsumerWidget {
  final ThemeMode currentMode;

  const _ThemeSwitcher({required this.currentMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
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
                  color: color.withValues(alpha: 0.1),
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
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.security,
            title: 'Confidentialité',
            subtitle: 'Données & sécurité',
            onTap: () => context.go('/settings/notifications'),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.cloud_sync,
            title: 'Synchronisation',
            subtitle: 'Dernière: il y a 5 min',
            onTap: () => _syncNow(context),
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
            onTap: () => context.push('/settings'),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.chat_bubble_outline,
            title: 'Contacter le support',
            subtitle: 'Assistance en direct',
            onTap: () => _showSupportDialog(context),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.feedback_outlined,
            title: 'Donner mon avis',
            subtitle: 'Améliorer l\'application',
            onTap: () => _showFeedbackDialog(context),
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
              'Horse Tempo',
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
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _showLegalDocument(context, 'terms'),
                  child: const Text('CGU'),
                ),
                const Text('•'),
                TextButton(
                  onPressed: () => _showLegalDocument(context, 'privacy'),
                  child: const Text('Confidentialité'),
                ),
                const Text('•'),
                TextButton(
                  onPressed: () => _showLicensesPage(context),
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

// ==================== HELPER FUNCTIONS ====================

void _showLanguageDialog(BuildContext context) {
  String selectedLanguage = 'fr';
  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => SimpleDialog(
        title: const Text('Choisir la langue'),
        children: [
          RadioListTile<String>(
            value: 'fr',
            groupValue: selectedLanguage,
            title: const Text('Français'),
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedLanguage = value);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Langue: Français')),
                );
              }
            },
          ),
          RadioListTile<String>(
            value: 'en',
            groupValue: selectedLanguage,
            title: const Text('English'),
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedLanguage = value);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Langue: English')),
                );
              }
            },
          ),
          RadioListTile<String>(
            value: 'es',
            groupValue: selectedLanguage,
            title: const Text('Español'),
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedLanguage = value);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Langue: Español')),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}

void _syncNow(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 16),
          Text('Synchronisation en cours...'),
        ],
      ),
      duration: Duration(seconds: 2),
    ),
  );
}

void _showSupportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Contacter le support'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email: support@horsetempo.app'),
          SizedBox(height: 8),
          Text('Horaires: 9h-18h (Lun-Ven)'),
          SizedBox(height: 8),
          Text('Temps de réponse moyen: 24h'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email copié!')),
            );
          },
          child: const Text('Copier email'),
        ),
      ],
    ),
  );
}

void _showFeedbackDialog(BuildContext context) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Votre avis'),
      content: TextField(
        controller: controller,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Partagez vos suggestions ou problèmes...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Merci pour votre retour!')),
            );
          },
          child: const Text('Envoyer'),
        ),
      ],
    ),
  );
}

void _showLegalDocument(BuildContext context, String type) {
  final title = type == 'terms' ? 'Conditions Générales d\'Utilisation' : 'Politique de Confidentialité';
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          child: Text(
            type == 'terms'
                ? '''CONDITIONS GÉNÉRALES D'UTILISATION

1. OBJET
Les présentes conditions générales d'utilisation ont pour objet de définir les conditions d'accès et d'utilisation de l'application Horse Tempo.

2. ACCEPTATION
L'utilisation de l'application implique l'acceptation pleine et entière des présentes conditions.

3. SERVICES
L'application propose des services d'analyse vidéo équine assistée par intelligence artificielle.

4. DONNÉES PERSONNELLES
Vos données sont traitées conformément à notre politique de confidentialité.

5. PROPRIÉTÉ INTELLECTUELLE
Tous les contenus de l'application sont protégés par le droit d'auteur.

6. RESPONSABILITÉ
L'analyse IA est fournie à titre indicatif et ne remplace pas l'avis d'un professionnel.'''
                : '''POLITIQUE DE CONFIDENTIALITÉ

1. COLLECTE DES DONNÉES
Nous collectons les données que vous nous fournissez : nom, email, vidéos équines.

2. UTILISATION
Vos données sont utilisées pour :
- Fournir nos services d'analyse
- Améliorer l'application
- Vous contacter si nécessaire

3. STOCKAGE
Vos données sont stockées de manière sécurisée sur des serveurs européens.

4. PARTAGE
Nous ne vendons jamais vos données à des tiers.

5. VOS DROITS
Vous pouvez demander l'accès, la modification ou la suppression de vos données.

6. CONTACT
privacy@horsetempo.app''',
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

void _showLicensesPage(BuildContext context) {
  showLicensePage(
    context: context,
    applicationName: 'Horse Tempo',
    applicationVersion: '1.0.0',
    applicationIcon: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Icon(Icons.pets, size: 48, color: AppColors.primary),
    ),
  );
}
