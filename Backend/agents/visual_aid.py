from typing import Dict, Any, List, Optional
import json
import base64
import io
from PIL import Image, ImageDraw, ImageFont
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np

from agents.base_agent import BaseAgent
from utils.logging import get_logger
import google.generativeai as genai
from utils.config import settings

class VisualAidAgent(BaseAgent):
    """
    Visual Aid Agent for generating educational diagrams and visual aids
    
    Converts text prompts into simple, blackboard-friendly diagrams
    and educational illustrations suitable for rural classrooms.
    """
    
    def __init__(self):
        super().__init__("VisualAidAgent")
        self.model = genai.GenerativeModel('gemini-pro')
        # For image generation, we'll use a different approach
        self.image_model = genai.GenerativeModel('gemini-pro-vision')
        
        # Diagram types and templates
        self.diagram_types = {
            "concept_map": {
                "description": "Mind maps and concept relationships",
                "use_cases": ["vocabulary", "topic_overview", "connections"]
            },
            "flowchart": {
                "description": "Process flows and step-by-step procedures",
                "use_cases": ["science_experiments", "math_procedures", "story_sequence"]
            },
            "timeline": {
                "description": "Historical events or process sequences",
                "use_cases": ["history", "life_cycles", "story_progression"]
            },
            "cycle_diagram": {
                "description": "Circular processes and cycles",
                "use_cases": ["water_cycle", "seasons", "life_cycles"]
            },
            "comparison_chart": {
                "description": "Compare and contrast concepts",
                "use_cases": ["similarities_differences", "pros_cons", "before_after"]
            },
            "labeled_diagram": {
                "description": "Diagrams with labels and annotations",
                "use_cases": ["body_parts", "plant_parts", "geography"]
            },
            "graph_chart": {
                "description": "Data visualization and charts",
                "use_cases": ["statistics", "survey_results", "comparisons"]
            }
        }
        
        # Visual style guidelines for rural classrooms
        self.style_guidelines = {
            "colors": {
                "primary": "#2E7D32",    # Dark green (chalk/natural)
                "secondary": "#1976D2",  # Blue
                "accent": "#F57C00",     # Orange
                "background": "#FFFDE7", # Light cream (like paper)
                "text": "#212121"        # Dark gray
            },
            "fonts": {
                "title": {"size": 16, "weight": "bold"},
                "heading": {"size": 14, "weight": "bold"},
                "body": {"size": 12, "weight": "normal"},
                "label": {"size": 10, "weight": "normal"}
            },
            "constraints": {
                "max_width": 800,
                "max_height": 600,
                "min_font_size": 10,
                "line_thickness": 2,
                "simple_shapes": True,
                "high_contrast": True
            }
        }

    async def process(self, request_data: Dict[str, Any], user_context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Generate Mermaid diagram visual aid using Gemini AI
        
        Args:
            request_data: Contains concept description, diagram type, and preferences
            user_context: Optional user context (not used in this agent)
            
        Returns:
            Dict containing generated Mermaid diagram and metadata
        """
        try:
            # Extract and validate input
            concept = request_data.get('concept', '')
            diagram_type = request_data.get('diagram_type', 'simple')
            language = request_data.get('language', 'en')
            grade_level = request_data.get('grade_level', 'grade_3_4')
            style = request_data.get('style', 'blackboard_simple')
            
            if not concept:
                raise ValueError("No concept description provided")
            
            self.logger.info(f"Generating visual aid for concept: {concept}")
            
            # Generate Mermaid diagram using Gemini
            try:
                # Generate Mermaid diagram using Gemini
                mermaid_result = await self._generate_mermaid_diagram_with_gemini(
                    concept, diagram_type, language, grade_level
                )
                
                # Generate teaching instructions
                teaching_data = await self._generate_teaching_instructions(
                    concept, {"title": concept, "description": f"Educational diagram for {concept}"}, language
                )
                
                return {
                    "diagram_description": f"Educational Mermaid diagram for {concept}",
                    "mermaid_code": mermaid_result["mermaid_code"],
                    "diagram_type": diagram_type,
                    "drawing_instructions": mermaid_result.get("drawing_instructions", []),
                    "teaching_instructions": teaching_data.get("instructions", []),
                    "key_points": teaching_data.get("key_points", []),
                    "metadata": {
                        "concept": concept,
                        "diagram_type": diagram_type,
                        "language": language,
                        "grade_level": grade_level,
                        "style": "mermaid_diagram",
                        "estimated_time": "5-10 minutes"
                    },
                    "materials_needed": ["chalk/marker", "blackboard/whiteboard", "eraser"],
                    "teaching_tips": teaching_data.get("tips", []),
                    "model_used": "gemini-pro",
                    "generation_method": "AI-generated Mermaid diagram",
                    "gemini_model": "gemini-pro"
                }
                
            except Exception as e:
                self.logger.error(f"Visual diagram generation failed: {str(e)}")
                self.logger.info("Using fallback visual aid")
                
                # Fallback to simple diagram generation
                try:
                    # Create a simple fallback structure
                    fallback_structure = self._create_fallback_structure(concept, diagram_type)
                    
                    # Create visual diagram from fallback structure
                    visual_result = await self._create_visual_diagram(fallback_structure, diagram_type)
                    
                    return {
                        "diagram_description": f"Simple educational diagram for {concept}",
                        "image_base64": visual_result["image_base64"],
                        "image_format": visual_result["format"],
                        "image_width": visual_result["width"],
                        "image_height": visual_result["height"],
                        "drawing_instructions": fallback_structure.get("drawing_instructions", []),
                        "teaching_instructions": [],
                        "key_points": [f"Learn about {concept}"],
                        "metadata": {
                            "concept": concept,
                            "diagram_type": diagram_type,
                            "language": language,
                            "grade_level": grade_level,
                            "style": "blackboard_simple",
                            "estimated_time": "5-10 minutes"
                        },
                        "materials_needed": ["chalk/marker", "blackboard/whiteboard", "eraser"],
                        "teaching_tips": ["Use this diagram to explain the concept step by step"]
                    }
                except Exception as fallback_error:
                    self.logger.error(f"Fallback also failed: {str(fallback_error)}")
                    raise

        except Exception as e:
            self.logger.error(f"Visual aid generation failed: {str(e)}")
            return {
                "success": False,
                "error": str(e),
                "agent": self.name
            }

    async def _generate_mermaid_diagram_with_gemini(self, concept: str, diagram_type: str, language: str, grade_level: str) -> Dict[str, Any]:
        """Generate Mermaid diagram using Gemini Pro"""
        
        # Map diagram types to Mermaid diagram types
        mermaid_type_map = {
            "concept_map": "mindmap",
            "flowchart": "flowchart",
            "timeline": "gantt",
            "cycle_diagram": "graph",
            "comparison_chart": "graph",
            "labeled_diagram": "graph",
            "graph_chart": "graph",
            "simple": "graph"
        }
        
        mermaid_type = mermaid_type_map.get(diagram_type, "graph")
        
        prompt = f"""Create a Mermaid diagram for the concept "{concept}" for {grade_level} students.

Requirements:
- Use Mermaid syntax for {mermaid_type} diagram type
- Simple, educational design suitable for classroom teaching
- Age-appropriate for {grade_level} students
- Language: {language}
- Include clear labels and relationships
- Make it easy for teachers to draw on blackboard
- Use simple shapes and clear text

Concept: {concept}
Diagram Type: {diagram_type}
Target Audience: {grade_level} students

Please generate ONLY the Mermaid code without any explanation or markdown formatting. The response should start with the diagram type (e.g., "graph TD" or "flowchart TD") and contain only valid Mermaid syntax.

Example format for flowchart:
flowchart TD
    A[Start] --> B[Process]
    B --> C[End]

Example format for mindmap:
mindmap
  root((Main Topic))
    Subtopic 1
    Subtopic 2
      Detail 1
      Detail 2

Generate the Mermaid diagram:"""

        try:
            response = self.model.generate_content(prompt)
            
            if response.text:
                # Extract Mermaid code from response
                mermaid_code = response.text.strip()
                
                # Clean up the response to get just the Mermaid code
                if "```mermaid" in mermaid_code:
                    # Extract from markdown code block
                    start = mermaid_code.find("```mermaid") + 9
                    end = mermaid_code.find("```", start)
                    if end != -1:
                        mermaid_code = mermaid_code[start:end].strip()
                elif "```" in mermaid_code:
                    # Extract from generic code block
                    start = mermaid_code.find("```") + 3
                    end = mermaid_code.find("```", start)
                    if end != -1:
                        mermaid_code = mermaid_code[start:end].strip()
                
                # Generate drawing instructions
                drawing_instructions = self._generate_drawing_instructions_from_mermaid(mermaid_code, concept)
                
                return {
                    "mermaid_code": mermaid_code,
                    "drawing_instructions": drawing_instructions,
                    "diagram_type": diagram_type
                }
            else:
                raise Exception("No content generated by Gemini")
                
        except Exception as e:
            self.logger.error(f"Mermaid diagram generation failed: {str(e)}")
            # Return fallback Mermaid diagram
            return {
                "mermaid_code": f"graph TD\n    A[{concept}] --> B[Learn]\n    B --> C[Understand]",
                "drawing_instructions": [f"Draw a simple diagram showing {concept}"],
                "diagram_type": diagram_type
            }
    
    def _generate_drawing_instructions_from_mermaid(self, mermaid_code: str, concept: str) -> List[str]:
        """Generate drawing instructions from Mermaid code"""
        instructions = []
        
        # Simple parsing of Mermaid code to generate drawing instructions
        if "flowchart" in mermaid_code or "graph" in mermaid_code:
            instructions.append(f"Start by drawing the main concept: {concept}")
            instructions.append("Add boxes for each step or component")
            instructions.append("Connect the boxes with arrows showing the flow")
        elif "mindmap" in mermaid_code:
            instructions.append(f"Draw the main topic '{concept}' in the center")
            instructions.append("Add branches for subtopics")
            instructions.append("Connect with lines to show relationships")
        elif "gantt" in mermaid_code:
            instructions.append("Draw a timeline with dates or steps")
            instructions.append("Add bars to show duration of activities")
        
        instructions.append("Use clear, simple shapes that are easy to draw")
        instructions.append("Add labels to explain each part")
        
        return instructions

    async def _generate_hand_drawable_image_with_gemini(self, concept: str, diagram_type: str, language: str, grade_level: str) -> Dict[str, Any]:
        """Generate hand-drawable educational image using Gemini AI"""
        
        # Create a detailed prompt for image generation
        image_prompt = f"""Create a simple, hand-drawable educational diagram for teaching "{concept}" to {grade_level} students.

Style requirements:
- Simple line drawing style that a teacher can easily draw on a blackboard with chalk
- Clean, minimal design with clear lines
- Use basic geometric shapes (circles, squares, triangles, lines, arrows)
- High contrast black and white design
- No complex shading or gradients
- Large, readable text labels
- Educational and age-appropriate for {grade_level} students
- Language: {language}

Diagram type: {diagram_type}

The image should be:
1. Easy to replicate by hand on a blackboard
2. Clear and educational
3. Suitable for rural Indian classroom settings
4. Simple enough for students to understand and teachers to draw

Concept: {concept}

Please create a clean, simple diagram that shows the key elements of {concept} in a way that can be easily drawn with chalk on a blackboard."""
        
        try:
            # Use Gemini Pro to generate detailed image description
            # Then create image using matplotlib with Gemini's guidance
            
            # Generate detailed image description using Gemini Pro
            image_description = await self._generate_image_description_with_gemini(
                concept, diagram_type, language, grade_level
            )
            
            # Create detailed drawing instructions
            drawing_instructions = self._generate_drawing_instructions(concept, diagram_type, grade_level)
            
            # Create a diagram structure with Gemini's guidance
            diagram_structure = {
                "title": concept,
                "description": image_description.get("description", f"Educational diagram for {concept}"),
                "elements": drawing_instructions["elements"],
                "connections": drawing_instructions.get("connections", []),
                "drawing_instructions": image_description.get("steps", drawing_instructions["steps"]),
                "teaching_tips": image_description.get("tips", drawing_instructions["tips"]),
                "style_guide": image_description.get("style_guide", {})
            }
            
            # Create image using matplotlib with Gemini's guidance
            image_result = await self._create_gemini_guided_image(diagram_structure, diagram_type)
            
            return {
                "image_base64": image_result["image_base64"],
                "format": "png",
                "width": 800,
                "height": 600,
                "description": diagram_structure["description"],
                "drawing_instructions": diagram_structure["drawing_instructions"],
                "teaching_tips": diagram_structure["teaching_tips"]
            }
                
        except Exception as e:
            self.logger.error(f"Gemini image generation failed: {str(e)}")
            # Fallback to simple diagram
            return await self._create_simple_fallback_image(concept, diagram_type)

    def _generate_drawing_instructions(self, concept: str, diagram_type: str, grade_level: str) -> Dict[str, Any]:
        """Generate detailed drawing instructions for hand-drawable diagrams"""
        
        concept_lower = concept.lower()
        
        if "water cycle" in concept_lower:
            return {
                "elements": [
                    {"id": "sun", "label": "Sun", "position": "top-right", "type": "main"},
                    {"id": "clouds", "label": "Clouds", "position": "top-center", "type": "main"},
                    {"id": "rain", "label": "Rain", "position": "center", "type": "main"},
                    {"id": "ocean", "label": "Ocean", "position": "bottom", "type": "main"},
                    {"id": "plants", "label": "Plants", "position": "bottom-left", "type": "secondary"}
                ],
                "connections": [
                    {"from": "ocean", "to": "clouds", "label": "Evaporation"},
                    {"from": "clouds", "to": "rain", "label": "Condensation"},
                    {"from": "rain", "to": "ocean", "label": "Collection"}
                ],
                "steps": [
                    "Draw a large sun in the top-right corner",
                    "Draw fluffy clouds in the top-center",
                    "Draw raindrops falling from clouds",
                    "Draw a wavy ocean at the bottom",
                    "Draw simple plants and trees",
                    "Add arrows showing water flow cycle"
                ],
                "tips": [
                    "Start with the sun and explain evaporation",
                    "Show how water moves through the cycle",
                    "Use different colored chalk for arrows"
                ]
            }
        elif "plant" in concept_lower or "parts" in concept_lower:
            return {
                "elements": [
                    {"id": "roots", "label": "Roots", "position": "bottom", "type": "main"},
                    {"id": "stem", "label": "Stem", "position": "center", "type": "main"},
                    {"id": "leaves", "label": "Leaves", "position": "top-left", "type": "main"},
                    {"id": "flower", "label": "Flower", "position": "top-right", "type": "main"}
                ],
                "connections": [],
                "steps": [
                    "Draw roots at the bottom",
                    "Draw a straight stem in the center",
                    "Draw leaves on the sides",
                    "Draw a flower at the top",
                    "Add labels for each part"
                ],
                "tips": [
                    "Explain each part's function",
                    "Show how parts work together",
                    "Use simple shapes for each part"
                ]
            }
        else:
            # Generic diagram
            return {
                "elements": [
                    {"id": "main", "label": concept, "position": "center", "type": "main"}
                ],
                "connections": [],
                "steps": [
                    f"Draw a simple diagram showing {concept}",
                    "Add clear labels",
                    "Use simple shapes and lines"
                ],
                "tips": [
                    f"Explain {concept} step by step",
                    "Use simple language for {grade_level} students",
                    "Encourage students to ask questions"
                ]
            }

    def _generate_mock_blackboard_diagram(self, concept: str, diagram_type: str, language: str) -> Dict[str, Any]:
        """Generate mock blackboard diagram for fallback"""
        
        concept_lower = concept.lower()
        
        if "water cycle" in concept_lower or "water" in concept_lower:
            return {
                "description": "Simple blackboard drawing of the water cycle showing sun, clouds, rain, and water body",
                "ascii_art": """
    ☀️ (sun)
        ☁️ ☁️ (clouds)
      💧💧💧 (rain)
    ↗️  evaporation  ↖️
    🌊~~~~~~~~~~~🌊 (water body)
    🌱🌳 (plants)
                """,
                "instructions": [
                    "Draw the sun in the top right corner",
                    "Draw 2-3 clouds in the sky",
                    "Draw wavy lines from water to clouds (evaporation)",
                    "Draw rain drops falling from clouds",
                    "Draw a water body (river/lake) at the bottom",
                    "Add simple trees and plants",
                    "Draw arrows to show the cycle direction",
                    "Label each part: Sun, Clouds, Rain, Water"
                ],
                "teaching_tips": [
                    "Start with the sun - explain it heats the water",
                    "Show how water rises as vapor (invisible)",
                    "Explain how clouds form when vapor cools",
                    "Demonstrate rain falling back to earth",
                    "Emphasize it's a never-ending cycle"
                ]
            }
            
        elif "photo" in concept_lower or "plant" in concept_lower:
            return {
                "description": "Simple diagram showing how plants make food using sunlight, water, and air",
                "ascii_art": """
    ☀️ (sunlight)
       ↓
    🌿🍃 (leaves)
    |  |
    🌱 (stem)
    |
   🌰 (roots)
   💧 (water)
                """,
                "instructions": [
                    "Draw a simple plant with leaves, stem, and roots",
                    "Draw the sun above the plant",
                    "Draw arrows from sun to leaves",
                    "Draw water drops near the roots",
                    "Draw CO2 symbols in the air",
                    "Show oxygen being released from leaves",
                    "Label: Sunlight, Water, CO2, Oxygen"
                ],
                "teaching_tips": [
                    "Explain that plants are like tiny food factories",
                    "Show how they need 3 ingredients: sun, water, air",
                    "Emphasize they make oxygen for us to breathe"
                ]
            }
            
        else:
            # Generic diagram template
            return {
                "description": f"Simple blackboard diagram explaining {concept} in easy steps",
                "ascii_art": f"""
    📝 {concept.upper()}
    
    Step 1: ○ ——→ □
    
    Step 2: □ ——→ △
    
    Step 3: △ ——→ ★
    
    Result: {concept} explained!
                """,
                "instructions": [
                    f"Write '{concept}' as the title",
                    "Draw simple shapes to represent main ideas",
                    "Connect shapes with arrows to show process",
                    "Add labels to explain each step",
                    "Use simple symbols students can recognize"
                ],
                "teaching_tips": [
                    f"Break down {concept} into simple steps",
                    "Use familiar examples from daily life",
                    "Encourage students to ask questions",
                    "Let students help draw parts of the diagram"
                ]
            }
    
    def _extract_ascii_from_text(self, text: str) -> str:
        """Extract ASCII art from Gemini response text"""
        # Simple extraction - look for patterns that look like ASCII art
        lines = text.split('\n')
        ascii_lines = []
        in_ascii = False
        
        for line in lines:
            if any(char in line for char in ['|', '-', '+', '*', '~', '^', 'o', '○', '□', '△']):
                ascii_lines.append(line)
                in_ascii = True
            elif in_ascii and len(line.strip()) == 0:
                ascii_lines.append(line)
            elif in_ascii and len(ascii_lines) > 3:
                break
                
        return '\n'.join(ascii_lines) if ascii_lines else f"Simple diagram of {concept}"
    
    def _extract_instructions_from_text(self, text: str) -> List[str]:
        """Extract numbered instructions from Gemini response"""
        lines = text.split('\n')
        instructions = []
        
        for line in lines:
            line = line.strip()
            if line and (line[0].isdigit() or line.startswith('-') or line.startswith('•')):
                # Clean up the instruction
                instruction = line.lstrip('0123456789.-• ').strip()
                if instruction:
                    instructions.append(instruction)
                    
        return instructions if instructions else [f"Draw a simple diagram showing {concept}"]

    async def _detect_diagram_type(self, concept: str, subject: str) -> str:
        """
        Auto-detect the best diagram type for the given concept
        
        Args:
            concept: Description of what to visualize
            subject: Subject context
            
        Returns:
            Best suited diagram type
        """
        try:
            detection_prompt = f"""
            Analyze this concept and determine the best diagram type for visualization.
            
            Concept: {concept}
            Subject: {subject}
            
            Available diagram types:
            {json.dumps(self.diagram_types, indent=2)}
            
            Return only the diagram type key (e.g., "concept_map", "flowchart", etc.)
            that would best represent this concept for students.
            """
            
            response = self.model.generate_content(detection_prompt)
            detected_type = response.text.strip().lower()
            
            # Validate detected type
            if detected_type in self.diagram_types:
                return detected_type
            else:
                # Fallback to concept_map
                return "concept_map"
                
        except Exception as e:
            self.logger.error(f"Diagram type detection failed: {str(e)}")
            return "concept_map"

    async def _generate_diagram_structure(
        self, 
        concept: str, 
        diagram_type: str, 
        language: str, 
        grade_level: str, 
        subject: str
    ) -> Dict[str, Any]:
        """
        Generate the structural data for the diagram
        
        Args:
            concept: What to visualize
            diagram_type: Type of diagram
            language: Target language
            grade_level: Educational level
            subject: Subject context
            
        Returns:
            Structured diagram data
        """
        try:
            structure_prompt = f"""
            Create a {diagram_type} structure for this concept:
            
            Concept: {concept}
            Language: {language}
            Grade Level: {grade_level}
            Subject: {subject}
            
            Requirements:
            - Simple, clear structure appropriate for {grade_level}
            - Use vocabulary suitable for rural Indian students
            - Include cultural context and familiar examples
            - Maximum 8-10 elements to avoid overcrowding
            - Clear relationships between elements
            
            Return a JSON structure with:
            - title: Main title
            - elements: List of diagram elements with text and positions
            - connections: Relationships between elements
            - colors: Color scheme suggestions
            - notes: Additional teaching notes
            
            Example for concept_map:
            {{
                "title": "Main Topic",
                "elements": [
                    {{"id": 1, "text": "Central Idea", "position": "center", "type": "main"}},
                    {{"id": 2, "text": "Sub-concept 1", "position": "top-left", "type": "sub"}}
                ],
                "connections": [
                    {{"from": 1, "to": 2, "label": "includes"}}
                ]
            }}
            """
            
            response = self.model.generate_content(structure_prompt)
            
            # Parse JSON response
            try:
                structure = json.loads(response.text)
            except json.JSONDecodeError:
                # Fallback structure
                structure = self._create_fallback_structure(concept, diagram_type)
            
            return structure
            
        except Exception as e:
            self.logger.error(f"Diagram structure generation failed: {str(e)}")
            return self._create_fallback_structure(concept, diagram_type)

    def _create_fallback_structure(self, concept: str, diagram_type: str) -> Dict[str, Any]:
        """
        Create a simple fallback structure when AI generation fails
        
        Args:
            concept: The concept to visualize
            diagram_type: Type of diagram
            
        Returns:
            Basic diagram structure
        """
        return {
            "title": concept,
            "elements": [
                {"id": 1, "text": concept, "position": "center", "type": "main"},
                {"id": 2, "text": "Detail 1", "position": "top", "type": "sub"},
                {"id": 3, "text": "Detail 2", "position": "right", "type": "sub"},
                {"id": 4, "text": "Detail 3", "position": "bottom", "type": "sub"}
            ],
            "connections": [
                {"from": 1, "to": 2, "label": ""},
                {"from": 1, "to": 3, "label": ""},
                {"from": 1, "to": 4, "label": ""}
            ],
            "colors": self.style_guidelines["colors"],
            "notes": "Simple diagram structure"
        }

    async def _create_gemini_guided_image(
        self, 
        structure: Dict[str, Any], 
        diagram_type: str
    ) -> Dict[str, Any]:
        """
        Create image using matplotlib with Gemini's guidance
        
        Args:
            structure: Diagram structure with Gemini's guidance
            diagram_type: Type of diagram to create
            
        Returns:
            Visual output data including image
        """
        try:
            # Set up the figure with Gemini's style guidance
            fig, ax = plt.subplots(1, 1, figsize=(10, 8))
            ax.set_xlim(0, 10)
            ax.set_ylim(0, 8)
            ax.axis('off')
            
            # Apply Gemini's style guide
            style_guide = structure.get("style_guide", {})
            colors = style_guide.get("colors", ["black", "white"])
            shapes = style_guide.get("shapes", ["simple"])
            layout = style_guide.get("layout", "central")
            
            # Set background
            fig.patch.set_facecolor('white')
            ax.set_facecolor('white')
            
            # Draw elements based on Gemini's guidance
            elements = structure.get("elements", [])
            connections = structure.get("connections", [])
            
            # Position mapping
            positions = {
                "center": (5, 4),
                "top": (5, 6.5),
                "bottom": (5, 1.5),
                "left": (2, 4),
                "right": (8, 4),
                "top-left": (2, 6.5),
                "top-right": (8, 6.5),
                "bottom-left": (2, 1.5),
                "bottom-right": (8, 1.5)
            }
            
            # Draw elements with Gemini's style
            for element in elements:
                pos = positions.get(element.get("position", "center"), (5, 4))
                label = element.get("label", "")
                element_type = element.get("type", "main")
                
                # Apply Gemini's shape guidance
                if "circles" in shapes or "simple" in shapes:
                    if element_type == "main":
                        circle = plt.Circle(pos, 0.8, fill=False, color=colors[0], linewidth=3)
                        ax.add_patch(circle)
                    else:
                        circle = plt.Circle(pos, 0.5, fill=False, color=colors[0], linewidth=2)
                        ax.add_patch(circle)
                else:
                    # Default rectangle
                    rect = plt.Rectangle((pos[0]-0.6, pos[1]-0.4), 1.2, 0.8, 
                                       fill=False, color=colors[0], linewidth=3)
                    ax.add_patch(rect)
                
                # Add label
                ax.text(pos[0], pos[1], label, ha='center', va='center', 
                       fontsize=12, fontweight='bold', color=colors[0])
            
            # Draw connections with arrows
            for connection in connections:
                from_pos = positions.get(connection.get("from", "center"), (5, 4))
                to_pos = positions.get(connection.get("to", "center"), (5, 4))
                label = connection.get("label", "")
                
                # Draw arrow
                ax.annotate('', xy=to_pos, xytext=from_pos,
                           arrowprops=dict(arrowstyle='->', lw=2, color=colors[0]))
                
                # Add connection label
                mid_x = (from_pos[0] + to_pos[0]) / 2
                mid_y = (from_pos[1] + to_pos[1]) / 2
                ax.text(mid_x, mid_y, label, ha='center', va='center',
                       fontsize=10, color=colors[0], bbox=dict(boxstyle="round,pad=0.3", 
                       facecolor='white', edgecolor=colors[0], linewidth=1))
            
            # Add title
            plt.title(structure.get("title", "Educational Diagram"), 
                     fontsize=16, fontweight='bold', color=colors[0], pad=20)
            
            # Save to base64
            buffer = io.BytesIO()
            plt.savefig(buffer, format='png', dpi=150, bbox_inches='tight',
                       facecolor='white', edgecolor='none')
            buffer.seek(0)
            
            # Convert to base64
            image_base64 = base64.b64encode(buffer.getvalue()).decode()
            plt.close()
            
            return {
                "image_base64": image_base64,
                "format": "png",
                "width": 800,
                "height": 600,
                "description": f"Gemini-guided {diagram_type} for {structure.get('title', 'concept')}",
                "model_used": "gemini-pro + matplotlib",
                "generation_method": "AI-guided image creation"
            }
            
        except Exception as e:
            self.logger.error(f"Gemini-guided image creation failed: {str(e)}")
            raise

    async def _create_hand_drawable_image(
        self, 
        structure: Dict[str, Any], 
        diagram_type: str
    ) -> Dict[str, Any]:
        """
        Create a hand-drawable style image using matplotlib
        
        Args:
            structure: Diagram structure data
            diagram_type: Type of diagram to create
            
        Returns:
            Visual output data including image
        """
        try:
            # Set up the figure with hand-drawn style
            fig, ax = plt.subplots(1, 1, figsize=(10, 8))
            ax.set_xlim(0, 10)
            ax.set_ylim(0, 8)
            ax.axis('off')
            
            # Set background color to white (like paper)
            fig.patch.set_facecolor('white')
            ax.set_facecolor('white')
            
            # Draw elements in hand-drawn style
            elements = structure.get("elements", [])
            connections = structure.get("connections", [])
            
            # Position mapping for hand-drawn style
            positions = {
                "center": (5, 4),
                "top": (5, 6.5),
                "bottom": (5, 1.5),
                "left": (2, 4),
                "right": (8, 4),
                "top-left": (2, 6.5),
                "top-right": (8, 6.5),
                "bottom-left": (2, 1.5),
                "bottom-right": (8, 1.5)
            }
            
            # Draw elements with hand-drawn style
            for element in elements:
                pos = positions.get(element.get("position", "center"), (5, 4))
                label = element.get("label", "")
                element_type = element.get("type", "main")
                
                # Draw simple shapes (hand-drawn style)
                if element_type == "main":
                    # Draw a simple circle or rectangle
                    circle = plt.Circle(pos, 0.8, fill=False, color='black', linewidth=3)
                    ax.add_patch(circle)
                else:
                    # Draw a smaller shape for secondary elements
                    circle = plt.Circle(pos, 0.5, fill=False, color='black', linewidth=2)
                    ax.add_patch(circle)
                
                # Add label with hand-drawn style font
                ax.text(pos[0], pos[1], label, ha='center', va='center', 
                       fontsize=12, fontweight='bold', color='black')
            
            # Draw connections with arrows
            for connection in connections:
                from_pos = positions.get(connection.get("from", "center"), (5, 4))
                to_pos = positions.get(connection.get("to", "center"), (5, 4))
                label = connection.get("label", "")
                
                # Draw arrow
                ax.annotate('', xy=to_pos, xytext=from_pos,
                           arrowprops=dict(arrowstyle='->', lw=2, color='black'))
                
                # Add connection label
                mid_x = (from_pos[0] + to_pos[0]) / 2
                mid_y = (from_pos[1] + to_pos[1]) / 2
                ax.text(mid_x, mid_y, label, ha='center', va='center',
                       fontsize=10, color='black', bbox=dict(boxstyle="round,pad=0.3", 
                       facecolor='white', edgecolor='black', linewidth=1))
            
            # Add title
            plt.title(structure.get("title", "Educational Diagram"), 
                     fontsize=16, fontweight='bold', color='black', pad=20)
            
            # Save to base64 with high quality
            buffer = io.BytesIO()
            plt.savefig(buffer, format='png', dpi=150, bbox_inches='tight',
                       facecolor='white', edgecolor='none')
            buffer.seek(0)
            
            # Convert to base64
            image_base64 = base64.b64encode(buffer.getvalue()).decode()
            plt.close()
            
            return {
                "image_base64": image_base64,
                "format": "png",
                "width": 800,
                "height": 600,
                "description": f"Hand-drawable {diagram_type} for {structure.get('title', 'concept')}"
            }
            
        except Exception as e:
            self.logger.error(f"Hand-drawable image creation failed: {str(e)}")
            raise

    async def _create_simple_fallback_image(self, concept: str, diagram_type: str) -> Dict[str, Any]:
        """Create a simple fallback image when main generation fails"""
        try:
            fig, ax = plt.subplots(1, 1, figsize=(8, 6))
            ax.set_xlim(0, 10)
            ax.set_ylim(0, 8)
            ax.axis('off')
            
            # Set background
            fig.patch.set_facecolor('white')
            ax.set_facecolor('white')
            
            # Draw a simple diagram
            ax.text(5, 4, concept, ha='center', va='center', 
                   fontsize=20, fontweight='bold', color='black')
            
            # Add a simple border
            rect = plt.Rectangle((1, 1), 8, 6, fill=False, color='black', linewidth=2)
            ax.add_patch(rect)
            
            # Save to base64
            buffer = io.BytesIO()
            plt.savefig(buffer, format='png', dpi=150, bbox_inches='tight',
                       facecolor='white', edgecolor='none')
            buffer.seek(0)
            
            image_base64 = base64.b64encode(buffer.getvalue()).decode()
            plt.close()
            
            return {
                "image_base64": image_base64,
                "format": "png",
                "width": 800,
                "height": 600,
                "description": f"Simple diagram for {concept}"
            }
            
        except Exception as e:
            self.logger.error(f"Fallback image creation failed: {str(e)}")
            # Return empty image data
            return {
                "image_base64": "",
                "format": "png",
                "width": 800,
                "height": 600,
                "description": f"Could not generate image for {concept}"
            }

    async def _create_visual_diagram(
        self, 
        structure: Dict[str, Any], 
        diagram_type: str
    ) -> Dict[str, Any]:
        """
        Create the actual visual diagram from structure
        
        Args:
            structure: Diagram structure data
            diagram_type: Type of diagram to create
            
        Returns:
            Visual output data including image
        """
        try:
            # Set up the figure
            fig, ax = plt.subplots(1, 1, figsize=(10, 8))
            ax.set_xlim(0, 10)
            ax.set_ylim(0, 8)
            ax.axis('off')
            
            # Set background color
            fig.patch.set_facecolor(self.style_guidelines["colors"]["background"])
            
            # Draw based on diagram type
            if diagram_type == "concept_map":
                self._draw_concept_map(ax, structure)
            elif diagram_type == "flowchart":
                self._draw_flowchart(ax, structure)
            elif diagram_type == "timeline":
                self._draw_timeline(ax, structure)
            elif diagram_type == "cycle_diagram":
                self._draw_cycle_diagram(ax, structure)
            elif diagram_type == "comparison_chart":
                self._draw_comparison_chart(ax, structure)
            elif diagram_type == "labeled_diagram":
                self._draw_labeled_diagram(ax, structure)
            else:
                self._draw_concept_map(ax, structure)  # Default fallback
            
            # Add title
            plt.title(structure.get("title", "Educational Diagram"), 
                     fontsize=self.style_guidelines["fonts"]["title"]["size"],
                     fontweight=self.style_guidelines["fonts"]["title"]["weight"],
                     color=self.style_guidelines["colors"]["text"])
            
            # Save to base64
            buffer = io.BytesIO()
            plt.savefig(buffer, format='png', dpi=150, bbox_inches='tight',
                       facecolor=self.style_guidelines["colors"]["background"])
            buffer.seek(0)
            
            # Convert to base64
            image_base64 = base64.b64encode(buffer.getvalue()).decode()
            plt.close()
            
            return {
                "image_base64": image_base64,
                "format": "png",
                "width": 800,
                "height": 600,
                "description": f"{diagram_type} for {structure.get('title', 'concept')}"
            }
            
        except Exception as e:
            self.logger.error(f"Visual diagram creation failed: {str(e)}")
            raise

    def _draw_concept_map(self, ax, structure: Dict[str, Any]):
        """Draw a concept map diagram"""
        elements = structure.get("elements", [])
        connections = structure.get("connections", [])
        colors = structure.get("colors", self.style_guidelines["colors"])
        
        # Position mapping
        positions = {
            "center": (5, 4),
            "top": (5, 6),
            "bottom": (5, 2),
            "left": (2, 4),
            "right": (8, 4),
            "top-left": (2, 6),
            "top-right": (8, 6),
            "bottom-left": (2, 2),
            "bottom-right": (8, 2)
        }
        
        element_positions = {}
        
        # Draw elements
        for element in elements:
            pos = positions.get(element.get("position", "center"), (5, 4))
            element_positions[element["id"]] = pos
            
            # Choose color based on type
            if element.get("type") == "main":
                color = colors["primary"]
                size = 150
            else:
                color = colors["secondary"]
                size = 100
            
            # Draw circle
            circle = patches.Circle(pos, 0.8, facecolor=color, 
                                  edgecolor=colors["text"], linewidth=2, alpha=0.8)
            ax.add_patch(circle)
            
            # Add text
            ax.text(pos[0], pos[1], element["text"], ha='center', va='center',
                   fontsize=10, color='white', weight='bold', wrap=True)
        
        # Draw connections
        for conn in connections:
            from_pos = element_positions.get(conn["from"])
            to_pos = element_positions.get(conn["to"])
            
            if from_pos and to_pos:
                ax.annotate('', xy=to_pos, xytext=from_pos,
                           arrowprops=dict(arrowstyle='->', lw=2, 
                                         color=colors["text"]))

    def _draw_flowchart(self, ax, structure: Dict[str, Any]):
        """Draw a flowchart diagram"""
        elements = structure.get("elements", [])
        colors = structure.get("colors", self.style_guidelines["colors"])
        
        # Arrange elements vertically
        y_positions = np.linspace(7, 1, len(elements))
        
        for i, element in enumerate(elements):
            y = y_positions[i]
            
            # Draw rectangle
            rect = patches.Rectangle((3, y-0.5), 4, 1, 
                                   facecolor=colors["secondary"], 
                                   edgecolor=colors["text"], linewidth=2)
            ax.add_patch(rect)
            
            # Add text
            ax.text(5, y, element["text"], ha='center', va='center',
                   fontsize=10, color='white', weight='bold')
            
            # Draw arrow to next element
            if i < len(elements) - 1:
                ax.annotate('', xy=(5, y_positions[i+1]+0.5), 
                           xytext=(5, y-0.5),
                           arrowprops=dict(arrowstyle='->', lw=2, 
                                         color=colors["text"]))

    def _draw_timeline(self, ax, structure: Dict[str, Any]):
        """Draw a timeline diagram"""
        elements = structure.get("elements", [])
        colors = structure.get("colors", self.style_guidelines["colors"])
        
        # Draw main timeline
        ax.plot([1, 9], [4, 4], color=colors["primary"], linewidth=4)
        
        # Add events
        x_positions = np.linspace(2, 8, len(elements))
        
        for i, element in enumerate(elements):
            x = x_positions[i]
            y = 4.5 if i % 2 == 0 else 3.5
            
            # Draw event marker
            ax.plot(x, 4, 'o', markersize=10, color=colors["accent"])
            
            # Draw connection line
            ax.plot([x, x], [4, y], color=colors["text"], linewidth=1)
            
            # Add text box
            bbox = dict(boxstyle="round,pad=0.3", facecolor=colors["background"], 
                       edgecolor=colors["text"])
            ax.text(x, y, element["text"], ha='center', va='center',
                   fontsize=9, bbox=bbox)

    def _draw_cycle_diagram(self, ax, structure: Dict[str, Any]):
        """Draw a cycle diagram"""
        elements = structure.get("elements", [])
        colors = structure.get("colors", self.style_guidelines["colors"])
        
        # Calculate positions in circle
        n = len(elements)
        angles = np.linspace(0, 2*np.pi, n, endpoint=False)
        center = (5, 4)
        radius = 2.5
        
        positions = []
        for angle in angles:
            x = center[0] + radius * np.cos(angle)
            y = center[1] + radius * np.sin(angle)
            positions.append((x, y))
        
        # Draw elements
        for i, (element, pos) in enumerate(zip(elements, positions)):
            # Draw circle
            circle = patches.Circle(pos, 0.6, facecolor=colors["secondary"], 
                                  edgecolor=colors["text"], linewidth=2)
            ax.add_patch(circle)
            
            # Add text
            ax.text(pos[0], pos[1], element["text"], ha='center', va='center',
                   fontsize=9, color='white', weight='bold')
            
            # Draw arrow to next element
            next_pos = positions[(i + 1) % n]
            mid_x = (pos[0] + next_pos[0]) / 2
            mid_y = (pos[1] + next_pos[1]) / 2
            
            ax.annotate('', xy=next_pos, xytext=pos,
                       arrowprops=dict(arrowstyle='->', lw=2, 
                                     color=colors["primary"],
                                     connectionstyle="arc3,rad=0.1"))

    def _draw_comparison_chart(self, ax, structure: Dict[str, Any]):
        """Draw a comparison chart"""
        elements = structure.get("elements", [])
        colors = structure.get("colors", self.style_guidelines["colors"])
        
        # Draw dividing line
        ax.plot([5, 5], [1, 7], color=colors["text"], linewidth=3)
        
        # Add headers
        ax.text(2.5, 6.5, "Side A", ha='center', va='center',
               fontsize=14, weight='bold', color=colors["primary"])
        ax.text(7.5, 6.5, "Side B", ha='center', va='center',
               fontsize=14, weight='bold', color=colors["secondary"])
        
        # Add comparison items
        left_items = [e for e in elements if e.get("side") == "A"][:4]
        right_items = [e for e in elements if e.get("side") == "B"][:4]
        
        y_positions = [5.5, 4.5, 3.5, 2.5]
        
        for i, item in enumerate(left_items):
            if i < len(y_positions):
                ax.text(2.5, y_positions[i], item["text"], ha='center', va='center',
                       fontsize=10, bbox=dict(boxstyle="round,pad=0.3", 
                                            facecolor=colors["background"]))
        
        for i, item in enumerate(right_items):
            if i < len(y_positions):
                ax.text(7.5, y_positions[i], item["text"], ha='center', va='center',
                       fontsize=10, bbox=dict(boxstyle="round,pad=0.3", 
                                            facecolor=colors["background"]))

    def _draw_labeled_diagram(self, ax, structure: Dict[str, Any]):
        """Draw a labeled diagram"""
        # This is a simplified version - in practice, you might want to 
        # generate more sophisticated labeled diagrams based on the content
        elements = structure.get("elements", [])
        colors = structure.get("colors", self.style_guidelines["colors"])
        
        # Draw a central shape (could be customized based on content)
        central_shape = patches.Rectangle((3, 2), 4, 4, 
                                        facecolor=colors["background"], 
                                        edgecolor=colors["primary"], linewidth=3)
        ax.add_patch(central_shape)
        
        # Add labels around the shape
        label_positions = [(1, 5), (5, 7), (9, 5), (5, 1)]
        
        for i, element in enumerate(elements[:4]):
            if i < len(label_positions):
                pos = label_positions[i]
                
                # Draw label
                ax.text(pos[0], pos[1], element["text"], ha='center', va='center',
                       fontsize=10, bbox=dict(boxstyle="round,pad=0.3", 
                                            facecolor=colors["accent"]))
                
                # Draw line to center
                center_pos = (5, 4)
                ax.plot([pos[0], center_pos[0]], [pos[1], center_pos[1]], 
                       color=colors["text"], linewidth=1, linestyle='--')

    async def _generate_teaching_instructions(
        self, 
        concept: str, 
        structure: Dict[str, Any], 
        language: str
    ) -> Dict[str, Any]:
        """
        Generate teaching instructions for using the visual aid
        
        Args:
            concept: Original concept
            structure: Diagram structure
            language: Target language
            
        Returns:
            Teaching instructions and tips
        """
        try:
            instructions_prompt = f"""
            Create teaching instructions for this visual aid:
            
            Concept: {concept}
            Diagram Structure: {structure.get('title', '')}
            Language: {language}
            
            Provide:
            1. How to introduce the diagram to students
            2. Key points to explain while showing the diagram
            3. Interactive questions to ask students
            4. Activities students can do with the diagram
            5. How to assess understanding
            6. Extension activities
            7. Materials needed (if any)
            8. Troubleshooting common student difficulties
            
            Keep instructions practical for rural classroom settings.
            """
            
            response = self.model.generate_content(instructions_prompt)
            
            return {
                "instructions": response.text,
                "concept": concept,
                "language": language,
                "classroom_type": "rural_indian"
            }
            
        except Exception as e:
            self.logger.error(f"Teaching instructions generation failed: {str(e)}")
            return {
                "instructions": f"Use this diagram to explain {concept}. Ask students to identify key elements and explain relationships.",
                "error": str(e)
            }

    def get_capabilities(self) -> Dict[str, Any]:
        """
        Get agent capabilities description
        
        Returns:
            Capabilities dictionary
        """
        return {
            "name": self.name,
            "description": "Generates educational diagrams and visual aids from text descriptions",
            "input_types": ["text"],
            "output_types": ["image", "teaching_instructions"],
            "supported_diagrams": list(self.diagram_types.keys()),
            "image_formats": ["PNG"],
            "max_elements": 10,
            "supported_languages": ["en", "hi", "mr", "ta", "bn", "gu"],
            "classroom_focus": "rural_indian_schools",
            "processing_time": "20-40 seconds per diagram"
        } 