export interface DocumentTypeEntry {
  type: string;
  typeLabel: string;
  icon: string;
  subTypes: string[];
}

export const DOCUMENT_TYPES: DocumentTypeEntry[] = [
  { type: 'rental_agreement', typeLabel: 'Rental Agreement', icon: 'home', subTypes: ['residential_lease', 'commercial_lease', 'room_rental'] },
  { type: 'nda', typeLabel: 'Non-Disclosure Agreement', icon: 'lock', subTypes: ['unilateral_nda', 'mutual_nda', 'employee_nda'] },
  { type: 'non_disclosure', typeLabel: 'Non-Disclosure Agreement', icon: 'lock', subTypes: ['unilateral_nda', 'mutual_nda', 'employee_nda'] },
  { type: 'employment_contract', typeLabel: 'Employment Contract', icon: 'briefcase', subTypes: ['permanent', 'fixed_term', 'probation'] },
  { type: 'freelance_agreement', typeLabel: 'Freelance Agreement', icon: 'pen_tool', subTypes: ['project_based', 'retainer', 'milestone'] },
  { type: 'sale_deed', typeLabel: 'Sale Deed', icon: 'file_text', subTypes: ['property_sale', 'asset_sale', 'business_sale'] },
  { type: 'power_of_attorney', typeLabel: 'Power of Attorney', icon: 'user_check', subTypes: ['general', 'special', 'durable'] },
  { type: 'loan_agreement', typeLabel: 'Loan Agreement', icon: 'dollar_sign', subTypes: ['personal_loan', 'business_loan', 'secured_loan'] },
  { type: 'terms_of_service', typeLabel: 'Terms of Service', icon: 'file', subTypes: ['saas', 'ecommerce', 'mobile_app'] },
  { type: 'privacy_policy', typeLabel: 'Privacy Policy', icon: 'shield', subTypes: ['website', 'app', 'enterprise'] },
  { type: 'partnership_deed', typeLabel: 'Partnership Deed', icon: 'users', subTypes: ['general_partnership', 'limited_partnership'] },
  { type: 'will', typeLabel: 'Will / Testament', icon: 'file', subTypes: ['simple_will', 'testamentary_trust', 'living_will'] },
  { type: 'testament', typeLabel: 'Will / Testament', icon: 'file', subTypes: ['simple_will', 'testamentary_trust', 'living_will'] },
  { type: 'court_notice', typeLabel: 'Court Notice', icon: 'gavel', subTypes: ['summons', 'legal_notice', 'show_cause'] },
  { type: 'mou', typeLabel: 'Memorandum of Understanding', icon: 'handshake', subTypes: ['joint_venture', 'collaboration', 'term_sheet'] },
  { type: 'memorandum', typeLabel: 'Memorandum of Understanding', icon: 'handshake', subTypes: ['joint_venture', 'collaboration', 'term_sheet'] },
  { type: 'service_agreement', typeLabel: 'Service Agreement', icon: 'settings', subTypes: ['professional_services', 'consulting', 'maintenance'] },
  { type: 'unknown', typeLabel: 'Unknown Document', icon: 'help_circle', subTypes: [] },
];

export function getTypeEntry(type: string): DocumentTypeEntry {
  const key = normalizeTypeKey(type);
  return DOCUMENT_TYPES.find(
    (t) => t.type === key
  ) ?? DOCUMENT_TYPES.find((t) => t.type === 'unknown')!;
}

export function getValidTypes(): string[] {
  return [...new Set(DOCUMENT_TYPES.map((t) => t.type))];
}

/**
 * Map an arbitrary classifier string (key, label, alias, or LLM free-text like
 * "Non-Disclosure Agreement") onto a canonical type key. Falls back to the
 * input normalized, or 'unknown' if nothing matches.
 */
export function normalizeTypeKey(raw: string | null | undefined): string {
  if (!raw) return 'unknown';
  const input = String(raw).trim();
  if (!input) return 'unknown';

  const norm = (s: string) =>
    s.toLowerCase().trim().replace(/[\s\-_/]+/g, '_').replace(/_+/g, '_');
  const key = norm(input);

  // Exact key match first.
  if (DOCUMENT_TYPES.some((t) => t.type === key)) return key;

  // Match against typeLabel, aliases, and subtype fragments.
  for (const t of DOCUMENT_TYPES) {
    const tLabel = norm(t.typeLabel);
    if (key === tLabel) return t.type;
    if (t.subTypes.some((s) => norm(s) === key)) return t.type;
  }

  // Partial / word-set matching: "non disclosure agreement" → nda,
  // "rental agreement" → rental_agreement.
  const words = key.replace(/_/g, ' ').split(' ').filter(Boolean);
  let best: { type: string; score: number } | null = null;
  for (const t of DOCUMENT_TYPES) {
    const tLabelWords = norm(t.typeLabel).replace(/_/g, ' ').split(' ').filter(Boolean);
    let score = 0;
    for (const w of words) {
      if (tLabelWords.includes(w)) score += 1;
    }
    if (t.type === 'nda' && (key.includes('nda') || key.includes('non_disclosure') || key.includes('confidential'))) score += 3;
    if (t.type === 'rental_agreement' && (key.includes('rent') || key.includes('lease'))) score += 3;
    if (t.type === 'employment_contract' && key.includes('employ')) score += 3;
    if (t.type === 'loan_agreement' && key.includes('loan')) score += 3;
    if (t.type === 'sale_deed' && (key.includes('sale') || key.includes('deed'))) score += 3;
    if (t.type === 'power_of_attorney' && key.includes('attorney')) score += 3;
    if (t.type === 'partnership_deed' && key.includes('partner')) score += 3;
    if (t.type === 'court_notice' && (key.includes('court') || key.includes('notice'))) score += 3;
    if (t.type === 'mou' && (key.includes('mou') || key.includes('memorandum'))) score += 3;
    if (t.type === 'terms_of_service' && key.includes('terms')) score += 3;
    if (t.type === 'privacy_policy' && key.includes('privacy')) score += 3;
    if (t.type === 'service_agreement' && key.includes('service')) score += 3;
    if (t.type === 'will' || t.type === 'testament') {
      if (key.includes('will') || key.includes('testament')) score += 3;
    }
    if (score > 0 && (!best || score > best.score)) {
      best = { type: t.type, score };
    }
  }
  if (best) return best.type;

  return 'unknown';
}
