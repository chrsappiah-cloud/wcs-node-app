import { z } from 'zod';

const alertTypeSchema = z.enum([
  'arrival',
  'departure',
  'sos',
  'low_battery',
  'device_offline',
  'inactivity'
]);

const geofenceSchema = z.object({
  id: z.string().min(1),
  lat: z.number(),
  lng: z.number(),
  radiusMeters: z.number(),
  name: z.string().min(1)
});

const locationEventSchema = z.object({
  userId: z.string().min(1),
  lat: z.number(),
  lng: z.number(),
  accuracy: z.number().nonnegative(),
  speed: z.number().nonnegative().optional(),
  recordedAt: z.string(),
  processedAt: z.string()
});

const alertEntitySchema = z.object({
  id: z.string().min(1),
  circleId: z.string().min(1),
  userId: z.string().min(1),
  type: alertTypeSchema,
  geofenceId: z.string().min(1).optional(),
  message: z.string().min(1),
  createdAt: z.string(),
  resolvedAt: z.string().optional(),
  acknowledged: z.boolean()
});

export const createCircleSchema = z.object({
  name: z.string().min(2),
  type: z.enum(['family', 'care', 'team']),
  userId: z.string().min(1)
});

export const locationPingSchema = z.object({
  userId: z.string().uuid().or(z.string().min(1)),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  accuracy: z.number().nonnegative(),
  speed: z.number().nonnegative().optional(),
  recordedAt: z.string()
});

export const sendOtpSchema = z.object({
  phone: z.string().regex(/^\+[1-9]\d{6,14}$/)
});

export const verifyOtpSchema = z.object({
  phone: z.string().regex(/^\+[1-9]\d{6,14}$/),
  code: z.string().regex(/^\d{6}$/)
});

export const createAlertSchema = z.object({
  circleId: z.string().min(1),
  userId: z.string().min(1),
  type: alertTypeSchema,
  message: z.string().min(1).max(500),
  geofenceId: z.string().min(1).optional()
});

export const sosSchema = z.object({
  userId: z.string().min(1),
  circleId: z.string().min(1),
  lat: z.number().finite(),
  lng: z.number().finite()
});

export const createCircleResponseSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  type: z.enum(['family', 'care', 'team']),
  createdAt: z.string(),
  members: z.array(z.string()),
  geofences: z.array(geofenceSchema)
});

export const locationPingResponseSchema = z.object({
  accepted: z.boolean(),
  event: locationEventSchema,
  timestamp: z.string()
});

export const sendOtpResponseSchema = z.object({
  sent: z.boolean()
});

export const verifyOtpResponseSchema = z.object({
  token: z.string().min(1)
});

export const createAlertResponseSchema = alertEntitySchema;

export const sosResponseSchema = z.object({
  accepted: z.boolean(),
  type: z.literal('sos'),
  alert: alertEntitySchema
});
