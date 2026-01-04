import { Process, Processor, OnQueueCompleted, OnQueueFailed } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import { Job } from 'bull';

import { PrismaService } from '../../../prisma/prisma.service';
import { EmailService } from '../../email/email.service';
import { QUEUE_NAMES } from '../queue.module';
import { NotificationJobData } from '../queue.service';

@Processor(QUEUE_NAMES.NOTIFICATIONS)
export class NotificationProcessor {
  private readonly logger = new Logger(NotificationProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly emailService: EmailService,
  ) {}

  @Process('send')
  async handleNotification(job: Job<NotificationJobData>) {
    const { type, template, data, userId, organizationId } = job.data;

    this.logger.log(`Processing ${type} notification: ${template}`);

    try {
      switch (type) {
        case 'email':
          await this.handleEmailNotification(userId!, template, data);
          break;
        case 'webhook':
          await this.handleWebhookNotification(organizationId!, template, data);
          break;
        case 'push':
          await this.handlePushNotification(userId!, template, data);
          break;
        default:
          throw new Error(`Unknown notification type: ${type}`);
      }

      this.logger.log(`Notification sent: ${template}`);
      return { success: true };
    } catch (error) {
      this.logger.error(`Notification failed: ${template}`, error);
      throw error;
    }
  }

  private async handleEmailNotification(
    userId: string,
    template: string,
    data: Record<string, any>,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new Error('User not found');
    }

    const subject = this.getEmailSubject(template, data);
    const html = this.renderEmailTemplate(template, { ...data, user });

    await this.emailService.sendEmail({
      to: user.email,
      subject,
      html,
    });
  }

  private async handleWebhookNotification(
    organizationId: string,
    event: string,
    payload: Record<string, any>,
  ) {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!organization) {
      throw new Error('Organization not found');
    }

    // Get webhook URL from organization settings
    const settings = organization.settings as any;
    const webhookUrl = settings?.webhookUrl;

    if (!webhookUrl) {
      this.logger.warn(`No webhook URL configured for org ${organizationId}`);
      return;
    }

    // Send webhook
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-HorseVision-Event': event,
        'X-HorseVision-Signature': this.generateSignature(payload),
      },
      body: JSON.stringify({
        event,
        timestamp: new Date().toISOString(),
        data: payload,
      }),
    });

    if (!response.ok) {
      throw new Error(`Webhook failed: ${response.status}`);
    }
  }

  private async handlePushNotification(
    userId: string,
    template: string,
    data: Record<string, any>,
  ) {
    // In production, implement push notifications via Firebase/OneSignal
    this.logger.log(`Push notification would be sent to user ${userId}: ${template}`);
  }

  private getEmailSubject(template: string, data: Record<string, any>): string {
    const subjects: Record<string, string> = {
      'analysis.completed': `Analyse terminée : ${data.analysisTitle || 'Nouvelle analyse'}`,
      'report.ready': `Rapport prêt : ${data.reportNumber || 'Nouveau rapport'}`,
      'analysis.failed': `Échec de l'analyse : ${data.analysisTitle}`,
      'team.invitation': `Invitation à rejoindre ${data.organizationName}`,
    };

    return subjects[template] || 'Notification Horse Vision AI';
  }

  private renderEmailTemplate(
    template: string,
    data: Record<string, any>,
  ): string {
    // In production, use a proper templating engine
    const templates: Record<string, (d: any) => string> = {
      'analysis.completed': (d) => `
        <h2>Analyse terminée</h2>
        <p>Bonjour ${d.user.firstName},</p>
        <p>L'analyse "${d.analysisTitle}" est maintenant terminée.</p>
        <p><a href="${d.reportUrl}">Voir le rapport</a></p>
      `,
      'report.ready': (d) => `
        <h2>Rapport prêt</h2>
        <p>Bonjour ${d.user.firstName},</p>
        <p>Le rapport ${d.reportNumber} est prêt pour révision.</p>
        <p><a href="${d.reportUrl}">Voir le rapport</a></p>
      `,
      'analysis.failed': (d) => `
        <h2>Analyse échouée</h2>
        <p>Bonjour ${d.user.firstName},</p>
        <p>L'analyse "${d.analysisTitle}" a échoué.</p>
        <p>Erreur: ${d.errorMessage}</p>
      `,
    };

    const templateFn = templates[template];
    if (!templateFn) {
      return `<p>Notification: ${template}</p><pre>${JSON.stringify(data, null, 2)}</pre>`;
    }

    return templateFn(data);
  }

  private generateSignature(payload: Record<string, any>): string {
    // In production, use HMAC with secret key
    const crypto = require('crypto');
    return crypto
      .createHash('sha256')
      .update(JSON.stringify(payload))
      .digest('hex');
  }

  @OnQueueCompleted()
  onCompleted(job: Job<NotificationJobData>) {
    this.logger.log(`Notification job ${job.id} completed: ${job.data.template}`);
  }

  @OnQueueFailed()
  onFailed(job: Job<NotificationJobData>, error: Error) {
    this.logger.error(
      `Notification job ${job.id} failed: ${job.data.template} - ${error.message}`,
    );
  }
}
