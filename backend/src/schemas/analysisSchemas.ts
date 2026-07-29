import { z } from 'zod';

export const PartySchema = z.object({
  name: z.string().min(1),
  role: z.string().min(1),
  type: z.enum(['individual', 'company', 'government', 'unknown']).default('unknown'),
  obligations: z.array(z.string()).default([]),
  obligations_summary: z.string().min(1),
});

export const ClauseSchema = z.object({
  clauseNumber: z.number().int().positive(),
  clauseTitle: z.string().min(1),
  originalText: z.string().min(1),
  plainEnglishText: z.string().min(1),
  readingLevel: z.enum(['grade_5', 'grade_8', 'standard']),
  keyLegalTerms: z.array(z.object({
    term: z.string().min(1),
    definition: z.string().min(1),
  })).default([]),
  riskLevel: z.enum(['none', 'low', 'medium', 'high']),
  riskScore: z.number().min(0).max(100),
  riskReason: z.string(),
  riskCategory: z.enum(['financial', 'legal', 'privacy', 'termination', 'obligation', 'liability', 'compliance', 'intellectual_property', 'operational']),
  counterSuggestion: z.string(),
});

export const CriticalDateSchema = z.object({
  label: z.string().min(1),
  date: z.string().min(1),
  urgency: z.enum(['high', 'medium', 'low']),
  importance: z.string().min(1),
});

export const KeyObligationSchema = z.object({
  party: z.string().min(1),
  obligation: z.string().min(1),
  consequence: z.string().min(1),
});

export const BreachScenarioSchema = z.object({
  scenario: z.string().min(1),
  consequence: z.string().min(1),
});

export const RiskItemSchema = z.object({
  riskType: z.enum(['financial', 'liability', 'privacy', 'termination', 'missing', 'compliance', 'legal', 'obligation', 'intellectual_property', 'operational']),
  title: z.string().min(1),
  description: z.string().min(1),
  severity: z.enum(['critical', 'high', 'medium', 'low']),
  severityScore: z.number().min(0).max(100),
  recommendation: z.string(),
  legalReference: z.string(),
});

export const DeadlineSchema = z.object({
  title: z.string().min(1),
  description: z.string().min(1),
  dueDate: z.string().min(1),
  recurrence: z.enum(['one-time', 'monthly', 'yearly', 'quarterly']),
});

export const AnalysisOutputSchema = z.object({
  documentType: z.string().min(1),
  detectedTypeConfidence: z.number().min(0).max(100),
  overallRiskScore: z.number().min(0).max(100),
  riskLevel: z.enum(['low', 'medium', 'high']),
  fairnessScore: z.number().min(0).max(100),
  favorsParty: z.string().min(1),
  summary: z.string().min(1),
  keyParties: z.array(PartySchema).default([]),
  criticalDates: z.array(CriticalDateSchema).default([]),
  keyObligations: z.array(KeyObligationSchema).default([]),
  missingClauses: z.array(z.string()).default([]),
  clauses: z.array(ClauseSchema).default([]),
  riskItems: z.array(RiskItemSchema).default([]),
  deadlines: z.array(DeadlineSchema).default([]),
  breachScenarios: z.array(BreachScenarioSchema).default([]),
});

export type Party = z.infer<typeof PartySchema>;
export type Clause = z.infer<typeof ClauseSchema>;
export type CriticalDate = z.infer<typeof CriticalDateSchema>;
export type KeyObligation = z.infer<typeof KeyObligationSchema>;
export type RiskItem = z.infer<typeof RiskItemSchema>;
export type Deadline = z.infer<typeof DeadlineSchema>;
export type BreachScenario = z.infer<typeof BreachScenarioSchema>;
export type AnalysisOutput = z.infer<typeof AnalysisOutputSchema>;
