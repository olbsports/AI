import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/health.dart';
import '../../theme/app_theme.dart';

/// Body Condition Score (BCS) Slider Widget using the Henneke Scale (1-9)
/// Provides visual feedback and detailed descriptions for each score level
class BodyConditionSliderWidget extends StatefulWidget {
  final int initialScore;
  final ValueChanged<int>? onScoreChanged;
  final bool readOnly;
  final bool showDescription;
  final bool showHorseVisual;

  const BodyConditionSliderWidget({
    super.key,
    this.initialScore = 5,
    this.onScoreChanged,
    this.readOnly = false,
    this.showDescription = true,
    this.showHorseVisual = true,
  });

  @override
  State<BodyConditionSliderWidget> createState() => _BodyConditionSliderWidgetState();
}

class _BodyConditionSliderWidgetState extends State<BodyConditionSliderWidget> {
  late int _currentScore;

  @override
  void initState() {
    super.initState();
    _currentScore = widget.initialScore.clamp(1, 9);
  }

  @override
  void didUpdateWidget(BodyConditionSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialScore != widget.initialScore) {
      setState(() {
        _currentScore = widget.initialScore.clamp(1, 9);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreData = _getScoreData(_currentScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score Corporel (BCS)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreData.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scoreData.color),
                  ),
                  child: Text(
                    '$_currentScore/9',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scoreData.color,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Horse Visual
            if (widget.showHorseVisual) ...[
              _buildHorseVisual(context, scoreData),
              const SizedBox(height: 16),
            ],

            // Score Label
            Center(
              child: Text(
                scoreData.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scoreData.color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 12),

            // Slider
            _buildSlider(context, scoreData),
            const SizedBox(height: 8),

            // Scale labels
            _buildScaleLabels(context),

            // Description
            if (widget.showDescription) ...[
              const SizedBox(height: 16),
              _buildDescription(context, scoreData),
            ],

            // Body area details
            const SizedBox(height: 16),
            _buildBodyAreaDetails(context, scoreData),
          ],
        ),
      ),
    );
  }

  Widget _buildHorseVisual(BuildContext context, _BCSData scoreData) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Horse silhouette representation
          CustomPaint(
            size: const Size(200, 100),
            painter: _HorseSilhouettePainter(
              score: _currentScore,
              color: scoreData.color,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          // Score indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scoreData.color.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_currentScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(BuildContext context, _BCSData scoreData) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: scoreData.color,
        inactiveTrackColor: scoreData.color.withValues(alpha: 0.2),
        thumbColor: scoreData.color,
        overlayColor: scoreData.color.withValues(alpha: 0.2),
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
      ),
      child: Slider(
        value: _currentScore.toDouble(),
        min: 1,
        max: 9,
        divisions: 8,
        onChanged: widget.readOnly
            ? null
            : (value) {
                final newScore = value.round();
                if (newScore != _currentScore) {
                  setState(() => _currentScore = newScore);
                  widget.onScoreChanged?.call(newScore);
                }
              },
      ),
    );
  }

  Widget _buildScaleLabels(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Maigre',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.error,
              ),
        ),
        Text(
          'Ideal',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.success,
              ),
        ),
        Text(
          'Obese',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.warning,
              ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, _BCSData scoreData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreData.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scoreData.color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                scoreData.icon,
                color: scoreData.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scoreData.color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            scoreData.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyAreaDetails(BuildContext context, _BCSData scoreData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zones a observer',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: scoreData.bodyAreas.map((area) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    area.icon,
                    size: 16,
                    color: scoreData.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    area.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  _BCSData _getScoreData(int score) {
    switch (score) {
      case 1:
        return _BCSData(
          label: 'Emaciation extreme',
          description:
              'Le cheval est extremement maigre. Les structures osseuses (cotes, colonne vertebrale, garrot, hanches) sont tres visibles. Aucune graisse palpable. Etat critique necessitant une intervention veterinaire immediate.',
          color: AppColors.error,
          icon: Icons.warning,
          bodyAreas: [
            _BodyArea('Cotes', Icons.view_week),
            _BodyArea('Garrot', Icons.arrow_upward),
            _BodyArea('Epaule', Icons.accessibility),
            _BodyArea('Encolure', Icons.swap_vert),
          ],
        );
      case 2:
        return _BCSData(
          label: 'Tres maigre',
          description:
              'Emaciation prononcee. Structures osseuses legerement saillantes mais visibles. Tres peu de tissu graisseux. Consultation veterinaire recommandee.',
          color: AppColors.error,
          icon: Icons.warning,
          bodyAreas: [
            _BodyArea('Cotes', Icons.view_week),
            _BodyArea('Garrot', Icons.arrow_upward),
            _BodyArea('Croupe', Icons.trending_down),
          ],
        );
      case 3:
        return _BCSData(
          label: 'Maigre',
          description:
              'Le cheval est maigre. Les cotes sont facilement visibles. Un sillon visible le long du dos. Hanches arrondies mais facilement discernables. Evaluation nutritionnelle necessaire.',
          color: const Color(0xFFFF7043),
          icon: Icons.trending_down,
          bodyAreas: [
            _BodyArea('Cotes', Icons.view_week),
            _BodyArea('Dos', Icons.straighten),
            _BodyArea('Hanches', Icons.crop_square),
          ],
        );
      case 4:
        return _BCSData(
          label: 'Legerement maigre',
          description:
              'Leger sillon le long du dos. Legere couverture de graisse sur les cotes. Les cotes peuvent etre facilement ressenties. Hanches non distinguables.',
          color: AppColors.warning,
          icon: Icons.remove,
          bodyAreas: [
            _BodyArea('Dos', Icons.straighten),
            _BodyArea('Cotes', Icons.view_week),
            _BodyArea('Epaule', Icons.accessibility),
          ],
        );
      case 5:
        return _BCSData(
          label: 'Ideal - Moderement bon',
          description:
              'Score corporel ideal. Dos plat (pas de sillon ni de creux). Les cotes peuvent etre facilement ressenties mais pas visuellement distinguees. Graisse autour de la queue commencant a se sentir spongieuse.',
          color: AppColors.success,
          icon: Icons.check_circle,
          bodyAreas: [
            _BodyArea('Dos', Icons.straighten),
            _BodyArea('Cotes', Icons.view_week),
            _BodyArea('Queue', Icons.swap_calls),
          ],
        );
      case 6:
        return _BCSData(
          label: 'Legerement gras',
          description:
              'Leger pli possible le long du dos. Les cotes peuvent etre facilement ressenties avec une legere couverture de graisse. La graisse autour de la queue se sent douce.',
          color: AppColors.warning,
          icon: Icons.add,
          bodyAreas: [
            _BodyArea('Dos', Icons.straighten),
            _BodyArea('Cotes', Icons.view_week),
            _BodyArea('Queue', Icons.swap_calls),
            _BodyArea('Encolure', Icons.swap_vert),
          ],
        );
      case 7:
        return _BCSData(
          label: 'Gras',
          description:
              'Pli visible le long du dos. Les cotes individuelles peuvent etre ressenties avec une pression ferme, mais un remplissage notable entre les cotes. Graisse deposee le long du garrot, derriere les epaules et autour de la queue.',
          color: const Color(0xFFFF7043),
          icon: Icons.trending_up,
          bodyAreas: [
            _BodyArea('Dos', Icons.straighten),
            _BodyArea('Cotes', Icons.view_week),
            _BodyArea('Garrot', Icons.arrow_upward),
            _BodyArea('Epaule', Icons.accessibility),
          ],
        );
      case 8:
        return _BCSData(
          label: 'Obese',
          description:
              'Pli evident le long du dos. Difficulte a sentir les cotes. Zone derriere l\'epaule remplie de graisse. Engorgement notable autour de la queue. Flans remplis. Risques pour la sante.',
          color: AppColors.error,
          icon: Icons.warning,
          bodyAreas: [
            _BodyArea('Dos', Icons.straighten),
            _BodyArea('Cotes', Icons.view_week),
            _BodyArea('Epaule', Icons.accessibility),
            _BodyArea('Flans', Icons.rectangle),
          ],
        );
      case 9:
        return _BCSData(
          label: 'Obesite extreme',
          description:
              'Pli tres evident le long du dos. Les cotes ne peuvent pas etre ressenties. Accumulation de graisse sur le garrot, les epaules et l\'encolure. Flancs remplis. Graisse le long de l\'interieur des cuisses. Risques serieux pour la sante.',
          color: AppColors.error,
          icon: Icons.error,
          bodyAreas: [
            _BodyArea('Dos', Icons.straighten),
            _BodyArea('Encolure', Icons.swap_vert),
            _BodyArea('Epaule', Icons.accessibility),
            _BodyArea('Cuisses', Icons.fitness_center),
          ],
        );
      default:
        return _BCSData(
          label: 'Ideal',
          description: 'Score ideal.',
          color: AppColors.success,
          icon: Icons.check_circle,
          bodyAreas: [],
        );
    }
  }
}

class _BCSData {
  final String label;
  final String description;
  final Color color;
  final IconData icon;
  final List<_BodyArea> bodyAreas;

  _BCSData({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    required this.bodyAreas,
  });
}

class _BodyArea {
  final String name;
  final IconData icon;

  _BodyArea(this.name, this.icon);
}

/// Custom painter for horse silhouette visualization
class _HorseSilhouettePainter extends CustomPainter {
  final int score;
  final Color color;
  final Color backgroundColor;

  _HorseSilhouettePainter({
    required this.score,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Calculate body width based on score
    final baseWidth = size.width * 0.3;
    final widthModifier = (score - 5) * 0.05; // -0.2 to +0.2 based on score
    final bodyWidth = baseWidth * (1 + widthModifier);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw horse body (simplified ellipse)
    final bodyRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: bodyWidth,
      height: size.height * 0.5,
    );
    canvas.drawOval(bodyRect, paint);
    canvas.drawOval(bodyRect, outlinePaint);

    // Draw neck
    final neckPath = Path();
    final neckWidth = bodyWidth * 0.25 * (1 + widthModifier * 0.5);
    neckPath.moveTo(centerX - bodyWidth * 0.3, centerY - size.height * 0.15);
    neckPath.quadraticBezierTo(
      centerX - bodyWidth * 0.5,
      centerY - size.height * 0.35,
      centerX - bodyWidth * 0.35 - neckWidth,
      centerY - size.height * 0.45,
    );
    neckPath.lineTo(centerX - bodyWidth * 0.35 + neckWidth, centerY - size.height * 0.4);
    neckPath.quadraticBezierTo(
      centerX - bodyWidth * 0.45,
      centerY - size.height * 0.3,
      centerX - bodyWidth * 0.25,
      centerY - size.height * 0.1,
    );
    neckPath.close();
    canvas.drawPath(neckPath, paint);
    canvas.drawPath(neckPath, outlinePaint);

    // Draw head
    final headPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final headRect = Rect.fromCenter(
      center: Offset(centerX - bodyWidth * 0.5, centerY - size.height * 0.42),
      width: bodyWidth * 0.35,
      height: size.height * 0.2,
    );
    canvas.drawOval(headRect, headPaint);
    canvas.drawOval(headRect, outlinePaint);

    // Draw legs (simplified)
    final legPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Front legs
    canvas.drawLine(
      Offset(centerX - bodyWidth * 0.2, centerY + size.height * 0.2),
      Offset(centerX - bodyWidth * 0.22, centerY + size.height * 0.48),
      legPaint,
    );
    canvas.drawLine(
      Offset(centerX - bodyWidth * 0.1, centerY + size.height * 0.22),
      Offset(centerX - bodyWidth * 0.08, centerY + size.height * 0.48),
      legPaint,
    );

    // Back legs
    canvas.drawLine(
      Offset(centerX + bodyWidth * 0.15, centerY + size.height * 0.2),
      Offset(centerX + bodyWidth * 0.12, centerY + size.height * 0.48),
      legPaint,
    );
    canvas.drawLine(
      Offset(centerX + bodyWidth * 0.25, centerY + size.height * 0.18),
      Offset(centerX + bodyWidth * 0.28, centerY + size.height * 0.48),
      legPaint,
    );

    // Draw ribs indicator (visible when score is low)
    if (score <= 4) {
      final ribPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final ribCount = 5 - score + 2; // More ribs visible when thinner
      for (int i = 0; i < ribCount; i++) {
        final ribX = centerX - bodyWidth * 0.1 + (i * bodyWidth * 0.08);
        canvas.drawLine(
          Offset(ribX, centerY - size.height * 0.1),
          Offset(ribX, centerY + size.height * 0.1),
          ribPaint,
        );
      }
    }

    // Draw fat deposits indicator (visible when score is high)
    if (score >= 7) {
      final fatPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      // Crest fat
      final crestRect = Rect.fromCenter(
        center: Offset(centerX - bodyWidth * 0.4, centerY - size.height * 0.32),
        width: bodyWidth * 0.2 * (score - 6) * 0.3,
        height: size.height * 0.1 * (score - 6) * 0.3,
      );
      canvas.drawOval(crestRect, fatPaint);

      // Tailhead fat
      final tailRect = Rect.fromCenter(
        center: Offset(centerX + bodyWidth * 0.35, centerY - size.height * 0.05),
        width: bodyWidth * 0.15 * (score - 6) * 0.3,
        height: size.height * 0.12 * (score - 6) * 0.3,
      );
      canvas.drawOval(tailRect, fatPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HorseSilhouettePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

/// Compact BCS display for cards
class BodyConditionScoreChip extends StatelessWidget {
  final int score;
  final bool showLabel;

  const BodyConditionScoreChip({
    super.key,
    required this.score,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    final label = _getScoreLabel(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BCS $score',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score <= 2) return AppColors.error;
    if (score <= 3) return const Color(0xFFFF7043);
    if (score == 4) return AppColors.warning;
    if (score == 5) return AppColors.success;
    if (score == 6) return AppColors.warning;
    if (score == 7) return const Color(0xFFFF7043);
    return AppColors.error;
  }

  String _getScoreLabel(int score) {
    if (score <= 2) return 'Tres maigre';
    if (score == 3) return 'Maigre';
    if (score == 4) return 'Mince';
    if (score == 5) return 'Ideal';
    if (score == 6) return 'Dodu';
    if (score == 7) return 'Gras';
    return 'Obese';
  }
}

/// BCS history chart showing scores over time
class BodyConditionHistoryWidget extends ConsumerWidget {
  final String horseId;
  final List<BodyConditionRecord> records;

  const BodyConditionHistoryWidget({
    super.key,
    required this.horseId,
    required this.records,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return _buildEmptyState(context);
    }

    final sortedRecords = [...records]..sort((a, b) => a.date.compareTo(b.date));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique BCS',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: _buildHistoryChart(context, sortedRecords),
            ),
            const SizedBox(height: 12),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryChart(BuildContext context, List<BodyConditionRecord> records) {
    return CustomPaint(
      size: const Size(double.infinity, 150),
      painter: _BCSHistoryChartPainter(
        records: records,
        idealScore: 5,
        primaryColor: Theme.of(context).colorScheme.primary,
        gridColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(context, AppColors.success, 'Ideal (5)'),
        const SizedBox(width: 16),
        _buildLegendItem(context, Theme.of(context).colorScheme.primary, 'Score'),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun score enregistre',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BCSHistoryChartPainter extends CustomPainter {
  final List<BodyConditionRecord> records;
  final int idealScore;
  final Color primaryColor;
  final Color gridColor;

  _BCSHistoryChartPainter({
    required this.records,
    required this.idealScore,
    required this.primaryColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final idealPaint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Draw grid lines
    for (int i = 1; i <= 9; i++) {
      final y = size.height - ((i - 1) / 8 * size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw ideal line
    final idealY = size.height - ((idealScore - 1) / 8 * size.height);
    canvas.drawLine(Offset(0, idealY), Offset(size.width, idealY), idealPaint);

    // Draw data line
    final path = Path();
    for (int i = 0; i < records.length; i++) {
      final x = records.length == 1 ? size.width / 2 : i / (records.length - 1) * size.width;
      final y = size.height - ((records[i].score - 1) / 8 * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw dot
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BCSHistoryChartPainter oldDelegate) {
    return oldDelegate.records != records;
  }
}
