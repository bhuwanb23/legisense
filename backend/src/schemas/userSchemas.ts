import { z } from 'zod';

export const updateProfileSchema = z.object({
  fullName: z.string().min(2).max(100).optional(),
  phoneNumber: z.string().optional(),
  profession: z.string().optional(),
  profilePhotoUrl: z.string().url().optional(),
});

export const updatePreferencesSchema = z.object({
  preferredLanguage: z.string().min(2).max(5).optional(),
  defaultJurisdiction: z.string().optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
export type UpdatePreferencesInput = z.infer<typeof updatePreferencesSchema>;
