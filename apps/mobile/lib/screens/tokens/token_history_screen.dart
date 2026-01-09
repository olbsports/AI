import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/tokens.dart';
import '../../providers/tokens_provider.dart';
import '../../theme/app_theme.dart';

class TokenHistoryScreen extends ConsumerStatefulWidget {
  const TokenHistoryScreen({super.key});

  @override
  ConsumerState<TokenHistoryScreen> createState() => _TokenHistoryScreenState();
}

class _TokenHistoryScreenState extends ConsumerState<TokenHistoryScreen> {
  TransactionType? _selectedType;
  TransactionDirection? _selectedDirection;
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final filter = TokenTransactionFilter(
      type: _selectedType,
      direction: _selectedDirection,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );

    final transactionsAsync = ref.watch(tokenTransactionsProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Tokens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Filtrer',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') {
                _handleExport();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Exporter CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters bar
          if (_hasActiveFilters()) _buildActiveFiltersBar(),

          // Transactions list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(tokenTransactionsProvider(filter));
              },
              child: transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildTransactionsList(transactions);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildErrorState(error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedType != null ||
        _selectedDirection != null ||
        _selectedDateRange != null;
  }

  Widget _buildActiveFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedType != null)
                    _buildFilterChip(
                      label: _selectedType!.displayName,
                      onDeleted: () => setState(() => _selectedType = null),
                    ),
                  if (_selectedDirection != null)
                    _buildFilterChip(
                      label: _selectedDirection == TransactionDirection.credit
                          ? 'Credits'
                          : 'Debits',
                      onDeleted: () => setState(() => _selectedDirection = null),
                    ),
                  if (_selectedDateRange != null)
                    _buildFilterChip(
                      label:
                          '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                      onDeleted: () => setState(() => _selectedDateRange = null),
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedDirection = null;
                _selectedDateRange = null;
              });
            },
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDeleted,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<TokenTransaction> transactions) {
    // Group transactions by date
    final groupedTransactions = <String, List<TokenTransaction>>{};
    for (final transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.createdAt);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }

    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dateTransactions = groupedTransactions[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatDateHeader(date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            // Transactions for this date
            ...dateTransactions.map((t) => _buildTransactionItem(t)),
            if (index < sortedDates.length - 1) const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return "Aujourd'hui";
    } else if (dateOnly == yesterday) {
      return 'Hier';
    } else {
      return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
    }
  }

  Widget _buildTransactionItem(TokenTransaction transaction) {
    final isCredit = transaction.direction == TransactionDirection.credit;
    final color = isCredit ? AppColors.success : AppColors.error;

    IconData icon;
    switch (transaction.type) {
      case TransactionType.purchase:
        icon = Icons.shopping_cart;
        break;
      case TransactionType.subscriptionCredit:
        icon = Icons.card_membership;
        break;
      case TransactionType.consumption:
        icon = Icons.play_circle_outline;
        break;
      case TransactionType.refund:
        icon = Icons.replay;
        break;
      case TransactionType.bonus:
        icon = Icons.card_giftcard;
        break;
      case TransactionType.transfer:
        icon = Icons.swap_horiz;
        break;
      case TransactionType.adjustment:
        icon = Icons.tune;
        break;
      case TransactionType.expiration:
        icon = Icons.timer_off;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description ??
                          transaction.type.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat('HH:mm').format(transaction.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        if (transaction.source != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              transaction.source!.type,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit ? '+' : '-'}${transaction.amount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  Text(
                    'tokens',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),

              // Status indicator
              if (transaction.status != TransactionStatus.completed)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildStatusBadge(transaction.status),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case TransactionStatus.pending:
        bgColor = AppColors.warningContainer;
        textColor = AppColors.warning;
        label = 'En cours';
        break;
      case TransactionStatus.failed:
        bgColor = AppColors.errorContainer;
        textColor = AppColors.error;
        label = 'Echoue';
        break;
      case TransactionStatus.refunded:
        bgColor = AppColors.infoContainer;
        textColor = AppColors.info;
        label = 'Rembourse';
        break;
      case TransactionStatus.completed:
        bgColor = AppColors.successContainer;
        textColor = AppColors.success;
        label = 'Complete';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune transaction',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveFilters()
                  ? 'Aucune transaction ne correspond a vos filtres'
                  : 'Votre historique de transactions apparaitra ici',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(tokenTransactionsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Filtrer les transactions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Direction filter
                    Text(
                      'Direction',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Tous'),
                          selected: _selectedDirection == null,
                          onSelected: (_) {
                            setModalState(() => _selectedDirection = null);
                            setState(() {});
                          },
                        ),
                        FilterChip(
                          label: const Text('Credits (+)'),
                          selected:
                              _selectedDirection == TransactionDirection.credit,
                          onSelected: (_) {
                            setModalState(() => _selectedDirection =
                                TransactionDirection.credit);
                            setState(() {});
                          },
                        ),
                        FilterChip(
                          label: const Text('Debits (-)'),
                          selected:
                              _selectedDirection == TransactionDirection.debit,
                          onSelected: (_) {
                            setModalState(() => _selectedDirection =
                                TransactionDirection.debit);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Type filter
                    Text(
                      'Type de transaction',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Tous'),
                          selected: _selectedType == null,
                          onSelected: (_) {
                            setModalState(() => _selectedType = null);
                            setState(() {});
                          },
                        ),
                        ...TransactionType.values.map((type) {
                          return FilterChip(
                            label: Text(type.displayName),
                            selected: _selectedType == type,
                            onSelected: (_) {
                              setModalState(() => _selectedType = type);
                              setState(() {});
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Date range filter
                    Text(
                      'Periode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                          initialDateRange: _selectedDateRange,
                        );
                        if (range != null) {
                          setModalState(() => _selectedDateRange = range);
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDateRange != null
                            ? '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'
                            : 'Selectionner une periode',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Apply button
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Appliquer les filtres'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showTransactionDetails(TokenTransaction transaction) {
    final isCredit = transaction.direction == TransactionDirection.credit;
    final color = isCredit ? AppColors.success : AppColors.error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Amount header
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${isCredit ? '+' : '-'}${transaction.amount}',
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                      ),
                      Text(
                        'tokens',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Details
                _buildDetailRow(
                  'Type',
                  transaction.type.displayName,
                ),
                _buildDetailRow(
                  'Statut',
                  _getStatusText(transaction.status),
                ),
                _buildDetailRow(
                  'Date',
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                ),
                _buildDetailRow(
                  'Solde apres',
                  '${transaction.balanceAfter} tokens',
                ),
                _buildDetailRow(
                  'Type de solde',
                  transaction.balanceType == BalanceType.included
                      ? 'Inclus (abonnement)'
                      : 'Achete',
                ),

                if (transaction.description != null)
                  _buildDetailRow('Description', transaction.description!),

                if (transaction.source != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Source',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type: ${transaction.source!.type}'),
                          if (transaction.source!.name != null)
                            Text('Nom: ${transaction.source!.name}'),
                        ],
                      ),
                    ),
                  ),
                ],

                if (transaction.purchase != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Details de l\'achat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pack: ${transaction.purchase!.packName}'),
                          Text(
                              'Tokens de base: ${transaction.purchase!.baseTokens}'),
                          Text(
                              'Bonus: +${transaction.purchase!.bonusTokens}'),
                          Text(
                              'Prix: ${transaction.purchase!.priceInEuros.toStringAsFixed(2)} EUR'),
                        ],
                      ),
                    ),
                  ),
                ],

                if (transaction.failureReason != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            transaction.failureReason!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'En cours';
      case TransactionStatus.completed:
        return 'Complete';
      case TransactionStatus.failed:
        return 'Echoue';
      case TransactionStatus.refunded:
        return 'Rembourse';
    }
  }

  void _handleExport() {
    // In a real app, this would trigger a CSV export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export CSV en cours de preparation...'),
      ),
    );

    // Simulate export
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Export CSV telecharge avec succes'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }
}
