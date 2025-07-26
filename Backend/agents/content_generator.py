"""
Content Generator Agent for Sahaayak AI Backend

This agent handles the creation of localized, age-appropriate educational
content including stories, lessons, and explanations for rural Indian schools.
"""

from typing import Any, Dict, Optional, List
import google.generativeai as genai

from .base_agent import BaseAgent
from utils.config import settings


class ContentGeneratorAgent(BaseAgent):
    """
    Content Generator agent for creating educational content.
    
    This agent uses Google's Gemini AI to generate culturally appropriate
    educational content in local languages for Indian rural schools.
    """
    
    def __init__(self):
        super().__init__("ContentGenerator")
        
        # Initialize Gemini AI
        genai.configure(api_key=settings.GOOGLE_API_KEY)
        self.model = genai.GenerativeModel('gemini-pro')
        
        # Content type templates
        self.content_templates = {
            "story": {
                "prompt_template": """Create an engaging educational story about {topic} for {grade_level} students in rural India. 
                
Requirements:
- Use simple, age-appropriate language
- Include cultural references familiar to Indian children
- Make it educational while entertaining
- Length: {length} words approximately
- Language: {language}
- Include a moral or learning objective

Story topic: {topic}
Additional context: {context}

Please write the story:""",
                "default_length": "200-300"
            },
            
            "explanation": {
                "prompt_template": """Provide a clear, simple explanation of {topic} for {grade_level} students in rural Indian schools.

Requirements:
- Use everyday examples that Indian children can relate to
- Break down complex concepts into simple parts
- Include practical applications or real-world connections
- Use analogies from rural Indian life (farming, animals, festivals, etc.)
- Language: {language}
- Keep it conversational and engaging

Topic to explain: {topic}
Additional context: {context}

Please provide the explanation:""",
                "default_length": "150-250"
            },
            
            "lesson": {
                "prompt_template": """Create a complete lesson on {topic} for {grade_level} students in rural Indian schools.

Requirements:
- Include learning objectives
- Provide step-by-step teaching instructions
- Add examples and activities suitable for resource-limited classrooms
- Include assessment questions
- Use cultural context familiar to rural Indian students
- Language: {language}

Lesson topic: {topic}
Duration: {duration} minutes
Additional context: {context}

Please create the lesson:""",
                "default_length": "300-500"
            },
            
            "activity": {
                "prompt_template": """Design an engaging classroom activity about {topic} for {grade_level} students in rural Indian schools.

Requirements:
- Use minimal resources (things available in rural schools)
- Make it interactive and hands-on
- Include clear instructions for teachers
- Ensure it's culturally appropriate and engaging
- Language: {language}
- Suitable for multi-grade classrooms if needed

Activity topic: {topic}
Duration: {duration} minutes
Additional context: {context}

Please design the activity:""",
                "default_length": "200-300"
            }
        }
        
        # Language-specific prompts
        self.language_prompts = {
            "hi": "कृपया हिंदी में जवाब दें। देवनागरी लिपि का उपयोग करें।",
            "en": "Please respond in English.",
            "ta": "தமிழில் பதிலளிக்கவும்।",
            "bn": "বাংলায় উত্তর দিন।",
            "gu": "ગુજરાતીમાં જવાબ આપો।",
            "mr": "मराठीत उत्तर द्या।",
            "kn": "ಕನ್ನಡದಲ್ಲಿ ಉತ್ತರಿಸಿ।"
        }
    
    async def process(
        self,
        request_data: Dict[str, Any],
        user_context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Process content generation request.
        
        Args:
            request_data: Contains content type, topic, and parameters
            user_context: Optional user context (grade levels taught, language preference)
            
        Returns:
            Dictionary containing generated content
        """
        # Extract request parameters
        content_type = request_data.get("content_type", "explanation")
        topic = request_data.get("topic", "")
        language = request_data.get("language", "en")
        grade_level = request_data.get("grade_level", "primary school")
        
        if not topic:
            raise ValueError("Topic is required for content generation")
        
        # Get user preferences from context
        if user_context:
            language = user_context.get("preferred_language", language)
            grade_level = user_context.get("grade_levels", grade_level)
        
        # Generate the content
        generated_content = await self._generate_content(
            content_type=content_type,
            topic=topic,
            language=language,
            grade_level=grade_level,
            additional_params=request_data
        )
        
        # Post-process and format the content
        formatted_content = self._format_content(
            content=generated_content,
            content_type=content_type,
            language=language
        )
        
        self.logger.info(
            "Content generated successfully",
            content_type=content_type,
            topic=topic,
            language=language,
            grade_level=grade_level,
            content_length=len(generated_content)
        )
        
        return {
            "content": formatted_content,
            "metadata": {
                "content_type": content_type,
                "topic": topic,
                "language": language,
                "grade_level": grade_level,
                "word_count": len(generated_content.split()),
                "estimated_reading_time": self._estimate_reading_time(generated_content)
            },
            "suggestions": self._generate_usage_suggestions(content_type, topic)
        }
    
    async def _generate_content(
        self,
        content_type: str,
        topic: str,
        language: str,
        grade_level: str,
        additional_params: Dict[str, Any]
    ) -> str:
        """
        Generate content using Gemini AI.
        
        Args:
            content_type: Type of content to generate
            topic: Topic for the content
            language: Target language
            grade_level: Target grade level
            additional_params: Additional parameters
            
        Returns:
            Generated content string
        """
        # Get template for content type
        if content_type not in self.content_templates:
            content_type = "explanation"  # Default fallback
        
        template_info = self.content_templates[content_type]
        prompt_template = template_info["prompt_template"]
        
        # Prepare prompt parameters
        prompt_params = {
            "topic": topic,
            "grade_level": grade_level,
            "language": self.language_prompts.get(language, self.language_prompts["en"]),
            "length": additional_params.get("length", template_info["default_length"]),
            "context": additional_params.get("context", ""),
            "duration": additional_params.get("duration", "30")
        }
        
        # Format the prompt
        formatted_prompt = prompt_template.format(**prompt_params)
        
        # Add cultural context
        cultural_prompt = self._add_cultural_context(formatted_prompt, language)
        
        try:
            # Generate content using Gemini
            response = self.model.generate_content(cultural_prompt)
            
            if response.text:
                return response.text.strip()
            else:
                raise Exception("No content generated by AI model")
                
        except Exception as e:
            self.logger.error("Failed to generate content", error=str(e))
            raise Exception(f"Content generation failed: {str(e)}")
    
    def _add_cultural_context(self, prompt: str, language: str) -> str:
        """
        Add cultural context to the prompt for better localized content.
        
        Args:
            prompt: Original prompt
            language: Target language
            
        Returns:
            Prompt with added cultural context
        """
        cultural_context = """
Additional Cultural Context for Indian Rural Schools:
- Students come from farming and rural backgrounds
- Limited access to technology and internet
- Strong family and community values
- Festivals: Diwali, Holi, Eid, Christmas, regional festivals
- Common animals: cows, buffalo, goats, chickens
- Common crops: rice, wheat, sugarcane, vegetables
- Transportation: bullock carts, bicycles, buses
- Daily life: helping with farm work, joint families
- Values: respect for elders, hard work, education as path to better life

Please incorporate these cultural elements naturally in your response.
"""
        
        return prompt + "\n" + cultural_context
    
    def _format_content(
        self,
        content: str,
        content_type: str,
        language: str
    ) -> str:
        """
        Format the generated content for better presentation.
        
        Args:
            content: Raw generated content
            content_type: Type of content
            language: Language of content
            
        Returns:
            Formatted content
        """
        # Clean up the content
        formatted = content.strip()
        
        # Add appropriate formatting based on content type
        if content_type == "story":
            # Ensure story has a clear structure
            if not formatted.startswith(("Once", "एक बार", "ಒಮ್ಮೆ")):
                if language == "hi":
                    formatted = "कहानी:\n\n" + formatted
                elif language == "en":
                    formatted = "Story:\n\n" + formatted
                else:
                    formatted = "कहानी/Story:\n\n" + formatted
        
        elif content_type == "lesson":
            # Ensure lesson has clear sections
            if "Learning Objectives" not in formatted and "उद्देश्य" not in formatted:
                if language == "hi":
                    formatted = "पाठ योजना:\n\n" + formatted
                else:
                    formatted = "Lesson Plan:\n\n" + formatted
        
        # Ensure proper line breaks and readability
        formatted = formatted.replace(". ", ".\n\n")
        formatted = formatted.replace("।", "।\n\n")  # Hindi sentence ending
        
        # Remove excessive line breaks
        while "\n\n\n" in formatted:
            formatted = formatted.replace("\n\n\n", "\n\n")
        
        return formatted
    
    def _estimate_reading_time(self, content: str) -> str:
        """
        Estimate reading time for the generated content.
        
        Args:
            content: Content to analyze
            
        Returns:
            Estimated reading time as string
        """
        word_count = len(content.split())
        
        # Average reading speeds (words per minute)
        reading_speeds = {
            "primary": 50,      # Primary school students
            "middle": 100,      # Middle school students  
            "high": 150         # High school students
        }
        
        # Use conservative estimate for primary students
        wpm = reading_speeds["primary"]
        
        minutes = max(1, round(word_count / wpm))
        
        if minutes == 1:
            return "1 minute"
        else:
            return f"{minutes} minutes"
    
    def _generate_usage_suggestions(
        self,
        content_type: str,
        topic: str
    ) -> List[str]:
        """
        Generate suggestions for how to use the created content.
        
        Args:
            content_type: Type of content created
            topic: Topic of the content
            
        Returns:
            List of usage suggestions
        """
        suggestions = []
        
        if content_type == "story":
            suggestions = [
                "Read aloud to the class for better engagement",
                "Ask students to identify the main characters and moral",
                "Have students draw pictures of their favorite scene",
                "Use as a starting point for creative writing exercises"
            ]
        
        elif content_type == "explanation":
            suggestions = [
                "Break the explanation into smaller chunks for better understanding",
                "Ask questions throughout to check comprehension",
                "Encourage students to ask their own questions",
                "Connect to students' daily life experiences"
            ]
        
        elif content_type == "lesson":
            suggestions = [
                "Adapt timing based on your students' pace",
                "Prepare simple materials mentioned in the lesson",
                "Plan for mixed-ability groups if needed",
                "Have backup activities ready for early finishers"
            ]
        
        elif content_type == "activity":
            suggestions = [
                "Test the activity yourself before class",
                "Prepare all materials in advance", 
                "Have clear rules and expectations",
                "Consider safety aspects for all activities"
            ]
        
        return suggestions
    
    def get_capabilities(self) -> Dict[str, Any]:
        """
        Return the capabilities of the Content Generator agent.
        
        Returns:
            Dictionary describing agent capabilities
        """
        return {
            "name": self.name,
            "description": "Educational content generation agent for rural Indian schools",
            "supported_operations": [
                "story_generation",
                "lesson_creation", 
                "explanation_writing",
                "activity_design"
            ],
            "supported_content_types": list(self.content_templates.keys()),
            "supported_languages": list(self.language_prompts.keys()),
            "input_types": ["text"],
            "output_types": ["formatted_text", "educational_content"]
        } 