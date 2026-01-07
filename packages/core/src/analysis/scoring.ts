import { RADIO_CATEGORIES } from '@horse-tempo/config';

/**
 * Calcule le score global à partir des scores individuels
 */
export function calculateGlobalScore(scores: {
  horse?: number;
  rider?: number;
  harmony?: number;
  technique?: number;
}): number {
  const validScores = Object.values(scores).filter(
    (s): s is number => typeof s === 'number'
  );

  if (validScores.length === 0) return 0;

  const sum = validScores.reduce((acc, score) => acc + score, 0);
  return Math.round((sum / validScores.length) * 10) / 10;
}

/**
 * Calcule la catégorie radiologique à partir du score
 */
export function calculateRadioCategory(
  score: number
): keyof typeof RADIO_CATEGORIES {
  if (score >= 9) return 'A';
  if (score >= 8) return 'A-';
  if (score >= 7) return 'B+';
  if (score >= 6) return 'B';
  if (score >= 5) return 'B-';
  if (score >= 4) return 'C';
  return 'D';
}

/**
 * Récupère la description d'une catégorie
 */
export function getCategoryDescription(
  category: keyof typeof RADIO_CATEGORIES
): string {
  return RADIO_CATEGORIES[category].description;
}

/**
 * Récupère la couleur associée à une catégorie
 */
export function getCategoryColor(
  category: keyof typeof RADIO_CATEGORIES
): string {
  return RADIO_CATEGORIES[category].color;
}

/**
 * Détermine la sévérité d'un problème
 */
export function determineSeverity(
  score: number
): 'low' | 'medium' | 'high' | 'critical' {
  if (score >= 8) return 'low';
  if (score >= 6) return 'medium';
  if (score >= 4) return 'high';
  return 'critical';
}

/**
 * Formate un score pour l'affichage
 */
export function formatScore(score: number): string {
  return score.toFixed(1);
}

/**
 * Calcule la progression entre deux scores
 */
export function calculateProgression(
  previousScore: number,
  currentScore: number
): {
  difference: number;
  percentage: number;
  trend: 'up' | 'down' | 'stable';
} {
  const difference = currentScore - previousScore;
  const percentage =
    previousScore > 0 ? (difference / previousScore) * 100 : 0;

  let trend: 'up' | 'down' | 'stable' = 'stable';
  if (difference > 0.5) trend = 'up';
  else if (difference < -0.5) trend = 'down';

  return {
    difference: Math.round(difference * 10) / 10,
    percentage: Math.round(percentage * 10) / 10,
    trend,
  };
}
