/** Adjacency maps keyed by country_code → state_code → neighboring state codes */
export const neighboringStates: Record<string, Record<string, string[]>> = {
  IN: {
    MH: ['GJ', 'MP', 'CT', 'TG', 'KA', 'GA', 'DN'],
    DL: ['HR', 'UP'],
    KA: ['MH', 'GA', 'AP', 'TG', 'TN', 'KL'],
    KL: ['KA', 'TN'],
    TN: ['KA', 'KL', 'AP', 'PY'],
    TG: ['MH', 'CT', 'AP', 'KA'],
    AP: ['TG', 'OR', 'TN', 'KA', 'CT'],
    GJ: ['RJ', 'MP', 'MH', 'DN'],
    RJ: ['PB', 'HR', 'UP', 'MP', 'GJ'],
    UP: ['UK', 'HR', 'DL', 'RJ', 'MP', 'CT', 'JH', 'BR'],
    WB: ['OR', 'JH', 'BR', 'SK'],
    PB: ['JK', 'HP', 'HR', 'RJ', 'CH'],
    HR: ['PB', 'HP', 'UK', 'UP', 'RJ', 'DL', 'CH'],
    MP: ['RJ', 'UP', 'CT', 'MH', 'GJ'],
    CT: ['MP', 'MH', 'TG', 'OR', 'JH', 'UP'],
    OR: ['WB', 'JH', 'CT', 'AP'],
    BR: ['UP', 'JH', 'WB'],
    JH: ['BR', 'WB', 'OR', 'CT', 'UP'],
    GA: ['MH', 'KA'],
    UK: ['HP', 'HR', 'UP'],
    HP: ['JK', 'PB', 'HR', 'UK'],
  },
  US: {
    CA: ['OR', 'NV', 'AZ'],
    NY: ['NJ', 'PA', 'CT', 'VT', 'MA'],
    TX: ['NM', 'OK', 'AR', 'LA'],
    FL: ['GA', 'AL'],
    WA: ['OR', 'ID'],
    OR: ['WA', 'ID', 'CA', 'NV'],
    NV: ['OR', 'ID', 'UT', 'AZ', 'CA'],
    AZ: ['CA', 'NV', 'UT', 'NM'],
  },
  CA: {
    ON: ['QC', 'MB'],
    BC: ['AB', 'YT', 'NT'],
    QC: ['ON', 'NB', 'NL'],
    AB: ['BC', 'SK', 'NT'],
  },
  AU: {
    NSW: ['QLD', 'SA', 'VIC', 'ACT'],
    VIC: ['NSW', 'SA'],
    QLD: ['NSW', 'SA', 'NT'],
    WA: ['NT', 'SA'],
  },
  GB: {
    ENG: ['SCT', 'WLS'],
    SCT: ['ENG'],
    WLS: ['ENG'],
    NIR: [],
  },
};

export function getNeighborStates(countryCode: string, stateCode: string): string[] {
  return neighboringStates[countryCode]?.[stateCode] ?? [];
}
