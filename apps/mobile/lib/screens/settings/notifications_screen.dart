import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _reminderEnabled = true;
  bool _socialEnabled = true;
  bool _marketplaceEnabled = true;
  bool _healthAlertsEnabled = true;
  bool _planningEnabled = true;
  bool _analysisEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Général'),
          SwitchListTile(
            title: const Text('Notifications push'),
            subtitle: const Text('Recevoir les notifications sur l\'appareil'),
            value: _pushEnabled,
            onChanged: (value) => setState(() => _pushEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Notifications par email'),
            subtitle: const Text('Recevoir un résumé par email'),
            value: _emailEnabled,
            onChanged: (value) => setState(() => _emailEnabled = value),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Rappels'),
          SwitchListTile(
            title: const Text('Rappels d\'événements'),
            subtitle: const Text('Rappels avant les événements du planning'),
            value: _reminderEnabled,
            onChanged: (value) => setState(() => _reminderEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Planning'),
            subtitle: const Text('Résumé quotidien du planning'),
            value: _planningEnabled,
            onChanged: (value) => setState(() => _planningEnabled = value),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Santé'),
          SwitchListTile(
            title: const Text('Alertes santé'),
            subtitle: const Text('Vaccins, vermifuges, soins à prévoir'),
            value: _healthAlertsEnabled,
            onChanged: (value) => setState(() => _healthAlertsEnabled = value),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Social'),
          SwitchListTile(
            title: const Text('Activité sociale'),
            subtitle: const Text('Likes, commentaires, nouveaux abonnés'),
            value: _socialEnabled,
            onChanged: (value) => setState(() => _socialEnabled = value),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Marketplace'),
          SwitchListTile(
            title: const Text('Marketplace'),
            subtitle: const Text('Messages et offres sur vos annonces'),
            value: _marketplaceEnabled,
            onChanged: (value) => setState(() => _marketplaceEnabled = value),
          ),
          const Divider(),
          _buildSectionHeader(context, 'IA'),
          SwitchListTile(
            title: const Text('Analyses IA'),
            subtitle: const Text('Nouvelles analyses et recommandations'),
            value: _analysisEnabled,
            onChanged: (value) => setState(() => _analysisEnabled = value),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              onPressed: _saveSettings,
              child: const Text('Enregistrer'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    // TODO: Implement API call to save notification settings
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préférences de notifications enregistrées'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
