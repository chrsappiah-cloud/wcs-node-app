import { z } from 'zod';

export const createCircleSchema = z.object({
  name: z.string().min(2),
  type: z.enum(['family', 'care', 'team'])
});

export const locationPingSchema = z.object({
  userId: z.string().uuid().or(z.string().min(1)),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  accuracy: z.number().nonnegative(),
  recordedAt: z.string()
});
