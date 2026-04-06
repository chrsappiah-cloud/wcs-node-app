import {
  BadGatewayException,
  BadRequestException,
  Body,
  Controller,
  Injectable,
  Logger,
  Module,
  Post,
  Req,
  ServiceUnavailableException
} from '@nestjs/common';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  Min,
  MinLength
} from 'class-validator';

type ApiRequestLike = {
  requestId?: string;
  ip?: string;
};

type OpenAITextContent = {
  type: 'input_text';
  text: string;
};

type OpenAIImageContent = {
  type: 'input_image';
  image_url: string;
};

type OpenAIContent = OpenAITextContent | OpenAIImageContent;

class AnalyzeImageDto {
  @IsOptional()
  @IsString()
  @MinLength(6)
  @MaxLength(1200)
  prompt?: string;

  @IsOptional()
  @IsUrl({ require_protocol: true })
  @MaxLength(2048)
  imageUrl?: string;

  @IsOptional()
  @IsString()
  @MaxLength(6_000_000)
  imageBase64?: string;

  @IsOptional()
  @IsIn(['image/jpeg', 'image/png', 'image/webp'])
  mimeType?: 'image/jpeg' | 'image/png' | 'image/webp';
}

class AnalyzeVideoDto {
  @IsOptional()
  @IsString()
  @MinLength(6)
  @MaxLength(1200)
  prompt?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @IsUrl({ require_protocol: true }, { each: true })
  frameUrls?: string[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @IsString({ each: true })
  @MaxLength(3_000_000, { each: true })
  frameBase64?: string[];

  @IsOptional()
  @IsIn(['image/jpeg', 'image/png', 'image/webp'])
  frameMimeType?: 'image/jpeg' | 'image/png' | 'image/webp';

  @IsOptional()
  @IsInt()
  @Min(1)
  durationSeconds?: number;
}

interface ResponsesApiOutputItem {
  type?: string;
  content?: Array<{ type?: string; text?: string }>;
}

interface ResponsesApiPayload {
  output_text?: string;
  output?: ResponsesApiOutputItem[];
}

@Injectable()
class OpenAIMediaService {
  private readonly logger = new Logger(OpenAIMediaService.name);
  private readonly model = process.env.OPENAI_VISION_MODEL || 'gpt-4.1-mini';
  private readonly timeoutMs = parseInt(process.env.OPENAI_TIMEOUT_MS || '20000', 10);

  private getApiKey(): string {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new ServiceUnavailableException('AI service is not configured');
    }
    return apiKey;
  }

  private normalizePrompt(prompt: string | undefined, fallback: string): string {
    if (!prompt || prompt.trim().length === 0) return fallback;
    return prompt.trim();
  }

  private isPrivateIpv4(hostname: string): boolean {
    const match = hostname.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
    if (!match) return false;

    const octets = match.slice(1).map(value => Number.parseInt(value, 10));
    if (octets.some(n => Number.isNaN(n) || n < 0 || n > 255)) return false;

    if (octets[0] === 10) return true;
    if (octets[0] === 127) return true;
    if (octets[0] === 169 && octets[1] === 254) return true;
    if (octets[0] === 192 && octets[1] === 168) return true;
    if (octets[0] === 172 && octets[1] >= 16 && octets[1] <= 31) return true;
    return false;
  }

  private assertSafeMediaUrl(rawUrl: string): string {
    let parsed: URL;
    try {
      parsed = new URL(rawUrl);
    } catch {
      throw new BadRequestException('Invalid media URL');
    }

    if (parsed.protocol !== 'https:') {
      throw new BadRequestException('Only HTTPS media URLs are allowed');
    }

    if (parsed.username || parsed.password) {
      throw new BadRequestException('Media URL must not include credentials');
    }

    const hostname = parsed.hostname.toLowerCase();
    if (
      hostname === 'localhost' ||
      hostname.endsWith('.local') ||
      hostname.endsWith('.internal') ||
      hostname === '0.0.0.0' ||
      this.isPrivateIpv4(hostname)
    ) {
      throw new BadRequestException('Local/private network URLs are not allowed');
    }

    return parsed.toString();
  }

  private toDataUrl(base64Payload: string, mimeType: string): string {
    return `data:${mimeType};base64,${base64Payload}`;
  }

  private extractOutputText(payload: ResponsesApiPayload): string {
    if (typeof payload.output_text === 'string' && payload.output_text.trim().length > 0) {
      return payload.output_text.trim();
    }

    const textFragments = (payload.output || [])
      .flatMap(item => item.content || [])
      .filter(content => content.type === 'output_text' && typeof content.text === 'string')
      .map(content => (content.text || '').trim())
      .filter(Boolean);

    if (textFragments.length > 0) {
      return textFragments.join('\n').trim();
    }

    throw new BadGatewayException('AI service returned an empty response');
  }

  private async callOpenAI(content: OpenAIContent[], requestId?: string): Promise<string> {
    const apiKey = this.getApiKey();
    const abortController = new AbortController();
    const timeoutHandle = setTimeout(() => abortController.abort(), this.timeoutMs);

    try {
      const response = await fetch('https://api.openai.com/v1/responses', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        },
        signal: abortController.signal,
        body: JSON.stringify({
          model: this.model,
          input: [{ role: 'user', content }],
          max_output_tokens: 700,
          temperature: 0.2
        })
      });

      if (!response.ok) {
        const body = await response.text();
        this.logger.warn(
          `OpenAI call failed status=${response.status} requestId=${requestId ?? 'n/a'} body=${body.slice(0, 300)}`
        );
        throw new BadGatewayException('AI service request failed');
      }

      const payload = (await response.json()) as ResponsesApiPayload;
      return this.extractOutputText(payload);
    } catch (error) {
      if (error instanceof BadGatewayException || error instanceof ServiceUnavailableException) {
        throw error;
      }

      if (error instanceof Error && error.name === 'AbortError') {
        throw new ServiceUnavailableException('AI service timed out');
      }

      this.logger.error(
        `Unexpected OpenAI integration error requestId=${requestId ?? 'n/a'}`,
        error instanceof Error ? error.stack : undefined
      );
      throw new ServiceUnavailableException('AI service is temporarily unavailable');
    } finally {
      clearTimeout(timeoutHandle);
    }
  }

  async analyzeImage(dto: AnalyzeImageDto, requestId?: string, requesterIp?: string) {
    const hasImageUrl = typeof dto.imageUrl === 'string' && dto.imageUrl.trim().length > 0;
    const hasImageBase64 = typeof dto.imageBase64 === 'string' && dto.imageBase64.trim().length > 0;

    if (hasImageUrl === hasImageBase64) {
      throw new BadRequestException('Provide exactly one of imageUrl or imageBase64');
    }

    const prompt = this.normalizePrompt(
      dto.prompt,
      'Analyze this therapy-related image. Return concise structured findings: summary, observable details, and recommended clinical follow-up prompts.'
    );

    const mimeType = dto.mimeType || 'image/jpeg';
    const imageSource = hasImageUrl
      ? this.assertSafeMediaUrl(dto.imageUrl as string)
      : this.toDataUrl(dto.imageBase64 as string, mimeType);

    const content: OpenAIContent[] = [
      { type: 'input_text', text: prompt },
      { type: 'input_image', image_url: imageSource }
    ];

    const analysis = await this.callOpenAI(content, requestId);

    return {
      requestId,
      requesterIp: requesterIp || null,
      model: this.model,
      analysis,
      generatedAt: new Date().toISOString()
    };
  }

  async analyzeVideo(dto: AnalyzeVideoDto, requestId?: string, requesterIp?: string) {
    const frameUrls = dto.frameUrls || [];
    const frameBase64 = dto.frameBase64 || [];
    const totalFrames = frameUrls.length + frameBase64.length;

    if (totalFrames === 0) {
      throw new BadRequestException('Provide at least one frame via frameUrls or frameBase64');
    }

    if (totalFrames > 8) {
      throw new BadRequestException('Maximum 8 frames are allowed per request');
    }

    const prompt = this.normalizePrompt(
      dto.prompt,
      'Analyze these video frames for therapy and safety context. Return scene summary, notable changes over time, and recommended care-team actions.'
    );

    const mimeType = dto.frameMimeType || 'image/jpeg';
    const content: OpenAIContent[] = [{ type: 'input_text', text: prompt }];

    for (const url of frameUrls) {
      content.push({ type: 'input_image', image_url: this.assertSafeMediaUrl(url) });
    }

    for (const frame of frameBase64) {
      content.push({ type: 'input_image', image_url: this.toDataUrl(frame, mimeType) });
    }

    const analysis = await this.callOpenAI(content, requestId);

    return {
      requestId,
      requesterIp: requesterIp || null,
      model: this.model,
      durationSeconds: dto.durationSeconds ?? null,
      frameCount: totalFrames,
      analysis,
      generatedAt: new Date().toISOString()
    };
  }
}

@Controller('media-support')
class OpenAIMediaController {
  constructor(private readonly service: OpenAIMediaService) {}

  @Post('image/analyze')
  analyzeImage(@Body() dto: AnalyzeImageDto, @Req() req: ApiRequestLike) {
    return this.service.analyzeImage(dto, req.requestId, req.ip);
  }

  @Post('video/analyze')
  analyzeVideo(@Body() dto: AnalyzeVideoDto, @Req() req: ApiRequestLike) {
    return this.service.analyzeVideo(dto, req.requestId, req.ip);
  }
}

@Module({
  controllers: [OpenAIMediaController],
  providers: [OpenAIMediaService]
})
export class OpenAIMediaModule {}
