import { format, formatDistance, parseISO } from 'date-fns';
import { fr, enUS, es, de, it, pt, nl, ar, ja, zhCN } from 'date-fns/locale';

const locales = {
  fr,
  en: enUS,
  es,
  de,
  it,
  pt,
  nl,
  ar,
  ja,
  zh: zhCN,
} as const;

type LocaleCode = keyof typeof locales;

/**
 * Formate une date selon la locale
 */
export function formatDate(
  date: Date | string,
  formatStr: string = 'PPP',
  locale: LocaleCode = 'fr'
): string {
  const parsedDate = typeof date === 'string' ? parseISO(date) : date;
  return format(parsedDate, formatStr, { locale: locales[locale] });
}

/**
 * Formate une date relative (ex: "il y a 2 heures")
 */
export function formatRelativeDate(
  date: Date | string,
  locale: LocaleCode = 'fr'
): string {
  const parsedDate = typeof date === 'string' ? parseISO(date) : date;
  return formatDistance(parsedDate, new Date(), {
    addSuffix: true,
    locale: locales[locale],
  });
}

/**
 * Formate un montant en euros
 */
export function formatCurrency(
  amount: number,
  currency: string = 'EUR',
  locale: string = 'fr-FR'
): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
  }).format(amount);
}

/**
 * Formate un pourcentage
 */
export function formatPercentage(
  value: number,
  decimals: number = 1
): string {
  return `${value.toFixed(decimals)}%`;
}

/**
 * Formate une taille de fichier
 */
export function formatFileSize(bytes: number): string {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  let size = bytes;
  let unitIndex = 0;

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }

  return `${size.toFixed(1)} ${units[unitIndex]}`;
}

/**
 * Formate une durée en secondes
 */
export function formatDuration(seconds: number): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  if (hours > 0) {
    return `${hours}h ${minutes}m ${secs}s`;
  }
  if (minutes > 0) {
    return `${minutes}m ${secs}s`;
  }
  return `${secs}s`;
}

/**
 * Tronque un texte avec ellipsis
 */
export function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength - 3)}...`;
}

/**
 * Génère des initiales à partir d'un nom
 */
export function getInitials(name: string): string {
  return name
    .split(' ')
    .map((part) => part.charAt(0).toUpperCase())
    .slice(0, 2)
    .join('');
}
