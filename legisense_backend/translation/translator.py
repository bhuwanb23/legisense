from typing import List, Dict, Any
import logging
import requests
import json

logger = logging.getLogger(__name__)

class DocumentTranslator:
    """Service for translating document content using Google Translate API."""
    
    def __init__(self):
        # Using Google Translate API via requests
        self.base_url = "https://translate.googleapis.com/translate_a/single"
    
    def translate_text(self, text: str, target_language: str, source_language: str = 'en') -> str:
        """Translate a single text string."""
        try:
            if not text or not text.strip():
                return text
            
            # Use Google Translate API via requests
            params = {
                'client': 'gtx',
                'sl': source_language,
                'tl': target_language,
                'dt': 't',
                'q': text
            }
            
            response = requests.get(self.base_url, params=params, timeout=10)
            response.raise_for_status()
            
            result = response.json()
            if result and len(result) > 0 and result[0]:
                translated_text = ''.join([item[0] for item in result[0] if item[0]])
                return translated_text
            
            return text
        except Exception as e:
            logger.error(f"Translation error for text '{text[:50]}...': {e}")
            return text  # Return original text if translation fails
    
    def translate_pages(self, pages: List[Dict[str, Any]], target_language: str, source_language: str = 'en') -> List[Dict[str, Any]]:
        """Translate a list of document pages."""
        translated_pages = []
        
        for page in pages:
            try:
                translated_page = page.copy()
                original_text = page.get('text', '')
                
                if original_text and original_text.strip():
                    translated_text = self.translate_text(original_text, target_language, source_language)
                    translated_page['text'] = translated_text
                
                translated_pages.append(translated_page)
            except Exception as e:
                logger.error(f"Error translating page {page.get('page_number', 'unknown')}: {e}")
                translated_pages.append(page)  # Keep original page if translation fails
        
        return translated_pages
    
    def translate_full_text(self, full_text: str, target_language: str, source_language: str = 'en') -> str:
        """Translate the full document text."""
        return self.translate_text(full_text, target_language, source_language)
    
    def get_language_code(self, language: str) -> str:
        """Convert language name to Google Translate language code."""
        language_map = {
            'en': 'en',
            'english': 'en',
            'hi': 'hi',
            'hindi': 'hi',
            'ta': 'ta',
            'tamil': 'ta',
            'te': 'te',
            'telugu': 'te',
        }
        return language_map.get(language.lower(), 'en')
