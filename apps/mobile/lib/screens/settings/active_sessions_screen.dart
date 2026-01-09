import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_button.dart';

class ActiveSessionsScreen extends ConsumerStatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  ConsumerState<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends ConsumerState<ActiveSessionsScreen> {
  @override
  void initState() {
    super.initState();
    // Load sessions when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).loadActiveSessions();
    });
  }

  Future<void> _handleRevokeSession(UserSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoquer cette session ?'),
        content: Text(
          'L\'appareil "${session.deviceName}" sera deconnecte. '
          'Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Revoquer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(authProvider.notifier).revokeSession(session.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session revoquee avec succes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleRevokeAllSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoquer toutes les sessions ?'),
        content: const Text(
          'Tous les autres appareils seront deconnectes. '
          'Vous resterez connecte sur cet appareil uniquement. '
          'Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Revoquer toutes'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(authProvider.notifier).revokeAllSessions();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les autres sessions ont ete revoquees'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
      case 'android':
      case 'ios':
        return Icons.smartphone;
      case 'tablet':
      case 'ipad':
        return Icons.tablet;
      case 'desktop':
      case 'windows':
      case 'macos':
      case 'linux':
        return Icons.computer;
      case 'web':
      case 'browser':
        return Icons.language;
      default:
        return Icons.devices_other;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'A l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final sessions = authState.activeSessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions actives'),
        actions: [
          if (sessions.where((s) => !s.isCurrent).isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Revoquer toutes les autres sessions',
              onPressed: authState.isLoading ? null : _handleRevokeAllSessions,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).loadActiveSessions();
        },
        child: authState.isLoading && sessions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices_other,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune session active',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Les sessions de vos appareils apparaitront ici',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Error message
                      if (authState.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: TextStyle(color: theme.colorScheme.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Maximum 5 sessions actives. Les sessions inactives depuis 30 jours sont automatiquement supprimees.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Current session
                      Text(
                        'Session actuelle',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...sessions.where((s) => s.isCurrent).map((session) =>
                          _SessionCard(
                            session: session,
                            onRevoke: null, // Can't revoke current session
                            getDeviceIcon: _getDeviceIcon,
                            formatDateTime: _formatDateTime,
                          ),
                      ),

                      // Other sessions
                      if (sessions.where((s) => !s.isCurrent).isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Autres sessions',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...sessions.where((s) => !s.isCurrent).map((session) =>
                            _SessionCard(
                              session: session,
                              onRevoke: () => _handleRevokeSession(session),
                              getDeviceIcon: _getDeviceIcon,
                              formatDateTime: _formatDateTime,
                            ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Revoke all button
                      if (sessions.where((s) => !s.isCurrent).isNotEmpty)
                        LoadingButton(
                          onPressed: _handleRevokeAllSessions,
                          isLoading: authState.isLoading,
                          text: 'Deconnecter tous les autres appareils',
                          icon: Icons.logout,
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final UserSession session;
  final VoidCallback? onRevoke;
  final IconData Function(String) getDeviceIcon;
  final String Function(DateTime) formatDateTime;

  const _SessionCard({
    required this.session,
    required this.onRevoke,
    required this.getDeviceIcon,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: session.isCurrent
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                getDeviceIcon(session.deviceType),
                color: session.isCurrent
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.deviceName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (session.isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Actuelle',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Derniere activite: ${formatDateTime(session.lastActiveAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (session.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            session.location!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (session.ipAddress != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'IP: ${session.ipAddress}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRevoke != null)
              IconButton(
                icon: Icon(
                  Icons.logout,
                  color: theme.colorScheme.error,
                ),
                onPressed: onRevoke,
                tooltip: 'Revoquer cette session',
              ),
          ],
        ),
      ),
    );
  }
}
