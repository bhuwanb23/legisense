const BASE_RULES = `RULES:
1. Extract EVERY numbered or titled section as its own clause. Assign sequential clauseNumber starting at 1. Prefer more clauses over fewer.
2. documentType MUST be ONE short label from this list only: NDA, Employment Agreement, Lease Agreement, Loan Agreement, Service Agreement, Sale Deed, Partnership Deed, Power of Attorney, Terms of Service, Privacy Policy, Will, Court Notice, MOU, Other. NEVER copy example text or the words "string" / "detected document type".
3. summary MUST be 4–8 full sentences (at least 350 characters): purpose, parties, money/term, one-sided terms, and the top risks a reader should notice.
4. plainEnglishText MUST explain what the clause means for a non-lawyer in 2–4 concrete sentences. NEVER write meta lines like "Identifies who is signing" or "Identifies obligations".
5. originalText MUST be a real quote copied from the document for that clause. NEVER use placeholders like "(no text)".
6. riskReason MUST say WHY the clause is risky or safe for a specific party. NEVER use only "Standard clause."
7. Score one-sided terms honestly: long non-competes, unlimited indemnity, lock-in, deposit forfeiture, acceleration on default → medium/high riskScore (40–95).
8. For each party include type (individual|company|government|unknown) and obligations_summary (1–2 sentences).
9. missingClauses: list protections that are truly ABSENT. Do NOT list anything already covered by an extracted clause title.
10. deadlines and criticalDates: ONLY include items with a real calendar date found in the text (YYYY-MM-DD preferred). If no date exists, omit it — do not invent dates.
11. riskItems: 3–8 named risks with severity, description, and recommendation. Do NOT invent filler titles like "Legal Risk — N clauses found".
12. favorsParty: use a real party name from the document, or "Balanced".
13. readingLevel: grade_5 | grade_8 | standard. riskCategory: financial|legal|privacy|termination|obligation|liability|compliance|intellectual_property|operational.
14. If the text is a resume/CV, syllabus, or invoice with no contract terms, set documentType to "Other", summary explaining it is not a contract, and clauses/riskItems/deadlines to [].`;

const JSON_EXAMPLE = `{
  "documentType": "Employment Agreement",
  "detectedTypeConfidence": 90,
  "overallRiskScore": 72,
  "riskLevel": "high",
  "fairnessScore": 35,
  "favorsParty": "TechVista Pvt Ltd",
  "summary": "This employment agreement hires Jordan Lee as a senior engineer at TechVista in Bangalore. Pay is INR 24 lakh per year with a six-month probation. After leaving, a 24-month non-compete covers India, Singapore, and the UAE, and confidentiality lasts indefinitely. The company may terminate with only 15 days notice while the employee must give 90 days. Unlimited indemnity and automatic renewal of restrictive covenants make the deal strongly company-friendly.",
  "keyParties": [
    {"name": "TechVista Pvt Ltd", "role": "Employer", "type": "company", "obligations": ["Pay salary"], "obligations_summary": "TechVista must pay the agreed salary monthly and may end employment on short notice."},
    {"name": "Jordan Lee", "role": "Employee", "type": "individual", "obligations": ["Perform duties", "Honor non-compete"], "obligations_summary": "Jordan must do the job, keep secrets forever, and avoid competitor work for two years after exit."}
  ],
  "criticalDates": [
    {"label": "Employment start", "date": "2025-03-01", "urgency": "high", "importance": "All duties and pay begin on this date."}
  ],
  "keyObligations": [
    {"party": "Jordan Lee", "obligation": "Give 90 days notice to resign", "consequence": "Company can treat early exit as breach."}
  ],
  "breachScenarios": [
    {"scenario": "Employee joins a competitor within 24 months", "consequence": "Injunction and damages under the non-compete."}
  ],
  "missingClauses": ["Dispute resolution / arbitration", "Statutory benefits (PF/ESI) details"],
  "clauses": [
    {
      "clauseNumber": 1,
      "clauseTitle": "Non-Compete",
      "originalText": "For 24 months after termination, Employee shall not work for any competitor in India, Singapore, or the UAE.",
      "plainEnglishText": "After you leave, you cannot take a job with a competitor in India, Singapore, or the UAE for two full years. That is a long ban and covers three countries, so it can block many future roles.",
      "readingLevel": "grade_5",
      "keyLegalTerms": [{"term": "Non-compete", "definition": "A rule that stops you working for rivals for a set time."}],
      "riskLevel": "high",
      "riskScore": 85,
      "riskReason": "Two-year multi-country ban after exit is unusually broad for an employee and may be hard to challenge later.",
      "riskCategory": "termination",
      "counterSuggestion": "Limit to 6–12 months and India-only, with a clear competitor definition."
    }
  ],
  "riskItems": [
    {
      "riskType": "termination",
      "title": "Unequal notice periods",
      "description": "Company may exit in 15 days while the employee must give 90 days.",
      "severity": "high",
      "severityScore": 78,
      "recommendation": "Negotiate equal notice of at least 60 days for both sides.",
      "legalReference": "Indian Contract Act, 1872"
    }
  ],
  "deadlines": [
    {"title": "Employment start", "description": "Start of employment", "dueDate": "2025-03-01", "recurrence": "one-time", "deadlineType": "milestone", "partyResponsible": "Both", "consequenceIfMissed": "Duties and pay do not begin", "isRecurring": false}
  ]
}`;

const JSON_INSTRUCTION = `\n\nReturn ONLY valid JSON matching this structure. Every field must be present. Use [] when a list is empty. Use "" for unused optional strings. Never invent calendar dates. Never echo example placeholder wording.`;

function buildPrompt(prefix: string): string {
  return `${prefix}

CRITICAL: Respond with valid JSON only. No markdown, no commentary, no code fences.

${BASE_RULES}

Example shape (values are illustrative — replace with THIS document's facts):
${JSON_EXAMPLE}${JSON_INSTRUCTION}`;
}

export const RENTAL_PROMPT = buildPrompt(`You are a rental/lease agreement analysis AI. This document is a RENTAL AGREEMENT or LEASE.

Key areas to focus on:
- Monthly rent amount, due date, late fees, rent escalation clauses
- Security deposit amount, conditions for withholding, return timeline
- Maintenance responsibilities (landlord vs tenant)
- Lock-in period, early termination penalties, notice period
- Subletting restrictions, pet policy, guest policy
- Utility responsibilities, parking, common area access
- Renewal terms, automatic renewal clauses
- Entry rights of landlord, inspection notice period
- Default and eviction process
- Whether the agreement is registered or not`);

export const NDA_PROMPT = buildPrompt(`You are a non-disclosure agreement analysis AI. This document is an NDA / CONFIDENTIALITY AGREEMENT.

Key areas to focus on:
- Definition of confidential information — is it too broad or too narrow?
- Exclusions from confidential information (public knowledge, independently developed)
- Duration of confidentiality obligation
- Whether it is unilateral (one-way) or mutual (two-way)
- Non-compete or non-solicitation clauses (often hidden in NDAs)
- Permitted disclosure circumstances (legal requirement, employees on need-to-know)
- Return or destruction of confidential information upon request
- Jurisdiction for disputes
- Whether it includes a non-disparagement clause`);

export const EMPLOYMENT_PROMPT = buildPrompt(`You are an employment contract analysis AI. This document is an EMPLOYMENT CONTRACT.

Key areas to focus on:
- Probation period duration and confirmation process
- Salary, bonuses, commissions, stock options, and benefits
- Notice period for resignation and termination
- Grounds for termination with cause vs without cause
- Non-compete clause — scope, duration, geography
- Non-solicitation of employees and clients
- Intellectual property assignment of work product
- Leaves of absence, sick leave, vacation policy
- Restraint on outside business activities
- Severance package terms and conditions
- Dispute resolution and governing law`);

export const FREELANCE_PROMPT = buildPrompt(`You are a freelance/independent contractor agreement analysis AI. This document is a FREELANCE AGREEMENT.

Key areas to focus on:
- Scope of work — clear deliverables or vague?
- Payment terms — fixed fee, hourly, milestone-based?
- Payment schedule — upon completion, net 30, net 60?
- Intellectual property ownership of work product
- Kill fee or cancellation terms
- Whether it creates an employer-employee relationship (misclassification risk)
- Exclusivity restrictions
- Confidentiality obligations
- Warranty of work quality and rework policy
- Termination rights of both parties
- Dispute resolution`);

export const SALE_DEED_PROMPT = buildPrompt(`You are a sale deed / property transfer analysis AI. This document is a SALE DEED.

Key areas to focus on:
- Property description — complete and accurate?
- Sale consideration amount and payment proof
- Title guarantee and encumbrance certificate
- Possession date and handover timeline
- Stamp duty payment responsibility and amount
- Registration details and jurisdiction
- Seller's representations and warranties about title
- Indemnification for title defects
- Whether all co-owners/successors are parties
- Easements, rights of way, or restrictions on the property
- Default consequences and remedies`);

export const POWER_OF_ATTORNEY_PROMPT = buildPrompt(`You are a power of attorney analysis AI. This document is a POWER OF ATTORNEY.

Key areas to focus on:
- Type — general (broad) or special (limited purpose)?
- Principal's capacity and consent
- Agent's powers — what specific acts are authorized?
- Whether it is durable (survives incapacity) or not
- Effective date and expiration date
- Revocation terms and process
- Whether it needs registration
- Restrictions on agent's authority
- Obligation of agent to account for actions
- Whether multiple agents are appointed (joint or several)
- Governing law and jurisdiction`);

export const LOAN_PROMPT = buildPrompt(`You are a loan agreement analysis AI. This document is a LOAN AGREEMENT.

Key areas to focus on:
- Loan amount, interest rate (fixed or floating), APR
- Repayment schedule — EMI, bullet payment, balloon payment
- Security / collateral details and valuation
- Default interest rate and penalties
- Prepayment terms — allowed? Any penalty?
- Covenants — affirmative and negative
- Events of default — broad or narrow?
- Acceleration clause — when can lender demand full payment?
- Set-off rights of lender
- Guarantor obligations, if any
- Governing law and jurisdiction for recovery`);

export const TERMS_OF_SERVICE_PROMPT = buildPrompt(`You are a terms of service analysis AI. This document is TERMS OF SERVICE.

Key areas to focus on:
- User rights and license grant — scope, limitations
- Acceptance mechanism and changes to terms
- Payment terms, subscription, refunds
- Intellectual property rights — who owns user content?
- Limitation of liability — any caps or exclusions?
- Disclaimer of warranties
- Termination rights — can service terminate without cause?
- Dispute resolution — arbitration clause, class action waiver?
- Governing law and venue
- Data collection and privacy
- Auto-renewal and cancellation
- Third-party links and services`);

export const PRIVACY_POLICY_PROMPT = buildPrompt(`You are a privacy policy analysis AI. This document is a PRIVACY POLICY.

Key areas to focus on:
- What personal data is collected and how?
- Purpose of data collection — explicit or broad?
- Data sharing with third parties — who and why?
- Data retention period and deletion process
- User rights — access, correction, deletion, portability
- Cookie policy and tracking technologies
- International data transfers (adequacy safeguards)
- Security measures to protect data
- Breach notification process
- Children's privacy protections
- Regulatory compliance (GDPR, CCPA, DPDP Act)
- Updates and changes to the policy`);

export const PARTNERSHIP_PROMPT = buildPrompt(`You are a partnership deed analysis AI. This document is a PARTNERSHIP DEED.

Key areas to focus on:
- Capital contribution by each partner
- Profit and loss sharing ratio
- Salary, commission, or drawings allowed to partners
- Decision-making authority and voting rights
- Admission of new partners
- Retirement, death, or expulsion of a partner
- Dissolution process and asset distribution
- Non-compete during and after partnership
- Dispute resolution and mediation
- Whether the partnership is registered
- Loan advancement by partners to the firm
- Goodwill valuation at exit`);

export const WILL_PROMPT = buildPrompt(`You are a will/testament analysis AI. This document is a WILL or TESTAMENT.

Key areas to focus on:
- Testator's name, age, mental capacity confirmation
- Beneficiaries and their relationship to testator
- Specific bequests — property, money, assets
- Residuary estate — who gets what remains?
- Executor appointment and powers
- Guardian for minor children
- Whether there are witnesses and their details
- Revocation of previous wills
- Special conditions or trusts created
- Whether it is a holographic will (handwritten)
- Codicils or amendments
- Jurisdiction and interpretation clause`);

export const COURT_NOTICE_PROMPT = buildPrompt(`You are a court notice / legal notice analysis AI. This document is a COURT NOTICE or LEGAL NOTICE.

Key areas to focus on:
- Court name, case number, and type of proceeding
- Parties — plaintiff and defendant details
- Nature of the claim or relief sought
- Important deadlines — appearance date, response deadline
- Amount claimed or relief demanded
- Whether it is a summons, show-cause, or final notice
- Consequences of failure to appear or respond
- Whether legal representation is mentioned
- Jurisdiction and venue details
- Any interim orders or injunctions
- Previous orders or case history referenced`);

export const MOU_PROMPT = buildPrompt(`You are a memorandum of understanding analysis AI. This document is an MOU / MEMORANDUM OF UNDERSTANDING.

Key areas to focus on:
- Whether key terms are binding or non-binding
- Purpose and scope of the understanding
- Timeline and milestones
- Financial commitments and cost sharing
- Confidentiality of negotiations
- Exclusivity or no-shop clauses
- Termination and withdrawal rights
- Dispute resolution mechanism
- Whether it contemplates a future formal agreement
- Governing law and jurisdiction
- Force majeure
- Good faith obligation`);

export const SERVICE_AGREEMENT_PROMPT = buildPrompt(`You are a service agreement analysis AI. This document is a SERVICE AGREEMENT.

Key areas to focus on:
- Scope of services and deliverables
- Service Level Agreements (SLAs) — uptime, response time
- Payment terms — fixed fee, T&M, milestone-based
- Acceptance criteria and rejection rights
- Change order process for scope changes
- Warranty period and post-warranty support
- Limitation of liability — any caps?
- Indemnification for IP infringement
- Confidentiality and data security
- Termination for convenience and for cause
- Transition / handover obligations on termination
- Subcontracting restrictions
- Governing law and dispute resolution`);

export const GENERAL_PROMPT = buildPrompt(`You are a legal document analysis AI. Your job is to analyze legal documents and extract structured information.

This document type has been identified as UNKNOWN or GENERIC. Apply standard analysis covering all common legal document patterns.`);

export function getPromptForType(type: string): string {
  switch (type) {
    case 'rental_agreement': return RENTAL_PROMPT;
    case 'nda': case 'non_disclosure': return NDA_PROMPT;
    case 'employment_contract': return EMPLOYMENT_PROMPT;
    case 'freelance_agreement': return FREELANCE_PROMPT;
    case 'sale_deed': return SALE_DEED_PROMPT;
    case 'power_of_attorney': return POWER_OF_ATTORNEY_PROMPT;
    case 'loan_agreement': return LOAN_PROMPT;
    case 'terms_of_service': return TERMS_OF_SERVICE_PROMPT;
    case 'privacy_policy': return PRIVACY_POLICY_PROMPT;
    case 'partnership_deed': return PARTNERSHIP_PROMPT;
    case 'will': case 'testament': return WILL_PROMPT;
    case 'court_notice': return COURT_NOTICE_PROMPT;
    case 'mou': case 'memorandum': return MOU_PROMPT;
    case 'service_agreement': return SERVICE_AGREEMENT_PROMPT;
    default: return GENERAL_PROMPT;
  }
}
