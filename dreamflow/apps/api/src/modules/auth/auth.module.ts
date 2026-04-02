import { createHmac, randomInt, createPublicKey, timingSafeEqual } from 'node:crypto';
import type { JsonWebKey } from 'node:crypto';
import {
  BadRequestException,
  Body,
  Controller,
  Injectable,
  Module,
  Post,
  UnauthorizedException
} from '@nestjs/common';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { ApiTags } from '@nestjs/swagger';
import { IsString, Matches, MaxLength, Length } from 'class-validator';

// ─── DTOs ────────────────────────────────────────────────────────────────────

class SendOtpDto {
  /** E.164 format required: +14155552671 */
  @IsString()
  @Matches(/^\+[1-9]\d{6,14}$/, { message: 'phone must be a valid E.164 number' })
  phone!: string;
}

class VerifyOtpDto {
  @IsString()
  @Matches(/^\+[1-9]\d{6,14}$/, { message: 'phone must be a valid E.164 number' })
  phone!: string;

  @IsString()
  @Length(6, 6, { message: 'code must be exactly 6 digits' })
  @Matches(/^\d{6}$/, { message: 'code must be numeric' })
  code!: string;
}

class AppleSignInDto {
  @IsString()
  @MaxLength(4096)
  identityToken!: string;
}

class GoogleSignInDto {
  @IsString()
  @MaxLength(4096)
  idToken!: string;
}

// ─── In-process OTP store ─────────────────────────────────────────────────────
// Supports at most 1 live OTP per phone. Replace with Redis for multi-replica.

interface OtpEntry {
  hash: string; // HMAC-SHA256 of the 6-digit code to avoid plain-text storage
  expiresAt: number; // epoch ms
  attempts: number;
}

const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes
const OTP_MAX_ATTEMPTS = 5;

// ─── Auth Service ─────────────────────────────────────────────────────────────

@Injectable()
class AuthService {
  private readonly otpStore = new Map<string, OtpEntry>();
  private readonly otpHmacKey: string;

  constructor(private readonly jwtService: JwtService) {
    // Fallback to a random key so unit tests never expose a known secret.
    this.otpHmacKey = process.env.OTP_HMAC_KEY ?? Math.random().toString(36).slice(2);
  }

  // ── Phone OTP ───────────────────────────────────────────────────────────────

  async sendOtp(phone: string): Promise<{ sent: boolean }> {
    const code = String(randomInt(0, 1_000_000)).padStart(6, '0');
    const hash = createHmac('sha256', this.otpHmacKey).update(code).digest('hex');

    this.otpStore.set(phone, { hash, expiresAt: Date.now() + OTP_TTL_MS, attempts: 0 });

    await this.dispatchSms(phone, `Your GeoWCS code: ${code}. Expires in 5 minutes.`);

    return { sent: true };
  }

  async verifyOtp(phone: string, code: string): Promise<{ token: string }> {
    const entry = this.otpStore.get(phone);

    if (!entry) {
      throw new UnauthorizedException('No pending verification for this number');
    }

    if (Date.now() > entry.expiresAt) {
      this.otpStore.delete(phone);
      throw new UnauthorizedException('Verification code has expired');
    }

    entry.attempts += 1;
    if (entry.attempts > OTP_MAX_ATTEMPTS) {
      this.otpStore.delete(phone);
      throw new UnauthorizedException('Too many failed attempts');
    }

    const expectedHash = createHmac('sha256', this.otpHmacKey).update(code).digest('hex');
    const expectedBuf = Buffer.from(expectedHash, 'hex');
    const actualBuf = Buffer.from(entry.hash, 'hex');

    // Constant-time comparison prevents timing oracle
    if (!timingSafeEqual(actualBuf, expectedBuf)) {
      throw new UnauthorizedException('Invalid verification code');
    }

    this.otpStore.delete(phone);
    return { token: this.issueToken(phone, 'phone') };
  }

  // ── Apple Sign In ───────────────────────────────────────────────────────────

  async signInWithApple(identityToken: string): Promise<{ token: string }> {
    const payload = await this.verifyAppleToken(identityToken);
    const userId = payload.sub as string;
    if (!userId) throw new UnauthorizedException('Invalid Apple identity token');
    return { token: this.issueToken(userId, 'apple') };
  }

  // ── Google Sign In ──────────────────────────────────────────────────────────

  async signInWithGoogle(idToken: string): Promise<{ token: string }> {
    const info = await this.fetchGoogleTokenInfo(idToken);
    const userId = info.sub ?? info.email;
    if (!userId) throw new UnauthorizedException('Invalid Google ID token');
    return { token: this.issueToken(userId, 'google') };
  }

  // ── JWT issue ───────────────────────────────────────────────────────────────

  private issueToken(userId: string, method: 'phone' | 'apple' | 'google'): string {
    return this.jwtService.sign(
      { sub: userId, authMethod: method, roles: ['viewer'] },
      { expiresIn: '7d' }
    );
  }

  // ── Apple JWKS token verification ───────────────────────────────────────────

  private async verifyAppleToken(token: string): Promise<Record<string, unknown>> {
    // Decode header to find the key id
    const [rawHeader] = token.split('.');
    const header = JSON.parse(
      Buffer.from(rawHeader, 'base64url').toString('utf8')
    ) as { kid: string; alg: string };

    // Fetch Apple's public keys
    const res = await fetch('https://appleid.apple.com/auth/keys');
    if (!res.ok) throw new UnauthorizedException('Could not fetch Apple public keys');
    const jwks = (await res.json()) as { keys: JsonWebKey[] };

    const jwk = jwks.keys.find(k => k.kid === header.kid);
    if (!jwk) throw new UnauthorizedException('Apple key not found');

    // Node 18+ supports importKey from JWK directly via createPublicKey
    const pubKey = createPublicKey({ key: jwk as JsonWebKey, format: 'jwk' });
    const pem = pubKey.export({ type: 'spki', format: 'pem' }) as string;

    // Use @nestjs/jwt's underlying jsonwebtoken to verify
    try {
      return this.jwtService.verify(token, {
        ...(pem && { secret: pem }),
        algorithms: ['RS256'],
        issuer: 'https://appleid.apple.com'
      } as Parameters<typeof this.jwtService.verify>[1]) as Record<string, unknown>;
    } catch {
      throw new UnauthorizedException('Apple token verification failed');
    }
  }

  // ── Google tokeninfo ────────────────────────────────────────────────────────

  private async fetchGoogleTokenInfo(
    idToken: string
  ): Promise<{ sub?: string; email?: string; aud?: string }> {
    const url = `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`;
    const res = await fetch(url);
    if (!res.ok) throw new UnauthorizedException('Google token verification failed');

    const info = (await res.json()) as { sub?: string; email?: string; aud?: string; error?: string };
    if (info.error) throw new UnauthorizedException('Invalid Google ID token');

    const expectedAud = process.env.GOOGLE_CLIENT_ID;
    if (expectedAud && info.aud !== expectedAud) {
      throw new UnauthorizedException('Google token audience mismatch');
    }

    return info;
  }

  // ── SMS dispatch ─────────────────────────────────────────────────────────────

  private async dispatchSms(to: string, body: string): Promise<void> {
    const sid = process.env.TWILIO_ACCOUNT_SID;
    const token = process.env.TWILIO_AUTH_TOKEN;
    const from = process.env.TWILIO_FROM_NUMBER;

    if (!sid || !token || !from) {
      // Not configured — log the code for local development only
      if (process.env.NODE_ENV !== 'production') {
        console.log(`[AuthService] DEV SMS to ${to}: ${body}`);
      }
      return;
    }

    const url = `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`;
    const encoded = Buffer.from(`${sid}:${token}`).toString('base64');

    const res = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${encoded}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({ To: to, From: from, Body: body }).toString()
    });

    if (!res.ok) {
      throw new BadRequestException('Failed to send verification SMS');
    }
  }
}

// ─── Auth Controller ──────────────────────────────────────────────────────────

@ApiTags('auth')
@Controller('auth')
class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('phone/send-otp')
  sendOtp(@Body() dto: SendOtpDto) {
    return this.authService.sendOtp(dto.phone);
  }

  @Post('phone/verify-otp')
  verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto.phone, dto.code);
  }

  @Post('apple')
  signInWithApple(@Body() dto: AppleSignInDto) {
    return this.authService.signInWithApple(dto.identityToken);
  }

  @Post('google')
  signInWithGoogle(@Body() dto: GoogleSignInDto) {
    return this.authService.signInWithGoogle(dto.idToken);
  }
}

// ─── Auth Module ──────────────────────────────────────────────────────────────

@Module({
  imports: [
    JwtModule.register({
      secret: process.env.JWT_SECRET ?? 'dev-only-change-in-production',
      signOptions: { issuer: 'geowcs' }
    })
  ],
  controllers: [AuthController],
  providers: [AuthService],
  exports: [JwtModule]
})
export class AuthModule {}
