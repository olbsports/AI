import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import { notFound } from 'next/navigation';
import { NextIntlClientProvider } from 'next-intl';
import { getMessages } from 'next-intl/server';

import '../globals.css';
import { Providers } from '@/components/providers';
import { SUPPORTED_LOCALES } from '@horse-tempo/config';

const inter = Inter({ subsets: ['latin'], variable: '--font-inter' });

export const metadata: Metadata = {
  title: 'Horse Tempo',
  description: 'Plateforme d\'analyse équestre et vétérinaire par intelligence artificielle',
};

interface RootLayoutProps {
  children: React.ReactNode;
  params: { locale: string };
}

export function generateStaticParams() {
  return SUPPORTED_LOCALES.map((locale) => ({ locale }));
}

export default async function RootLayout({
  children,
  params: { locale },
}: RootLayoutProps) {
  if (!SUPPORTED_LOCALES.includes(locale as typeof SUPPORTED_LOCALES[number])) {
    notFound();
  }

  const messages = await getMessages();

  return (
    <html lang={locale} suppressHydrationWarning>
      <body className={inter.variable}>
        <NextIntlClientProvider messages={messages}>
          <Providers>{children}</Providers>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
