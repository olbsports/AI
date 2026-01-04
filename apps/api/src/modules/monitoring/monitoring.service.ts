import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PrismaService } from '../../prisma/prisma.service';
import {
  LogQueryDto,
  LogLevel,
  CreateAlertRuleDto,
  AlertSeverity,
  AlertStatus,
  AcknowledgeAlertDto,
} from './dto/monitoring.dto';

export interface SystemHealth {
  status: 'healthy' | 'degraded' | 'unhealthy';
  uptime: number;
  services: {
    database: ServiceStatus;
    redis: ServiceStatus;
    storage: ServiceStatus;
    queue: ServiceStatus;
  };
  metrics: {
    cpuUsage: number;
    memoryUsage: number;
    diskUsage: number;
    activeConnections: number;
  };
}

export interface ServiceStatus {
  status: 'up' | 'down' | 'degraded';
  latency: number;
  lastCheck: Date;
}

export interface LogEntry {
  id: string;
  level: LogLevel;
  message: string;
  context: string;
  metadata: any;
  timestamp: Date;
}

export interface Alert {
  id: string;
  ruleId: string;
  ruleName: string;
  severity: AlertSeverity;
  status: AlertStatus;
  message: string;
  value: number;
  threshold: number;
  createdAt: Date;
  acknowledgedAt?: Date;
  resolvedAt?: Date;
}

@Injectable()
export class MonitoringService {
  private readonly logger = new Logger(MonitoringService.name);
  private readonly startTime = Date.now();

  // In-memory storage for demo (use Redis/DB in production)
  private logs: LogEntry[] = [];
  private alerts: Alert[] = [];
  private alertRules: (CreateAlertRuleDto & { id: string })[] = [];

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    // Initialize some default alert rules
    this.alertRules = [
      {
        id: 'rule-1',
        name: 'High Error Rate',
        metric: 'error_rate',
        operator: 'gt',
        threshold: 5,
        severity: AlertSeverity.HIGH,
        notifications: { email: true },
      },
      {
        id: 'rule-2',
        name: 'Low Token Balance',
        metric: 'token_balance',
        operator: 'lt',
        threshold: 100,
        severity: AlertSeverity.MEDIUM,
        notifications: { email: true },
      },
      {
        id: 'rule-3',
        name: 'Queue Backlog',
        metric: 'queue_size',
        operator: 'gt',
        threshold: 100,
        severity: AlertSeverity.HIGH,
        notifications: { email: true, webhook: true },
      },
    ];
  }

  async getSystemHealth(): Promise<SystemHealth> {
    const [dbStatus, redisStatus, storageStatus, queueStatus] = await Promise.all([
      this.checkDatabase(),
      this.checkRedis(),
      this.checkStorage(),
      this.checkQueue(),
    ]);

    const allUp =
      dbStatus.status === 'up' &&
      redisStatus.status === 'up' &&
      storageStatus.status === 'up' &&
      queueStatus.status === 'up';

    const anyDown =
      dbStatus.status === 'down' ||
      redisStatus.status === 'down' ||
      storageStatus.status === 'down' ||
      queueStatus.status === 'down';

    return {
      status: anyDown ? 'unhealthy' : allUp ? 'healthy' : 'degraded',
      uptime: Date.now() - this.startTime,
      services: {
        database: dbStatus,
        redis: redisStatus,
        storage: storageStatus,
        queue: queueStatus,
      },
      metrics: {
        cpuUsage: Math.random() * 30 + 10, // Mock
        memoryUsage: Math.random() * 40 + 30, // Mock
        diskUsage: Math.random() * 20 + 40, // Mock
        activeConnections: Math.floor(Math.random() * 50 + 10), // Mock
      },
    };
  }

  async getDetailedMetrics(): Promise<{
    requests: { total: number; perMinute: number; errors: number };
    database: { queries: number; avgLatency: number; connections: number };
    queue: { pending: number; processing: number; completed: number; failed: number };
    cache: { hits: number; misses: number; hitRate: number };
  }> {
    // Get real queue stats
    const [pendingAnalyses, processingAnalyses, completedAnalyses, failedAnalyses] =
      await Promise.all([
        this.prisma.analysisSession.count({ where: { status: 'pending' } }),
        this.prisma.analysisSession.count({ where: { status: 'processing' } }),
        this.prisma.analysisSession.count({ where: { status: 'completed' } }),
        this.prisma.analysisSession.count({ where: { status: 'failed' } }),
      ]);

    return {
      requests: {
        total: Math.floor(Math.random() * 10000 + 5000),
        perMinute: Math.floor(Math.random() * 100 + 20),
        errors: Math.floor(Math.random() * 50),
      },
      database: {
        queries: Math.floor(Math.random() * 1000 + 500),
        avgLatency: Math.random() * 10 + 2,
        connections: Math.floor(Math.random() * 20 + 5),
      },
      queue: {
        pending: pendingAnalyses,
        processing: processingAnalyses,
        completed: completedAnalyses,
        failed: failedAnalyses,
      },
      cache: {
        hits: Math.floor(Math.random() * 5000 + 2000),
        misses: Math.floor(Math.random() * 500 + 100),
        hitRate: Math.random() * 20 + 75,
      },
    };
  }

  async getLogs(query: LogQueryDto): Promise<{
    logs: LogEntry[];
    total: number;
    page: number;
    limit: number;
  }> {
    // Get audit logs from database
    const page = query.page || 1;
    const limit = query.limit || 50;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (query.from || query.to) {
      where.createdAt = {};
      if (query.from) where.createdAt.gte = new Date(query.from);
      if (query.to) where.createdAt.lte = new Date(query.to);
    }

    if (query.search) {
      where.action = { contains: query.search, mode: 'insensitive' };
    }

    const [auditLogs, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          organization: { select: { name: true } },
        },
      }),
      this.prisma.auditLog.count({ where }),
    ]);

    const logs: LogEntry[] = auditLogs.map((log) => ({
      id: log.id,
      level: this.mapActionToLevel(log.action),
      message: log.action,
      context: (log.organization as any)?.name || 'System',
      metadata: log.details,
      timestamp: log.createdAt,
    }));

    return { logs, total, page, limit };
  }

  async getAlerts(status?: AlertStatus): Promise<Alert[]> {
    if (status) {
      return this.alerts.filter((a) => a.status === status);
    }
    return this.alerts;
  }

  async createAlertRule(dto: CreateAlertRuleDto): Promise<CreateAlertRuleDto & { id: string }> {
    const rule = {
      ...dto,
      id: `rule-${Date.now()}`,
    };
    this.alertRules.push(rule);
    return rule;
  }

  async getAlertRules(): Promise<(CreateAlertRuleDto & { id: string })[]> {
    return this.alertRules;
  }

  async deleteAlertRule(id: string): Promise<void> {
    const index = this.alertRules.findIndex((r) => r.id === id);
    if (index === -1) {
      throw new NotFoundException('Alert rule not found');
    }
    this.alertRules.splice(index, 1);
  }

  async acknowledgeAlert(id: string, dto: AcknowledgeAlertDto): Promise<Alert> {
    const alert = this.alerts.find((a) => a.id === id);
    if (!alert) {
      throw new NotFoundException('Alert not found');
    }

    alert.status = AlertStatus.ACKNOWLEDGED;
    alert.acknowledgedAt = new Date();

    return alert;
  }

  async resolveAlert(id: string): Promise<Alert> {
    const alert = this.alerts.find((a) => a.id === id);
    if (!alert) {
      throw new NotFoundException('Alert not found');
    }

    alert.status = AlertStatus.RESOLVED;
    alert.resolvedAt = new Date();

    return alert;
  }

  async getErrorReport(days: number = 7): Promise<{
    totalErrors: number;
    byType: Record<string, number>;
    byDay: { date: string; count: number }[];
    recentErrors: { message: string; count: number; lastOccurred: Date }[];
  }> {
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    // Get failed analyses as proxy for errors
    const failedAnalyses = await this.prisma.analysisSession.findMany({
      where: {
        status: 'failed',
        createdAt: { gte: since },
      },
      select: {
        errorMessage: true,
        createdAt: true,
        type: true,
      },
    });

    const byType: Record<string, number> = {};
    const byDay = new Map<string, number>();
    const errorCounts = new Map<string, { count: number; lastOccurred: Date }>();

    failedAnalyses.forEach((a) => {
      // By type
      byType[a.type] = (byType[a.type] || 0) + 1;

      // By day
      const date = a.createdAt.toISOString().split('T')[0];
      byDay.set(date, (byDay.get(date) || 0) + 1);

      // By error message
      const msg = a.errorMessage || 'Unknown error';
      const existing = errorCounts.get(msg);
      if (!existing || a.createdAt > existing.lastOccurred) {
        errorCounts.set(msg, {
          count: (existing?.count || 0) + 1,
          lastOccurred: a.createdAt,
        });
      }
    });

    return {
      totalErrors: failedAnalyses.length,
      byType,
      byDay: Array.from(byDay.entries())
        .map(([date, count]) => ({ date, count }))
        .sort((a, b) => a.date.localeCompare(b.date)),
      recentErrors: Array.from(errorCounts.entries())
        .map(([message, data]) => ({ message, ...data }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 10),
    };
  }

  async getPerformanceReport(): Promise<{
    avgResponseTime: number;
    p95ResponseTime: number;
    p99ResponseTime: number;
    slowestEndpoints: { endpoint: string; avgTime: number }[];
    analysisPerformance: {
      avgProcessingTime: number;
      byType: Record<string, number>;
    };
  }> {
    // Get analysis processing times
    const analyses = await this.prisma.analysisSession.findMany({
      where: {
        status: 'completed',
        processingTimeMs: { not: null },
      },
      select: {
        type: true,
        processingTimeMs: true,
      },
      orderBy: { createdAt: 'desc' },
      take: 1000,
    });

    const times = analyses.map((a) => a.processingTimeMs!).sort((a, b) => a - b);
    const avgTime = times.length > 0 ? times.reduce((a, b) => a + b, 0) / times.length : 0;
    const p95Index = Math.floor(times.length * 0.95);
    const p99Index = Math.floor(times.length * 0.99);

    const byType: Record<string, number[]> = {};
    analyses.forEach((a) => {
      if (!byType[a.type]) byType[a.type] = [];
      byType[a.type].push(a.processingTimeMs!);
    });

    const avgByType: Record<string, number> = {};
    Object.entries(byType).forEach(([type, times]) => {
      avgByType[type] = times.reduce((a, b) => a + b, 0) / times.length;
    });

    return {
      avgResponseTime: Math.random() * 50 + 20, // Mock API response time
      p95ResponseTime: Math.random() * 100 + 50,
      p99ResponseTime: Math.random() * 200 + 100,
      slowestEndpoints: [
        { endpoint: 'POST /analysis', avgTime: 150 },
        { endpoint: 'POST /reports/generate', avgTime: 120 },
        { endpoint: 'GET /exports', avgTime: 80 },
      ],
      analysisPerformance: {
        avgProcessingTime: avgTime,
        byType: avgByType,
      },
    };
  }

  // Private helper methods
  private async checkDatabase(): Promise<ServiceStatus> {
    const start = Date.now();
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return {
        status: 'up',
        latency: Date.now() - start,
        lastCheck: new Date(),
      };
    } catch {
      return {
        status: 'down',
        latency: Date.now() - start,
        lastCheck: new Date(),
      };
    }
  }

  private async checkRedis(): Promise<ServiceStatus> {
    // Mock Redis check (implement with actual Redis client in production)
    return {
      status: 'up',
      latency: Math.random() * 5 + 1,
      lastCheck: new Date(),
    };
  }

  private async checkStorage(): Promise<ServiceStatus> {
    // Mock S3/storage check
    return {
      status: 'up',
      latency: Math.random() * 20 + 5,
      lastCheck: new Date(),
    };
  }

  private async checkQueue(): Promise<ServiceStatus> {
    // Mock queue check
    return {
      status: 'up',
      latency: Math.random() * 10 + 2,
      lastCheck: new Date(),
    };
  }

  private mapActionToLevel(action: string): LogLevel {
    if (action.includes('error') || action.includes('failed')) return LogLevel.ERROR;
    if (action.includes('warn')) return LogLevel.WARN;
    if (action.includes('debug')) return LogLevel.DEBUG;
    return LogLevel.INFO;
  }
}
