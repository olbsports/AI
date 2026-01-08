import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _registrationEnabled = true;
  bool _freeTrialEnabled = true;
  int _freeTrialDays = 14;
  int _maxAnalysesPerDay = 10;
  int _maxFileSizeMB = 100;
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(systemSettingsProvider);
    final auditLogsAsync = ref.watch(auditLogsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paramètres',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              const TabBar(
                tabs: [
                  Tab(text: 'Général'),
                  Tab(text: 'Feature Flags'),
                  Tab(text: 'Audit Logs'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: settingsAsync.when(
                  data: (settings) => TabBarView(
                    children: [
                      _buildGeneralSettings(settings),
                      _buildFeatureFlags(settings),
                      _buildAuditLogs(auditLogsAsync),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(SystemSettings settings) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Maintenance mode
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mode maintenance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Désactive temporairement l\'accès à l\'application',
                            style: TextStyle(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                      Switch(
                        value: settings.maintenanceMode,
                        onChanged: (value) async {
                          await ref.read(adminActionsProvider.notifier).toggleMaintenanceMode(
                                value,
                                value ? 'Maintenance en cours' : null,
                              );
                        },
                        activeColor: AdminColors.warning,
                      ),
                    ],
                  ),
                  if (settings.maintenanceMode && settings.maintenanceMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: AdminColors.warning),
                          const SizedBox(width: 12),
                          Expanded(child: Text(settings.maintenanceMessage!)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Registration settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inscriptions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    'Inscriptions actives',
                    'Permettre les nouvelles inscriptions',
                    Switch(
                      value: _registrationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _registrationEnabled = value;
                          _hasChanges = true;
                        });
                      },
                    ),
                  ),
                  _buildSettingRow(
                    'Période d\'essai',
                    'Activer la période d\'essai gratuite',
                    Switch(
                      value: _freeTrialEnabled,
                      onChanged: (value) {
                        setState(() {
                          _freeTrialEnabled = value;
                          _hasChanges = true;
                        });
                      },
                    ),
                  ),
                  _buildSettingRow(
                    'Durée essai',
                    '$_freeTrialDays jours',
                    SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: const InputDecoration(
                          suffixText: 'jours',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: _freeTrialDays.toString()),
                        onChanged: (value) {
                          setState(() {
                            _freeTrialDays = int.tryParse(value) ?? _freeTrialDays;
                            _hasChanges = true;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Limits settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Limites',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    'Analyses max/jour',
                    'Limite quotidienne d\'analyses',
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: TextEditingController(text: _maxAnalysesPerDay.toString()),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _maxAnalysesPerDay = int.tryParse(value) ?? _maxAnalysesPerDay;
                            _hasChanges = true;
                          });
                        },
                      ),
                    ),
                  ),
                  _buildSettingRow(
                    'Taille fichier max',
                    '$_maxFileSizeMB MB',
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: TextEditingController(text: _maxFileSizeMB.toString()),
                        decoration: const InputDecoration(suffixText: 'MB'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _maxFileSizeMB = int.tryParse(value) ?? _maxFileSizeMB;
                            _hasChanges = true;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hasChanges ? () => _saveSettings() : null,
              child: const Text('Enregistrer les modifications'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String title, String subtitle, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: AdminColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildFeatureFlags(SystemSettings settings) {
    final flags = [
      ('gamification', 'Gamification', 'Badges, XP, défis'),
      ('social_feed', 'Feed social', 'Publications, likes, commentaires'),
      ('marketplace', 'Marketplace', 'Achat/vente de chevaux'),
      ('breeding', 'Conseiller élevage', 'Recommandations de reproduction'),
      ('clubs', 'Clubs', 'Écuries virtuelles'),
      ('ai_analysis', 'Analyse IA vidéo', 'Analyse locomotion par IA'),
      ('notifications_push', 'Notifications push', 'Notifications mobiles'),
      ('export_pdf', 'Export PDF', 'Génération de rapports PDF'),
    ];

    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: flags.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final flag = flags[index];
          final isEnabled = settings.featureFlags[flag.$1] ?? true;
          return ListTile(
            title: Text(flag.$2, style: const TextStyle(color: AdminColors.textPrimary)),
            subtitle: Text(flag.$3, style: TextStyle(color: AdminColors.textSecondary)),
            trailing: Switch(
              value: isEnabled,
              onChanged: (value) async {
                await ref.read(adminActionsProvider.notifier).toggleFeatureFlag(flag.$1, value);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuditLogs(AsyncValue<List<AuditLog>> logsAsync) {
    return logsAsync.when(
      data: (logs) => Card(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AdminColors.darkCard,
                child: Text(log.actorName.substring(0, 1).toUpperCase()),
              ),
              title: Text(
                '${log.actorName} - ${log.action}',
                style: const TextStyle(color: AdminColors.textPrimary),
              ),
              subtitle: Text(
                '${log.resourceType}/${log.resourceId}',
                style: TextStyle(color: AdminColors.textSecondary),
              ),
              trailing: Text(
                _formatDate(log.createdAt),
                style: TextStyle(color: AdminColors.textMuted, fontSize: 12),
              ),
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }

  Future<void> _saveSettings() async {
    try {
      await ref.read(adminActionsProvider.notifier).updateSystemSettings(
        registrationEnabled: _registrationEnabled,
        freeTrialEnabled: _freeTrialEnabled,
        freeTrialDays: _freeTrialDays,
        maxAnalysesPerDay: _maxAnalysesPerDay,
        maxFileSize: _maxFileSizeMB * 1000000,
      );
      ref.invalidate(systemSettingsProvider);
      setState(() => _hasChanges = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres enregistrés avec succès'),
            backgroundColor: AdminColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AdminColors.error,
          ),
        );
      }
    }
  }
}
