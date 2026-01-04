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
  ],
})
export class AppModule {}
