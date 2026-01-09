import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';

/// Screen for managing trusted devices that can skip 2FA
class TrustedDevicesScreen extends ConsumerStatefulWidget {
  const TrustedDevicesScreen({super.key});

  @override
  ConsumerState<TrustedDevicesScreen> createState() => _TrustedDevicesScreenState();
}

class _TrustedDevicesScreenState extends ConsumerState<TrustedDevicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).loadTrustedDevices();
    });
  }

  Future<void> _handleRemoveDevice(TrustedDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet appareil ?'),
        content: Text(
          'L\'appareil "${device.deviceName}" ne sera plus considere comme fiable. '
          'La prochaine connexion depuis cet appareil necessiera le code 2FA.',
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(authProvider.notifier).removeTrustedDevice(device.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appareil supprime'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleRemoveAllDevices() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tous les appareils ?'),
        content: const Text(
          'Tous les appareils fiables seront supprimes. '
          'Vous devrez entrer le code 2FA lors de votre prochaine connexion '
          'depuis n\'importe quel appareil.',
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
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final devices = ref.read(authProvider).trustedDevices;
      int removedCount = 0;

      for (final device in devices) {
        final success = await ref.read(authProvider.notifier).removeTrustedDevice(device.id);
        if (success) removedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$removedCount appareils supprimes'),
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

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatExpirationDate(DateTime? expiresAt) {
    if (expiresAt == null) return 'Jamais';

    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'Expire';
    } else if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Demain';
    } else if (difference.inDays < 7) {
      return 'Dans ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(expiresAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final devices = authState.trustedDevices;
    final user = authState.user;

    // Check if 2FA is enabled
    if (user != null && !user.mfaEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appareils fiables')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Authentification 2FA non activee',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Activez l\'authentification a deux facteurs pour gerer les appareils fiables.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appareils fiables'),
        actions: [
          if (devices.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Supprimer tous les appareils',
              onPressed: authState.isLoading ? null : _handleRemoveAllDevices,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).loadTrustedDevices();
        },
        child: authState.isLoading && devices.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : devices.isEmpty
                ? _buildEmptyState(theme)
                : _buildDevicesList(theme, devices, authState),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun appareil fiable',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Lors de votre prochaine connexion avec 2FA, '
              'cochez "Faire confiance a cet appareil" pour l\'ajouter ici.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesList(
    ThemeData theme,
    List<TrustedDevice> devices,
    AuthState authState,
  ) {
    return ListView(
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
                Icon(Icons.error_outline, color: theme.colorScheme.error),
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
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Les appareils fiables peuvent se connecter sans code 2FA pendant 30 jours.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Devices count
        Text(
          '${devices.length} appareil${devices.length > 1 ? 's' : ''} fiable${devices.length > 1 ? 's' : ''}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Devices list
        ...devices.map((device) => _TrustedDeviceCard(
          device: device,
          onRemove: () => _handleRemoveDevice(device),
          getDeviceIcon: _getDeviceIcon,
          formatDate: _formatDate,
          formatExpirationDate: _formatExpirationDate,
        )),

        const SizedBox(height: 24),

        // Security tip
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Conseil de securite',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Supprimez les appareils que vous ne reconnaissez pas ou que vous n\'utilisez plus. '
                'Ne faites jamais confiance a un appareil partage ou public.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustedDeviceCard extends StatelessWidget {
  final TrustedDevice device;
  final VoidCallback onRemove;
  final IconData Function(String) getDeviceIcon;
  final String Function(DateTime) formatDate;
  final String Function(DateTime?) formatExpirationDate;

  const _TrustedDeviceCard({
    required this.device,
    required this.onRemove,
    required this.getDeviceIcon,
    required this.formatDate,
    required this.formatExpirationDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = device.expiresAt != null &&
        device.expiresAt!.isBefore(DateTime.now());

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
                color: isExpired
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                getDeviceIcon(device.deviceType),
                color: isExpired
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
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
                          device.deviceName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Expire',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onError,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ajoute le ${formatDate(device.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: isExpired
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expire: ${formatExpirationDate(device.expiresAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isExpired
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              onPressed: onRemove,
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }
}
