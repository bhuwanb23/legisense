export interface ContractTemplate {
  type: string;
  jurisdiction: string;
  title: string;
  body: string;
}

export const CONTRACT_TEMPLATES: ContractTemplate[] = [
  {
    type: 'rental_agreement',
    jurisdiction: 'MH',
    title: 'Fair Maharashtra Leave and Licence (Residential)',
    body: `LEAVE AND LICENCE AGREEMENT (FAIR FORM)

This Leave and Licence Agreement is made at Mumbai, Maharashtra BETWEEN the Licensor and the Licensee.

1. GRANT. The Licensor grants a personal, non-exclusive licence to use the residential premises for the Term stated in the schedule. This licence does not create a tenancy except as required by applicable law.

2. LICENCE FEE. The Licensee shall pay the monthly licence fee on or before the 10th day of each month. Any increase requires written mutual agreement and shall not exceed 5% per year.

3. SECURITY DEPOSIT. Deposit shall not exceed three (3) months' licence fee, shall be kept in a segregated account, and shall be refunded with accrued interest within 15 days of vacant possession, less only documented damage beyond ordinary wear.

4. LOCK-IN AND NOTICE. Any lock-in shall not exceed three (3) months. After lock-in either party may terminate with 30 days' written notice. Liquidated damages, if any, shall not exceed one month's fee.

5. REPAIRS. The Licensor shall keep the structure, plumbing, and electrical systems in habitable condition. The Licensee shall keep the interior reasonably clean.

6. DEFAULT. If fee is unpaid, the Licensor shall give 15 days' written notice to cure. The Licensor shall not lock out, disconnect utilities, or seize goods without a court order.

7. INDEMNITY. Each party indemnifies the other only for loss caused by its own negligence or wilful default, capped at 12 months' licence fee, excluding the indemnified party's own negligence.

8. STAMP AND REGISTRATION. The parties shall stamp and, if required, register this instrument under Maharashtra law. Stamp duty shall be shared equally unless otherwise agreed.

9. DISPUTE RESOLUTION. Disputes shall first go to mediation in Mumbai, then to the courts at Mumbai, Maharashtra.

10. GOVERNING LAW. Laws of India and the State of Maharashtra apply.`,
  },
  {
    type: 'nda',
    jurisdiction: 'IN',
    title: 'Fair Mutual Non-Disclosure Agreement',
    body: `MUTUAL NON-DISCLOSURE AGREEMENT (FAIR FORM)

The parties agree to protect Confidential Information exchanged for a stated Purpose.

1. MUTUAL OBLIGATIONS. Both parties are Disclosing and Receiving parties. Confidential Information is information marked confidential or that a reasonable person would treat as confidential.

2. EXCLUSIONS. Information that is public, independently developed, or rightfully received from a third party without duty of confidence is not confidential.

3. USE. The Receiving Party shall use Confidential Information only for the Purpose and shall protect it with at least reasonable care.

4. TERM. Confidentiality lasts for three (3) years from disclosure, except trade secrets which last while they remain secrets.

5. RETURN. On written request, the Receiving Party shall return or destroy Confidential Information, except one copy kept for legal archival.

6. NO LICENCE. Nothing grants IP rights except the limited right to use for the Purpose.

7. REMEDIES. Injunctions may be sought, but liquidated damages and unlimited indemnity are not included.

8. GOVERNING LAW. Laws of India. Courts at the parties' agreed city have jurisdiction.`,
  },
  {
    type: 'employment_contract',
    jurisdiction: 'IN',
    title: 'Fair Employment Agreement (India)',
    body: `EMPLOYMENT AGREEMENT (FAIR FORM)

The Company employs the Employee in the role stated in the schedule.

1. DUTIES. The Employee shall perform the role in good faith. The Company shall provide tools and a safe workplace.

2. PAY AND BENEFITS. Salary is paid monthly. Statutory benefits (PF, ESI, gratuity, leave) apply as required by Indian law and cannot be waived.

3. PROBATION. Probation, if any, shall not exceed six months, with written confirmation or extension.

4. NOTICE. Either party may terminate with 30 days' written notice or payment in lieu. Summary dismissal is limited to proven gross misconduct after an opportunity to be heard.

5. NON-COMPETE. Any post-employment non-compete shall not exceed six months, must be limited to the Employee's actual function and cities of work, and is void if the Company terminates without cause.

6. CONFIDENTIALITY. Confidentiality lasts while information remains confidential, not in perpetuity for public facts.

7. IP. Work product created in the course of employment for the Company belongs to the Company. Pre-existing IP remains with the Employee.

8. DISPUTE RESOLUTION. Internal grievance first, then courts at the place of employment.

9. GOVERNING LAW. Laws of India.`,
  },
];

export function findTemplate(type: string, jurisdiction?: string): ContractTemplate | undefined {
  const key = type.toLowerCase().replace(/[\s-]+/g, '_');
  const aliased = key === 'non_disclosure' ? 'nda' : key === 'lease' || key === 'leave_and_licence' ? 'rental_agreement' : key;
  const matches = CONTRACT_TEMPLATES.filter((t) => t.type === aliased || t.type === key);
  if (jurisdiction) {
    const jur = jurisdiction.toUpperCase();
    return matches.find((t) => t.jurisdiction === jur) || matches[0];
  }
  return matches[0];
}
