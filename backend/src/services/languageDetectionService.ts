import { franc } from 'franc-min';
import { SUPPORTED_LANGUAGES } from '../config/languages';

/** ISO 639-3 → ISO 639-1 for languages we care about */
const ISO3_TO_ISO1: Record<string, string> = {
  eng: 'en', hin: 'hi', tam: 'ta', tel: 'te', kan: 'kn', mal: 'ml', mar: 'mr',
  guj: 'gu', pan: 'pa', ben: 'bn', ori: 'or', asm: 'as', urd: 'ur', spa: 'es',
  fra: 'fr', deu: 'de', por: 'pt', ita: 'it', nld: 'nl', pol: 'pl', rus: 'ru',
  ukr: 'uk', arb: 'ar', ara: 'ar', fas: 'fa', pes: 'fa', tur: 'tr', cmn: 'zh',
  zho: 'zh', jpn: 'ja', kor: 'ko', tha: 'th', vie: 'vi', ind: 'id', msa: 'ms',
  tgl: 'tl', swh: 'sw', hau: 'ha', amh: 'am', nep: 'ne', sin: 'si', mya: 'my',
};

const SUPPORTED_SET = new Set(SUPPORTED_LANGUAGES.map((l) => l.code));

export function toIso6391(code: string | null | undefined): string {
  if (!code) return 'en';
  const lower = code.toLowerCase().split(/[-_]/)[0];
  if (lower.length === 2) return lower;
  return ISO3_TO_ISO1[lower] || 'en';
}

export function detectLanguage(text: string): { language: string; confidence: 'high' | 'medium' | 'low' } {
  const sample = (text || '').replace(/\s+/g, ' ').trim().slice(0, 5000);
  if (sample.length < 20) {
    return { language: 'en', confidence: 'low' };
  }

  const iso3 = franc(sample, { minLength: 20 });
  if (!iso3 || iso3 === 'und') {
    return { language: 'en', confidence: 'low' };
  }

  const iso1 = ISO3_TO_ISO1[iso3] || 'en';
  const confidence = sample.length > 200 ? 'high' : sample.length > 80 ? 'medium' : 'low';

  if (!SUPPORTED_SET.has(iso1)) {
    return { language: iso1, confidence };
  }

  return { language: iso1, confidence };
}
