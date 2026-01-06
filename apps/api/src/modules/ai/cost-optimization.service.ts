import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { PrismaService } from '../../prisma/prisma.service';
import { firstValueFrom } from 'rxjs';
import * as crypto from 'crypto';

/**
 * Cost Optimization Service for Claude API
 *
 * Intelligently routes requests to the most cost-effective model:
 * - Haiku ($0.25/$1.25 per 1M tokens): Simple tasks, chat, quick analyses
 * - Sonnet ($3/$15 per 1M tokens): Complex analyses, detailed reports
 * - Vision: Always uses Sonnet (required for images)
 *
 * Strategies:
 * 1. Task classification: Route by complexity
 * 2. Aggressive caching: 7-day cache for analyses
 * 3. Prompt optimization: Reduce token usage
 * 4. Batch processing: Group similar requests
 */
@Injectable()
export class CostOptimizationService {
  private readonly logger = new Logger(CostOptimizationService.name);
  private readonly baseUrl = 'https://api.anthropic.com/v1';
  private readonly apiKey = process.env.ANTHROPIC_API_KEY;

  // Model configurations
  private readonly models = {
    haiku: {
      id: 'claude-3-haiku-20240307',
      inputCost: 0.25, // per 1M tokens
      outputCost: 1.25, // per 1M tokens
      maxTokens: 4096,
      bestFor: ['chat', 'simple_analysis', 'classification', 'extraction', 'quick_summary'],
    },
    sonnet: {
      id: 'claude-sonnet-4-20250514',
      inputCost: 3, // per 1M tokens
      outputCost: 15, // per 1M tokens
      maxTokens: 8192,
      bestFor: ['complex_analysis', 'detailed_report', 'vision', 'medical', 'breeding'],
    },
  };

  // Task complexity classification
  private readonly taskComplexity: Record<string, 'low' | 'medium' | 'high'> = {
    // Low complexity -> Haiku
    chat: 'low',
    simple_question: 'low',
    translation: 'low',
    classification: 'low',
    extraction: 'low',
    quick_summary: 'low',
    weather_adaptation: 'low',
    fatigue_check: 'low',
    reminder_generation: 'low',

    // Medium complexity -> Haiku with longer context
    plan_modification: 'medium',
    behavior_summary: 'medium',
    exercise_suggestion: 'medium',
    nutrition_basic: 'medium',

    // High complexity -> Sonnet
    video_analysis: 'high',
    medical_imaging: 'high',
    breeding_match: 'high',
    detailed_report: 'high',
    competition_analysis: 'high',
    course_design: 'high',
    valuation: 'high',
    locomotion_analysis: 'high',
    figure_detection: 'high',
    comprehensive_exam: 'high',
  };

  constructor(
    private http: HttpService,
    private prisma: PrismaService
  ) {}

  /**
   * Smart request routing - automatically chooses the best model
   */
  async smartRequest(params: {
    task: string;
    prompt: string;
    system?: string;
    maxTokens?: number;
    useCache?: boolean;
    forceModel?: 'haiku' | 'sonnet';
  }): Promise<OptimizedResponse> {
    const startTime = Date.now();
    const cacheKey = this.generateCacheKey(params.task, params.prompt);

    // Check cache first
    if (params.useCache !== false) {
      const cached = await this.getCached(cacheKey);
      if (cached) {
        this.logger.debug(`Cache hit for task: ${params.task}`);
        return {
          ...cached,
          cached: true,
          model: 'cached',
          costSaved: cached.originalCost || 0,
        };
      }
    }

    // Select optimal model
    const model = params.forceModel
      ? this.models[params.forceModel]
      : this.selectModel(params.task, params.prompt);

    this.logger.debug(`Selected model ${model.id} for task: ${params.task}`);

    // Make request
    try {
      const response = await firstValueFrom(
        this.http.post(
          `${this.baseUrl}/messages`,
          {
            model: model.id,
            max_tokens: params.maxTokens || model.maxTokens,
            system: params.system || this.getOptimizedSystemPrompt(params.task),
            messages: [{ role: 'user', content: this.optimizePrompt(params.prompt) }],
          },
          {
            headers: {
              'x-api-key': this.apiKey,
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            },
          }
        )
      );

      const data = response.data as any;
      const processingTime = Date.now() - startTime;

      // Calculate cost
      const cost = this.calculateCost(model, data.usage.input_tokens, data.usage.output_tokens);

      // Calculate savings compared to always using Sonnet
      const sonnetCost = this.calculateCost(
        this.models.sonnet,
        data.usage.input_tokens,
        data.usage.output_tokens
      );
      const savings = sonnetCost - cost;

      const result: OptimizedResponse = {
        content: data.content[0]?.text || '',
        model: model.id,
        usage: {
          inputTokens: data.usage.input_tokens,
          outputTokens: data.usage.output_tokens,
        },
        cost,
        costSaved: savings,
        processingTimeMs: processingTime,
        cached: false,
      };

      // Cache result
      if (params.useCache !== false) {
        await this.cacheResult(cacheKey, params.task, result);
      }

      // Log cost metrics
      await this.logCostMetrics(params.task, model.id, cost, savings);

      this.logger.log(
        `Task: ${params.task}, Model: ${model.id}, Cost: $${cost.toFixed(4)}, Saved: $${savings.toFixed(4)}`
      );

      return result;
    } catch (error: any) {
      this.logger.error('Smart request failed', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Batch multiple similar requests for efficiency
   */
  async batchRequest(params: {
    task: string;
    items: Array<{ id: string; prompt: string }>;
    system?: string;
  }): Promise<Map<string, OptimizedResponse>> {
    const results = new Map<string, OptimizedResponse>();

    // Group by cache status
    const uncached: typeof params.items = [];

    for (const item of params.items) {
      const cacheKey = this.generateCacheKey(params.task, item.prompt);
      const cached = await this.getCached(cacheKey);

      if (cached) {
        results.set(item.id, { ...cached, cached: true, model: 'cached', costSaved: 0 });
      } else {
        uncached.push(item);
      }
    }

    // Process uncached items
    // For batch efficiency, use parallel requests with rate limiting
    const batchSize = 5;
    for (let i = 0; i < uncached.length; i += batchSize) {
      const batch = uncached.slice(i, i + batchSize);

      const batchPromises = batch.map(async (item) => {
        const response = await this.smartRequest({
          task: params.task,
          prompt: item.prompt,
          system: params.system,
        });
        return { id: item.id, response };
      });

      const batchResults = await Promise.all(batchPromises);

      for (const { id, response } of batchResults) {
        results.set(id, response);
      }

      // Rate limiting delay between batches
      if (i + batchSize < uncached.length) {
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
    }

    return results;
  }

  /**
   * Vision analysis (always uses Sonnet)
   */
  async visionRequest(params: {
    task: string;
    imageBase64: string;
    prompt: string;
    mediaType?: 'image/jpeg' | 'image/png' | 'image/webp';
  }): Promise<OptimizedResponse> {
    const startTime = Date.now();
    const model = this.models.sonnet; // Vision requires Sonnet

    try {
      const response = await firstValueFrom(
        this.http.post(
          `${this.baseUrl}/messages`,
          {
            model: model.id,
            max_tokens: model.maxTokens,
            system: this.getOptimizedSystemPrompt(params.task),
            messages: [
              {
                role: 'user',
                content: [
                  {
                    type: 'image',
                    source: {
                      type: 'base64',
                      media_type: params.mediaType || 'image/jpeg',
                      data: params.imageBase64,
                    },
                  },
                  {
                    type: 'text',
                    text: this.optimizePrompt(params.prompt),
                  },
                ],
              },
            ],
          },
          {
            headers: {
              'x-api-key': this.apiKey,
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            },
          }
        )
      );

      const data = response.data as any;
      const processingTime = Date.now() - startTime;

      const cost = this.calculateCost(model, data.usage.input_tokens, data.usage.output_tokens);

      this.logger.log(`Vision task: ${params.task}, Cost: $${cost.toFixed(4)}`);

      return {
        content: data.content[0]?.text || '',
        model: model.id,
        usage: {
          inputTokens: data.usage.input_tokens,
          outputTokens: data.usage.output_tokens,
        },
        cost,
        costSaved: 0,
        processingTimeMs: processingTime,
        cached: false,
      };
    } catch (error: any) {
      this.logger.error('Vision request failed', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Get cost analytics for a time period
   */
  async getCostAnalytics(params: {
    startDate: Date;
    endDate: Date;
    groupBy?: 'day' | 'task' | 'model';
  }): Promise<CostAnalytics> {
    const metrics = await this.prisma.aICostMetric.findMany({
      where: {
        createdAt: {
          gte: params.startDate,
          lte: params.endDate,
        },
      },
    });

    const totalCost = metrics.reduce((sum, m) => sum + m.cost, 0);
    const totalSaved = metrics.reduce((sum, m) => sum + m.saved, 0);
    const totalRequests = metrics.length;

    // Group by task type
    const byTask = new Map<string, { cost: number; count: number; saved: number }>();
    for (const m of metrics) {
      const existing = byTask.get(m.task) || { cost: 0, count: 0, saved: 0 };
      byTask.set(m.task, {
        cost: existing.cost + m.cost,
        count: existing.count + 1,
        saved: existing.saved + m.saved,
      });
    }

    // Group by model
    const byModel = new Map<string, { cost: number; count: number }>();
    for (const m of metrics) {
      const existing = byModel.get(m.model) || { cost: 0, count: 0 };
      byModel.set(m.model, {
        cost: existing.cost + m.cost,
        count: existing.count + 1,
      });
    }

    return {
      period: {
        start: params.startDate,
        end: params.endDate,
      },
      totalCost,
      totalSaved,
      totalRequests,
      avgCostPerRequest: totalRequests > 0 ? totalCost / totalRequests : 0,
      savingsPercentage: totalCost > 0 ? (totalSaved / (totalCost + totalSaved)) * 100 : 0,
      byTask: Object.fromEntries(byTask),
      byModel: Object.fromEntries(byModel),
      recommendations: this.generateCostRecommendations(metrics),
    };
  }

  /**
   * Estimate cost for a batch of operations
   */
  estimateBatchCost(params: {
    tasks: Array<{ task: string; estimatedPromptTokens: number; estimatedOutputTokens: number }>;
  }): CostEstimate {
    let totalWithOptimization = 0;
    let totalWithoutOptimization = 0;
    const breakdown: Array<{ task: string; model: string; cost: number }> = [];

    for (const task of params.tasks) {
      const model = this.selectModel(task.task, '');
      const cost = this.calculateCost(
        model,
        task.estimatedPromptTokens,
        task.estimatedOutputTokens
      );
      const sonnetCost = this.calculateCost(
        this.models.sonnet,
        task.estimatedPromptTokens,
        task.estimatedOutputTokens
      );

      totalWithOptimization += cost;
      totalWithoutOptimization += sonnetCost;
      breakdown.push({ task: task.task, model: model.id, cost });
    }

    return {
      estimatedCost: totalWithOptimization,
      withoutOptimization: totalWithoutOptimization,
      potentialSavings: totalWithoutOptimization - totalWithOptimization,
      savingsPercentage:
        ((totalWithoutOptimization - totalWithOptimization) / totalWithoutOptimization) * 100,
      breakdown,
    };
  }

  // Private helper methods

  private selectModel(
    task: string,
    prompt: string
  ): typeof this.models.haiku | typeof this.models.sonnet {
    const complexity = this.taskComplexity[task] || 'medium';

    // High complexity tasks always use Sonnet
    if (complexity === 'high') {
      return this.models.sonnet;
    }

    // Check prompt length - longer prompts might need Sonnet for better understanding
    const estimatedTokens = this.estimateTokens(prompt);
    if (estimatedTokens > 3000 && complexity === 'medium') {
      return this.models.sonnet;
    }

    // Default to Haiku for low/medium complexity
    return this.models.haiku;
  }

  private calculateCost(
    model: typeof this.models.haiku,
    inputTokens: number,
    outputTokens: number
  ): number {
    return (inputTokens * model.inputCost + outputTokens * model.outputCost) / 1_000_000;
  }

  private estimateTokens(text: string): number {
    // Rough estimation: ~4 characters per token
    return Math.ceil(text.length / 4);
  }

  private optimizePrompt(prompt: string): string {
    // Remove excessive whitespace
    let optimized = prompt.replace(/\s+/g, ' ').trim();

    // Remove redundant instructions
    optimized = optimized
      .replace(/please|s'il vous plaît|svp/gi, '')
      .replace(/\s+/g, ' ')
      .trim();

    return optimized;
  }

  private getOptimizedSystemPrompt(task: string): string {
    // Concise system prompts to reduce token usage
    const prompts: Record<string, string> = {
      chat: 'Expert équestre. Réponses concises en français.',
      simple_analysis: 'Analyse brève. JSON: {"analysis":"...","points":["..."]}',
      classification: 'Classifie. JSON: {"category":"...","confidence":0.95}',
      extraction: 'Extrais les données. JSON uniquement.',
      quick_summary: 'Résumé en 2-3 phrases.',
      weather_adaptation:
        'Adapte l\'entraînement à la météo. JSON: {"adaptations":["..."],"alternatives":["..."]}',
      fatigue_check: 'Évalue la fatigue. JSON: {"level":"low|medium|high","recommendation":"..."}',
      video_analysis:
        'Expert biomécanique équine. Analyse détaillée avec scores et recommandations.',
      medical_imaging: 'Vétérinaire radiologue équin. Analyse pathologique détaillée.',
      breeding_match: 'Conseiller élevage. Analyse génétique et morphologique complète.',
      course_design: 'Chef de piste CSO. Design de parcours avec distances et difficultés.',
      locomotion_analysis: 'Biomécanique. Analyse allures, dissymétries, recommandations.',
      figure_detection: "Juge dressage. Identifie figures, qualité d'exécution, notes.",
    };

    return prompts[task] || 'Expert équestre. Réponses structurées en JSON.';
  }

  private generateCacheKey(task: string, prompt: string): string {
    return crypto.createHash('sha256').update(`${task}:${prompt}`).digest('hex');
  }

  private async getCached(cacheKey: string): Promise<OptimizedResponse | null> {
    try {
      const cached = await this.prisma.aIAnalysisCache.findUnique({
        where: { inputHash: cacheKey },
      });

      if (cached && cached.expiresAt > new Date()) {
        return {
          content: (cached.result as any)?.content || '',
          model: cached.model,
          usage: {
            inputTokens: cached.inputTokens,
            outputTokens: cached.outputTokens,
          },
          cost: 0, // No cost for cached results
          costSaved: cached.costUsd || 0,
          processingTimeMs: 0,
          cached: true,
          originalCost: cached.costUsd || 0,
        };
      }
    } catch (error) {
      this.logger.debug('Cache lookup failed', error);
    }
    return null;
  }

  private async cacheResult(
    cacheKey: string,
    task: string,
    result: OptimizedResponse
  ): Promise<void> {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7-day cache

    try {
      await this.prisma.aIAnalysisCache.upsert({
        where: { inputHash: cacheKey },
        create: {
          inputHash: cacheKey,
          type: task,
          provider: 'anthropic',
          model: result.model,
          result: { content: result.content },
          inputTokens: result.usage.inputTokens,
          outputTokens: result.usage.outputTokens,
          costUsd: result.cost,
          expiresAt,
        },
        update: {
          result: { content: result.content },
          inputTokens: result.usage.inputTokens,
          outputTokens: result.usage.outputTokens,
          costUsd: result.cost,
          expiresAt,
        },
      });
    } catch (error) {
      this.logger.debug('Failed to cache result', error);
    }
  }

  private async logCostMetrics(
    task: string,
    model: string,
    cost: number,
    saved: number
  ): Promise<void> {
    try {
      await this.prisma.aICostMetric.create({
        data: {
          task,
          model,
          cost,
          saved,
        },
      });
    } catch (error) {
      // Table might not exist yet, log silently
      this.logger.debug('Failed to log cost metrics', error);
    }
  }

  private generateCostRecommendations(metrics: any[]): string[] {
    const recommendations: string[] = [];

    // Analyze patterns
    const sonnetUsage = metrics.filter((m) => m.model.includes('sonnet')).length;
    const haikuUsage = metrics.filter((m) => m.model.includes('haiku')).length;
    const totalUsage = metrics.length;

    if (totalUsage > 0 && sonnetUsage / totalUsage > 0.8) {
      recommendations.push(
        'Considérez utiliser Haiku pour les tâches simples comme le chat et les classifications.'
      );
    }

    // Check for uncached repeated requests
    const taskCounts = new Map<string, number>();
    for (const m of metrics) {
      taskCounts.set(m.task, (taskCounts.get(m.task) || 0) + 1);
    }

    for (const [task, count] of taskCounts) {
      if (count > 10) {
        recommendations.push(
          `Tâche "${task}" appelée ${count} fois. Vérifiez que le cache fonctionne correctement.`
        );
      }
    }

    if (recommendations.length === 0) {
      recommendations.push('Utilisation optimale détectée. Continuez ainsi!');
    }

    return recommendations;
  }
}

// Type definitions
export interface OptimizedResponse {
  content: string;
  model: string;
  usage: {
    inputTokens: number;
    outputTokens: number;
  };
  cost: number;
  costSaved: number;
  processingTimeMs: number;
  cached: boolean;
  originalCost?: number;
}

export interface CostAnalytics {
  period: {
    start: Date;
    end: Date;
  };
  totalCost: number;
  totalSaved: number;
  totalRequests: number;
  avgCostPerRequest: number;
  savingsPercentage: number;
  byTask: Record<string, { cost: number; count: number; saved: number }>;
  byModel: Record<string, { cost: number; count: number }>;
  recommendations: string[];
}

export interface CostEstimate {
  estimatedCost: number;
  withoutOptimization: number;
  potentialSavings: number;
  savingsPercentage: number;
  breakdown: Array<{ task: string; model: string; cost: number }>;
}
