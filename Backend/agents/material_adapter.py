import base64
import io
from typing import Dict, Any, List, Optional
from PIL import Image
import cv2
import numpy as np

from .base_agent import BaseAgent
from ..utils.logging import get_logger
import google.generativeai as genai
from ..utils.config import settings

class MaterialAdapterAgent(BaseAgent):
    """
    Material Adapter Agent for processing textbook images
    
    Uses Gemini Vision to extract content from textbook images and
    adapts them into worksheets for multiple grade levels.
    """
    
    def __init__(self):
        super().__init__("MaterialAdapterAgent")
        self.model = genai.GenerativeModel('gemini-pro-vision')
        
        # Worksheet templates for different grades
        self.worksheet_templates = {
            "grade_1_2": {
                "complexity": "very_simple",
                "vocabulary": "basic",
                "instructions": "Use pictures and simple words",
                "activities": ["matching", "coloring", "tracing", "counting"]
            },
            "grade_3_4": {
                "complexity": "simple",
                "vocabulary": "elementary",
                "instructions": "Short sentences with examples",
                "activities": ["fill_blanks", "multiple_choice", "drawing", "short_answers"]
            },
            "grade_5_6": {
                "complexity": "moderate",
                "vocabulary": "intermediate",
                "instructions": "Clear explanations with practice",
                "activities": ["essay_questions", "problem_solving", "research", "projects"]
            }
        }
        
        # Content adaptation prompts for Indian context
        self.cultural_adaptations = {
            "examples": [
                "Use local festivals like Diwali, Holi, Eid",
                "Include Indian foods like rice, dal, roti",
                "Reference Indian animals like elephant, peacock, tiger",
                "Use Indian names like Ravi, Priya, Arjun, Kavya",
                "Include village and farming contexts"
            ],
            "measurements": "Use metric system (meters, kilograms, liters)",
            "currency": "Use Indian Rupees (₹)",
            "seasons": "Reference Indian seasons (monsoon, winter, summer)"
        }

    async def process(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process textbook image and generate multi-grade worksheets
        
        Args:
            request: Contains image data, target grades, and adaptation preferences
            
        Returns:
            Dict containing worksheets for different grade levels
        """
        try:
            # Extract and validate input
            image_data = request.get('image')
            target_grades = request.get('target_grades', ['grade_3_4'])
            language = request.get('language', 'en')
            subject = request.get('subject', 'general')
            
            if not image_data:
                raise ValueError("No image data provided")
            
            # Process the image
            processed_image = await self._preprocess_image(image_data)
            
            # Extract content using Gemini Vision
            extracted_content = await self._extract_content_from_image(
                processed_image, language, subject
            )
            
            # Generate worksheets for each target grade
            worksheets = {}
            for grade_level in target_grades:
                worksheet = await self._generate_worksheet(
                    extracted_content, grade_level, language, subject
                )
                worksheets[grade_level] = worksheet
            
            # Add teaching suggestions
            teaching_suggestions = await self._generate_teaching_suggestions(
                extracted_content, target_grades, language
            )
            
            return {
                "success": True,
                "extracted_content": extracted_content,
                "worksheets": worksheets,
                "teaching_suggestions": teaching_suggestions,
                "metadata": {
                    "agent": self.name,
                    "processing_time": self.get_processing_time(),
                    "language": language,
                    "subject": subject,
                    "grade_levels": target_grades
                }
            }
            
        except Exception as e:
            self.logger.error(f"Material adaptation failed: {str(e)}")
            return {
                "success": False,
                "error": str(e),
                "agent": self.name
            }

    async def _preprocess_image(self, image_data: str) -> Image.Image:
        """
        Preprocess image for better OCR and content extraction
        
        Args:
            image_data: Base64 encoded image or file path
            
        Returns:
            Preprocessed PIL Image
        """
        try:
            # Decode base64 image
            if image_data.startswith('data:image'):
                # Remove data URL prefix
                image_data = image_data.split(',')[1]
            
            image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes))
            
            # Convert to RGB if necessary
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Apply image enhancement using OpenCV
            cv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
            
            # Enhance contrast and brightness
            alpha = 1.2  # Contrast control
            beta = 10    # Brightness control
            enhanced = cv2.convertScaleAbs(cv_image, alpha=alpha, beta=beta)
            
            # Apply denoising
            denoised = cv2.fastNlMeansDenoisingColored(enhanced, None, 10, 10, 7, 21)
            
            # Convert back to PIL Image
            final_image = Image.fromarray(cv2.cvtColor(denoised, cv2.COLOR_BGR2RGB))
            
            # Resize if too large (max 1024px on longest side)
            max_size = 1024
            if max(final_image.size) > max_size:
                final_image.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
            
            return final_image
            
        except Exception as e:
            self.logger.error(f"Image preprocessing failed: {str(e)}")
            raise

    async def _extract_content_from_image(
        self, 
        image: Image.Image, 
        language: str, 
        subject: str
    ) -> Dict[str, Any]:
        """
        Extract content from textbook image using Gemini Vision
        
        Args:
            image: Preprocessed PIL Image
            language: Target language for extraction
            subject: Subject context
            
        Returns:
            Extracted content with structure and metadata
        """
        try:
            # Prepare the prompt for content extraction
            extraction_prompt = f"""
            Analyze this textbook page image and extract all educational content.
            
            Language: {language}
            Subject: {subject}
            
            Please provide:
            1. Main topic/concept being taught
            2. Key learning objectives
            3. All text content (headings, paragraphs, captions)
            4. Mathematical formulas or equations (if any)
            5. Diagrams, charts, or visual elements description
            6. Questions or exercises present
            7. Vocabulary or key terms
            8. Grade level estimation
            
            Format the response as structured JSON with clear sections.
            Include original text and suggest simplified versions for younger students.
            """
            
            # Call Gemini Vision API
            response = self.model.generate_content([extraction_prompt, image])
            
            # Parse and structure the response
            content = self._parse_extraction_response(response.text)
            
            return content
            
        except Exception as e:
            self.logger.error(f"Content extraction failed: {str(e)}")
            raise

    def _parse_extraction_response(self, response_text: str) -> Dict[str, Any]:
        """
        Parse and structure the Gemini Vision response
        
        Args:
            response_text: Raw response from Gemini Vision
            
        Returns:
            Structured content dictionary
        """
        try:
            # Try to parse as JSON first
            import json
            try:
                return json.loads(response_text)
            except json.JSONDecodeError:
                pass
            
            # Fallback: Structure the text response
            lines = response_text.strip().split('\n')
            structured_content = {
                "main_topic": "",
                "learning_objectives": [],
                "text_content": "",
                "key_terms": [],
                "questions": [],
                "visual_elements": [],
                "grade_level": "unknown",
                "raw_response": response_text
            }
            
            current_section = None
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                
                # Identify sections
                if "topic" in line.lower() or "concept" in line.lower():
                    current_section = "main_topic"
                elif "objective" in line.lower():
                    current_section = "learning_objectives"
                elif "text" in line.lower() or "content" in line.lower():
                    current_section = "text_content"
                elif "term" in line.lower() or "vocabulary" in line.lower():
                    current_section = "key_terms"
                elif "question" in line.lower() or "exercise" in line.lower():
                    current_section = "questions"
                elif "visual" in line.lower() or "diagram" in line.lower():
                    current_section = "visual_elements"
                elif "grade" in line.lower():
                    current_section = "grade_level"
                else:
                    # Add content to current section
                    if current_section and line:
                        if current_section in ["learning_objectives", "key_terms", "questions", "visual_elements"]:
                            structured_content[current_section].append(line)
                        else:
                            structured_content[current_section] += f" {line}"
            
            return structured_content
            
        except Exception as e:
            self.logger.error(f"Response parsing failed: {str(e)}")
            return {"error": str(e), "raw_response": response_text}

    async def _generate_worksheet(
        self, 
        content: Dict[str, Any], 
        grade_level: str, 
        language: str, 
        subject: str
    ) -> Dict[str, Any]:
        """
        Generate worksheet adapted for specific grade level
        
        Args:
            content: Extracted content from image
            grade_level: Target grade level
            language: Target language
            subject: Subject context
            
        Returns:
            Generated worksheet content
        """
        try:
            template = self.worksheet_templates.get(grade_level, self.worksheet_templates["grade_3_4"])
            
            worksheet_prompt = f"""
            Create a worksheet based on this textbook content for {grade_level} students.
            
            Original Content:
            - Topic: {content.get('main_topic', '')}
            - Text: {content.get('text_content', '')}
            - Key Terms: {content.get('key_terms', [])}
            
            Worksheet Requirements:
            - Complexity: {template['complexity']}
            - Vocabulary: {template['vocabulary']}
            - Instructions: {template['instructions']}
            - Activities: {template['activities']}
            - Language: {language}
            - Subject: {subject}
            
            Cultural Adaptations:
            {self.cultural_adaptations}
            
            Generate:
            1. Worksheet title
            2. Learning objectives (simple for grade level)
            3. 5-8 activities/questions appropriate for this grade
            4. Answer key
            5. Extension activities for advanced students
            6. Assessment rubric
            
            Make it engaging and culturally relevant for rural Indian students.
            """
            
            # Generate worksheet using Gemini
            model = genai.GenerativeModel('gemini-pro')
            response = model.generate_content(worksheet_prompt)
            
            worksheet = {
                "title": f"{content.get('main_topic', 'Learning Activity')} - {grade_level.replace('_', ' ').title()}",
                "grade_level": grade_level,
                "content": response.text,
                "estimated_time": self._estimate_completion_time(grade_level),
                "difficulty": template['complexity'],
                "activities": template['activities']
            }
            
            return worksheet
            
        except Exception as e:
            self.logger.error(f"Worksheet generation failed: {str(e)}")
            raise

    async def _generate_teaching_suggestions(
        self, 
        content: Dict[str, Any], 
        grade_levels: List[str], 
        language: str
    ) -> Dict[str, Any]:
        """
        Generate teaching suggestions for the extracted content
        
        Args:
            content: Extracted content
            grade_levels: Target grade levels
            language: Target language
            
        Returns:
            Teaching suggestions and tips
        """
        try:
            suggestions_prompt = f"""
            Provide teaching suggestions for this content across grade levels {grade_levels}.
            
            Content: {content.get('main_topic', '')}
            Key Concepts: {content.get('key_terms', [])}
            Language: {language}
            
            Generate:
            1. Pre-lesson preparation tips
            2. Introduction activities
            3. Main lesson delivery methods
            4. Student engagement strategies
            5. Assessment ideas
            6. Differentiation for different abilities
            7. Materials needed (using locally available items)
            8. Common misconceptions to address
            9. Real-world connections
            10. Follow-up activities
            
            Focus on practical, low-resource solutions for rural Indian classrooms.
            """
            
            model = genai.GenerativeModel('gemini-pro')
            response = model.generate_content(suggestions_prompt)
            
            return {
                "suggestions": response.text,
                "target_grades": grade_levels,
                "language": language,
                "focus": "rural_indian_context"
            }
            
        except Exception as e:
            self.logger.error(f"Teaching suggestions generation failed: {str(e)}")
            return {"error": str(e)}

    def _estimate_completion_time(self, grade_level: str) -> str:
        """
        Estimate completion time based on grade level
        
        Args:
            grade_level: Target grade level
            
        Returns:
            Estimated completion time string
        """
        time_estimates = {
            "grade_1_2": "15-20 minutes",
            "grade_3_4": "25-30 minutes",
            "grade_5_6": "35-45 minutes"
        }
        return time_estimates.get(grade_level, "30 minutes")

    def get_capabilities(self) -> Dict[str, Any]:
        """
        Get agent capabilities description
        
        Returns:
            Capabilities dictionary
        """
        return {
            "name": self.name,
            "description": "Processes textbook images and generates multi-grade worksheets",
            "input_types": ["image"],
            "output_types": ["worksheet", "teaching_suggestions"],
            "supported_formats": ["JPEG", "PNG", "WebP"],
            "max_image_size": "10MB",
            "supported_languages": ["en", "hi", "mr", "ta", "bn", "gu"],
            "grade_levels": list(self.worksheet_templates.keys()),
            "processing_time": "30-60 seconds per image"
        } 