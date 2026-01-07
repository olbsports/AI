/**
 * Constantes globales de l'application Horse Tempo
 */

// =============================================================================
// APPLICATION
// =============================================================================

export const APP_NAME = 'Horse Tempo';
export const APP_DESCRIPTION = "Plateforme d'analyse équestre par intelligence artificielle";
export const APP_VERSION = '0.1.0';

// =============================================================================
// PLANS & TOKENS
// =============================================================================

export const PLANS = {
  FREE: 'free',
  STARTER: 'starter',
  RIDER: 'rider',
  CHAMPION: 'champion',
  PRO: 'pro',
  ELITE: 'elite',
  ENTERPRISE: 'enterprise',
} as const;

export type Plan = (typeof PLANS)[keyof typeof PLANS];

export const PLAN_LIMITS: Record<Plan, { analyses: number; horses: number; users: number; tokens: number }> = {
  free: { analyses: 3, horses: 1, users: 1, tokens: 0 },
  starter: { analyses: 15, horses: 3, users: 1, tokens: 50 },
  rider: { analyses: 50, horses: 10, users: 2, tokens: 150 },
  champion: { analyses: 150, horses: 25, users: 5, tokens: 500 },
  pro: { analyses: -1, horses: 50, users: 10, tokens: 1500 }, // -1 = illimité
  elite: { analyses: -1, horses: -1, users: -1, tokens: 5000 },
  enterprise: { analyses: -1, horses: -1, users: -1, tokens: -1 },
};

export const PLAN_DETAILS: Record<Plan, { monthlyPrice: number; features: string[] }> = {
  free: {
    monthlyPrice: 0,
    features: ['3 analyses/mois', '1 cheval', 'Support email'],
  },
  starter: {
    monthlyPrice: 19,
    features: ['15 analyses/mois', '3 chevaux', '50 tokens inclus', 'Support email'],
  },
  rider: {
    monthlyPrice: 39,
    features: ['50 analyses/mois', '10 chevaux', '150 tokens inclus', '2 membres', 'Support prioritaire'],
  },
  champion: {
    monthlyPrice: 79,
    features: ['150 analyses/mois', '25 chevaux', '500 tokens inclus', '5 membres', 'Support prioritaire'],
  },
  pro: {
    monthlyPrice: 149,
    features: ['Analyses illimitées', '50 chevaux', '1500 tokens inclus', '10 membres', 'Accès API', 'Support dédié'],
  },
  elite: {
    monthlyPrice: 299,
    features: ['Tout illimité', '5000 tokens inclus', 'Accès API avancé', 'Support VIP', 'Formation incluse'],
  },
  enterprise: {
    monthlyPrice: -1,
    features: ['Tout illimité', 'Tokens sur mesure', 'API dédiée', 'Support 24/7', 'SLA garanti'],
  },
};

// =============================================================================
// TOKENS - Coût par type d'analyse
// =============================================================================

export const TOKEN_COSTS = {
  // Analyse vidéo
  VIDEO_BASIC: 50, // 30s, niveau débutant
  VIDEO_STANDARD: 100, // 1-2min
  VIDEO_PARCOURS: 150, // Parcours complet
  VIDEO_ADVANCED: 250, // Analyse détaillée

  // Rapports radiologiques
  RADIO_STANDARD: 200,
  RADIO_COMPLETE: 300,
  RADIO_CERTIFIED: 500, // Rapport commercial

  // Services premium
  ESTIMATION_VALUE: 800, // Estimation valeur marchande
  EXPERT_REVIEW: 1000, // Avis expert humain

  // Aliases pour l'interface utilisateur
  COURSE_ANALYSIS: 150, // = VIDEO_PARCOURS
  VIDEO_ANALYSIS: 100, // = VIDEO_STANDARD
  RADIO_ANALYSIS: 200, // = RADIO_STANDARD
  LOCOMOTION_ANALYSIS: 250, // = VIDEO_ADVANCED
} as const;

// =============================================================================
// ANALYSE - Types et statuts
// =============================================================================

export const ANALYSIS_TYPES = {
  VIDEO_PERFORMANCE: 'video_performance',
  VIDEO_COURSE: 'video_course',
  RADIOLOGICAL: 'radiological',
  LOCOMOTION: 'locomotion',
} as const;

export type AnalysisType = (typeof ANALYSIS_TYPES)[keyof typeof ANALYSIS_TYPES];

export const ANALYSIS_STATUS = {
  PENDING: 'pending',
  PROCESSING: 'processing',
  COMPLETED: 'completed',
  FAILED: 'failed',
  CANCELLED: 'cancelled',
} as const;

export type AnalysisStatus = (typeof ANALYSIS_STATUS)[keyof typeof ANALYSIS_STATUS];

// =============================================================================
// RAPPORTS - Catégories radiologiques
// =============================================================================

export const RADIO_CATEGORIES = {
  A: { label: 'A', description: 'Compatible usage sportif', color: 'green' },
  'A-': { label: 'A-', description: 'Compatible usage sportif (mineur)', color: 'green' },
  'B+': { label: 'B+', description: 'Points attention mineurs', color: 'yellow' },
  B: { label: 'B', description: 'Dossier incomplet', color: 'orange' },
  'B-': { label: 'B-', description: 'Points attention modérés', color: 'orange' },
  C: { label: 'C', description: 'Anomalies significatives', color: 'red' },
  D: { label: 'D', description: 'Non compatible usage sportif', color: 'red' },
} as const;

export type RadioCategory = keyof typeof RADIO_CATEGORIES;

// =============================================================================
// CHEVAL - Données de référence
// =============================================================================

export const HORSE_GENDERS = {
  MALE: 'male',
  FEMALE: 'female',
  GELDING: 'gelding',
} as const;

export const HORSE_COLORS = [
  'bay', // Bai
  'dark_bay', // Bai brun
  'chestnut', // Alezan
  'black', // Noir
  'gray', // Gris
  'palomino', // Palomino
  'buckskin', // Isabelle
  'roan', // Rouan
  'pinto', // Pie
  'appaloosa', // Appaloosa
  'other', // Autre
] as const;

export const HORSE_BREEDS = [
  'SF', // Selle Français
  'KWPN', // Hollandais
  'BWP', // Belge
  'Hanovrien',
  'Oldenbourg',
  'Holsteiner',
  'Westphalien',
  'Anglo-Arabe',
  'Pur-Sang',
  'Trotteur',
  'Irish Sport Horse',
  'Zangersheide',
  'Autre',
] as const;

// =============================================================================
// OBSTACLES - Types
// =============================================================================

export const OBSTACLE_TYPES = {
  VERTICAL: 'vertical',
  OXER: 'oxer',
  TRIPLE_BAR: 'triple_bar',
  COMBINATION: 'combination',
  WATER: 'water',
  LIVERPOOL: 'liverpool',
  WALL: 'wall',
} as const;

export type ObstacleType = (typeof OBSTACLE_TYPES)[keyof typeof OBSTACLE_TYPES];

// =============================================================================
// LIMITES FICHIERS
// =============================================================================

export const FILE_LIMITS = {
  MAX_VIDEO_SIZE_MB: 500,
  MAX_IMAGE_SIZE_MB: 50,
  MAX_DOCUMENT_SIZE_MB: 20,
  ALLOWED_VIDEO_TYPES: ['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm'],
  ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/png', 'image/webp', 'image/dicom'],
  ALLOWED_DOCUMENT_TYPES: ['application/pdf'],
} as const;

// =============================================================================
// LANGUES SUPPORTÉES
// =============================================================================

export const LOCALES = [
  'fr-FR',
  'en-GB',
  'en-US',
  'es-ES',
  'de-DE',
  'nl-NL',
  'it-IT',
  'pt-PT',
  'ar-SA',
] as const;

// Simplified locales for next-intl (fr, en, etc.)
export const SUPPORTED_LOCALES = ['fr', 'en'] as const;

export type Locale = (typeof LOCALES)[number];
export type SupportedLocale = (typeof SUPPORTED_LOCALES)[number];

export const DEFAULT_LOCALE: SupportedLocale = 'fr';

export const RTL_LOCALES: Locale[] = ['ar-SA'];
