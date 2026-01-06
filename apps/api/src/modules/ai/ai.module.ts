import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { AnthropicService } from './anthropic.service';
import { AIAnalysisService } from './analysis.service';
import { VideoAnalysisService } from './video-analysis.service';
import { MedicalImagingService } from './medical-imaging.service';
import { ExaminationPackagesService } from './examination-packages.service';
import { AutoDetectionService } from './auto-detection.service';
import { AdaptivePlanService } from './adaptive-plan.service';
import { CourseDesignerService } from './course-designer.service';
import { CostOptimizationService } from './cost-optimization.service';
import { ProgressTrackingService } from './progress-tracking.service';
import { ComparisonService } from './comparison.service';
import { EvolutionReportService } from './evolution-report.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [
    HttpModule.register({
      timeout: 180000, // 3 minutes for AI calls (complex analyses)
    }),
    PrismaModule,
  ],
  providers: [
    AnthropicService,
    AIAnalysisService,
    VideoAnalysisService,
    MedicalImagingService,
    ExaminationPackagesService,
    AutoDetectionService,
    AdaptivePlanService,
    CourseDesignerService,
    CostOptimizationService,
    ProgressTrackingService,
    ComparisonService,
    EvolutionReportService,
  ],
  exports: [
    AnthropicService,
    AIAnalysisService,
    VideoAnalysisService,
    MedicalImagingService,
    ExaminationPackagesService,
    AutoDetectionService,
    AdaptivePlanService,
    CourseDesignerService,
    CostOptimizationService,
    ProgressTrackingService,
    ComparisonService,
    EvolutionReportService,
  ],
})
export class AIModule {}
