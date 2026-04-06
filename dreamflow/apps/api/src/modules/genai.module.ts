import {
  BadGatewayException,
  BadRequestException,
  Body,
  Controller,
  Get,
  Injectable,
  Logger,
  Module,
  Post,
  ServiceUnavailableException
} from '@nestjs/common';
import {
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength
} from 'class-validator';

type ProviderName = 'openai' | 'anthropic' | 'gemini' | 'huggingface';

class GenerateTextDto {
  @IsString()
  @MinLength(3)
  @MaxLength(6000)
  prompt!: string;

  @IsOptional()
  @IsIn(['auto', 'openai', 'anthropic', 'gemini', 'huggingface'])
  provider?: 'auto' | ProviderName;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  model?: string;

  @IsOptional()
  @IsInt()
  @Min(32)
  @Max(4096)
  maxTokens?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(2)
  temperature?: number;
}

@Injectable()
class GenAIService {
  private readonly logger = new Logger(GenAIService.name);
  private readonly timeoutMs = parseInt(process.env.GENAI_TIMEOUT_MS || '25000', 10);

  private providerOrder: ProviderName[] = ['openai', 'anthropic', 'gemini', 'huggingface'];

  getProviderStatus() {
    return {
      configuredProviders: this.providerOrder.filter(provider => this.isProviderConfigured(provider)),
      defaults: {
        openai: process.env.OPENAI_TEXT_MODEL || 'gpt-4.1-mini',
        anthropic: process.env.ANTHROPIC_TEXT_MODEL || 'claude-3-5-sonnet-latest',
        gemini: process.env.GOOGLE_AI_MODEL || 'gemini-2.0-flash',
        huggingface: process.env.HUGGINGFACE_MODEL || 'mistralai/Mistral-7B-Instruct-v0.2'
      }
    };
  }

  private isProviderConfigured(provider: ProviderName): boolean {
    switch (provider) {
      case 'openai':
        return !!process.env.OPENAI_API_KEY;
      case 'anthropic':
        return !!process.env.ANTHROPIC_API_KEY;
      case 'gemini':
        return !!process.env.GOOGLE_AI_API_KEY;
      case 'huggingface':
        return !!process.env.HUGGINGFACE_API_KEY;
      default:
        return false;
    }
  }

  private async postJson(url: string, init: RequestInit): Promise<any> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const response = await fetch(url, { ...init, signal: controller.signal });
      const text = await response.text();
      const payload = text ? JSON.parse(text) : {};

      if (!response.ok) {
        throw new BadGatewayException(
          `Provider request failed with status ${response.status}`
        );
      }

      return payload;
    } catch (error) {
      if (error instanceof BadGatewayException) {
        throw error;
      }

      if (error instanceof Error && error.name === 'AbortError') {
        throw new ServiceUnavailableException('Provider timed out');
      }

      throw new ServiceUnavailableException('Provider unavailable');
    } finally {
      clearTimeout(timeout);
    }
  }

  private async generateWithOpenAI(dto: GenerateTextDto) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) throw new ServiceUnavailableException('OpenAI not configured');

    const payload = await this.postJson('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: dto.model || process.env.OPENAI_TEXT_MODEL || 'gpt-4.1-mini',
        input: dto.prompt,
        max_output_tokens: dto.maxTokens ?? 600,
        temperature: dto.temperature ?? 0.3
      })
    });

    const text =
      typeof payload.output_text === 'string'
        ? payload.output_text
        : Array.isArray(payload.output)
          ? payload.output
              .flatMap((item: any) => item?.content || [])
              .filter((part: any) => part?.type === 'output_text' && typeof part?.text === 'string')
              .map((part: any) => part.text)
              .join('\n')
          : '';

    if (!text || !text.trim()) {
      throw new BadGatewayException('OpenAI returned empty output');
    }

    return { provider: 'openai' as const, text: text.trim() };
  }

  private async generateWithAnthropic(dto: GenerateTextDto) {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) throw new ServiceUnavailableException('Anthropic not configured');

    const payload = await this.postJson('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json'
      },
      body: JSON.stringify({
        model: dto.model || process.env.ANTHROPIC_TEXT_MODEL || 'claude-3-5-sonnet-latest',
        max_tokens: dto.maxTokens ?? 600,
        temperature: dto.temperature ?? 0.3,
        messages: [{ role: 'user', content: dto.prompt }]
      })
    });

    const text = Array.isArray(payload.content)
      ? payload.content
          .filter((part: any) => part?.type === 'text' && typeof part?.text === 'string')
          .map((part: any) => part.text)
          .join('\n')
      : '';

    if (!text || !text.trim()) {
      throw new BadGatewayException('Anthropic returned empty output');
    }

    return { provider: 'anthropic' as const, text: text.trim() };
  }

  private async generateWithGemini(dto: GenerateTextDto) {
    const apiKey = process.env.GOOGLE_AI_API_KEY;
    if (!apiKey) throw new ServiceUnavailableException('Gemini not configured');

    const model = dto.model || process.env.GOOGLE_AI_MODEL || 'gemini-2.0-flash';
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${apiKey}`;

    const payload = await this.postJson(endpoint, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: dto.prompt }] }],
        generationConfig: {
          maxOutputTokens: dto.maxTokens ?? 600,
          temperature: dto.temperature ?? 0.3
        }
      })
    });

    const text = Array.isArray(payload.candidates)
      ? payload.candidates
          .flatMap((candidate: any) => candidate?.content?.parts || [])
          .filter((part: any) => typeof part?.text === 'string')
          .map((part: any) => part.text)
          .join('\n')
      : '';

    if (!text || !text.trim()) {
      throw new BadGatewayException('Gemini returned empty output');
    }

    return { provider: 'gemini' as const, text: text.trim() };
  }

  private async generateWithHuggingFace(dto: GenerateTextDto) {
    const apiKey = process.env.HUGGINGFACE_API_KEY;
    if (!apiKey) throw new ServiceUnavailableException('Hugging Face not configured');

    const model = dto.model || process.env.HUGGINGFACE_MODEL || 'mistralai/Mistral-7B-Instruct-v0.2';
    const endpoint = `https://api-inference.huggingface.co/models/${encodeURIComponent(model)}`;

    const payload = await this.postJson(endpoint, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        inputs: dto.prompt,
        parameters: {
          max_new_tokens: dto.maxTokens ?? 600,
          temperature: dto.temperature ?? 0.3,
          return_full_text: false
        }
      })
    });

    const text = Array.isArray(payload)
      ? payload
          .map((item: any) => item?.generated_text)
          .filter((value: any) => typeof value === 'string')
          .join('\n')
      : typeof payload?.generated_text === 'string'
        ? payload.generated_text
        : '';

    if (!text || !text.trim()) {
      throw new BadGatewayException('Hugging Face returned empty output');
    }

    return { provider: 'huggingface' as const, text: text.trim() };
  }

  private async callProvider(provider: ProviderName, dto: GenerateTextDto) {
    switch (provider) {
      case 'openai':
        return this.generateWithOpenAI(dto);
      case 'anthropic':
        return this.generateWithAnthropic(dto);
      case 'gemini':
        return this.generateWithGemini(dto);
      case 'huggingface':
        return this.generateWithHuggingFace(dto);
      default:
        throw new BadRequestException(`Unsupported provider: ${provider}`);
    }
  }

  async generateText(dto: GenerateTextDto) {
    const provider = dto.provider || 'auto';

    if (provider !== 'auto') {
      const result = await this.callProvider(provider, dto);
      return {
        provider: result.provider,
        text: result.text,
        generatedAt: new Date().toISOString()
      };
    }

    const attempts: Array<{ provider: ProviderName; reason: string }> = [];

    for (const candidate of this.providerOrder) {
      if (!this.isProviderConfigured(candidate)) {
        attempts.push({ provider: candidate, reason: 'not-configured' });
        continue;
      }

      try {
        const result = await this.callProvider(candidate, dto);
        return {
          provider: result.provider,
          text: result.text,
          generatedAt: new Date().toISOString(),
          fallbackAttempts: attempts
        };
      } catch (error) {
        const reason = error instanceof Error ? error.message : 'unknown-error';
        attempts.push({ provider: candidate, reason });
        this.logger.warn(`Provider fallback: ${candidate} failed (${reason})`);
      }
    }

    throw new ServiceUnavailableException({
      message: 'No configured AI provider succeeded',
      fallbackAttempts: attempts
    });
  }
}

@Controller('genai')
class GenAIController {
  constructor(private readonly service: GenAIService) {}

  @Get('providers')
  providers() {
    return this.service.getProviderStatus();
  }

  @Post('generate')
  generate(@Body() dto: GenerateTextDto) {
    return this.service.generateText(dto);
  }
}

@Module({
  controllers: [GenAIController],
  providers: [GenAIService]
})
export class GenAIModule {}