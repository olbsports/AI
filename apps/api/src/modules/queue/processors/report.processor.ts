import { Process, Processor, OnQueueCompleted, OnQueueFailed } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import { Job } from 'bull';
import { ConfigService } from '@nestjs/config';

import { PrismaService } from '../../../prisma/prisma.service';
import { QUEUE_NAMES } from '../queue.constants';
import { ReportJobData } from '../queue.service';

@Processor(QUEUE_NAMES.REPORTS)
export class ReportProcessor {
  private readonly logger = new Logger(ReportProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  @Process('generate')
  async handleReportGeneration(job: Job<ReportJobData>) {
    this.logger.log(`Generating report: ${job.data.reportId}`);

    const { reportId, analysisId, type } = job.data;

    try {
      // Get report and analysis data
      const report = await this.prisma.report.findUnique({
        where: { id: reportId },
        include: {
          horse: true,
          analysisSession: true,
          organization: true,
        },
      });

      if (!report) {
        throw new Error('Report not found');
      }

      await job.progress(20);

      // Generate HTML report
      let htmlUrl: string | null = null;
      let pdfUrl: string | null = null;

      if (type === 'html' || type === 'both') {
        htmlUrl = await this.generateHtmlReport(report);
        await job.progress(50);
      }

      if (type === 'pdf' || type === 'both') {
        pdfUrl = await this.generatePdfReport(report, htmlUrl);
        await job.progress(90);
      }

      // Update report with URLs
      const updatedReport = await this.prisma.report.update({
        where: { id: reportId },
        data: {
          ...(htmlUrl && { htmlReportUrl: htmlUrl }),
          ...(pdfUrl && { pdfReportUrl: pdfUrl }),
          status: 'pending_review',
        },
      });

      await job.progress(100);

      this.logger.log(`Report generated: ${reportId}`);
      return updatedReport;
    } catch (error) {
      this.logger.error(`Report generation failed: ${reportId}`, error);
      throw error;
    }
  }

  private async generateHtmlReport(report: any): Promise<string> {
    // In production, generate actual HTML and upload to S3
    // For now, return a mock URL
    const baseUrl = this.configService.get('CDN_URL', 'https://cdn.horsevision.ai');
    const key = `reports/${report.organizationId}/${report.id}/report.html`;

    // Simulate HTML generation
    await new Promise((resolve) => setTimeout(resolve, 1000));

    return `${baseUrl}/${key}`;
  }

  private async generatePdfReport(report: any, htmlUrl: string | null): Promise<string> {
    // In production, use Puppeteer/WeasyPrint to convert HTML to PDF
    const baseUrl = this.configService.get('CDN_URL', 'https://cdn.horsevision.ai');
    const key = `reports/${report.organizationId}/${report.id}/report.pdf`;

    // Simulate PDF generation
    await new Promise((resolve) => setTimeout(resolve, 2000));

    return `${baseUrl}/${key}`;
  }

  @OnQueueCompleted()
  onCompleted(job: Job<ReportJobData>) {
    this.logger.log(`Report job ${job.id} completed for report ${job.data.reportId}`);
  }

  @OnQueueFailed()
  onFailed(job: Job<ReportJobData>, error: Error) {
    this.logger.error(
      `Report job ${job.id} failed for report ${job.data.reportId}: ${error.message}`,
    );
  }
}
