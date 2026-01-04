import { useTranslations } from 'next-intl';
import Link from 'next/link';

import { Button } from '@horse-vision/ui';

export default function HomePage() {
  const t = useTranslations('home');

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="text-center space-y-8">
        <h1 className="text-5xl font-bold tracking-tight">
          <span className="text-primary">Horse Vision</span> AI
        </h1>

        <p className="text-xl text-muted-foreground max-w-2xl">
          {t('subtitle')}
        </p>

        <div className="flex gap-4 justify-center">
          <Button asChild size="lg">
            <Link href="/auth/login">{t('login')}</Link>
          </Button>
          <Button asChild variant="outline" size="lg">
            <Link href="/auth/register">{t('register')}</Link>
          </Button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-16 max-w-4xl">
          <FeatureCard
            title={t('features.analysis.title')}
            description={t('features.analysis.description')}
            icon="🎯"
          />
          <FeatureCard
            title={t('features.radio.title')}
            description={t('features.radio.description')}
            icon="🩺"
          />
          <FeatureCard
            title={t('features.reports.title')}
            description={t('features.reports.description')}
            icon="📊"
          />
        </div>
      </div>
    </main>
  );
}

function FeatureCard({
  title,
  description,
  icon,
}: {
  title: string;
  description: string;
  icon: string;
}) {
  return (
    <div className="rounded-lg border bg-card p-6 text-left">
      <div className="text-4xl mb-4">{icon}</div>
      <h3 className="font-semibold text-lg mb-2">{title}</h3>
      <p className="text-sm text-muted-foreground">{description}</p>
    </div>
  );
}
