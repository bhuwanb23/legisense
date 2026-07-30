export interface JurisdictionSeed {
  countryCode: string;
  countryName: string;
  stateCode: string | null;
  stateName: string | null;
}

const INDIA_STATES: Array<[string, string]> = [
  ['AP', 'Andhra Pradesh'], ['AR', 'Arunachal Pradesh'], ['AS', 'Assam'], ['BR', 'Bihar'],
  ['CT', 'Chhattisgarh'], ['GA', 'Goa'], ['GJ', 'Gujarat'], ['HR', 'Haryana'],
  ['HP', 'Himachal Pradesh'], ['JH', 'Jharkhand'], ['KA', 'Karnataka'], ['KL', 'Kerala'],
  ['MP', 'Madhya Pradesh'], ['MH', 'Maharashtra'], ['MN', 'Manipur'], ['ML', 'Meghalaya'],
  ['MZ', 'Mizoram'], ['NL', 'Nagaland'], ['OR', 'Odisha'], ['PB', 'Punjab'],
  ['RJ', 'Rajasthan'], ['SK', 'Sikkim'], ['TN', 'Tamil Nadu'], ['TG', 'Telangana'],
  ['TR', 'Tripura'], ['UP', 'Uttar Pradesh'], ['UK', 'Uttarakhand'], ['WB', 'West Bengal'],
];

const INDIA_UTS: Array<[string, string]> = [
  ['AN', 'Andaman and Nicobar Islands'], ['CH', 'Chandigarh'],
  ['DN', 'Dadra and Nagar Haveli and Daman and Diu'], ['DL', 'Delhi'],
  ['JK', 'Jammu and Kashmir'], ['LA', 'Ladakh'], ['LD', 'Lakshadweep'], ['PY', 'Puducherry'],
];

const US_STATES: Array<[string, string]> = [
  ['AL', 'Alabama'], ['AK', 'Alaska'], ['AZ', 'Arizona'], ['AR', 'Arkansas'], ['CA', 'California'],
  ['CO', 'Colorado'], ['CT', 'Connecticut'], ['DE', 'Delaware'], ['FL', 'Florida'], ['GA', 'Georgia'],
  ['HI', 'Hawaii'], ['ID', 'Idaho'], ['IL', 'Illinois'], ['IN', 'Indiana'], ['IA', 'Iowa'],
  ['KS', 'Kansas'], ['KY', 'Kentucky'], ['LA', 'Louisiana'], ['ME', 'Maine'], ['MD', 'Maryland'],
  ['MA', 'Massachusetts'], ['MI', 'Michigan'], ['MN', 'Minnesota'], ['MS', 'Mississippi'], ['MO', 'Missouri'],
  ['MT', 'Montana'], ['NE', 'Nebraska'], ['NV', 'Nevada'], ['NH', 'New Hampshire'], ['NJ', 'New Jersey'],
  ['NM', 'New Mexico'], ['NY', 'New York'], ['NC', 'North Carolina'], ['ND', 'North Dakota'], ['OH', 'Ohio'],
  ['OK', 'Oklahoma'], ['OR', 'Oregon'], ['PA', 'Pennsylvania'], ['RI', 'Rhode Island'], ['SC', 'South Carolina'],
  ['SD', 'South Dakota'], ['TN', 'Tennessee'], ['TX', 'Texas'], ['UT', 'Utah'], ['VT', 'Vermont'],
  ['VA', 'Virginia'], ['WA', 'Washington'], ['WV', 'West Virginia'], ['WI', 'Wisconsin'], ['WY', 'Wyoming'],
  ['DC', 'District of Columbia'],
];

const CA_PROVINCES: Array<[string, string]> = [
  ['AB', 'Alberta'], ['BC', 'British Columbia'], ['MB', 'Manitoba'], ['NB', 'New Brunswick'],
  ['NL', 'Newfoundland and Labrador'], ['NS', 'Nova Scotia'], ['NT', 'Northwest Territories'],
  ['NU', 'Nunavut'], ['ON', 'Ontario'], ['PE', 'Prince Edward Island'], ['QC', 'Quebec'],
  ['SK', 'Saskatchewan'], ['YT', 'Yukon'],
];

const AU_STATES: Array<[string, string]> = [
  ['NSW', 'New South Wales'], ['VIC', 'Victoria'], ['QLD', 'Queensland'], ['WA', 'Western Australia'],
  ['SA', 'South Australia'], ['TAS', 'Tasmania'], ['ACT', 'Australian Capital Territory'],
  ['NT', 'Northern Territory'],
];

const UK_NATIONS: Array<[string, string]> = [
  ['ENG', 'England'], ['SCT', 'Scotland'], ['WLS', 'Wales'], ['NIR', 'Northern Ireland'],
];

function expand(
  countryCode: string,
  countryName: string,
  states: Array<[string, string]>,
): JurisdictionSeed[] {
  const rows: JurisdictionSeed[] = [
    { countryCode, countryName, stateCode: null, stateName: null },
  ];
  for (const [code, name] of states) {
    rows.push({ countryCode, countryName, stateCode: code, stateName: name });
  }
  return rows;
}

export const jurisdictionSeeds: JurisdictionSeed[] = [
  ...expand('IN', 'India', [...INDIA_STATES, ...INDIA_UTS]),
  ...expand('US', 'United States', US_STATES),
  ...expand('CA', 'Canada', CA_PROVINCES),
  ...expand('AU', 'Australia', AU_STATES),
  ...expand('GB', 'United Kingdom', UK_NATIONS),
];
