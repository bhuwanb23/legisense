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
  return DOCUMENT_TYPES.find(
    (t) => t.type === type
  ) ?? DOCUMENT_TYPES.find((t) => t.type === 'unknown')!;
}

export function getValidTypes(): string[] {
  return [...new Set(DOCUMENT_TYPES.map((t) => t.type))];
}
