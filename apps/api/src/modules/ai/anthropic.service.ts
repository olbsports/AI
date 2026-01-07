import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { PrismaService } from '../../prisma/prisma.service';
import { firstValueFrom } from 'rxjs';
import * as crypto from 'crypto';

/**
 * Anthropic Claude API Service
 *
 * Provides AI-powered analysis for:
 * - Horse valuation insights (EquiCote)
 * - Video/image analysis
 * - Breeding recommendations
 * - Health assessment summaries
 * - Natural language queries
 *
 * Uses Claude 3.5 Sonnet for optimal cost/performance
 */
@Injectable()
export class AnthropicService {
  private readonly logger = new Logger(AnthropicService.name);
  private readonly baseUrl = 'https://api.anthropic.com/v1';
  private readonly apiKey = process.env.ANTHROPIC_API_KEY;
  private readonly defaultModel = process.env.ANTHROPIC_MODEL || 'claude-sonnet-4-20250514';

  // Token costs in USD (per 1M tokens)
  private readonly tokenCosts: Record<string, { input: number; output: number }> = {
    'claude-sonnet-4-20250514': { input: 3, output: 15 },
    'claude-3-5-sonnet-20241022': { input: 3, output: 15 },
    'claude-3-opus-20240229': { input: 15, output: 75 },
    'claude-3-haiku-20240307': { input: 0.25, output: 1.25 },
  };

  constructor(
    private http: HttpService,
    private prisma: PrismaService,
  ) {}

  /**
   * Send a message to Claude
   */
  async sendMessage(params: {
    messages: Array<{ role: 'user' | 'assistant'; content: string }>;
    system?: string;
    model?: string;
    maxTokens?: number;
    temperature?: number;
  }): Promise<AnthropicResponse> {
    const model = params.model || this.defaultModel;
    const startTime = Date.now();

    try {
      const response = await firstValueFrom(
        this.http.post(
          `${this.baseUrl}/messages`,
          {
            model,
            max_tokens: params.maxTokens || 4096,
            temperature: params.temperature || 0.7,
            system: params.system,
            messages: params.messages,
          },
          {
            headers: {
              'x-api-key': this.apiKey,
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            },
          },
        ),
      );

      const data = response.data;
      const processingTime = Date.now() - startTime;

      // Calculate cost
      const costs = this.tokenCosts[model] || this.tokenCosts[this.defaultModel];
      const costUsd = (data.usage.input_tokens * costs.input + data.usage.output_tokens * costs.output) / 1_000_000;

      this.logger.log(`Anthropic call completed: ${data.usage.input_tokens} in / ${data.usage.output_tokens} out, cost: $${costUsd.toFixed(4)}`);

      return {
        content: data.content[0]?.text || '',
        model: data.model,
        usage: {
          inputTokens: data.usage.input_tokens,
          outputTokens: data.usage.output_tokens,
        },
        costUsd,
        processingTimeMs: processingTime,
      };
    } catch (error: any) {
      this.logger.error('Anthropic API call failed', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Analyze content with caching
   */
  async analyze(
    prompt: string,
    type: 'valuation' | 'locomotion' | 'video' | 'breeding_match' | 'health' | 'general',
    options: {
      useCache?: boolean;
      system?: string;
      model?: string;
    } = {},
  ): Promise<{
    analysis: string;
    recommendations: string[];
    confidence?: number;
    cached: boolean;
  }> {
    const useCache = options.useCache !== false;

    // Check cache
    if (useCache) {
      const inputHash = this.hashInput(prompt, type);
      const cached = await this.getCachedAnalysis(inputHash);
      if (cached) {
        this.logger.debug('Returning cached analysis');
        return { ...cached, cached: true };
      }
    }

    // Build system prompt based on type
    const systemPrompt = options.system || this.getSystemPrompt(type);

    const response = await this.sendMessage({
      messages: [{ role: 'user', content: prompt }],
      system: systemPrompt,
      model: options.model,
    });

    // Parse structured response
    const result = this.parseAnalysisResponse(response.content, type);

    // Cache result
    if (useCache) {
      await this.cacheAnalysis(prompt, type, response, result);
    }

    return { ...result, cached: false };
  }

  /**
   * Analyze image/video frames
   */
  async analyzeImage(
    imageBase64: string,
    prompt: string,
    options: {
      mediaType?: 'image/jpeg' | 'image/png' | 'image/webp' | 'image/gif';
      type?: 'locomotion' | 'conformation' | 'general';
    } = {},
  ): Promise<{
    analysis: string;
    observations: string[];
    score?: number;
  }> {
    const systemPrompt = this.getImageAnalysisPrompt(options.type || 'general');

    try {
      const response = await firstValueFrom(
        this.http.post(
          `${this.baseUrl}/messages`,
          {
            model: this.defaultModel,
            max_tokens: 4096,
            system: systemPrompt,
            messages: [
              {
                role: 'user',
                content: [
                  {
                    type: 'image',
                    source: {
                      type: 'base64',
                      media_type: options.mediaType || 'image/jpeg',
                      data: imageBase64,
                    },
                  },
                  {
                    type: 'text',
                    text: prompt,
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
          },
        ),
      );

      const content = response.data.content[0]?.text || '';
      return this.parseImageAnalysisResponse(content);
    } catch (error: any) {
      this.logger.error('Image analysis failed', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Generate natural language response for chat
   */
  async chat(
    conversationHistory: Array<{ role: 'user' | 'assistant'; content: string }>,
    context?: string,
  ): Promise<string> {
    const systemPrompt = `Tu es un assistant expert en équitation et en chevaux pour l'application Horse Tempo.
Tu aides les utilisateurs avec:
- Questions sur leurs chevaux
- Conseils d'entraînement
- Informations sur les soins
- Analyse de performances
- Conseils d'élevage

${context ? `Contexte supplémentaire:\n${context}` : ''}

Réponds de manière concise et professionnelle en français.`;

    const response = await this.sendMessage({
      messages: conversationHistory,
      system: systemPrompt,
      maxTokens: 1024,
      temperature: 0.8,
    });

    return response.content;
  }

  /**
   * Extract structured data from text
   */
  async extractData<T>(
    text: string,
    schema: string,
    instructions: string,
  ): Promise<T | null> {
    const prompt = `Extrais les informations suivantes du texte ci-dessous.

SCHEMA DE SORTIE (JSON):
${schema}

INSTRUCTIONS:
${instructions}

TEXTE:
${text}

Réponds UNIQUEMENT avec le JSON valide, sans commentaires.`;

    const response = await this.sendMessage({
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.2,
    });

    try {
      // Extract JSON from response
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]) as T;
      }
      return null;
    } catch (error) {
      this.logger.error('Failed to parse extracted data', error);
      return null;
    }
  }

  // Helper methods
  private getSystemPrompt(type: string): string {
    const prompts: Record<string, string> = {
      valuation: `Tu es un expert en valorisation équine pour EquiCote.
Analyse les données du cheval et fournis:
1. Une analyse courte (2-3 phrases) de la valorisation
2. Des recommandations concrètes pour améliorer la valeur
3. Un niveau de confiance (0-100)

Format ta réponse en JSON:
{
  "analysis": "...",
  "recommendations": ["...", "..."],
  "confidence": 75
}`,

      locomotion: `Tu es un vétérinaire spécialisé en biomécanique équine.
Analyse la locomotion du cheval et fournis:
1. Observations sur la régularité des allures
2. Points d'attention potentiels
3. Recommandations

Format ta réponse en JSON:
{
  "analysis": "...",
  "observations": ["...", "..."],
  "concerns": ["...", "..."],
  "recommendations": ["...", "..."]
}`,

      breeding_match: `Tu es un conseiller en élevage équin spécialisé en génétique.
Analyse la compatibilité entre la jument et l'étalon proposé.
Considère:
- Indices génétiques (ISO, IDR, ICC)
- Modèle et morphologie
- Lignées et consanguinité
- Objectifs sportifs

Format ta réponse en JSON:
{
  "analysis": "...",
  "compatibility_score": 85,
  "strengths": ["...", "..."],
  "weaknesses": ["...", "..."],
  "recommendations": ["...", "..."]
}`,

      health: `Tu es un vétérinaire équin expérimenté.
Analyse les informations de santé et fournis:
1. Résumé de l'état de santé
2. Points de vigilance
3. Recommandations de suivi

Format ta réponse en JSON:
{
  "analysis": "...",
  "status": "bon|attention|préoccupant",
  "concerns": ["...", "..."],
  "recommendations": ["...", "..."]
}`,

      general: `Tu es un expert équestre polyvalent.
Analyse la demande et fournis une réponse structurée.

Format ta réponse en JSON:
{
  "analysis": "...",
  "recommendations": ["...", "..."]
}`,
    };

    return prompts[type] || prompts.general;
  }

  private getImageAnalysisPrompt(type: string): string {
    const prompts: Record<string, string> = {
      locomotion: `Tu es un expert en biomécanique équine.
Analyse cette image/vidéo du cheval en mouvement.
Observe:
- La régularité des allures
- L'engagement des postérieurs
- L'équilibre général
- Tout signe de boiterie ou asymétrie

Format ta réponse en JSON:
{
  "analysis": "...",
  "observations": ["...", "..."],
  "score": 85,
  "concerns": ["...", "..."]
}`,

      conformation: `Tu es un juge de modèle et allures.
Analyse la conformation du cheval dans cette image.
Observe:
- Proportions générales
- Ligne du dos
- Aplombs
- Qualité des membres

Format ta réponse en JSON:
{
  "analysis": "...",
  "observations": ["...", "..."],
  "score": 80,
  "strengths": ["...", "..."],
  "weaknesses": ["...", "..."]
}`,

      general: `Tu es un expert équestre.
Analyse cette image de cheval et décris ce que tu observes.

Format ta réponse en JSON:
{
  "analysis": "...",
  "observations": ["...", "..."]
}`,
    };

    return prompts[type] || prompts.general;
  }

  private parseAnalysisResponse(content: string, type: string): {
    analysis: string;
    recommendations: string[];
    confidence?: number;
  } {
    try {
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        return {
          analysis: parsed.analysis || content,
          recommendations: parsed.recommendations || [],
          confidence: parsed.confidence || parsed.compatibility_score,
        };
      }
    } catch (error) {
      this.logger.debug('Failed to parse JSON response, using raw content');
    }

    return {
      analysis: content,
      recommendations: [],
    };
  }

  private parseImageAnalysisResponse(content: string): {
    analysis: string;
    observations: string[];
    score?: number;
  } {
    try {
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        return {
          analysis: parsed.analysis || content,
          observations: parsed.observations || [],
          score: parsed.score,
        };
      }
    } catch (error) {
      this.logger.debug('Failed to parse image analysis JSON');
    }

    return {
      analysis: content,
      observations: [],
    };
  }

  private hashInput(prompt: string, type: string): string {
    return crypto.createHash('sha256').update(`${type}:${prompt}`).digest('hex');
  }

  private async getCachedAnalysis(inputHash: string): Promise<{
    analysis: string;
    recommendations: string[];
    confidence?: number;
  } | null> {
    const cached = await this.prisma.aIAnalysisCache.findUnique({
      where: { inputHash },
    });

    if (cached && cached.expiresAt > new Date()) {
      return cached.result as any;
    }

    return null;
  }

  private async cacheAnalysis(
    prompt: string,
    type: string,
    response: AnthropicResponse,
    result: any,
  ): Promise<void> {
    const inputHash = this.hashInput(prompt, type);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // Cache for 7 days

    try {
      await this.prisma.aIAnalysisCache.upsert({
        where: { inputHash },
        create: {
          inputHash,
          type,
          provider: 'anthropic',
          model: response.model,
          result,
          confidence: result.confidence,
          inputTokens: response.usage.inputTokens,
          outputTokens: response.usage.outputTokens,
          costUsd: response.costUsd,
          expiresAt,
        },
        update: {
          result,
          confidence: result.confidence,
          inputTokens: response.usage.inputTokens,
          outputTokens: response.usage.outputTokens,
          costUsd: response.costUsd,
          expiresAt,
        },
      });
    } catch (error) {
      this.logger.error('Failed to cache analysis', error);
    }
  }
}

// Type definitions
export interface AnthropicResponse {
  content: string;
  model: string;
  usage: {
    inputTokens: number;
    outputTokens: number;
  };
  costUsd: number;
  processingTimeMs: number;
}
