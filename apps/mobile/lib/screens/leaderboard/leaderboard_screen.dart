import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.weekly;
  int _selectedGalopLevel = 0; // 0 = all
  HorseDiscipline? _selectedDiscipline;
  HorseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Cavaliers'),
            Tab(icon: Icon(Icons.pets), text: 'Chevaux'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period selector
          _buildPeriodSelector(),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRiderLeaderboard(),
                _buildHorseLeaderboard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: LeaderboardPeriod.values.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(period.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPeriod = period);
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRiderLeaderboard() {
    // Mock data - will be replaced with API call
    final mockRiders = _getMockRiderData();

    return Column(
      children: [
        // Galop level filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildGalopChip(0, 'Tous'),
              for (int i = 1; i <= 7; i++) _buildGalopChip(i, 'Galop $i'),
            ],
          ),
        ),
        const Divider(height: 1),
        // Leaderboard list
        Expanded(
          child: mockRiders.isEmpty
              ? _buildEmptyState('Aucun cavalier dans ce classement')
              : ListView.builder(
                  itemCount: mockRiders.length,
                  itemBuilder: (context, index) {
                    final entry = mockRiders[index];
                    return _buildRiderEntry(entry, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGalopChip(int level, String label) {
    final isSelected = _selectedGalopLevel == level;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedGalopLevel = level);
        },
      ),
    );
  }

  Widget _buildRiderEntry(RiderLeaderboardEntry entry, int index) {
    final isTopThree = entry.rank <= 3;
    final rankColor = _getRankColor(entry.rank);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isTopThree ? rankColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: entry.riderPhotoUrl != null
                  ? NetworkImage(entry.riderPhotoUrl!)
                  : null,
              child: entry.riderPhotoUrl == null
                  ? Text(entry.riderName[0].toUpperCase())
                  : null,
            ),
            if (isTopThree)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: rankColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _getRankEmoji(entry.rank),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isTopThree ? rankColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${entry.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTopThree ? Colors.white : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.riderName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _buildRankChange(entry.rankChange),
          ],
        ),
        subtitle: Row(
          children: [
            const SizedBox(width: 36),
            Text('Galop ${entry.galopLevel}'),
            const SizedBox(width: 8),
            Icon(Icons.analytics, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 2),
            Text('${entry.analysisCount}'),
            const SizedBox(width: 8),
            if (entry.streakDays > 0) ...[
              const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
              const SizedBox(width: 2),
              Text('${entry.streakDays}j'),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.score}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'pts',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _showRiderDetails(entry),
      ),
    );
  }

  Widget _buildHorseLeaderboard() {
    // Mock data - will be replaced with API call
    final mockHorses = _getMockHorseData();

    return Column(
      children: [
        // Discipline filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildDisciplineChip(null, 'Toutes'),
              for (final discipline in HorseDiscipline.values.where((d) => d != HorseDiscipline.other))
                _buildDisciplineChip(discipline, discipline.displayName),
            ],
          ),
        ),
        // Category filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryChip(null, 'Tous niveaux'),
              for (final category in HorseCategory.values)
                _buildCategoryChip(category, category.displayName),
            ],
          ),
        ),
        const Divider(height: 1),
        // Leaderboard list
        Expanded(
          child: mockHorses.isEmpty
              ? _buildEmptyState('Aucun cheval dans ce classement')
              : ListView.builder(
                  itemCount: mockHorses.length,
                  itemBuilder: (context, index) {
                    final entry = mockHorses[index];
                    return _buildHorseEntry(entry, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDisciplineChip(HorseDiscipline? discipline, String label) {
    final isSelected = _selectedDiscipline == discipline;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedDiscipline = selected ? discipline : null);
        },
      ),
    );
  }

  Widget _buildCategoryChip(HorseCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = selected ? category : null);
        },
      ),
    );
  }

  Widget _buildHorseEntry(HorseLeaderboardEntry entry, int index) {
    final isTopThree = entry.rank <= 3;
    final rankColor = _getRankColor(entry.rank);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isTopThree ? rankColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: entry.horsePhotoUrl != null
                  ? NetworkImage(entry.horsePhotoUrl!)
                  : null,
              child: entry.horsePhotoUrl == null
                  ? const Icon(Icons.pets)
                  : null,
            ),
            if (isTopThree)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: rankColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _getRankEmoji(entry.rank),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isTopThree ? rankColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${entry.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTopThree ? Colors.white : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.horseName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _buildRankChange(entry.rankChange),
          ],
        ),
        subtitle: Row(
          children: [
            const SizedBox(width: 36),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.discipline.displayName,
                style: TextStyle(fontSize: 10, color: AppColors.secondary),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.category.displayName,
                style: const TextStyle(fontSize: 10),
              ),
            ),
            const SizedBox(width: 8),
            if (entry.averageScore > 0) ...[
              const Icon(Icons.star, size: 14, color: Colors.amber),
              Text(' ${entry.averageScore.toStringAsFixed(1)}'),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.score}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'pts',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _showHorseDetails(entry),
      ),
    );
  }

  Widget _buildRankChange(int change) {
    if (change == 0) return const SizedBox.shrink();

    final isUp = change > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: isUp ? Colors.green : Colors.red,
        ),
        Text(
          '${change.abs()}',
          style: TextStyle(
            fontSize: 12,
            color: isUp ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtres',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('Plus de filtres à venir...'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Appliquer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRiderDetails(RiderLeaderboardEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: entry.riderPhotoUrl != null
                      ? NetworkImage(entry.riderPhotoUrl!)
                      : null,
                  child: entry.riderPhotoUrl == null
                      ? Text(entry.riderName[0].toUpperCase(), style: const TextStyle(fontSize: 32))
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  entry.riderName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Center(
                child: Text(
                  'Galop ${entry.galopLevel} • Rang #${entry.rank}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 24),
              _buildStatRow('Score total', '${entry.score} pts'),
              _buildStatRow('Analyses réalisées', '${entry.analysisCount}'),
              _buildStatRow('Chevaux', '${entry.horseCount}'),
              _buildStatRow('Série en cours', '${entry.streakDays} jours'),
              _buildStatRow('Progression', '+${entry.progressRate.toStringAsFixed(1)}%'),
              const SizedBox(height: 24),
              if (entry.badges.isNotEmpty) ...[
                Text('Badges', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: entry.badges.map((badge) => Chip(label: Text(badge))).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showHorseDetails(HorseLeaderboardEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: entry.horsePhotoUrl != null
                      ? NetworkImage(entry.horsePhotoUrl!)
                      : null,
                  child: entry.horsePhotoUrl == null
                      ? const Icon(Icons.pets, size: 48)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  entry.horseName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Center(
                child: Text(
                  '${entry.discipline.displayName} • ${entry.category.displayName} • Rang #${entry.rank}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 24),
              _buildStatRow('Score total', '${entry.score} pts'),
              _buildStatRow('Analyses réalisées', '${entry.analysisCount}'),
              _buildStatRow('Note moyenne', '${entry.averageScore.toStringAsFixed(1)}/10'),
              _buildStatRow('Progression', '+${entry.progressRate.toStringAsFixed(1)}%'),
              if (entry.breed != null) _buildStatRow('Race', entry.breed!),
              const SizedBox(height: 24),
              if (entry.achievements.isNotEmpty) ...[
                Text('Accomplissements', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: entry.achievements.map((a) => Chip(label: Text(a))).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Mock data for demonstration
  List<RiderLeaderboardEntry> _getMockRiderData() {
    return [
      RiderLeaderboardEntry(
        id: '1',
        riderId: 'r1',
        riderName: 'Marie Dupont',
        galopLevel: 7,
        rank: 1,
        previousRank: 2,
        score: 2450,
        analysisCount: 48,
        horseCount: 3,
        streakDays: 15,
        progressRate: 12.5,
        badges: ['Expert', 'Assidu'],
        lastActivityAt: DateTime.now(),
      ),
      RiderLeaderboardEntry(
        id: '2',
        riderId: 'r2',
        riderName: 'Thomas Martin',
        galopLevel: 6,
        rank: 2,
        previousRank: 1,
        score: 2380,
        analysisCount: 42,
        horseCount: 2,
        streakDays: 8,
        progressRate: 8.2,
        badges: ['Passionné'],
        lastActivityAt: DateTime.now(),
      ),
      RiderLeaderboardEntry(
        id: '3',
        riderId: 'r3',
        riderName: 'Sophie Leroux',
        galopLevel: 5,
        rank: 3,
        previousRank: 4,
        score: 2150,
        analysisCount: 35,
        horseCount: 2,
        streakDays: 22,
        progressRate: 15.8,
        badges: ['Régulier', 'Motivé'],
        lastActivityAt: DateTime.now(),
      ),
      for (int i = 4; i <= 10; i++)
        RiderLeaderboardEntry(
          id: '$i',
          riderId: 'r$i',
          riderName: 'Cavalier $i',
          galopLevel: 7 - (i % 5),
          rank: i,
          previousRank: i + (i % 2 == 0 ? 1 : -1),
          score: 2000 - (i * 100),
          analysisCount: 30 - i,
          horseCount: 1,
          streakDays: i % 10,
          progressRate: 5.0,
          badges: [],
          lastActivityAt: DateTime.now(),
        ),
    ];
  }

  List<HorseLeaderboardEntry> _getMockHorseData() {
    return [
      HorseLeaderboardEntry(
        id: '1',
        horseId: 'h1',
        horseName: 'Étoile du Matin',
        breed: 'Selle Français',
        category: HorseCategory.amateur,
        discipline: HorseDiscipline.cso,
        rank: 1,
        previousRank: 1,
        score: 3200,
        analysisCount: 28,
        averageScore: 8.5,
        progressRate: 18.2,
        achievements: ['Champion régional', 'Sans faute'],
        lastAnalysisAt: DateTime.now(),
      ),
      HorseLeaderboardEntry(
        id: '2',
        horseId: 'h2',
        horseName: 'Spirit',
        breed: 'KWPN',
        category: HorseCategory.pro,
        discipline: HorseDiscipline.dressage,
        rank: 2,
        previousRank: 3,
        score: 3050,
        analysisCount: 32,
        averageScore: 8.2,
        progressRate: 12.5,
        achievements: ['Étoile montante'],
        lastAnalysisAt: DateTime.now(),
      ),
      HorseLeaderboardEntry(
        id: '3',
        horseId: 'h3',
        horseName: 'Tornado',
        breed: 'Pur-sang',
        category: HorseCategory.club,
        discipline: HorseDiscipline.cce,
        rank: 3,
        previousRank: 2,
        score: 2900,
        analysisCount: 25,
        averageScore: 7.8,
        progressRate: 8.0,
        achievements: ['Polyvalent'],
        lastAnalysisAt: DateTime.now(),
      ),
      HorseLeaderboardEntry(
        id: '4',
        horseId: 'h4',
        horseName: 'Buttons',
        category: HorseCategory.club,
        discipline: HorseDiscipline.hobbyHorse,
        rank: 4,
        previousRank: 5,
        score: 2750,
        analysisCount: 20,
        averageScore: 9.2,
        progressRate: 25.0,
        achievements: ['Hobby Horse Star'],
        lastAnalysisAt: DateTime.now(),
      ),
      for (int i = 5; i <= 10; i++)
        HorseLeaderboardEntry(
          id: '$i',
          horseId: 'h$i',
          horseName: 'Cheval $i',
          category: HorseCategory.values[i % HorseCategory.values.length],
          discipline: HorseDiscipline.values[i % (HorseDiscipline.values.length - 1)],
          rank: i,
          previousRank: i,
          score: 2500 - (i * 100),
          analysisCount: 15,
          averageScore: 7.0,
          progressRate: 5.0,
          achievements: [],
          lastAnalysisAt: DateTime.now(),
        ),
    ];
  }
}
