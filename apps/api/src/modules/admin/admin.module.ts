import { Module } from '@nestjs/common';

import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';
import { DashboardController } from './dashboard.controller';
import { ModerationController } from './moderation.controller';
import { SupportController } from './support.controller';
import { UsersAdminController } from './users-admin.controller';
import { SubscriptionsAdminController } from './subscriptions-admin.controller';
import { SettingsAdminController } from './settings-admin.controller';
import { AnalyticsAdminController } from './analytics-admin.controller';
import { AuditLogsController } from './audit-logs.controller';

@Module({
  controllers: [
    AdminController,
    DashboardController,
    ModerationController,
    SupportController,
    UsersAdminController,
    SubscriptionsAdminController,
    SettingsAdminController,
    AnalyticsAdminController,
    AuditLogsController,
  ],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
