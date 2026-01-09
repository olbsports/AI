import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PrismaService } from '../../prisma/prisma.service';
import { TokensService } from '../tokens/tokens.service';
import {
  CreateRadiologyDto,
  ValidateRadiologyDto,
  RadiologyQueryDto,
  ExamType,
  RadiologyStatus,
  AnatomicalRegion,
  REGION_LABELS,
  RADIOLOGY_TOKEN_COSTS,
  RadiologyResponseDto,
} from './dto/radiology.dto';

@Injectable()
export class RadiologyService {
  private readonly logger = new Logger(RadiologyService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly tokensService: TokensService,
    private readonly configService: ConfigService,
  ) {}

  async create(
    organizationId: string,
    userId: string,
    dto: CreateRadiologyDto,
  ): Promise<RadiologyResponseDto> {
    // Verify horse belongs to organization
    const horse = await this.prisma.horse.findFirst({
      where: {
        id: dto.horseId,
        organizationId,
      },
    });

    if (!horse) {
      throw new NotFoundException('Cheval non trouvé');
    }

    const examType = dto.examType || ExamType.STANDARD;
    const tokenCost = RADIOLOGY_TOKEN_COSTS[examType];

    // Check token availability
    const tokenCheck = await this.tokensService.checkTokenAvailability(
      organizationId,
      { amount: tokenCost },
    );

    if (!tokenCheck.available) {
      throw new BadRequestException(
        `Tokens insuffisants. Requis: ${tokenCost}, Disponible: ${tokenCheck.currentBalance}`,
      );
    }

    // Reserve tokens
    const reservationId = `radio_${Date.now()}`;
    await this.tokensService.reserveTokens(organizationId, tokenCost, reservationId);

    // Create analysis
    const analysis = await this.prisma.radiologyAnalysis.create({
      data: {
        horseId: dto.horseId,
        organizationId,
        examType,
        examDate: dto.examDate ? new Date(dto.examDate) : new Date(),
        indication: dto.indication,
        clinicalHistory: dto.clinicalHistory,
        status: RadiologyStatus.PENDING,
        createdById: userId,
      },
      include: {
        horse: true,
        images: true,
      },
    });

    this.logger.log(`Created radiology analysis ${analysis.id} for horse ${horse.name}`);

    return this.formatResponse(analysis);
  }

  async findAll(
    organizationId: string,
    query: RadiologyQueryDto,
  ): Promise<{
    analyses: RadiologyResponseDto[];
    total: number;
    page: number;
    limit: number;
  }> {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = { organizationId };

    if (query.horseId) {
      where.horseId = query.horseId;
    }
    if (query.status) {
      where.status = query.status;
    }
    if (query.examType) {
      where.examType = query.examType;
    }

    const [analyses, total] = await Promise.all([
      this.prisma.radiologyAnalysis.findMany({
        where,
        include: {
          horse: true,
          images: true,
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.radiologyAnalysis.count({ where }),
    ]);

    return {
      analyses: analyses.map((a) => this.formatResponse(a)),
      total,
      page,
      limit,
    };
  }

  async findOne(
    organizationId: string,
    id: string,
  ): Promise<RadiologyResponseDto> {
    const analysis = await this.prisma.radiologyAnalysis.findFirst({
      where: {
        id,
        organizationId,
      },
      include: {
        horse: true,
        images: {
          orderBy: { sortOrder: 'asc' },
        },
      },
    });

    if (!analysis) {
      throw new NotFoundException('Analyse radiologique non trouvée');
    }

    return this.formatResponse(analysis);
  }

  async getStatus(
    organizationId: string,
    id: string,
  ): Promise<{
    id: string;
    status: string;
    progress: number;
    imagesProcessed: number;
    totalImages: number;
    estimatedTimeRemaining: number | null;
  }> {
    const analysis = await this.prisma.radiologyAnalysis.findFirst({
      where: { id, organizationId },
      include: {
        images: true,
      },
    });

    if (!analysis) {
      throw new NotFoundException('Analyse non trouvée');
    }

    const totalImages = analysis.images.length;
    const processedImages = analysis.images.filter((i) => i.aiAnalyzed).length;
    const progress = totalImages > 0 ? Math.round((processedImages / totalImages) * 100) : 0;

    // Estimate time remaining (approx 5 seconds per image)
    const estimatedTimeRemaining =
      analysis.status === RadiologyStatus.PROCESSING
        ? (totalImages - processedImages) * 5
        : null;

    return {
      id: analysis.id,
      status: analysis.status,
      progress,
      imagesProcessed: processedImages,
      totalImages,
      estimatedTimeRemaining,
    };
  }

  async uploadImages(
    organizationId: string,
    id: string,
    files: Express.Multer.File[],
    imageInfos: { region: AnatomicalRegion; view?: string }[],
  ): Promise<RadiologyResponseDto> {
    const analysis = await this.prisma.radiologyAnalysis.findFirst({
      where: { id, organizationId },
    });

    if (!analysis) {
      throw new NotFoundException('Analyse non trouvée');
    }

    if (analysis.status !== RadiologyStatus.PENDING && analysis.status !== RadiologyStatus.UPLOADING) {
      throw new BadRequestException('Impossible d\'ajouter des images à cette analyse');
    }

    // Update status to uploading
    await this.prisma.radiologyAnalysis.update({
      where: { id },
      data: { status: RadiologyStatus.UPLOADING },
    });

    // Process and save each image
    const imagePromises = files.map(async (file, index) => {
      const info = imageInfos[index] || { region: AnatomicalRegion.AUTRE };

      // In production, upload to S3 and get URLs
      const url = await this.uploadToStorage(file);
      const thumbnailUrl = await this.generateThumbnail(file, url);

      return this.prisma.radioImage.create({
        data: {
          analysisId: id,
          filename: `${id}_${index}_${info.region}.${file.mimetype.split('/')[1]}`,
          originalFilename: file.originalname,
          mimeType: file.mimetype,
          fileSize: file.size,
          url,
          thumbnailUrl,
          region: info.region,
          regionLabel: REGION_LABELS[info.region] || 'Autre',
          view: info.view,
          sortOrder: index,
          uploadStatus: 'uploaded',
        },
      });
    });

    await Promise.all(imagePromises);

    // Return updated analysis
    return this.findOne(organizationId, id);
  }

  async startAnalysis(
    organizationId: string,
    id: string,
  ): Promise<RadiologyResponseDto> {
    const analysis = await this.prisma.radiologyAnalysis.findFirst({
      where: { id, organizationId },
      include: { images: true },
    });

    if (!analysis) {
      throw new NotFoundException('Analyse non trouvée');
    }

    if (analysis.images.length === 0) {
      throw new BadRequestException('Aucune image à analyser');
    }

    if (analysis.status === RadiologyStatus.PROCESSING) {
      throw new BadRequestException('Analyse déjà en cours');
    }

    if (analysis.status === RadiologyStatus.COMPLETED) {
      throw new BadRequestException('Analyse déjà terminée');
    }

    // Update status to processing
    await this.prisma.radiologyAnalysis.update({
      where: { id },
      data: {
        status: RadiologyStatus.PROCESSING,
        startedAt: new Date(),
      },
    });

    // Trigger async analysis (in production, use queue)
    this.processAnalysisAsync(id, organizationId);

    return this.findOne(organizationId, id);
  }

  private async processAnalysisAsync(
    analysisId: string,
    organizationId: string,
  ): Promise<void> {
    const startTime = Date.now();

    try {
      const analysis = await this.prisma.radiologyAnalysis.findUnique({
        where: { id: analysisId },
        include: {
          images: true,
          horse: true,
        },
      });

      if (!analysis) return;

      // Process each image with AI
      const findings: any[] = [];
      const recommendations: any[] = [];
      let totalScore = 0;

      for (const image of analysis.images) {
        const imageResult = await this.analyzeImage(image, analysis.horse);

        // Update image with results
        await this.prisma.radioImage.update({
          where: { id: image.id },
          data: {
            aiAnalyzed: true,
            aiScore: imageResult.score,
            detections: imageResult.detections,
          },
        });

        totalScore += imageResult.score;
        findings.push(...imageResult.findings);
        recommendations.push(...imageResult.recommendations);
      }

      // Calculate global score and category
      const globalScore = analysis.images.length > 0
        ? totalScore / analysis.images.length
        : 0;
      const category = this.calculateCategory(globalScore, findings);

      // Generate conclusion
      const conclusion = this.generateConclusion(
        analysis.horse.name,
        findings,
        globalScore,
        category,
      );

      // Complete analysis
      const processingTime = Date.now() - startTime;
      const tokenCost = RADIOLOGY_TOKEN_COSTS[analysis.examType as ExamType];

      await this.prisma.radiologyAnalysis.update({
        where: { id: analysisId },
        data: {
          status: RadiologyStatus.COMPLETED,
          completedAt: new Date(),
          processingTimeMs: processingTime,
          globalScore,
          category,
          findings,
          recommendations: [...new Set(recommendations)], // Deduplicate
          conclusion,
          tokensConsumed: tokenCost,
          aiModel: 'claude-3-opus',
          aiConfidence: 0.85,
        },
      });

      // Consume tokens
      await this.tokensService.consumeReservation(`radio_${analysis.createdAt.getTime()}`);

      this.logger.log(
        `Completed radiology analysis ${analysisId} in ${processingTime}ms. Score: ${globalScore}, Category: ${category}`,
      );
    } catch (error) {
      this.logger.error(`Error processing radiology analysis ${analysisId}:`, error);

      await this.prisma.radiologyAnalysis.update({
        where: { id: analysisId },
        data: {
          status: RadiologyStatus.FAILED,
          errorMessage: error.message,
        },
      });

      // Release token reservation
      await this.tokensService.releaseReservation(`radio_${Date.now()}`);
    }
  }

  private async analyzeImage(
    image: any,
    horse: any,
  ): Promise<{
    score: number;
    detections: any[];
    findings: any[];
    recommendations: string[];
  }> {
    // In production, this would call Claude Vision API
    // For now, return simulated analysis

    // Simulate processing time
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Simulated AI analysis based on region
    const regionRisks: Record<string, number> = {
      boulet: 0.3,
      jarret: 0.25,
      pied: 0.35,
      genou: 0.2,
      dos: 0.15,
    };

    const regionKey = image.region.split('_')[0];
    const riskFactor = regionRisks[regionKey] || 0.2;

    // Generate random but realistic detections
    const hasFindings = Math.random() < riskFactor;
    const detections: any[] = [];
    const findings: any[] = [];
    const recommendations: string[] = [];

    if (hasFindings) {
      const findingTypes = this.getPossibleFindings(image.region);
      const numFindings = Math.floor(Math.random() * 2) + 1;

      for (let i = 0; i < numFindings; i++) {
        const finding = findingTypes[Math.floor(Math.random() * findingTypes.length)];
        const severity = this.getRandomSeverity();
        const confidence = 70 + Math.random() * 25;

        detections.push({
          id: `det_${Date.now()}_${i}`,
          pathologyType: finding.type,
          label: finding.label,
          severity,
          confidence: Math.round(confidence),
          boundingBox: {
            x: Math.random() * 0.6 + 0.2,
            y: Math.random() * 0.6 + 0.2,
            width: 0.1 + Math.random() * 0.15,
            height: 0.1 + Math.random() * 0.15,
          },
          description: finding.description,
          recommendation: finding.recommendation,
        });

        findings.push({
          region: image.regionLabel,
          type: finding.type,
          label: finding.label,
          severity,
          description: finding.description,
        });

        if (finding.recommendation) {
          recommendations.push(finding.recommendation);
        }
      }
    }

    // Calculate score (100 = perfect, lower = more issues)
    let score = 100;
    for (const detection of detections) {
      const penalty = {
        low: 5,
        moderate: 15,
        high: 30,
        critical: 50,
      }[detection.severity] || 10;
      score -= penalty;
    }
    score = Math.max(0, score);

    return {
      score,
      detections,
      findings,
      recommendations,
    };
  }

  private getPossibleFindings(region: string): any[] {
    const commonFindings = [
      {
        type: 'osteophyte',
        label: 'Ostéophyte',
        description: 'Formation osseuse marginale détectée',
        recommendation: 'Surveillance recommandée',
      },
      {
        type: 'arthritis',
        label: 'Arthrose débutante',
        description: 'Signes d\'usure articulaire',
        recommendation: 'Consultation vétérinaire conseillée',
      },
    ];

    const regionSpecific: Record<string, any[]> = {
      boulet: [
        {
          type: 'sesamoidite',
          label: 'Sésamoïdite',
          description: 'Inflammation des os sésamoïdes',
          recommendation: 'Repos et traitement anti-inflammatoire',
        },
        {
          type: 'chip_fracture',
          label: 'Fragment ostéochondral',
          description: 'Petit fragment osseux détaché',
          recommendation: 'Évaluation chirurgicale recommandée',
        },
      ],
      jarret: [
        {
          type: 'spavin',
          label: 'Éparvin',
          description: 'Arthrose du jarret',
          recommendation: 'Traitement adapté selon sévérité',
        },
      ],
      pied: [
        {
          type: 'navicular',
          label: 'Syndrome naviculaire',
          description: 'Anomalie de l\'os naviculaire',
          recommendation: 'Ferrure orthopédique recommandée',
        },
        {
          type: 'laminitis',
          label: 'Fourbure chronique',
          description: 'Signes de rotation de la phalange',
          recommendation: 'Prise en charge urgente',
        },
      ],
    };

    const regionKey = region.split('_')[0];
    return [...commonFindings, ...(regionSpecific[regionKey] || [])];
  }

  private getRandomSeverity(): string {
    const rand = Math.random();
    if (rand < 0.4) return 'low';
    if (rand < 0.75) return 'moderate';
    if (rand < 0.95) return 'high';
    return 'critical';
  }

  private calculateCategory(score: number, findings: any[]): string {
    const criticalCount = findings.filter((f) => f.severity === 'critical').length;
    const highCount = findings.filter((f) => f.severity === 'high').length;

    if (criticalCount > 0 || score < 40) return 'D';
    if (highCount > 1 || score < 55) return 'C';
    if (highCount > 0 || score < 70) return 'B-';
    if (findings.length > 2 || score < 80) return 'B';
    if (findings.length > 0 || score < 90) return 'B+';
    if (score < 95) return 'A-';
    return 'A';
  }

  private generateConclusion(
    horseName: string,
    findings: any[],
    score: number,
    category: string,
  ): string {
    if (findings.length === 0) {
      return `L'examen radiologique de ${horseName} ne révèle aucune anomalie significative. ` +
        `Le bilan est favorable (catégorie ${category}).`;
    }

    const severityText = {
      low: 'mineures',
      moderate: 'modérées',
      high: 'significatives',
      critical: 'majeures',
    };

    const maxSeverity = findings.reduce((max, f) => {
      const order = ['low', 'moderate', 'high', 'critical'];
      return order.indexOf(f.severity) > order.indexOf(max) ? f.severity : max;
    }, 'low');

    const regions = [...new Set(findings.map((f) => f.region))];

    return `L'examen radiologique de ${horseName} révèle des anomalies ${severityText[maxSeverity]} ` +
      `au niveau de: ${regions.join(', ')}. ` +
      `Score global: ${Math.round(score)}/100 (catégorie ${category}). ` +
      `${findings.length} point(s) d'attention identifié(s). ` +
      `Une consultation vétérinaire est recommandée pour définir la prise en charge adaptée.`;
  }

  async validate(
    organizationId: string,
    id: string,
    userId: string,
    dto: ValidateRadiologyDto,
  ): Promise<RadiologyResponseDto> {
    const analysis = await this.prisma.radiologyAnalysis.findFirst({
      where: { id, organizationId },
    });

    if (!analysis) {
      throw new NotFoundException('Analyse non trouvée');
    }

    if (analysis.status !== RadiologyStatus.COMPLETED) {
      throw new BadRequestException('L\'analyse doit être terminée pour être validée');
    }

    await this.prisma.radiologyAnalysis.update({
      where: { id },
      data: {
        validatedById: userId,
        validatedAt: new Date(),
        vetNotes: dto.vetNotes,
        vetSignature: dto.vetSignature,
      },
    });

    return this.findOne(organizationId, id);
  }

  async compare(
    organizationId: string,
    id1: string,
    id2: string,
  ): Promise<{
    analysis1: RadiologyResponseDto;
    analysis2: RadiologyResponseDto;
    comparison: {
      scoreDifference: number;
      newFindings: any[];
      resolvedFindings: any[];
      unchangedFindings: any[];
      trend: 'improving' | 'stable' | 'declining';
    };
  }> {
    const [analysis1, analysis2] = await Promise.all([
      this.findOne(organizationId, id1),
      this.findOne(organizationId, id2),
    ]);

    // Compare findings
    const findings1 = new Set(analysis1.findings.map((f: any) => f.type));
    const findings2 = new Set(analysis2.findings.map((f: any) => f.type));

    const newFindings = analysis2.findings.filter((f: any) => !findings1.has(f.type));
    const resolvedFindings = analysis1.findings.filter((f: any) => !findings2.has(f.type));
    const unchangedFindings = analysis2.findings.filter((f: any) => findings1.has(f.type));

    const scoreDiff = (analysis2.globalScore || 0) - (analysis1.globalScore || 0);
    let trend: 'improving' | 'stable' | 'declining' = 'stable';
    if (scoreDiff > 5) trend = 'improving';
    else if (scoreDiff < -5) trend = 'declining';

    return {
      analysis1,
      analysis2,
      comparison: {
        scoreDifference: scoreDiff,
        newFindings,
        resolvedFindings,
        unchangedFindings,
        trend,
      },
    };
  }

  async delete(organizationId: string, id: string): Promise<void> {
    const analysis = await this.prisma.radiologyAnalysis.findFirst({
      where: { id, organizationId },
    });

    if (!analysis) {
      throw new NotFoundException('Analyse non trouvée');
    }

    if (analysis.validatedAt) {
      throw new ForbiddenException('Une analyse validée ne peut pas être supprimée');
    }

    await this.prisma.radiologyAnalysis.delete({
      where: { id },
    });

    this.logger.log(`Deleted radiology analysis ${id}`);
  }

  async generateReport(
    organizationId: string,
    id: string,
  ): Promise<{ reportUrl: string }> {
    const analysis = await this.findOne(organizationId, id);

    if (analysis.status !== RadiologyStatus.COMPLETED) {
      throw new BadRequestException('L\'analyse doit être terminée pour générer un rapport');
    }

    // In production, generate PDF report
    const reportUrl = `${this.configService.get('STORAGE_URL')}/reports/radio_${id}.pdf`;

    return { reportUrl };
  }

  private formatResponse(analysis: any): RadiologyResponseDto {
    return {
      id: analysis.id,
      horseId: analysis.horseId,
      horseName: analysis.horse?.name || 'Unknown',
      examDate: analysis.examDate,
      examType: analysis.examType,
      status: analysis.status,
      globalScore: analysis.globalScore,
      category: analysis.category,
      findings: analysis.findings || [],
      recommendations: analysis.recommendations || [],
      conclusion: analysis.conclusion,
      images: (analysis.images || []).map((img: any) => ({
        id: img.id,
        filename: img.filename,
        url: img.url,
        thumbnailUrl: img.thumbnailUrl,
        region: img.region,
        regionLabel: img.regionLabel,
        view: img.view,
        aiScore: img.aiScore,
        detections: img.detections || [],
      })),
      validatedAt: analysis.validatedAt,
      tokensConsumed: analysis.tokensConsumed,
      createdAt: analysis.createdAt,
      completedAt: analysis.completedAt,
    };
  }

  private async uploadToStorage(file: Express.Multer.File): Promise<string> {
    // In production, upload to S3
    // For now, return a placeholder URL
    const storageUrl = this.configService.get('STORAGE_URL') || 'https://storage.horsetempo.com';
    return `${storageUrl}/radiology/${Date.now()}_${file.originalname}`;
  }

  private async generateThumbnail(
    file: Express.Multer.File,
    originalUrl: string,
  ): Promise<string> {
    // In production, generate actual thumbnail
    return originalUrl.replace('/radiology/', '/radiology/thumbs/');
  }
}
