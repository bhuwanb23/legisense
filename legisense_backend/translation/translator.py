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
    
    def translate_analysis_json(self, analysis_json: dict, target_language: str, source_language: str = 'en') -> dict:
        """Translate the entire analysis JSON structure."""
        try:
            translated_analysis = analysis_json.copy()
            
            # Translate TL;DR bullets
            if 'tldr_bullets' in translated_analysis:
                translated_analysis['tldr_bullets'] = [
                    self.translate_text(bullet, target_language, source_language)
                    for bullet in translated_analysis['tldr_bullets']
                ]
            
            # Translate clauses
            if 'clauses' in translated_analysis:
                translated_clauses = []
                for clause in translated_analysis['clauses']:
                    translated_clause = clause.copy()
                    if 'category' in translated_clause:
                        translated_clause['category'] = self.translate_text(
                            translated_clause['category'], target_language, source_language
                        )
                    if 'original_snippet' in translated_clause:
                        translated_clause['original_snippet'] = self.translate_text(
                            translated_clause['original_snippet'], target_language, source_language
                        )
                    if 'explanation' in translated_clause:
                        translated_clause['explanation'] = self.translate_text(
                            translated_clause['explanation'], target_language, source_language
                        )
                    translated_clauses.append(translated_clause)
                translated_analysis['clauses'] = translated_clauses
            
            # Translate risk flags
            if 'risk_flags' in translated_analysis:
                translated_flags = []
                for flag in translated_analysis['risk_flags']:
                    translated_flag = flag.copy()
                    if 'text' in translated_flag:
                        translated_flag['text'] = self.translate_text(
                            translated_flag['text'], target_language, source_language
                        )
                    if 'why' in translated_flag:
                        translated_flag['why'] = self.translate_text(
                            translated_flag['why'], target_language, source_language
                        )
                    translated_flags.append(translated_flag)
                translated_analysis['risk_flags'] = translated_flags
            
            # Translate comparative context
            if 'comparative_context' in translated_analysis:
                translated_context = []
                for context in translated_analysis['comparative_context']:
                    translated_context_item = context.copy()
                    if 'label' in translated_context_item:
                        translated_context_item['label'] = self.translate_text(
                            translated_context_item['label'], target_language, source_language
                        )
                    if 'standard' in translated_context_item:
                        translated_context_item['standard'] = self.translate_text(
                            translated_context_item['standard'], target_language, source_language
                        )
                    if 'contract' in translated_context_item:
                        translated_context_item['contract'] = self.translate_text(
                            translated_context_item['contract'], target_language, source_language
                        )
                    if 'assessment' in translated_context_item:
                        translated_context_item['assessment'] = self.translate_text(
                            translated_context_item['assessment'], target_language, source_language
                        )
                    translated_context.append(translated_context_item)
                translated_analysis['comparative_context'] = translated_context
            
            # Translate suggested questions
            if 'suggested_questions' in translated_analysis:
                translated_analysis['suggested_questions'] = [
                    self.translate_text(question, target_language, source_language)
                    for question in translated_analysis['suggested_questions']
                ]
            
            return translated_analysis
            
        except Exception as e:
            logger.error(f"Error translating analysis JSON: {e}")
            return analysis_json  # Return original if translation fails
