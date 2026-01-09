import { Controller, Get, Post, Delete, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import {
  RegisterPushTokenDto,
  UnregisterPushTokenDto,
  UpdatePreferencesDto,
} from './dto/push-notification.dto';

@ApiTags('notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all notifications' })
  async getNotifications(
    @CurrentUser() user: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string
  ) {
    return this.notificationsService.getNotifications(
      user.id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20
    );
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get unread notification count' })
  async getUnreadCount(@CurrentUser() user: any) {
    return this.notificationsService.getUnreadCount(user.id);
  }

  @Post('mark-read')
  @ApiOperation({ summary: 'Mark notifications as read' })
  async markAsRead(@CurrentUser() user: any, @Body() body: { ids: string[] }) {
    return this.notificationsService.markManyAsRead(body.ids, user.id);
  }

  @Post('mark-all-read')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  async markAllAsRead(@CurrentUser() user: any) {
    return this.notificationsService.markAllAsRead(user.id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a notification' })
  async deleteNotification(@CurrentUser() user: any, @Param('id') id: string) {
    return this.notificationsService.deleteNotification(id, user.id);
  }

  // ==================== PUSH SUBSCRIPTIONS ====================

  @Get('push/subscriptions')
  @ApiOperation({ summary: 'Get all push subscriptions for current user' })
  async getPushSubscriptions(@CurrentUser() user: any) {
    return this.notificationsService.getPushSubscriptions(user.id);
  }

  @Post('push/register')
  @ApiOperation({ summary: 'Register a push notification token' })
  async registerPushToken(@CurrentUser() user: any, @Body() dto: RegisterPushTokenDto) {
    return this.notificationsService.registerPushToken(user.id, {
      token: dto.token,
      platform: dto.platform,
      deviceId: dto.deviceId,
      deviceName: dto.deviceName,
      appVersion: dto.appVersion,
    });
  }

  @Delete('push/unregister')
  @ApiOperation({ summary: 'Unregister a push notification token' })
  async unregisterPushToken(@CurrentUser() user: any, @Body() dto: UnregisterPushTokenDto) {
    return this.notificationsService.unregisterPushToken(user.id, dto.deviceId);
  }

  // ==================== NOTIFICATION PREFERENCES ====================

  @Get('preferences')
  @ApiOperation({ summary: 'Get notification preferences' })
  async getPreferences(@CurrentUser() user: any) {
    return this.notificationsService.getPreferences(user.id);
  }

  @Patch('preferences')
  @ApiOperation({ summary: 'Update notification preferences' })
  async updatePreferences(@CurrentUser() user: any, @Body() dto: UpdatePreferencesDto) {
    return this.notificationsService.updatePreferences(user.id, dto);
  }
}
