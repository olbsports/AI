import { getRequestConfig } from 'next-intl/server';
import { notFound } from 'next/navigation';

import { SUPPORTED_LOCALES } from '@horse-tempo/config';

export default getRequestConfig(async ({ locale }) => {
  if (!SUPPORTED_LOCALES.includes(locale as typeof SUPPORTED_LOCALES[number])) {
    notFound();
  }

  return {
    messages: (await import(`./messages/${locale}.json`)).default,
  };
});
