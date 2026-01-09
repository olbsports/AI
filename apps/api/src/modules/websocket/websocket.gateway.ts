import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

// Extended Socket type with user info
type AuthenticatedSocket = Socket & {
  userId?: string;
  organizationId?: string;
};

// ==================== WEBSOCKET EVENTS ====================

export enum WsEvents {
  // Connection
  CONNECTION = 'connection',
  DISCONNECT = 'disconnect',
  AUTHENTICATED = 'authenticated',
  AUTH_ERROR = 'auth_error',

  // Notifications
  NOTIFICATION = 'notification',
  NOTIFICATION_COUNT = 'notification_count',

  // Analysis
  ANALYSIS_STARTED = 'analysis_started',
  ANALYSIS_PROGRESS = 'analysis_progress',
  ANALYSIS_COMPLETED = 'analysis_completed',
  ANALYSIS_FAILED = 'analysis_failed',

  // Token Balance
  TOKEN_BALANCE_UPDATED = 'token_balance_updated',
  TOKEN_LOW = 'token_low',

  // Social
  NEW_FOLLOWER = 'new_follower',
  NEW_LIKE = 'new_like',
  NEW_COMMENT = 'new_comment',

  // Messaging
  NEW_MESSAGE = 'new_message',
  MESSAGE_READ = 'message_read',
  TYPING = 'typing',

  // Horse Updates
  HORSE_UPDATED = 'horse_updated',
  HEALTH_REMINDER = 'health_reminder',

  // System
  SYSTEM_MESSAGE = 'system_message',
  MAINTENANCE = 'maintenance',
}

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
  namespace: '/',
  transports: ['websocket', 'polling'],
})
export class AppWebSocketGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(AppWebSocketGateway.name);
  private connectedUsers: Map<string, Set<string>> = new Map(); // userId -> Set<socketId>

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService
  ) {}

  afterInit(server: Server) {
    this.logger.log('WebSocket Gateway initialized');
  }

  async handleConnection(client: AuthenticatedSocket) {
    try {
      // Extract token from handshake
      const token =
        client.handshake.auth?.token ||
        client.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        client.emit(WsEvents.AUTH_ERROR, { message: 'No token provided' });
        client.disconnect();
        return;
      }

      // Verify JWT token
      const payload = await this.jwtService.verifyAsync(token, {
        secret: this.configService.get<string>('JWT_SECRET'),
      });

      // Store user info on socket
      client.userId = payload.sub;
      client.organizationId = payload.organizationId;

      // Track connected user
      if (!this.connectedUsers.has(client.userId)) {
        this.connectedUsers.set(client.userId, new Set());
      }
      this.connectedUsers.get(client.userId)!.add(client.id);

      // Join user-specific room
      client.join(`user:${client.userId}`);

      // Join organization room
      if (client.organizationId) {
        client.join(`org:${client.organizationId}`);
      }

      client.emit(WsEvents.AUTHENTICATED, {
        userId: client.userId,
        organizationId: client.organizationId,
      });

      this.logger.debug(`Client connected: ${client.id} (user: ${client.userId})`);
    } catch (error) {
      this.logger.error(`Connection error: ${error.message}`);
      client.emit(WsEvents.AUTH_ERROR, { message: 'Invalid token' });
      client.disconnect();
    }
  }

  handleDisconnect(client: AuthenticatedSocket) {
    if (client.userId) {
      const userSockets = this.connectedUsers.get(client.userId);
      if (userSockets) {
        userSockets.delete(client.id);
        if (userSockets.size === 0) {
          this.connectedUsers.delete(client.userId);
        }
      }
    }
    this.logger.debug(`Client disconnected: ${client.id}`);
  }

  // ==================== SUBSCRIPTION HANDLERS ====================

  @SubscribeMessage('subscribe_analysis')
  handleSubscribeAnalysis(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { analysisId: string }
  ) {
    client.join(`analysis:${data.analysisId}`);
    return { subscribed: true, analysisId: data.analysisId };
  }

  @SubscribeMessage('unsubscribe_analysis')
  handleUnsubscribeAnalysis(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { analysisId: string }
  ) {
    client.leave(`analysis:${data.analysisId}`);
    return { unsubscribed: true, analysisId: data.analysisId };
  }

  @SubscribeMessage('subscribe_horse')
  handleSubscribeHorse(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { horseId: string }
  ) {
    client.join(`horse:${data.horseId}`);
    return { subscribed: true, horseId: data.horseId };
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { conversationId: string; isTyping: boolean }
  ) {
    // Broadcast typing status to conversation participants
    client.to(`conversation:${data.conversationId}`).emit(WsEvents.TYPING, {
      userId: client.userId,
      conversationId: data.conversationId,
      isTyping: data.isTyping,
    });
  }

  // ==================== EMIT METHODS ====================

  emitToUser(userId: string, event: WsEvents, data: any) {
    this.server.to(`user:${userId}`).emit(event, data);
  }

  emitToOrganization(organizationId: string, event: WsEvents, data: any) {
    this.server.to(`org:${organizationId}`).emit(event, data);
  }

  emitToAnalysis(analysisId: string, event: WsEvents, data: any) {
    this.server.to(`analysis:${analysisId}`).emit(event, data);
  }

  emitToHorse(horseId: string, event: WsEvents, data: any) {
    this.server.to(`horse:${horseId}`).emit(event, data);
  }

  emitToAll(event: WsEvents, data: any) {
    this.server.emit(event, data);
  }

  // ==================== NOTIFICATION HELPERS ====================

  sendNotification(userId: string, notification: any) {
    this.emitToUser(userId, WsEvents.NOTIFICATION, notification);
  }

  sendAnalysisProgress(analysisId: string, progress: { percent: number; stage: string }) {
    this.emitToAnalysis(analysisId, WsEvents.ANALYSIS_PROGRESS, progress);
  }

  sendAnalysisCompleted(analysisId: string, userId: string, result: any) {
    this.emitToAnalysis(analysisId, WsEvents.ANALYSIS_COMPLETED, result);
    this.emitToUser(userId, WsEvents.ANALYSIS_COMPLETED, { analysisId, ...result });
  }

  sendAnalysisFailed(analysisId: string, userId: string, error: any) {
    this.emitToAnalysis(analysisId, WsEvents.ANALYSIS_FAILED, error);
    this.emitToUser(userId, WsEvents.ANALYSIS_FAILED, { analysisId, ...error });
  }

  sendTokenBalanceUpdate(
    userId: string,
    balance: { total: number; included: number; purchased: number }
  ) {
    this.emitToUser(userId, WsEvents.TOKEN_BALANCE_UPDATED, balance);
  }

  sendTokenLowAlert(userId: string, remaining: number) {
    this.emitToUser(userId, WsEvents.TOKEN_LOW, { remaining });
  }

  // ==================== UTILITY METHODS ====================

  isUserOnline(userId: string): boolean {
    return this.connectedUsers.has(userId);
  }

  getOnlineUserCount(): number {
    return this.connectedUsers.size;
  }

  getConnectedSocketCount(): number {
    let count = 0;
    this.connectedUsers.forEach((sockets) => (count += sockets.size));
    return count;
  }
}
