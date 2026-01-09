import { Module } from '@nestjs/common';
import { CalendarController } from './calendar.controller';
import { CalendarService } from './calendar.service';
import { ReminderService } from './reminder.service';

@Module({
  controllers: [CalendarController],
  providers: [
    CalendarService,
    ReminderService,
  ],
  exports: [
    CalendarService,
    ReminderService,
  ],
})
export class CalendarModule {}
