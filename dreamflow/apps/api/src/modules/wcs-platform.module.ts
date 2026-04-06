import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Injectable,
  Module,
  Post
} from '@nestjs/common';
import { Pool } from 'pg';
import * as nodemailer from 'nodemailer';

const ENQUIRY_RECIPIENT = 'christopher.appiahthompson@myworldclass.org';

function createMailTransporter() {
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST ?? 'smtp.gmail.com',
    port: Number(process.env.SMTP_PORT ?? 587),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });
}

import {
  IsEmail,
  IsIn,
  IsISO8601,
  IsOptional,
  IsString,
  MaxLength,
  MinLength
} from 'class-validator';

class BookCallDto {
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name!: string;

  @IsEmail()
  email!: string;

  @IsOptional()
  @IsString()
  @MaxLength(24)
  phone?: string;

  @IsOptional()
  @IsString()
  @MaxLength(600)
  notes?: string;
}

class CreateTherapySessionDto {
  @IsString()
  @MinLength(2)
  @MaxLength(64)
  participantId!: string;

  @IsISO8601()
  scheduledFor!: string;

  @IsIn(['music', 'visual-arts', 'movement', 'storytelling'])
  modality!: 'music' | 'visual-arts' | 'movement' | 'storytelling';

  @IsOptional()
  @IsString()
  @MaxLength(600)
  therapeuticGoal?: string;
}

class GenerateInsightDto {
  @IsString()
  @MinLength(2)
  @MaxLength(64)
  participantId!: string;

  @IsString()
  @MinLength(10)
  @MaxLength(2000)
  reflection!: string;
}

class SubmitConsultDto {
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name!: string;

  @IsEmail()
  email!: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  channel?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1200)
  details?: string;
}

interface Lead {
  id: string;
  name: string;
  email: string;
  phone?: string;
  notes?: string;
  createdAt: string;
}

interface TherapySession {
  id: string;
  participantId: string;
  scheduledFor: string;
  modality: 'music' | 'visual-arts' | 'movement' | 'storytelling';
  therapeuticGoal?: string;
  status: 'scheduled';
}

interface ConsultLead {
  id: string;
  name: string;
  email: string;
  channel?: string;
  details?: string;
  submittedAt: string;
}

@Injectable()
class WcsPlatformRepository {
  private pool: Pool | null = null;
  private readonly dbEnabled: boolean;
  private initPromise: Promise<void> | null = null;

  private buildDatabaseUrl(): string | null {
    if (process.env.DATABASE_URL) {
      return process.env.DATABASE_URL;
    }

    const host = process.env.DATABASE_HOST;
    const port = process.env.DATABASE_PORT || '5432';
    const db = process.env.DATABASE_NAME;
    const user = process.env.DATABASE_USER;
    const password = process.env.DATABASE_PASSWORD;

    if (!host || !db || !user || !password) {
      return null;
    }

    return `postgresql://${encodeURIComponent(user)}:${encodeURIComponent(password)}@${host}:${port}/${db}`;
  }

  constructor() {
    const databaseUrl = this.buildDatabaseUrl();
    this.dbEnabled = !!databaseUrl;
    if (this.dbEnabled) {
      this.pool = new Pool({
        connectionString: databaseUrl || undefined,
        ssl:
          process.env.DATABASE_SSL === 'true'
            ? {
                rejectUnauthorized: process.env.DATABASE_SSL_REJECT_UNAUTHORIZED !== 'false'
              }
            : undefined
      });
      this.initPromise = this.initSchema();
    }
  }

  isDatabaseActive() {
    return this.dbEnabled && !!this.pool;
  }

  private async initSchema() {
    if (!this.pool) return;
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS wcs_book_call_leads (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        notes TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS wcs_consult_leads (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        channel TEXT,
        details TEXT,
        submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS wcs_therapy_sessions (
        id TEXT PRIMARY KEY,
        participant_id TEXT NOT NULL,
        scheduled_for TIMESTAMPTZ NOT NULL,
        modality TEXT NOT NULL,
        therapeutic_goal TEXT,
        status TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);
  }

  private async ready() {
    if (this.initPromise) {
      await this.initPromise;
      this.initPromise = null;
    }
  }

  async createBookCallLead(lead: Lead) {
    if (!this.pool) return;
    await this.ready();
    await this.pool.query(
      `
      INSERT INTO wcs_book_call_leads (id, name, email, phone, notes, created_at)
      VALUES ($1, $2, $3, $4, $5, $6)
      `,
      [lead.id, lead.name, lead.email, lead.phone ?? null, lead.notes ?? null, lead.createdAt]
    );
  }

  async createConsultLead(consult: ConsultLead) {
    if (!this.pool) return;
    await this.ready();
    await this.pool.query(
      `
      INSERT INTO wcs_consult_leads (id, name, email, channel, details, submitted_at)
      VALUES ($1, $2, $3, $4, $5, $6)
      `,
      [
        consult.id,
        consult.name,
        consult.email,
        consult.channel ?? null,
        consult.details ?? null,
        consult.submittedAt
      ]
    );
  }

  async createTherapySession(session: TherapySession) {
    if (!this.pool) return;
    await this.ready();
    await this.pool.query(
      `
      INSERT INTO wcs_therapy_sessions (id, participant_id, scheduled_for, modality, therapeutic_goal, status)
      VALUES ($1, $2, $3, $4, $5, $6)
      `,
      [
        session.id,
        session.participantId,
        session.scheduledFor,
        session.modality,
        session.therapeuticGoal ?? null,
        session.status
      ]
    );
  }

  async listTherapySessions(): Promise<TherapySession[]> {
    if (!this.pool) return [];
    await this.ready();
    const result = await this.pool.query<{
      id: string;
      participant_id: string;
      scheduled_for: string;
      modality: 'music' | 'visual-arts' | 'movement' | 'storytelling';
      therapeutic_goal: string | null;
      status: 'scheduled';
    }>(
      `
      SELECT id, participant_id, scheduled_for, modality, therapeutic_goal, status
      FROM wcs_therapy_sessions
      ORDER BY scheduled_for DESC
      `
    );
    return result.rows.map((row: {
      id: string;
      participant_id: string;
      scheduled_for: string;
      modality: 'music' | 'visual-arts' | 'movement' | 'storytelling';
      therapeutic_goal: string | null;
      status: 'scheduled';
    }) => ({
      id: row.id,
      participantId: row.participant_id,
      scheduledFor: row.scheduled_for,
      modality: row.modality,
      therapeuticGoal: row.therapeutic_goal ?? undefined,
      status: row.status
    }));
  }
}

@Injectable()
class WcsPlatformService {
  private readonly leads: Lead[] = [];
  private readonly sessions: TherapySession[] = [];
  private readonly consults: ConsultLead[] = [];

  constructor(private readonly repository: WcsPlatformRepository) {}

  getLandingData() {
    return {
      hero: {
        title: 'Dr Christopher Appiah-Thompson',
        subtitle:
          'Global consultant and advocate for social justice, working across disability, mental health, dementia care, education, and creative storytelling through World Class Scholars.',
        primaryCta: 'Request a Conversation'
      },
      phases: [
        {
          step: 1,
          name: 'Consult',
          detail: 'Strategic advisory and systems-level advocacy for organisations working in disability, mental health, and dementia care.'
        },
        {
          step: 2,
          name: 'Educate',
          detail: 'Course design, workshop facilitation, and professional development grounded in equity and trauma-aware practice.'
        },
        {
          step: 3,
          name: 'Create',
          detail: 'Digital campaigns, brand storytelling, creative arts resources, podcasts, and media production for humane and inclusive systems.'
        }
      ],
      services: [
        { key: 'consultancy', title: 'Consultancy and Advocacy', blurb: 'Policy advisory, systems change, and social justice advocacy.' },
        { key: 'education', title: 'Education and Training', blurb: 'Courses, workshops, and professional development in equity and care.' },
        { key: 'digital-campaigns', title: 'Digital Campaigns and Brand Storytelling', blurb: 'Ethical digital presence and campaign strategy for purpose-driven organisations.' },
        { key: 'creative-arts', title: 'Creative Arts and Media', blurb: 'Podcasts, art projects, and media resources supporting wellbeing and inclusion.' }
      ]
    };
  }

  async createLead(dto: BookCallDto) {
    const lead: Lead = {
      id: `lead_${Date.now()}`,
      createdAt: new Date().toISOString(),
      ...dto
    };

    this.leads.push(lead);
    await this.repository.createBookCallLead(lead);

    if (process.env.SMTP_USER && process.env.SMTP_PASS) {
      try {
        const transporter = createMailTransporter();
        await transporter.sendMail({
          from: `"World Class Scholars Enquiries" <${process.env.SMTP_USER}>`,
          to: ENQUIRY_RECIPIENT,
          replyTo: dto.email,
          subject: `New enquiry from ${dto.name}`,
          text: [
            `Name:    ${dto.name}`,
            `Email:   ${dto.email}`,
            `Phone:   ${dto.phone ?? '—'}`,
            ``,
            `Message:`,
            dto.notes ?? '(no message provided)',
            ``,
            `Submitted: ${lead.createdAt}`
          ].join('\n')
        });
      } catch (mailErr) {
        console.error('[WCS] Failed to dispatch enquiry email:', mailErr);
      }
    }

    return {
      message: 'Enquiry received. We will be in touch shortly.',
      lead
    };
  }

  async createTherapySession(dto: CreateTherapySessionDto) {
    const sessionDate = new Date(dto.scheduledFor);
    if (Number.isNaN(sessionDate.getTime())) {
      throw new BadRequestException('scheduledFor must be a valid ISO date string');
    }

    const session: TherapySession = {
      id: `session_${Date.now()}`,
      participantId: dto.participantId,
      scheduledFor: sessionDate.toISOString(),
      modality: dto.modality,
      therapeuticGoal: dto.therapeuticGoal,
      status: 'scheduled'
    };

    this.sessions.push(session);
    await this.repository.createTherapySession(session);
    return { session };
  }

  async listTherapySessions() {
    if (this.repository.isDatabaseActive()) {
      const sessions = await this.repository.listTherapySessions();
      return { sessions };
    }
    return { sessions: this.sessions };
  }

  generateInsight(dto: GenerateInsightDto) {
    // Placeholder deterministic insight until OpenAI/PyTorch worker integration is enabled.
    const signal = dto.reflection.length > 240 ? 'high-detail' : 'brief';
    const recommendation =
      signal === 'high-detail'
        ? 'Introduce a guided visual-arts reflection next session to reinforce emotional labeling.'
        : 'Prompt with a short music-based breathing exercise before journaling.';

    return {
      participantId: dto.participantId,
      signal,
      recommendation,
      generatedAt: new Date().toISOString()
    };
  }

  async submitConsult(dto: SubmitConsultDto) {
    const consult: ConsultLead = {
      id: `consult_${Date.now()}`,
      submittedAt: new Date().toISOString(),
      ...dto
    };
    this.consults.push(consult);
    await this.repository.createConsultLead(consult);
    return {
      success: true,
      message: 'Consultation request captured',
      consult
    };
  }

  getMarketingMetrics() {
    return {
      sessionsGrowth: [42, 55, 68, 80, 108],
      featureMix: {
        artGen: 40,
        musicCues: 22,
        breathing: 18,
        coachNotes: 20
      },
      mvpProgress: [12, 26, 43, 61, 78, 96],
      funnel: [
        { stage: 'Ad Click', value: 2000 },
        { stage: 'Landing Visit', value: 1240 },
        { stage: 'Consult Form', value: 295 },
        { stage: 'Booked Call', value: 128 },
        { stage: 'Pilot Signed', value: 19 }
      ]
    };
  }
}

@Controller('wcs-platform')
class WcsPlatformController {
  constructor(private readonly service: WcsPlatformService) {}

  @Get('landing-content')
  getLandingContent() {
    return this.service.getLandingData();
  }

  @Post('book-call')
  bookCall(@Body() dto: BookCallDto) {
    return this.service.createLead(dto);
  }

  @Post('therapy-sessions')
  createTherapySession(@Body() dto: CreateTherapySessionDto) {
    return this.service.createTherapySession(dto);
  }

  @Get('therapy-sessions')
  getTherapySessions() {
    return this.service.listTherapySessions();
  }

  @Post('ai/insights')
  generateInsight(@Body() dto: GenerateInsightDto) {
    return this.service.generateInsight(dto);
  }

  @Post('consult')
  submitConsult(@Body() dto: SubmitConsultDto) {
    return this.service.submitConsult(dto);
  }

  @Get('metrics')
  getMarketingMetrics() {
    return this.service.getMarketingMetrics();
  }
}

@Module({
  controllers: [WcsPlatformController],
  providers: [WcsPlatformRepository, WcsPlatformService]
})
export class WcsPlatformModule {}
