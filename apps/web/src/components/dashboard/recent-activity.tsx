'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@horse-vision/ui';
import { Activity, FileText, User, CreditCard } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { fr } from 'date-fns/locale';

interface ActivityItem {
  id: string;
  type: 'analysis' | 'report' | 'user' | 'payment';
  title: string;
  description: string;
  timestamp: Date;
}

interface RecentActivityProps {
  activities: ActivityItem[];
  loading?: boolean;
}

const iconMap = {
  analysis: Activity,
  report: FileText,
  user: User,
  payment: CreditCard,
};

const colorMap = {
  analysis: 'text-blue-600 bg-blue-100',
  report: 'text-green-600 bg-green-100',
  user: 'text-purple-600 bg-purple-100',
  payment: 'text-orange-600 bg-orange-100',
};

export function RecentActivity({ activities, loading = false }: RecentActivityProps) {
  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Activité récente</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="flex items-center gap-4">
                <div className="h-10 w-10 animate-pulse rounded-full bg-muted" />
                <div className="flex-1 space-y-2">
                  <div className="h-4 w-3/4 animate-pulse rounded bg-muted" />
                  <div className="h-3 w-1/2 animate-pulse rounded bg-muted" />
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Activité récente</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {activities.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-4">
              Aucune activité récente
            </p>
          ) : (
            activities.map((activity) => {
              const Icon = iconMap[activity.type];
              return (
                <div key={activity.id} className="flex items-center gap-4">
                  <div className={`p-2 rounded-full ${colorMap[activity.type]}`}>
                    <Icon className="h-4 w-4" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{activity.title}</p>
                    <p className="text-xs text-muted-foreground truncate">
                      {activity.description}
                    </p>
                  </div>
                  <span className="text-xs text-muted-foreground whitespace-nowrap">
                    {formatDistanceToNow(activity.timestamp, { addSuffix: true, locale: fr })}
                  </span>
                </div>
              );
            })
          )}
        </div>
      </CardContent>
    </Card>
  );
}
