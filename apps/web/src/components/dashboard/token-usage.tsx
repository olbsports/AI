'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@horse-tempo/ui';
import { Progress } from '@horse-tempo/ui';
import { Coins } from 'lucide-react';

interface TokenUsageProps {
  balance: number;
  used: number;
  limit: number;
  loading?: boolean;
}

export function TokenUsage({ balance, used, limit, loading = false }: TokenUsageProps) {
  const usagePercent = limit > 0 ? (used / limit) * 100 : 0;
  const isLow = balance < limit * 0.2;

  if (loading) {
    return (
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Tokens</CardTitle>
          <Coins className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            <div className="h-8 w-20 animate-pulse rounded bg-muted" />
            <div className="h-2 w-full animate-pulse rounded bg-muted" />
            <div className="h-4 w-32 animate-pulse rounded bg-muted" />
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">Tokens</CardTitle>
        <Coins className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{balance.toLocaleString()}</div>
        <div className="mt-3 space-y-2">
          <Progress value={usagePercent} className="h-2" />
          <div className="flex justify-between text-xs text-muted-foreground">
            <span>{used.toLocaleString()} utilisés ce mois</span>
            <span>{limit.toLocaleString()} alloués</span>
          </div>
        </div>
        {isLow && (
          <p className="mt-2 text-xs text-orange-600">
            ⚠️ Solde faible - Pensez à recharger
          </p>
        )}
      </CardContent>
    </Card>
  );
}
