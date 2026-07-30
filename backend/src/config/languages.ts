export interface SupportedLanguage {
  code: string;
  name: string;
  script?: string;
}

export const SUPPORTED_LANGUAGES: SupportedLanguage[] = [
  { code: 'en', name: 'English', script: 'Latin' },
  { code: 'hi', name: 'Hindi', script: 'Devanagari' },
  { code: 'ta', name: 'Tamil', script: 'Tamil' },
  { code: 'te', name: 'Telugu', script: 'Telugu' },
  { code: 'kn', name: 'Kannada', script: 'Kannada' },
  { code: 'ml', name: 'Malayalam', script: 'Malayalam' },
  { code: 'mr', name: 'Marathi', script: 'Devanagari' },
  { code: 'gu', name: 'Gujarati', script: 'Gujarati' },
  { code: 'pa', name: 'Punjabi', script: 'Gurmukhi' },
  { code: 'bn', name: 'Bengali', script: 'Bengali' },
  { code: 'or', name: 'Odia', script: 'Odia' },
  { code: 'as', name: 'Assamese', script: 'Bengali' },
  { code: 'ur', name: 'Urdu', script: 'Arabic' },
  { code: 'es', name: 'Spanish', script: 'Latin' },
  { code: 'fr', name: 'French', script: 'Latin' },
  { code: 'de', name: 'German', script: 'Latin' },
  { code: 'pt', name: 'Portuguese', script: 'Latin' },
  { code: 'it', name: 'Italian', script: 'Latin' },
  { code: 'nl', name: 'Dutch', script: 'Latin' },
  { code: 'pl', name: 'Polish', script: 'Latin' },
  { code: 'ru', name: 'Russian', script: 'Cyrillic' },
  { code: 'uk', name: 'Ukrainian', script: 'Cyrillic' },
  { code: 'ar', name: 'Arabic', script: 'Arabic' },
  { code: 'fa', name: 'Persian', script: 'Arabic' },
  { code: 'tr', name: 'Turkish', script: 'Latin' },
  { code: 'zh', name: 'Chinese', script: 'Han' },
  { code: 'ja', name: 'Japanese', script: 'Japanese' },
  { code: 'ko', name: 'Korean', script: 'Hangul' },
  { code: 'th', name: 'Thai', script: 'Thai' },
  { code: 'vi', name: 'Vietnamese', script: 'Latin' },
  { code: 'id', name: 'Indonesian', script: 'Latin' },
  { code: 'ms', name: 'Malay', script: 'Latin' },
  { code: 'tl', name: 'Filipino', script: 'Latin' },
  { code: 'sw', name: 'Swahili', script: 'Latin' },
  { code: 'ha', name: 'Hausa', script: 'Latin' },
  { code: 'am', name: 'Amharic', script: 'Ethiopic' },
  { code: 'ne', name: 'Nepali', script: 'Devanagari' },
  { code: 'si', name: 'Sinhala', script: 'Sinhala' },
  { code: 'my', name: 'Burmese', script: 'Myanmar' },
];

export function getLanguageName(code: string): string {
  return SUPPORTED_LANGUAGES.find((l) => l.code === code)?.name || code;
}

export function isSupportedLanguage(code: string): boolean {
  return SUPPORTED_LANGUAGES.some((l) => l.code === code);
}
