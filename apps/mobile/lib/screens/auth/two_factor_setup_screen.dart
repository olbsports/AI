import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_button.dart';

/// Screen for setting up Two-Factor Authentication (2FA)
/// Shows QR code for authenticator apps and backup codes
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  TwoFactorSetupResponse? _setupResponse;
  bool _isLoading = true;
  bool _showSecret = false;
  bool _setupComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initSetup();
  }

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _initSetup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ref.read(authProvider.notifier).enable2FA();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _setupResponse = response;
        if (response == null) {
          _error = ref.read(authProvider).error ?? 'Erreur lors de l\'initialisation';
        }
      });
    }
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  void _handleCodeChange(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_code.length == 6) {
      _handleVerify();
    }
  }

  void _handlePaste(String? value) {
    if (value == null) return;

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 6) {
      for (int i = 0; i < 6; i++) {
        _codeControllers[i].text = digits[i];
      }
      _focusNodes[5].requestFocus();
      _handleVerify();
    }
  }

  Future<void> _handleVerify() async {
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer les 6 chiffres du code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).confirm2FASetup(_code);

    if (!mounted) return;

    if (success) {
      setState(() {
        _setupComplete = true;
      });
    } else {
      // Clear the code fields on error
      for (final controller in _codeControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copie dans le presse-papiers'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuration 2FA')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_setupComplete && _setupResponse != null) {
      return _buildBackupCodesView(theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration 2FA'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _setupResponse != null
              ? _buildSetupView(theme, authState)
              : _buildErrorView(theme),
        ),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
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
            _error ?? 'Une erreur est survenue',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _initSetup,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupView(ThemeData theme, AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step indicator
          _buildStepIndicator(theme, 1),
          const SizedBox(height: 24),

          // Title and description
          Text(
            'Scannez le QR code',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Ouvrez votre application d\'authentification (Google Authenticator, Authy, etc.) et scannez le QR code ci-dessous.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // QR Code
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: _setupResponse!.qrCodeUrl.isNotEmpty
                    ? _setupResponse!.qrCodeUrl
                    : 'otpauth://totp/HorseTempo:${ref.read(authProvider).user?.email ?? "user"}?secret=${_setupResponse!.secret}&issuer=HorseTempo',
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Manual entry option
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showSecret = !_showSecret;
              });
            },
            icon: Icon(_showSecret ? Icons.visibility_off : Icons.visibility),
            label: Text(_showSecret
                ? 'Masquer la cle secrete'
                : 'Entrer la cle manuellement'),
          ),

          if (_showSecret) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Cle secrete',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _setupResponse!.secret,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _copyToClipboard(
                      _setupResponse!.secret,
                      'Cle secrete',
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copier'),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Step 2: Verification
          _buildStepIndicator(theme, 2),
          const SizedBox(height: 24),

          Text(
            'Entrez le code de verification',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez le code a 6 chiffres affiche dans votre application.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

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

          // Code input
          GestureDetector(
            onLongPress: () async {
              final data = await Clipboard.getData('text/plain');
              _handlePaste(data?.text);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  child: TextFormField(
                    controller: _codeControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _handleCodeChange(index, value),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appui long pour coller le code',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Verify button
          LoadingButton(
            onPressed: _handleVerify,
            isLoading: authState.isLoading,
            text: 'Activer la 2FA',
            icon: Icons.security,
          ),
          const SizedBox(height: 16),

          // Cancel button
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCodesView(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Codes de secours'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Authentification 2FA activee !',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sauvegardez ces codes de secours dans un endroit sur. Ils vous permettront d\'acceder a votre compte si vous perdez l\'acces a votre application d\'authentification.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

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
                        'Ces codes ne seront affiches qu\'une seule fois. Sauvegardez-les maintenant !',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Backup codes grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Codes de secours',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: _setupResponse!.backupCodes.map((code) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            code,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Copy and download buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final codes = _setupResponse!.backupCodes.join('\n');
                        _copyToClipboard(codes, 'Codes de secours');
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copier'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // In a real app, this would save to a file
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Prenez une capture d\'ecran ou notez les codes'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Telecharger'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Confirmation checkbox
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
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
                        'Chaque code ne peut etre utilise qu\'une seule fois.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Done button
              FilledButton.icon(
                onPressed: () {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Authentification a deux facteurs activee'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('J\'ai sauvegarde mes codes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme, int step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(theme, 1, step >= 1),
        Container(
          width: 40,
          height: 2,
          color: step >= 2
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
        _buildStepCircle(theme, 2, step >= 2),
      ],
    );
  }

  Widget _buildStepCircle(ThemeData theme, int number, bool active) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? theme.colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$number',
          style: theme.textTheme.labelLarge?.copyWith(
            color: active
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
