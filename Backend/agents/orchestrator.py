"""
Orchestrator Agent for Sahaayak AI Backend

This agent handles intent detection and routing of incoming requests
to the appropriate specialized AI agents based on the request content.
"""

from typing import Any, Dict, Optional, List
import re

from agents.base_agent import BaseAgent


class OrchestratorAgent(BaseAgent):
    """
    Orchestrator agent responsible for intent detection and request routing.
    
    This agent analyzes incoming requests, determines the user's intent,
    and routes the request to the appropriate specialized agent for processing.
    """
    
    def __init__(self):
        super().__init__("Orchestrator")
        
        # Define intent patterns and their corresponding agents
        self.intent_patterns = {
            "content_generation": {
                "patterns": [
                    r"(?i)(create|generate|write|make).*?(story|lesson|content|explanation)",
                    r"(?i)(tell|create).*?(story|tale)",
                    r"(?i)(explain|describe).*?(concept|topic|subject)",
                    r"(?i)(content|material).*?(generation|creation)",
                ],
                "keywords": ["story", "lesson", "content", "explanation", "generate", "create", "write"],
                "agent": "ContentGenerator"
            },
            "question_answering": {
                "patterns": [
                    r"(?i)(what|how|why|when|where|who).*?\?",
                    r"(?i)(explain|tell me|help).*?(about|with)",
                    r"(?i)(question|ask|doubt|clarify)",
                    r"(?i)(can you|could you|please).*?(help|explain|tell)",
                ],
                "keywords": ["what", "how", "why", "question", "ask", "help", "explain"],
                "agent": "KnowledgeExplainer"
            },
            "material_adaptation": {
                "patterns": [
                    r"(?i)(worksheet|exercise|activity).*?(create|make|generate)",
                    r"(?i)(textbook|book|page).*?(adapt|convert|transform)",
                    r"(?i)(grade.*?level|difficulty.*?level)",
                    r"(?i)(image|picture|photo).*?(worksheet|exercise)",
                ],
                "keywords": ["worksheet", "exercise", "textbook", "adapt", "grade", "level"],
                "agent": "MaterialAdapter"
            },
            "visual_aid": {
                "patterns": [
                    r"(?i)(diagram|chart|visual|drawing).*?(create|make|generate)",
                    r"(?i)(blackboard|board).*?(diagram|drawing)",
                    r"(?i)(visual.*?aid|visual.*?help)",
                    r"(?i)(draw|sketch|illustrate)",
                ],
                "keywords": ["diagram", "visual", "drawing", "chart", "blackboard", "draw"],
                "agent": "VisualAid"
            },
            "assessment": {
                "patterns": [
                    r"(?i)(reading|fluency|pronunciation).*?(assessment|evaluation|check)",
                    r"(?i)(audio|voice|speech).*?(evaluate|assess|check)",
                    r"(?i)(student.*?reading|reading.*?student)",
                ],
                "keywords": ["reading", "fluency", "assessment", "audio", "evaluate", "speech"],
                "agent": "Assessment"
            },
            "lesson_planning": {
                "patterns": [
                    r"(?i)(lesson.*?plan|weekly.*?plan|plan.*?lesson)",
                    r"(?i)(schedule|planning|curriculum)",
                    r"(?i)(week.*?activity|daily.*?activity)",
                    r"(?i)(plan.*?week|plan.*?day)",
                ],
                "keywords": ["lesson", "plan", "schedule", "weekly", "curriculum", "activity"],
                "agent": "LessonPlanner"
            }
        }
    
    async def process(
        self,
        request_data: Dict[str, Any],
        user_context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Process the orchestration request by detecting intent and routing.
        
        Args:
            request_data: Contains the user input and request details
            user_context: Optional user context for better intent detection
            
        Returns:
            Dictionary containing routing information and detected intent
        """
        # Extract input text from various possible fields
        input_text = self._extract_input_text(request_data)
        
        if not input_text:
            raise ValueError("No input text found in request data")
        
        # Check if request type is explicitly provided (from frontend)
        explicit_type = request_data.get("type")
        if explicit_type and explicit_type in self.intent_patterns:
            detected_intent = explicit_type
            self.logger.info(f"Using explicit request type: {explicit_type}")
        else:
            # Detect intent from the input text
            detected_intent = self._detect_intent(input_text, user_context)
        
        # Get routing information
        routing_info = self._get_routing_info(detected_intent, request_data)
        
        self.logger.info(
            "Intent detected and routing determined",
            input_length=len(input_text),
            detected_intent=detected_intent,
            target_agent=routing_info["target_agent"],
            confidence=routing_info["confidence"]
        )
        
        return {
            "detected_intent": detected_intent,
            "target_agent": routing_info["target_agent"],
            "confidence": routing_info["confidence"],
            "routing_data": routing_info["routing_data"],
            "input_analysis": {
                "input_length": len(input_text),
                "language": self._detect_language(input_text),
                "contains_image": "image" in request_data or "file" in request_data,
                "contains_audio": "audio" in request_data,
            }
        }
    
    def _extract_input_text(self, request_data: Dict[str, Any]) -> str:
        """
        Extract input text from various possible fields in the request.
        
        Args:
            request_data: The request data dictionary
            
        Returns:
            Extracted input text
        """
        # Try different possible field names for input text
        text_fields = ["text", "input", "query", "prompt", "message", "content"]
        
        for field in text_fields:
            if field in request_data and request_data[field]:
                return str(request_data[field]).strip()
        
        # Check if there's a nested structure
        if "data" in request_data:
            for field in text_fields:
                if field in request_data["data"] and request_data["data"][field]:
                    return str(request_data["data"][field]).strip()
        
        return ""
    
    def _detect_intent(
        self,
        input_text: str,
        user_context: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Detect the user's intent from the input text.
        
        Args:
            input_text: The user's input text
            user_context: Optional user context for better detection
            
        Returns:
            Detected intent string
        """
        input_lower = input_text.lower()
        intent_scores = {}
        
        # Score each intent based on pattern matching and keywords
        for intent, config in self.intent_patterns.items():
            score = 0.0
            
            # Check regex patterns
            for pattern in config["patterns"]:
                if re.search(pattern, input_text):
                    score += 2.0  # Pattern match is strong indicator
                    break
            
            # Check keywords
            keyword_matches = 0
            for keyword in config["keywords"]:
                if keyword.lower() in input_lower:
                    keyword_matches += 1
            
            # Add keyword score (normalized by number of keywords)
            if config["keywords"]:
                score += (keyword_matches / len(config["keywords"])) * 1.5
            
            intent_scores[intent] = score
        
        # Find the intent with the highest score
        if intent_scores:
            best_intent = max(intent_scores, key=intent_scores.get)
            best_score = intent_scores[best_intent]
            
            # If score is too low, default to question answering
            if best_score < 0.5:
                return "question_answering"
            
            return best_intent
        
        # Default fallback
        return "question_answering"
    
    def _detect_language(self, text: str) -> str:
        """
        Detect the language of the input text.
        
        Args:
            text: Input text to analyze
            
        Returns:
            Detected language code (en, hi, etc.)
        """
        # Simple language detection based on character patterns
        
        # Check for Devanagari script (Hindi)
        devanagari_pattern = r'[\u0900-\u097F]'
        if re.search(devanagari_pattern, text):
            return "hi"
        
        # Check for other Indian language scripts
        # Tamil
        if re.search(r'[\u0B80-\u0BFF]', text):
            return "ta"
        
        # Bengali
        if re.search(r'[\u0980-\u09FF]', text):
            return "bn"
        
        # Gujarati
        if re.search(r'[\u0A80-\u0AFF]', text):
            return "gu"
        
        # Marathi (uses Devanagari, but for now treat same as Hindi)
        # Kannada
        if re.search(r'[\u0C80-\u0CFF]', text):
            return "kn"
        
        # Default to English
        return "en"
    
    def _get_routing_info(
        self,
        intent: str,
        request_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Get routing information for the detected intent.
        
        Args:
            intent: Detected intent
            request_data: Original request data
            
        Returns:
            Dictionary containing routing information
        """
        if intent in self.intent_patterns:
            target_agent = self.intent_patterns[intent]["agent"]
            confidence = 0.8  # Base confidence for pattern-matched intents
        else:
            target_agent = "KnowledgeExplainer"  # Default fallback
            confidence = 0.3  # Low confidence for fallback
        
        # Adjust confidence based on additional factors
        input_text = self._extract_input_text(request_data)
        
        # Higher confidence for longer, more specific inputs
        if len(input_text) > 50:
            confidence += 0.1
        
        # Higher confidence if specific media types are present
        if intent == "material_adaptation" and ("image" in request_data or "file" in request_data):
            confidence += 0.15
        
        if intent == "assessment" and "audio" in request_data:
            confidence += 0.15
        
        # Cap confidence at 1.0
        confidence = min(confidence, 1.0)
        
        return {
            "target_agent": target_agent,
            "confidence": confidence,
            "routing_data": {
                "original_request": request_data,
                "detected_language": self._detect_language(input_text),
                "processing_hints": self._get_processing_hints(intent, request_data)
            }
        }
    
    def _get_processing_hints(
        self,
        intent: str,
        request_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Get processing hints for the target agent.
        
        Args:
            intent: Detected intent
            request_data: Original request data
            
        Returns:
            Dictionary containing processing hints
        """
        hints = {
            "priority": "normal",
            "expected_output_type": "text",
            "processing_time_estimate": "fast"
        }
        
        # Add intent-specific hints
        if intent == "content_generation":
            hints.update({
                "expected_output_type": "text",
                "processing_time_estimate": "medium",
                "content_type": "educational"
            })
        
        elif intent == "material_adaptation":
            hints.update({
                "expected_output_type": "text_and_image",
                "processing_time_estimate": "slow",
                "requires_image_processing": True
            })
        
        elif intent == "visual_aid":
            hints.update({
                "expected_output_type": "image_description",
                "processing_time_estimate": "medium",
                "output_format": "diagram_instructions"
            })
        
        elif intent == "assessment":
            hints.update({
                "expected_output_type": "structured_feedback",
                "processing_time_estimate": "slow",
                "requires_audio_processing": True
            })
        
        elif intent == "lesson_planning":
            hints.update({
                "expected_output_type": "structured_plan",
                "processing_time_estimate": "medium",
                "output_format": "weekly_schedule"
            })
        
        return hints
    
    def get_capabilities(self) -> Dict[str, Any]:
        """
        Return the capabilities of the Orchestrator agent.
        
        Returns:
            Dictionary describing agent capabilities
        """
        return {
            "name": self.name,
            "description": "Intent detection and request routing agent",
            "supported_operations": [
                "intent_detection",
                "request_routing", 
                "language_detection",
                "confidence_scoring"
            ],
            "supported_intents": list(self.intent_patterns.keys()),
            "input_types": ["text", "multimodal"],
            "output_types": ["routing_info"]
        } 