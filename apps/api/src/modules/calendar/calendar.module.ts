import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { CalendarController } from './calendar.controller';
import { CalendarService } from './calendar.service';
import { ReminderService } from './reminder.service';
import { HealthReminderService } from './health-reminder.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    NotificationsModule,
  ],
  controllers: [CalendarController],
  providers: [
    CalendarService,
    ReminderService,
    HealthReminderService,
  ],
  exports: [
    CalendarService,
    ReminderService,
    HealthReminderService,
  ],
})
export class CalendarModule {}
