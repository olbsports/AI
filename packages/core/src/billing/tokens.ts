import { TOKEN_COSTS, PLAN_LIMITS, type Plan } from '@horse-tempo/config';
import type { AnalysisType } from '@horse-tempo/types';

/**
 * Calcule le coût en tokens pour une analyse
 */
export function calculateTokenCost(analysisType: AnalysisType): number {
  switch (analysisType) {
    case 'video_performance':
      return TOKEN_COSTS.VIDEO_STANDARD;
    case 'video_course':
      return TOKEN_COSTS.VIDEO_PARCOURS;
    case 'radiological':
      return TOKEN_COSTS.RADIO_STANDARD;
    case 'locomotion':
      return TOKEN_COSTS.VIDEO_ADVANCED;
    default:
      return TOKEN_COSTS.VIDEO_STANDARD;
  }
}

/**
 * Vérifie si l'organisation a assez de tokens
 */
export function hasEnoughTokens(
  currentBalance: number,
  analysisType: AnalysisType
): boolean {
  return currentBalance >= calculateTokenCost(analysisType);
}

/**
 * Calcule le nouveau solde après une analyse
 */
export function calculateNewBalance(
  currentBalance: number,
  analysisType: AnalysisType
): number {
  return Math.max(0, currentBalance - calculateTokenCost(analysisType));
}

/**
 * Récupère les limites du plan
 */
export function getPlanLimits(plan: Plan) {
  return PLAN_LIMITS[plan];
}

/**
 * Vérifie si le plan permet une fonctionnalité
 */
export function planHasFeature(
  plan: Plan,
  feature: keyof (typeof PLAN_LIMITS)[Plan]
): boolean {
  const limits = PLAN_LIMITS[plan];
  const value = limits[feature];

  if (typeof value === 'boolean') {
    return value;
  }

  if (typeof value === 'number') {
    return value > 0 || value === -1; // -1 = illimité
  }

  return false;
}

/**
 * Calcule le prix en euros pour un nombre de tokens
 */
export function calculateTokenPrice(tokenCount: number): number {
  // Prix dégressif
  if (tokenCount >= 1000) {
    return tokenCount * 0.08; // 0.08€/token pour 1000+
  } else if (tokenCount >= 500) {
    return tokenCount * 0.09; // 0.09€/token pour 500+
  } else if (tokenCount >= 100) {
    return tokenCount * 0.10; // 0.10€/token pour 100+
  }
  return tokenCount * 0.12; // 0.12€/token par défaut
}

/**
 * Formatte le solde de tokens
 */
export function formatTokenBalance(balance: number): string {
  if (balance >= 1000) {
    return `${(balance / 1000).toFixed(1)}k`;
  }
  return balance.toString();
}
