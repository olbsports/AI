import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue, Job, JobOptions } from 'bull';
import { QUEUE_NAMES } from './queue.constants';

export interface AnalysisJobData {
  analysisId: string;
  organizationId: string;
  type: string;
  inputMediaUrls: string[];
  metadata?: Record<string, any>;
}

export interface ReportJobData {
  reportId: string;
  analysisId: string;
  organizationId: string;
  type: 'html' | 'pdf' | 'both';
}

export interface NotificationJobData {
  type: 'email' | 'push' | 'webhook';
  userId?: string;
  organizationId?: string;
  template: string;
  data: Record<string, any>;
}

@Injectable()
export class QueueService {
  private readonly logger = new Logger(QueueService.name);

  constructor(
    @InjectQueue(QUEUE_NAMES.ANALYSIS) private analysisQueue: Queue,
    @InjectQueue(QUEUE_NAMES.REPORTS) private reportsQueue: Queue,
    @InjectQueue(QUEUE_NAMES.NOTIFICATIONS) private notificationsQueue: Queue,
  ) {}

  // ========== ANALYSIS JOBS ==========

  async queueAnalysis(
    data: AnalysisJobData,
    options?: JobOptions,
  ): Promise<Job<AnalysisJobData>> {
    this.logger.log(`Queuing analysis job: ${data.analysisId}`);
    return this.analysisQueue.add('process', data, {
      priority: this.getAnalysisPriority(data.type),
      ...options,
    });
  }

  private getAnalysisPriority(type: string): number {
    // Lower number = higher priority
    const priorities: Record<string, number> = {
      radiological: 1,
      locomotion: 2,
      video_performance: 3,
      video_course: 3,
    };
    return priorities[type] || 5;
  }

  async getAnalysisJobStatus(jobId: string) {
    const job = await this.analysisQueue.getJob(jobId);
    if (!job) return null;

    return {
      id: job.id,
      status: await job.getState(),
      progress: job.progress(),
      data: job.data,
      failedReason: job.failedReason,
      processedOn: job.processedOn,
      finishedOn: job.finishedOn,
    };
  }

  // ========== REPORT JOBS ==========

  async queueReportGeneration(
    data: ReportJobData,
    options?: JobOptions,
  ): Promise<Job<ReportJobData>> {
    this.logger.log(`Queuing report generation: ${data.reportId}`);
    return this.reportsQueue.add('generate', data, options);
  }

  // ========== NOTIFICATION JOBS ==========

  async queueNotification(
    data: NotificationJobData,
    options?: JobOptions,
  ): Promise<Job<NotificationJobData>> {
    this.logger.log(`Queuing notification: ${data.template}`);
    return this.notificationsQueue.add('send', data, {
      attempts: 5,
      ...options,
    });
  }

  async queueEmailNotification(
    userId: string,
    template: string,
    data: Record<string, any>,
  ) {
    return this.queueNotification({
      type: 'email',
      userId,
      template,
      data,
    });
  }

  async queueWebhook(
    organizationId: string,
    event: string,
    payload: Record<string, any>,
  ) {
    return this.queueNotification({
      type: 'webhook',
      organizationId,
      template: event,
      data: payload,
    });
  }

  // ========== QUEUE STATS ==========

  async getQueueStats() {
    const [analysisStats, reportStats, notificationStats] = await Promise.all([
      this.getQueueCounts(this.analysisQueue),
      this.getQueueCounts(this.reportsQueue),
      this.getQueueCounts(this.notificationsQueue),
    ]);

    return {
      analysis: analysisStats,
      reports: reportStats,
      notifications: notificationStats,
    };
  }

  private async getQueueCounts(queue: Queue) {
    const [waiting, active, completed, failed, delayed] = await Promise.all([
      queue.getWaitingCount(),
      queue.getActiveCount(),
      queue.getCompletedCount(),
      queue.getFailedCount(),
      queue.getDelayedCount(),
    ]);

    return { waiting, active, completed, failed, delayed };
  }

  // ========== CLEANUP ==========

  async cleanOldJobs(maxAge: number = 7 * 24 * 60 * 60 * 1000) {
    const cleanOptions = {
      force: true,
      limit: 1000,
    };

    await Promise.all([
      this.analysisQueue.clean(maxAge, 'completed'),
      this.analysisQueue.clean(maxAge, 'failed'),
      this.reportsQueue.clean(maxAge, 'completed'),
      this.reportsQueue.clean(maxAge, 'failed'),
      this.notificationsQueue.clean(maxAge, 'completed'),
      this.notificationsQueue.clean(maxAge, 'failed'),
    ]);
  }
}
