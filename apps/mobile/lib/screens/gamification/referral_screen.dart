import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gamification.dart';
import '../../providers/gamification_provider.dart';
import '../../theme/app_theme.dart';

/// Referral screen with shareable code and referral list
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _emailController = TextEditingController();
  bool _isInviting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(referralStatsProvider);
    final referralsAsync = ref.watch(referralsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parrainage'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(referralStatsProvider);
          ref.invalidate(referralsListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Referral code card
              statsAsync.when(
                data: (stats) => _buildReferralCodeCard(context, stats),
                loading: () => const Card(
                  child: SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Erreur de chargement')),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Rewards info
              _buildRewardsInfo(context),
              const SizedBox(height: 24),

              // Invite by email
              _buildInviteByEmail(context),
              const SizedBox(height: 24),

              // Stats
              statsAsync.when(
                data: (stats) => _buildStatsSection(context, stats),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Referrals list
              Text(
                'Mes filleuls',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              referralsAsync.when(
                data: (referrals) => referrals.isEmpty
                    ? _buildEmptyReferrals(context)
                    : Column(
                        children: referrals.map((r) => _buildReferralItem(context, r)).toList(),
                      ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Erreur de chargement')),
                  ),
                ),
              ),

              // Referral milestones
              const SizedBox(height: 24),
              _buildMilestones(context, statsAsync.valueOrNull),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard(BuildContext context, ReferralStats stats) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre code de parrainage',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.referralCode.isNotEmpty
                          ? stats.referralCode
                          : 'HORSE-XXXXX',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyCode(stats.referralCode),
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label: const Text('Copier', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _shareCode(stats.referralCode, stats.referralLink),
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Comment ca marche ?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRewardStep(
              context,
              '1',
              'Partagez votre code',
              'Envoyez votre code a vos amis cavaliers',
            ),
            const SizedBox(height: 12),
            _buildRewardStep(
              context,
              '2',
              'Ils s\'inscrivent',
              'Votre ami utilise le code a l\'inscription',
            ),
            const SizedBox(height: 12),
            _buildRewardStep(
              context,
              '3',
              'Vous gagnez tous les deux !',
              'Vous: 500 XP + 50 tokens\nVotre ami: 200 XP + 20 tokens',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardStep(
    BuildContext context,
    String step,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInviteByEmail(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inviter par email',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'email@exemple.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isInviting ? null : _sendInvite,
                  child: _isInviting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Inviter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, ReferralStats stats) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            '${stats.totalReferrals}',
            'Filleuls',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            '${stats.activeReferrals}',
            'Actifs',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            '${stats.totalTokensEarned}',
            'Tokens gagnes',
            Icons.token,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReferrals(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun filleul pour le moment',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Partagez votre code pour commencer !',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralItem(BuildContext context, Referral referral) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(referral.status).withValues(alpha: 0.1),
          child: Text(
            referral.refereeName.isNotEmpty
                ? referral.refereeName[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: _getStatusColor(referral.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          referral.refereeName.isNotEmpty ? referral.refereeName : 'En attente...',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _formatDate(referral.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(referral.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusLabel(referral.status),
            style: TextStyle(
              color: _getStatusColor(referral.status),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestones(BuildContext context, ReferralStats? stats) {
    final theme = Theme.of(context);
    final currentCount = stats?.totalReferrals ?? 0;

    final milestones = [
      {'count': 1, 'reward': '500 XP + 50 tokens', 'badge': null},
      {'count': 5, 'reward': '200 tokens', 'badge': 'Ambassadeur'},
      {'count': 10, 'reward': '500 tokens', 'badge': 'Recruteur'},
      {'count': 25, 'reward': '1 mois PRO', 'badge': 'Champion Parrain'},
      {'count': 50, 'reward': '3 mois PRO', 'badge': 'Legende'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objectifs de parrainage',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...milestones.map((milestone) {
          final count = milestone['count'] as int;
          final reward = milestone['reward'] as String;
          final badge = milestone['badge'] as String?;
          final isAchieved = currentCount >= count;
          final isNext = !isAchieved && milestones.where((m) =>
              (m['count'] as int) < count && currentCount >= (m['count'] as int)).length ==
              milestones.where((m) => (m['count'] as int) < count).length;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isAchieved
                      ? AppColors.success.withValues(alpha: 0.1)
                      : isNext
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isAchieved
                      ? const Icon(Icons.check, color: AppColors.success)
                      : Text(
                          '$count',
                          style: TextStyle(
                            color: isNext ? AppColors.primary : AppColors.textTertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              title: Text(
                '$count filleuls',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isAchieved ? AppColors.success : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (badge != null)
                    Text(
                      'Badge: $badge',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              trailing: isNext
                  ? Text(
                      '${count - currentCount} restant',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Color _getStatusColor(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return Colors.orange;
      case ReferralStatus.registered:
        return Colors.blue;
      case ReferralStatus.active:
        return AppColors.success;
      case ReferralStatus.expired:
        return Colors.grey;
    }
  }

  String _getStatusLabel(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.pending:
        return 'En attente';
      case ReferralStatus.registered:
        return 'Inscrit';
      case ReferralStatus.active:
        return 'Actif';
      case ReferralStatus.expired:
        return 'Expire';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copie dans le presse-papiers'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareCode(String code, String link) {
    final notifier = ref.read(gamificationNotifierProvider.notifier);
    notifier.shareReferralCode(code, link);
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un email valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isInviting = true);

    final notifier = ref.read(gamificationNotifierProvider.notifier);
    final success = await notifier.sendReferralInvite(email);

    setState(() => _isInviting = false);

    if (mounted) {
      if (success) {
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation envoyee avec succes !'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi de l\'invitation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
