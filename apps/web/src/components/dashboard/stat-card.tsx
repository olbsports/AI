'use client';

import { Card, CardContent, CardHeader, CardTitle, cn } from '@horse-tempo/ui';
import { ArrowDown, ArrowUp, Minus } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string | number;
  description?: string;
  change?: number;
  changeLabel?: string;
  icon?: React.ReactNode;
  loading?: boolean;
}

export function StatCard({
  title,
  value,
  description,
  change,
  changeLabel = 'vs période précédente',
  icon,
  loading = false,
}: StatCardProps) {
  const isPositive = change && change > 0;
  const isNegative = change && change < 0;

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        {icon && <div className="text-muted-foreground">{icon}</div>}
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="space-y-2">
            <div className="h-8 w-24 animate-pulse rounded bg-muted" />
            <div className="h-4 w-32 animate-pulse rounded bg-muted" />
          </div>
        ) : (
          <>
            <div className="text-2xl font-bold">{value}</div>
            {(description || change !== undefined) && (
              <div className="flex items-center gap-2 mt-1">
                {change !== undefined && (
                  <span
                    className={cn(
                      'flex items-center text-xs font-medium',
                      isPositive && 'text-green-600',
                      isNegative && 'text-red-600',
                      !isPositive && !isNegative && 'text-muted-foreground'
                    )}
                  >
                    {isPositive ? (
                      <ArrowUp className="h-3 w-3 mr-0.5" />
                    ) : isNegative ? (
                      <ArrowDown className="h-3 w-3 mr-0.5" />
                    ) : (
                      <Minus className="h-3 w-3 mr-0.5" />
                    )}
                    {Math.abs(change).toFixed(1)}%
                  </span>
                )}
                <span className="text-xs text-muted-foreground">
                  {description || changeLabel}
                </span>
              </div>
            )}
          </>
        )}
      </CardContent>
    </Card>
  );
}
