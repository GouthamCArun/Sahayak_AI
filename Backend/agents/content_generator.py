"""
Content Generator Agent for Sahaayak AI Backend

This agent handles the creation of localized, age-appropriate educational
content including stories, lessons, and explanations for rural Indian schools.
"""

from typing import Any, Dict, Optional, List
import google.generativeai as genai

from agents.base_agent import BaseAgent
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
        self.model = genai.GenerativeModel('gemini-1.5-flash')  # Updated model name
        
        # Content type templates with markdown support
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
- Format as markdown with proper headings, paragraphs, and emphasis

Story topic: {topic}
Additional context: {context}

Please write the story in markdown format:""",
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
- Format as markdown with headings, bullet points, and emphasis
- Include simple Mermaid diagrams where helpful (flowcharts, mind maps, simple diagrams)

Topic to explain: {topic}
Additional context: {context}

Please provide the explanation in markdown format with Mermaid diagrams where appropriate:""",
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
- Format as markdown with proper structure
- Include Mermaid diagrams for concepts that benefit from visual representation

Lesson topic: {topic}
Duration: {duration} minutes
Additional context: {context}

Please create the lesson in markdown format with Mermaid diagrams:""",
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
- Format as markdown with clear sections
- Include simple Mermaid diagrams for activity flow or setup

Activity topic: {topic}
Duration: {duration} minutes
Additional context: {context}

Please design the activity in markdown format with Mermaid diagrams:""",
                "default_length": "200-300"
            },
            
            "quiz": {
                "prompt_template": """Create 10 educational questions and answers about {topic} for {grade_level} students in rural Indian schools.

Requirements:
- Create exactly 10 questions
- Mix different question types: multiple choice, true/false, short answer
- Questions should be age-appropriate for {grade_level}
- Include cultural context familiar to Indian children
- Provide clear, correct answers
- Language: {language}
- Difficulty should match the grade level
- Include explanations for answers where helpful
- IMPORTANT: Generate valid JSON without extra spaces, line breaks, or formatting issues
- Format the quiz introduction and instructions in markdown

Topic: {topic}
Number of questions: 10
Additional context: {context}

Please create the quiz with markdown introduction and JSON format for questions:

# Quiz: {topic}

## Instructions
Complete the following questions. Read each question carefully and choose the best answer.

## Questions

```json
{{
    "questions": [
        {{
            "question": "Question text here",
            "type": "multiple_choice",
            "options": ["A", "B", "C", "D"],
            "correct_answer": "Correct answer",
            "explanation": "Brief explanation of why this is correct"
        }},
        {{
            "question": "Another question here",
            "type": "true_false",
            "options": ["True", "False"],
            "correct_answer": "True",
            "explanation": "Explanation here"
        }}
    ],
    "topic": "{topic}",
    "grade_level": "{grade_level}",
    "total_questions": 10
}}
```

CRITICAL: Ensure the JSON is valid and properly formatted. Do not add extra spaces, line breaks, or special characters within the JSON fields.""",
                "default_length": "500-800"
            },
            
            "worksheet": {
                "prompt_template": """Create a comprehensive educational worksheet about {topic} for {grade_level} students in rural Indian schools.

Requirements:
- Create a complete worksheet with multiple activities
- Include different types of exercises: fill-in-the-blanks, multiple choice, short answers, matching, etc.
- Make it age-appropriate for {grade_level} students
- Include cultural context familiar to Indian children
- Use simple, clear instructions
- Language: {language}
- Subject: {subject}
- Worksheet type: {worksheet_type}
- Include answer key at the end
- Make it suitable for printing and classroom use
- Format as markdown with clear sections and formatting
- Include simple Mermaid diagrams for visual exercises or concept maps

Topic: {topic}
Subject: {subject}
Grade Level: {grade_level}
Additional context: {context}

Please create the worksheet in markdown format with Mermaid diagrams:""",
                "default_length": "800-1200"
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
            "kn": "ಕನ್ನಡದಲ್ಲಿ ಉತ್ತರಿಸಿ।",
            "ml": "ദയവായി മലയാളത്തിൽ ഉത്തരം നൽകുക।"
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
        if content_type == "quiz":
            # For quiz content, clean the JSON to ensure it's valid
            formatted_content = self._clean_json_content(generated_content)
        else:
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
            "duration": additional_params.get("duration", "30"),
            "subject": additional_params.get("subject", "general"),
            "worksheet_type": additional_params.get("worksheet_type", "mixed")
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
            # Fallback mock content for ANY Gemini API error (timeout, connection, auth, etc.)
            self.logger.info("Using mock content fallback due to Gemini API issue")
            
            # Generate dynamic mock content based on language and topic
            return self._generate_mock_content(topic, language, grade_level)
    
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
    
    def _clean_json_content(self, content: str) -> str:
        """
        Clean and validate JSON content, especially for quiz generation.
        
        Args:
            content: Raw content that should contain JSON
            
        Returns:
            Cleaned JSON content
        """
        try:
            # Try to extract JSON from markdown code blocks first
            import re
            import json
            
            # Look for JSON in markdown code blocks
            json_patterns = [
                r'```json\s*(\{[\s\S]*?\})\s*```',
                r'```\s*(\{[\s\S]*?\})\s*```',
                r'`(\{[\s\S]*?\})`',
            ]
            
            for pattern in json_patterns:
                match = re.search(pattern, content, re.DOTALL)
                if match:
                    json_str = match.group(1)
                    # Clean the JSON string
                    json_str = json_str.strip()
                    # Remove extra whitespace and normalize
                    json_str = re.sub(r'\s+', ' ', json_str)
                    # Try to parse and re-serialize to validate
                    parsed = json.loads(json_str)
                    return json.dumps(parsed, ensure_ascii=False, separators=(',', ':'))
            
            # If no markdown found, try to parse the entire content as JSON
            content_clean = content.strip()
            content_clean = re.sub(r'\s+', ' ', content_clean)
            parsed = json.loads(content_clean)
            return json.dumps(parsed, ensure_ascii=False, separators=(',', ':'))
            
        except (json.JSONDecodeError, Exception) as e:
            self.logger.warning(f"JSON cleaning failed: {str(e)}")
            # Return original content if cleaning fails
            return content
    
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
    
    def _generate_mock_content(self, topic: str, language: str, grade_level: str) -> str:
        """
        Generate mock educational content for any topic and language.
        Used as fallback when Gemini API is unavailable.
        """
        # Get language-specific elements
        if language == "hi":  # Hindi
            greeting = "नमस्ते"
            village = "गाँव"
            child_name = "राज"
            teacher = "गुरुजी"
            moral_start = "शिक्षा:"
        elif language == "ta":  # Tamil
            greeting = "வணக்கம்"
            village = "கிராமம்"
            child_name = "முருகன்"
            teacher = "ஆசிரியர்"
            moral_start = "நீதி:"
        elif language == "bn":  # Bengali
            greeting = "নমস্কার"
            village = "গ্রাম"
            child_name = "রাহুল"
            teacher = "শিক্ষক"
            moral_start = "শিক্ষা:"
        elif language == "ml":  # Malayalam
            greeting = "നമസ്കാരം"
            village = "ഗ്രാമം"
            child_name = "അരുൺ"
            teacher = "ഗുരു"
            moral_start = "പാഠം:"
        else:  # English (default)
            greeting = "Hello"
            village = "village"
            child_name = "Ravi"
            teacher = "teacher"
            moral_start = "MORAL:"
        
        # Topic-specific story elements
        topic_lower = topic.lower()
        
        if "photo" in topic_lower or "plant" in topic_lower:
            if language == "hi":
                story = f"""एक बार एक हरे-भरे {village} में पुनिया नाम का एक छोटा पौधा रहता था।

{child_name} ने पूछा, "पुनिया, तुम अपना खाना कैसे बनाते हो?"

पुनिया ने मुस्कराते हुए कहा, "मैं सूरज की रोशनी, पानी और हवा का उपयोग करके अपना खाना बनाता हूँ!"

{moral_start} पेड़-पौधे हमारे मित्र हैं। वे अपना खाना बनाते हैं और हमें साफ हवा देते हैं।"""
            elif language == "ml":
                story = f"""ഒരിക്കൽ പച്ചയായ ഒരു {village}ത്തിൽ പുനിയ എന്ന ചെറിയ ചെടി ജീവിച്ചിരുന്നു।

{child_name} ചോദിച്ചു, "പുനിയേ, നീ എങ്ങനെയാണ് ഭക്ഷണം ഉണ്ടാക്കുന്നത്?"

പുനിയ പുഞ്ചിരിച്ചുകൊണ്ട് പറഞ്ഞു, "ഞാൻ സൂര്യപ്രകാശം, വെള്ളം, വായു എന്നിവ ഉപയോഗിച്ച് എന്റെ ഭക്ഷണം ഉണ്ടാക്കുന്നു! എന്റെ ഇലകൾ ചെറിയ അടുക്കളകൾ പോലെയാണ്."

{moral_start} ചെടികൾ നമ്മുടെ സുഹൃത്തുക്കളാണ്. അവ സ്വന്തം ഭക്ഷണം ഉണ്ടാക്കുകയും നമുക്ക് ശുദ്ധവായു നൽകുകയും ചെയ്യുന്നു।"""
            else:
                story = f"""Once upon a time in a green {village}, there lived a little plant named Puniya.

{child_name} asked, "Puniya, how do you make your food?"

Puniya smiled and said, "I use sunlight, water, and air to make my own food! My leaves are like tiny kitchens."

{moral_start} Plants are our friends. They make their own food and give us fresh air to breathe."""
                
        elif "water" in topic_lower or "cycle" in topic_lower:
            if language == "hi":
                story = f"""एक बार बूमी नाम की एक छोटी पानी की बूंद कुएं में रहती थी।

सूरज की गर्मी से बूमी भाप बनकर आसमान में उड़ गई। बादलों में मिलकर वह बारिश बनी।

{moral_start} पानी की यात्रा कभी नहीं रुकती। हमें पानी की बचत करनी चाहिए।"""
            elif language == "ml":
                story = f"""ഒരിക്കൽ ബൂമി എന്ന ചെറിയ വെള്ളത്തുള്ളി കിണറ്റിൽ താമസിച്ചിരുന്നു।

സൂര്യന്റെ ചൂടിൽ ബൂമി നീരാവിയായി ആകാശത്തേക്ക് പറന്നു. മേഘങ്ങളിൽ ചേർന്ന് അവൾ വീണ്ടും മഴയായി.

{moral_start} വെള്ളത്തിന്റെ യാത്ര ഒരിക്കലും നിർത്തുന്നില്ല. നമുക്ക് ഓരോ തുള്ളി വെള്ളവും ലാഭിക്കണം."""
            else:
                story = f"""Once upon a time, a little water drop named Boomi lived in a well.

When the sun heated her, Boomi turned into vapor and flew to the sky. In the clouds, she became rain again.

{moral_start} Water is always moving in a cycle. We should save every drop of water."""
                
        else:
            # Generic educational story for any topic
            if language == "hi":
                story = f"""एक बार एक सुंदर {village} में {child_name} नाम का एक जिज्ञासु बच्चा रहता था।

{teacher} ने कहा, "आज हम {topic} के बारे में सीखेंगे!"

{child_name} ने बहुत कुछ सीखा और समझा कि {topic} कितना महत्वपूर्ण है।

{moral_start} ज्ञान एक दीपक की तरह है जो अंधेरे को मिटाता है।"""
            elif language == "ml":
                story = f"""ഒരിക്കൽ സുന്ദരമായ ഒരു {village}ത്തിൽ {child_name} എന്ന കൗതുകമുള്ള കുട്ടി ജീവിച്ചിരുന്നു।

ജ്ഞാനിയായ {teacher} പറഞ്ഞു, "ഇന്ന് നമ്മൾ {topic} എന്നതിനെക്കുറിച്ച് പഠിക്കും!"

{child_name} ധാരാളം അത്ഭുതകരമായ കാര്യങ്ങൾ പഠിക്കുകയും {topic} ദൈനംദിന ജീവിതത്തിൽ എത്ര പ്രധാനമാണെന്ന് മനസ്സിലാക്കുകയും ചെയ്തു।

{moral_start} അറിവ് ഇരുട്ടിനെ പ്രകാശിപ്പിക്കുന്ന ദീപം പോലെയാണ്. പഠനം നമ്മെ വളർത്താൻ സഹായിക്കുന്നു!"""
            else:
                story = f"""Once upon a time in a beautiful {village}, there lived a curious child named {child_name}.

The wise {teacher} said, "Today we will learn about {topic}!"

{child_name} learned many wonderful things and understood how important {topic} is in daily life.

{moral_start} Knowledge is like a lamp that lights up the darkness. Learning helps us grow!"""
        
        return f"""{story}

[Mock content for {topic} in {language} - Set up Google API key for real AI generation]""" 