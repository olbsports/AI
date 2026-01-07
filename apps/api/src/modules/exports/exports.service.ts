import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PrismaService } from '../../prisma/prisma.service';
import { ExportRequestDto, ExportFormat, ExportEntity } from './dto/export.dto';

export interface ExportResult {
  filename: string;
  contentType: string;
  data: Buffer | string;
}

@Injectable()
export class ExportsService {
  private readonly logger = new Logger(ExportsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  async exportData(organizationId: string, dto: ExportRequestDto): Promise<ExportResult> {
    const data = await this.fetchData(organizationId, dto);

    if (data.length === 0) {
      throw new NotFoundException('No data to export');
    }

    const timestamp = new Date().toISOString().split('T')[0];
    const filename = `${dto.entity}_export_${timestamp}`;

    switch (dto.format) {
      case ExportFormat.CSV:
        return this.exportCsv(data, filename, dto.fields);
      case ExportFormat.EXCEL:
        return this.exportExcel(data, filename, dto.fields);
      case ExportFormat.JSON:
        return this.exportJson(data, filename);
      case ExportFormat.PDF:
        return this.exportPdf(data, filename, dto.entity);
      default:
        throw new BadRequestException('Unsupported export format');
    }
  }

  private async fetchData(organizationId: string, dto: ExportRequestDto): Promise<any[]> {
    const where: any = { organizationId };

    if (dto.from || dto.to) {
      where.createdAt = {};
      if (dto.from) where.createdAt.gte = new Date(dto.from);
      if (dto.to) where.createdAt.lte = new Date(dto.to);
    }

    if (dto.filters) {
      try {
        const additionalFilters = JSON.parse(dto.filters);
        Object.assign(where, additionalFilters);
      } catch {
        // Ignore invalid JSON
      }
    }

    switch (dto.entity) {
      case ExportEntity.HORSES:
        return this.prisma.horse.findMany({
          where,
          include: { rider: { select: { firstName: true, lastName: true } } },
        });

      case ExportEntity.RIDERS:
        return this.prisma.rider.findMany({
          where,
          include: { _count: { select: { horses: true } } },
        });

      case ExportEntity.ANALYSES:
        return this.prisma.analysisSession.findMany({
          where,
          include: {
            horse: { select: { name: true } },
            rider: { select: { firstName: true, lastName: true } },
          },
        });

      case ExportEntity.REPORTS:
        return this.prisma.report.findMany({
          where,
          include: { horse: { select: { name: true } } },
        });

      case ExportEntity.INVOICES:
        return this.prisma.invoice.findMany({ where });

      case ExportEntity.USERS:
        return this.prisma.user.findMany({
          where,
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            role: true,
            isActive: true,
            createdAt: true,
            lastLoginAt: true,
          },
        });

      case ExportEntity.TOKENS:
        return this.prisma.tokenTransaction.findMany({
          where,
          orderBy: { createdAt: 'desc' },
        });

      default:
        throw new BadRequestException('Unknown entity type');
    }
  }

  private exportCsv(data: any[], filename: string, fields?: string[]): ExportResult {
    if (data.length === 0) {
      return {
        filename: `${filename}.csv`,
        contentType: 'text/csv',
        data: Buffer.from(''),
      };
    }

    const headers = fields || this.extractHeaders(data[0]);
    const rows = data.map((item) => this.flattenObject(item, headers));

    const csvContent = [
      headers.join(','),
      ...rows.map((row) =>
        headers.map((h) => this.escapeCsvValue(row[h])).join(','),
      ),
    ].join('\n');

    return {
      filename: `${filename}.csv`,
      contentType: 'text/csv; charset=utf-8',
      data: Buffer.from('\ufeff' + csvContent, 'utf-8'), // BOM for Excel
    };
  }

  private exportExcel(data: any[], filename: string, fields?: string[]): ExportResult {
    // Simplified Excel export using CSV format with .xlsx extension
    // In production, use a library like xlsx or exceljs
    const csvResult = this.exportCsv(data, filename, fields);

    return {
      filename: `${filename}.xlsx`,
      contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      data: csvResult.data, // Would be actual Excel binary in production
    };
  }

  private exportJson(data: any[], filename: string): ExportResult {
    return {
      filename: `${filename}.json`,
      contentType: 'application/json',
      data: Buffer.from(JSON.stringify(data, null, 2)),
    };
  }

  private exportPdf(data: any[], filename: string, entity: ExportEntity): ExportResult {
    // Generate HTML that can be converted to PDF
    const html = this.generatePdfHtml(data, entity);

    // In production, use Puppeteer or similar to convert HTML to PDF
    return {
      filename: `${filename}.pdf`,
      contentType: 'application/pdf',
      data: Buffer.from(html), // Would be actual PDF binary in production
    };
  }

  private generatePdfHtml(data: any[], entity: ExportEntity): string {
    const headers = this.extractHeaders(data[0] || {});
    const title = entity.charAt(0).toUpperCase() + entity.slice(1);

    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Export ${title}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; }
    h1 { color: #333; border-bottom: 2px solid #0066cc; padding-bottom: 10px; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #0066cc; color: white; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .footer { margin-top: 30px; font-size: 12px; color: #666; }
  </style>
</head>
<body>
  <h1>Export ${title}</h1>
  <p>Généré le ${new Date().toLocaleDateString('fr-FR')} à ${new Date().toLocaleTimeString('fr-FR')}</p>
  <p>Total: ${data.length} enregistrements</p>

  <table>
    <thead>
      <tr>${headers.map((h) => `<th>${h}</th>`).join('')}</tr>
    </thead>
    <tbody>
      ${data
        .map(
          (item) =>
            `<tr>${headers.map((h) => `<td>${this.formatValue(item[h])}</td>`).join('')}</tr>`,
        )
        .join('')}
    </tbody>
  </table>

  <div class="footer">
    <p>Horse Tempo - Export automatique</p>
  </div>
</body>
</html>`;
  }

  async exportReport(
    organizationId: string,
    reportId: string,
    format: 'pdf' | 'html',
  ): Promise<ExportResult> {
    const report = await this.prisma.report.findFirst({
      where: { id: reportId, organizationId },
      include: {
        horse: true,
        analysisSession: true,
        organization: true,
      },
    });

    if (!report) {
      throw new NotFoundException('Report not found');
    }

    const html = this.generateReportHtml(report);

    if (format === 'html') {
      return {
        filename: `report_${report.reportNumber}.html`,
        contentType: 'text/html',
        data: Buffer.from(html),
      };
    }

    // For PDF, return HTML (would use Puppeteer in production)
    return {
      filename: `report_${report.reportNumber}.pdf`,
      contentType: 'application/pdf',
      data: Buffer.from(html),
    };
  }

  private generateReportHtml(report: any): string {
    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Rapport ${report.reportNumber}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
    .header { text-align: center; border-bottom: 3px solid #0066cc; padding-bottom: 20px; }
    .logo { font-size: 24px; font-weight: bold; color: #0066cc; }
    h1 { color: #333; }
    .section { margin: 20px 0; padding: 15px; background: #f9f9f9; border-radius: 5px; }
    .section-title { font-size: 18px; font-weight: bold; color: #0066cc; margin-bottom: 10px; }
    .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
    .info-item { padding: 5px 0; }
    .label { font-weight: bold; color: #666; }
    .score { font-size: 48px; font-weight: bold; text-align: center; color: #0066cc; }
    .category { font-size: 24px; text-align: center; color: #333; }
    .recommendations { background: #e8f4fc; padding: 15px; border-radius: 5px; }
    .recommendation-item { padding: 5px 0; border-bottom: 1px solid #ccc; }
    .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; }
  </style>
</head>
<body>
  <div class="header">
    <div class="logo">🐴 Horse Tempo</div>
    <h1>Rapport d'Analyse ${report.type === 'radiological' ? 'Radiologique' : 'de Performance'}</h1>
    <p>N° ${report.reportNumber}</p>
  </div>

  <div class="section">
    <div class="section-title">Informations Générales</div>
    <div class="info-grid">
      <div class="info-item"><span class="label">Cheval:</span> ${report.horse?.name || 'N/A'}</div>
      <div class="info-item"><span class="label">Date d'examen:</span> ${new Date(report.examDate).toLocaleDateString('fr-FR')}</div>
      <div class="info-item"><span class="label">Lieu:</span> ${report.location || 'N/A'}</div>
      <div class="info-item"><span class="label">Vétérinaire(s):</span> ${report.veterinarians?.join(', ') || 'N/A'}</div>
    </div>
  </div>

  ${
    report.globalScore
      ? `
  <div class="section">
    <div class="section-title">Score Global</div>
    <div class="score">${report.globalScore}/100</div>
    <div class="category">Catégorie: ${report.category || 'N/A'}</div>
    <p style="text-align: center">${report.categoryDescription || ''}</p>
  </div>
  `
      : ''
  }

  ${
    report.recommendations?.length
      ? `
  <div class="section recommendations">
    <div class="section-title">Recommandations</div>
    ${report.recommendations.map((r: string) => `<div class="recommendation-item">• ${r}</div>`).join('')}
  </div>
  `
      : ''
  }

  ${
    report.conclusion
      ? `
  <div class="section">
    <div class="section-title">Conclusion</div>
    <p>${report.conclusion}</p>
  </div>
  `
      : ''
  }

  <div class="footer">
    <p>Rapport généré automatiquement par Horse Tempo</p>
    <p>© ${new Date().getFullYear()} Horse Tempo - Tous droits réservés</p>
  </div>
</body>
</html>`;
  }

  async getExportHistory(organizationId: string): Promise<any[]> {
    // In production, track exports in database
    return [];
  }

  private extractHeaders(obj: any): string[] {
    const headers: string[] = [];
    const extract = (o: any, prefix = '') => {
      for (const key of Object.keys(o)) {
        if (o[key] !== null && typeof o[key] === 'object' && !Array.isArray(o[key])) {
          if (key === '_count') {
            headers.push(...Object.keys(o[key]).map((k) => `${key}_${k}`));
          } else {
            extract(o[key], `${prefix}${key}_`);
          }
        } else {
          headers.push(`${prefix}${key}`);
        }
      }
    };
    extract(obj);
    return headers.filter((h) => !h.includes('password') && !h.includes('secret'));
  }

  private flattenObject(obj: any, headers: string[]): Record<string, any> {
    const result: Record<string, any> = {};

    const flatten = (o: any, prefix = '') => {
      for (const key of Object.keys(o)) {
        if (o[key] !== null && typeof o[key] === 'object' && !Array.isArray(o[key])) {
          if (key === '_count') {
            for (const k of Object.keys(o[key])) {
              result[`${key}_${k}`] = o[key][k];
            }
          } else {
            flatten(o[key], `${prefix}${key}_`);
          }
        } else {
          result[`${prefix}${key}`] = o[key];
        }
      }
    };

    flatten(obj);
    return result;
  }

  private escapeCsvValue(value: any): string {
    if (value === null || value === undefined) return '';
    const str = String(value);
    if (str.includes(',') || str.includes('"') || str.includes('\n')) {
      return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
  }

  private formatValue(value: any): string {
    if (value === null || value === undefined) return '-';
    if (value instanceof Date) return value.toLocaleDateString('fr-FR');
    if (Array.isArray(value)) return value.join(', ');
    if (typeof value === 'object') return JSON.stringify(value);
    return String(value);
  }
}
