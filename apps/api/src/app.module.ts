import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';

import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { HorsesModule } from './modules/horses/horses.module';
import { AnalysisModule } from './modules/analysis/analysis.module';
import { ReportsModule } from './modules/reports/reports.module';
import { HealthModule } from './modules/health/health.module';
import { EmailModule } from './modules/email/email.module';
import { InvitationsModule } from './modules/invitations/invitations.module';
import { UploadModule } from './modules/upload/upload.module';
import { RidersModule } from './modules/riders/riders.module';
import { QueueModule } from './modules/queue/queue.module';
import { BillingModule } from './modules/billing/billing.module';
import { TokensModule } from './modules/tokens/tokens.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { InvoicesModule } from './modules/invoices/invoices.module';
import { AdminModule } from './modules/admin/admin.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { ExportsModule } from './modules/exports/exports.module';
import { MonitoringModule } from './modules/monitoring/monitoring.module';

// New social/mobile modules
import { SocialModule } from './modules/social/social.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { ClubsModule } from './modules/clubs/clubs.module';
import { MarketplaceModule } from './modules/marketplace/marketplace.module';
import { LeaderboardModule } from './modules/leaderboard/leaderboard.module';

// Calendar, Dashboard, Gamification, Services
import { CalendarModule } from './modules/calendar/calendar.module';
import { DashboardModule } from './modules/dashboard/dashboard.module';
import { GamificationModule } from './modules/gamification/gamification.module';
import { ServicesModule } from './modules/services/services.module';

// Gestation/Breeding
import { GestationModule } from './modules/gestation/gestation.module';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),

    // Rate limiting
    ThrottlerModule.forRoot([
      {
        ttl: 60000, // 1 minute
        limit: 100, // 100 requests per minute
      },
    ]),

    // Database
    PrismaModule,

    // Core modules
    EmailModule,

    // Feature modules
    AuthModule,
    UsersModule,
    HorsesModule,
    RidersModule,
    AnalysisModule,
    ReportsModule,
    HealthModule,
    InvitationsModule,
    UploadModule,
    QueueModule,

    // Billing modules
    BillingModule,
    TokensModule,
    SubscriptionsModule,
    InvoicesModule,

    // Admin & Monitoring modules
    AdminModule,
    AnalyticsModule,
    ExportsModule,
    MonitoringModule,

    // Social & Mobile modules
    SocialModule,
    NotificationsModule,
    ClubsModule,
    MarketplaceModule,
    LeaderboardModule,

    // Calendar, Dashboard, Gamification, Services
    CalendarModule,
    DashboardModule,
    GamificationModule,
    ServicesModule,

    // Gestation/Breeding
    GestationModule,
  ],
})
export class AppModule {}
