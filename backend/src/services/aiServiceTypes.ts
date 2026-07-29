export interface AiAnalysisResult {
  documentType: string;
  detectedTypeConfidence: number;
  overallRiskScore: number;
  riskLevel: string;
  fairnessScore: number;
  favorsParty: string;
  summary: string;
  keyParties: Array<{ name: string; role: string; obligations: string[] }>;
  criticalDates: Array<{ label: string; date: string; urgency: string }>;
  keyObligations: Array<{ party: string; obligation: string }>;
  missingClauses: string[];
  clauses: Array<{
    clauseNumber: number;
    clauseTitle: string;
    originalText: string;
    plainEnglishText: string;
    riskLevel: string;
    riskScore: number;
    riskReason: string;
    riskCategory: string;
    counterSuggestion: string;
  }>;
  riskItems: Array<{
    riskType: string;
    title: string;
    description: string;
    severity: string;
    severityScore: number;
    recommendation: string;
    legalReference: string;
  }>;
  deadlines: Array<{
    title: string;
    description: string;
    dueDate: string;
    recurrence: string;
  }>;
}
