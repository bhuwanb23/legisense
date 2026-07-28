import * as cheerio from 'cheerio';
import { URL } from 'url';

export interface ScrapeResult {
  title: string;
  text: string;
  url: string;
  siteName: string | null;
}

export async function scrapeUrl(urlString: string): Promise<ScrapeResult> {
  if (!isValidUrl(urlString)) {
    throw new Error(`Invalid URL: "${urlString}". Only http:// and https:// are supported.`);
  }

  const parsed = new URL(urlString);

  const response = await fetch(urlString, {
    headers: {
      'User-Agent': 'Legisense/1.0 (Document Analysis Bot; +https://legisense.app)',
      'Accept': 'text/html,application/xhtml+xml',
    },
    signal: AbortSignal.timeout(30_000),
  });

  if (!response.ok) {
    throw new Error(`URL returned status ${response.status}: ${response.statusText}`);
  }

  const html = await response.text();
  const $ = cheerio.load(html);

  // Remove non-content elements
  $('script, style, nav, footer, header, aside, iframe, noscript, svg, form, button, input, select, textarea').remove();
  $('[role="navigation"], [role="banner"], [role="contentinfo"], [aria-hidden="true"]').remove();

  const title = $('title').first().text().trim() || $('h1').first().text().trim() || 'Untitled';

  const siteName =
    $('meta[property="og:site_name"]').attr('content') ||
    $('meta[name="application-name"]').attr('content') ||
    null;

  // Collect text from main content areas first, then body
  let text = '';
  const mainSelectors = 'main, article, [role="main"], .content, .post, .article-body, #content';

  $(mainSelectors).each((_, el) => {
    text += $(el).text() + '\n';
  });

  if (!text.trim()) {
    text = $('body').text();
  }

  // Clean up whitespace
  text = text
    .replace(/\t/g, ' ')
    .replace(/ +/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();

  if (!text) {
    throw new Error('No text content found at URL');
  }

  return { title, text, url: urlString, siteName };
}

export function isValidUrl(str: string): boolean {
  try {
    const u = new URL(str);
    return u.protocol === 'http:' || u.protocol === 'https:';
  } catch {
    return false;
  }
}
