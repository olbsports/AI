import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_theme.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Support',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatCard('Ouverts', ref.watch(openTicketsCountProvider).valueOrNull ?? 0, AdminColors.warning),
                const SizedBox(width: 16),
                _buildStatCard('En cours', ref.watch(inProgressTicketsCountProvider).valueOrNull ?? 0, AdminColors.primary),
                const SizedBox(width: 16),
                _buildStatCard('Résolus (7j)', ref.watch(resolvedTicketsCountProvider).valueOrNull ?? 0, AdminColors.success),
                const SizedBox(width: 16),
                _buildStatCard('Temps moyen', ref.watch(averageResponseTimeProvider).valueOrNull ?? 'N/A', AdminColors.accent),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                children: [
                  // Tickets list
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: ticketsAsync.when(
                        data: (tickets) => ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: tickets.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return _buildTicketItem(ticket);
                          },
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Erreur: $e')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Quick stats
                  Expanded(
                    child: Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Par catégorie',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...TicketCategory.values.map((cat) => _buildCategoryRow(cat)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Réponses rapides',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildQuickReply('Problème de connexion'),
                                _buildQuickReply('Question facturation'),
                                _buildQuickReply('Bug signalé'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.support_agent, color: color),
              ),
              const SizedBox(width: 12),
              Builder(
                builder: (ctx) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(ctx).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(label, style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketItem(SupportTicket ticket) {
    return InkWell(
      onTap: () => _showTicketDetails(ticket),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(ticket.priority.colorValue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.confirmation_number,
                color: Color(ticket.priority.colorValue),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (ctx) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(ctx).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${ticket.userName} • ${ticket.category.displayName}',
                      style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(ticket.status.colorValue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ticket.status.displayName,
                style: TextStyle(
                  color: Color(ticket.status.colorValue),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (ctx) => Text(
                DateFormat('dd/MM').format(ticket.createdAt),
                style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(TicketCategory category) {
    return Consumer(
      builder: (context, ref, _) {
        final statsByCategory = ref.watch(supportStatsByCategoryProvider).valueOrNull ?? {};
        final count = statsByCategory[category.name] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category.displayName, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              Text(
                count.toString(),
                style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickReply(String title) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton(
          onPressed: () => _useQuickReply(context, title),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(title, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  void _showTicketDetails(SupportTicket ticket) {
    // This would navigate to ticket detail screen
    // For now show a dialog with ticket info
  }

  void _useQuickReply(BuildContext context, String replyType) {
    final templates = {
      'Problème de connexion': '''Bonjour,

Merci de nous avoir contacté. Pour résoudre votre problème de connexion, veuillez essayer les étapes suivantes :

1. Vérifiez votre connexion internet
2. Effacez le cache de l'application
3. Essayez de vous reconnecter

Si le problème persiste, n'hésitez pas à nous recontacter.

Cordialement,
L'équipe Horse Tempo''',
      'Question facturation': '''Bonjour,

Merci pour votre message concernant la facturation.

Vous pouvez consulter vos factures dans l'onglet "Abonnement" de votre compte. Si vous avez une question spécifique, merci de nous préciser les détails.

Cordialement,
L'équipe Horse Tempo''',
      'Bug signalé': '''Bonjour,

Merci de nous avoir signalé ce bug. Notre équipe technique a bien pris en compte votre rapport et travaille à sa résolution.

Nous vous tiendrons informé dès que le correctif sera déployé.

Cordialement,
L'équipe Horse Tempo''',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Réponse "$replyType" copiée'),
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text('Modèle: $replyType'),
                content: SingleChildScrollView(
                  child: Text(templates[replyType] ?? ''),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
