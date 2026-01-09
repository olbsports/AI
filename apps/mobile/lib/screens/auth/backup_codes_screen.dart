import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_button.dart';

/// Screen for viewing and regenerating 2FA backup codes
class BackupCodesScreen extends ConsumerStatefulWidget {
  const BackupCodesScreen({super.key});

  @override
  ConsumerState<BackupCodesScreen> createState() => _BackupCodesScreenState();
}

class _BackupCodesScreenState extends ConsumerState<BackupCodesScreen> {
  List<BackupCode> _backupCodes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBackupCodes();
  }

  Future<void> _loadBackupCodes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final codes = await ref.read(authProvider.notifier).getBackupCodes();
      if (mounted) {
        setState(() {
          _backupCodes = codes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement des codes';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _regenerateCodes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerer les codes ?'),
        content: const Text(
          'Tous les codes existants seront invalides. '
          'Vous devrez sauvegarder les nouveaux codes. '
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
            child: const Text('Regenerer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newCodes = await ref.read(authProvider.notifier).regenerateBackupCodes();
      if (mounted) {
        setState(() {
          _backupCodes = newCodes;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nouveaux codes generes. Sauvegardez-les !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors de la regeneration';
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    final codes = _backupCodes
        .where((c) => !c.used)
        .map((c) => c.code)
        .join('\n');
    Clipboard.setData(ClipboardData(text: codes));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Codes copies dans le presse-papiers'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;

    // Check if 2FA is enabled
    if (user != null && !user.mfaEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Codes de secours')),
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
                  'Activez l\'authentification a deux facteurs pour acceder aux codes de secours.',
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
        title: const Text('Codes de secours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerer les codes',
            onPressed: _isLoading ? null : _regenerateCodes,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBackupCodes,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView(theme)
                : _buildCodesView(theme),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadBackupCodes,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodesView(ThemeData theme) {
    final usedCount = _backupCodes.where((c) => c.used).length;
    final totalCount = _backupCodes.length;
    final remainingCount = totalCount - usedCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'A propos des codes de secours',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Utilisez ces codes pour vous connecter si vous perdez l\'acces a votre application d\'authentification. Chaque code ne peut etre utilise qu\'une seule fois.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: remainingCount < 3
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                remainingCount < 3 ? Icons.warning : Icons.check_circle,
                color: remainingCount < 3
                    ? theme.colorScheme.error
                    : Colors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$remainingCount codes disponibles',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$usedCount codes utilises sur $totalCount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (remainingCount < 3)
                TextButton(
                  onPressed: _regenerateCodes,
                  child: const Text('Regenerer'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Codes list
        Text(
          'Vos codes de secours',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        ...List.generate(_backupCodes.length, (index) {
          final code = _backupCodes[index];
          return _BackupCodeCard(
            code: code,
            index: index + 1,
          );
        }),

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _backupCodes.any((c) => !c.used) ? _copyToClipboard : null,
                icon: const Icon(Icons.copy),
                label: const Text('Copier'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LoadingButton(
                onPressed: _regenerateCodes,
                isLoading: false,
                text: 'Regenerer',
                icon: Icons.refresh,
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Warning
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ne partagez jamais vos codes de secours. Ils donnent acces a votre compte.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackupCodeCard extends StatelessWidget {
  final BackupCode code;
  final int index;

  const _BackupCodeCard({
    required this.code,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: code.used
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: code.used
              ? theme.colorScheme.outline.withOpacity(0.2)
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: code.used
                  ? theme.colorScheme.outline.withOpacity(0.2)
                  : theme.colorScheme.primaryContainer,
            ),
            child: Center(
              child: Text(
                '$index',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: code.used
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              code.code,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                decoration: code.used ? TextDecoration.lineThrough : null,
                color: code.used
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (code.used)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Utilise',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copie'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Copier',
            ),
        ],
      ),
    );
  }
}
