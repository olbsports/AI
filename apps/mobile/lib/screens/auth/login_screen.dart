import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/loading_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberDevice = false;

  // Rate limit countdown
  Timer? _rateLimitTimer;
  int _rateLimitCountdown = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _rateLimitTimer?.cancel();
    super.dispose();
  }

  void _startRateLimitCountdown(int seconds) {
    _rateLimitCountdown = seconds;
    _rateLimitTimer?.cancel();
    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_rateLimitCountdown > 0) {
        setState(() {
          _rateLimitCountdown--;
        });
      } else {
        timer.cancel();
        ref.read(authProvider.notifier).clearRateLimit();
      }
    });
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes min ${secs.toString().padLeft(2, '0')} sec';
    }
    return '$secs sec';
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final result = await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
            rememberDevice: _rememberDevice,
          );

      if (!mounted) return;

      if (result.success) {
        context.go('/dashboard');
      } else if (result.requires2FA) {
        // Navigate to 2FA screen
        context.push('/two-factor');
      } else if (result.isRateLimited && result.retryAfterSeconds != null) {
        _startRateLimitCountdown(result.retryAfterSeconds!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Start rate limit countdown if needed
    if (authState.isRateLimited &&
        authState.rateLimitRetryAfter != null &&
        _rateLimitCountdown == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRateLimitCountdown(authState.rateLimitRemainingSeconds);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                // Logo
                SvgPicture.asset(
                  'assets/images/logo_horsetempo.svg',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 24),
                Text(
                  'Horse Tempo',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous a votre compte',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Rate limit warning
                if (_rateLimitCountdown > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Trop de tentatives',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Veuillez reessayer dans ${_formatCountdown(_rateLimitCountdown)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Error message
                if (authState.error != null && _rateLimitCountdown == 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: _rateLimitCountdown == 0,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'exemple@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'L\'email est requis';
                    }
                    // Improved email regex (RFC 5322 compliant)
                    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                        .hasMatch(value)) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: _rateLimitCountdown == 0,
                  onFieldSubmitted: (_) => _rateLimitCountdown == 0 ? _handleLogin() : null,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le mot de passe est requis';
                    }
                    if (value.length < 8) {
                      return 'Minimum 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Remember device checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _rememberDevice,
                      onChanged: _rateLimitCountdown == 0
                          ? (value) {
                              setState(() {
                                _rememberDevice = value ?? false;
                              });
                            }
                          : null,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _rateLimitCountdown == 0
                            ? () {
                                setState(() {
                                  _rememberDevice = !_rememberDevice;
                                });
                              }
                            : null,
                        child: Text(
                          'Se souvenir de cet appareil',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _rateLimitCountdown > 0
                                    ? Theme.of(context).disabledColor
                                    : null,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Mot de passe oublie ?'),
                  ),
                ),
                const SizedBox(height: 24),

                // Login button
                LoadingButton(
                  onPressed: _rateLimitCountdown > 0 ? null : _handleLogin,
                  isLoading: authState.isLoading,
                  text: _rateLimitCountdown > 0
                      ? 'Patientez ${_formatCountdown(_rateLimitCountdown)}'
                      : 'Se connecter',
                  icon: Icons.login,
                ),
                const SizedBox(height: 24),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('S\'inscrire'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
