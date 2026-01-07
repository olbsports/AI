import createMiddleware from 'next-intl/middleware';

import { SUPPORTED_LOCALES, DEFAULT_LOCALE } from '@horse-tempo/config';

export default createMiddleware({
  locales: SUPPORTED_LOCALES,
  defaultLocale: DEFAULT_LOCALE,
});

export const config = {
  matcher: ['/', '/(fr|en|es|de|it|pt|nl|ar|ja|zh)/:path*'],
};
