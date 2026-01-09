import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tokens.dart';
import '../../providers/tokens_provider.dart';
import '../../theme/app_theme.dart';

class PurchaseTokensScreen extends ConsumerStatefulWidget {
  const PurchaseTokensScreen({super.key});

  @override
  ConsumerState<PurchaseTokensScreen> createState() => _PurchaseTokensScreenState();
}

class _PurchaseTokensScreenState extends ConsumerState<PurchaseTokensScreen> {
  String? _selectedPackId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final packsAsync = ref.watch(tokenPacksProvider);
    final balanceAsync = ref.watch(tokenBalanceDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acheter des Tokens'),
      ),
      body: Column(
        children: [
          // Current balance banner
          balanceAsync.when(
            data: (balance) => _buildBalanceBanner(context, balance),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Packs list
          Expanded(
            child: packsAsync.when(
              data: (packs) => _buildPacksList(context, packs),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text('Erreur: $error'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(tokenPacksProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Purchase button
          if (_selectedPackId != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: packsAsync.when(
                  data: (packs) {
                    final selectedPack = packs.firstWhere(
                      (p) => p.id == _selectedPackId,
                      orElse: () => packs.first,
                    );
                    return _buildPurchaseButton(context, selectedPack);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBalanceBanner(BuildContext context, TokenBalance balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.toll,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Solde actuel: ',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            '${balance.totalBalance} tokens',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacksList(BuildContext context, List<TokenPack> packs) {
    final activePacks = packs.where((p) => p.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activePacks.length,
      itemBuilder: (context, index) {
        final pack = activePacks[index];
        return _buildPackCard(context, pack);
      },
    );
  }

  Widget _buildPackCard(BuildContext context, TokenPack pack) {
    final isSelected = _selectedPackId == pack.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : pack.isPopular
                  ? AppColors.secondary
                  : Colors.transparent,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPackId = pack.id;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and badges
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              pack.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (pack.isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Populaire',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pack.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Radio<String>(
                    value: pack.id,
                    groupValue: _selectedPackId,
                    onChanged: (value) {
                      setState(() {
                        _selectedPackId = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Token details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.toll,
                              size: 24,
                              color: AppColors.tertiary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${pack.totalTokens}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.tertiary,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'tokens',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        if (pack.bonusPercent > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${pack.bonusTokens} bonus (+${pack.bonusPercent}%)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${pack.priceInEuros.toStringAsFixed(2)} EUR',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      Text(
                        '${pack.pricePerToken.toStringAsFixed(3)} EUR/token',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context, TokenPack pack) {
    return Column(
      children: [
        // Summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pack ${pack.name}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '${pack.baseTokens} tokens',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (pack.bonusTokens > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bonus +${pack.bonusPercent}%',
                      style: TextStyle(
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      '+${pack.bonusTokens} tokens',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${pack.totalTokens} tokens pour ${pack.priceInEuros.toStringAsFixed(2)} EUR',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Purchase button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isProcessing ? null : () => _handlePurchase(pack),
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.payment),
            label: Text(
              _isProcessing
                  ? 'Traitement en cours...'
                  : 'Payer ${pack.priceInEuros.toStringAsFixed(2)} EUR',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Security info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Paiement securise par Stripe',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handlePurchase(TokenPack pack) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final tokensNotifier = ref.read(tokensNotifierProvider.notifier);
      final purchaseIntent = await tokensNotifier.initiatePurchase(pack.id);

      if (purchaseIntent == null) {
        if (mounted) {
          _showErrorSnackbar('Impossible de lancer le paiement');
        }
        return;
      }

      // In a real app, you would use Stripe SDK to present the payment sheet
      // For now, we'll simulate a successful payment
      final confirmed = await _showPaymentConfirmationDialog(pack, purchaseIntent);

      if (confirmed == true) {
        final success = await tokensNotifier.confirmPurchase(purchaseIntent.paymentIntentId);

        if (mounted) {
          if (success) {
            _showSuccessDialog(pack);
          } else {
            _showErrorSnackbar('Erreur lors de la confirmation du paiement');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool?> _showPaymentConfirmationDialog(
    TokenPack pack,
    TokenPurchaseIntent intent,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pack: ${pack.name}'),
            Text('Tokens: ${pack.totalTokens}'),
            const SizedBox(height: 8),
            Text(
              'Montant: ${pack.priceInEuros.toStringAsFixed(2)} EUR',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Note: Dans une application de production, vous seriez redirige vers l\'interface de paiement Stripe.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer (simulation)'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(TokenPack pack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          size: 64,
          color: AppColors.success,
        ),
        title: const Text('Achat reussi !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${pack.totalTokens} tokens ont ete ajoutes a votre compte.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Merci pour votre achat !',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to tokens screen
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
