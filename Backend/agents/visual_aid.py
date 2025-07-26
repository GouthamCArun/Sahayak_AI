from typing import Dict, Any, List, Optional
import json
import base64
import io
from PIL import Image, ImageDraw, ImageFont
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np

from .base_agent import BaseAgent
from ..utils.logging import get_logger
import google.generativeai as genai
from ..utils.config import settings

class VisualAidAgent(BaseAgent):
    """
    Visual Aid Agent for generating educational diagrams and visual aids
    
    Converts text prompts into simple, blackboard-friendly diagrams
    and educational illustrations suitable for rural classrooms.
    """
    
    def __init__(self):
        super().__init__("VisualAidAgent")
        self.model = genai.GenerativeModel('gemini-pro')
        
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

    async def process(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate visual aid based on text description
        
        Args:
            request: Contains concept description, diagram type, and preferences
            
        Returns:
            Dict containing generated visual aid and metadata
        """
        try:
            # Extract and validate input
            concept = request.get('concept', '')
            diagram_type = request.get('diagram_type', 'auto')
            language = request.get('language', 'en')
            grade_level = request.get('grade_level', 'grade_3_4')
            subject = request.get('subject', 'general')
            
            if not concept:
                raise ValueError("No concept description provided")
            
            # Auto-detect diagram type if not specified
            if diagram_type == 'auto':
                diagram_type = await self._detect_diagram_type(concept, subject)
            
            # Generate diagram structure
            diagram_structure = await self._generate_diagram_structure(
                concept, diagram_type, language, grade_level, subject
            )
            
            # Create visual representation
            visual_output = await self._create_visual_diagram(
                diagram_structure, diagram_type
            )
            
            # Generate teaching instructions
            teaching_instructions = await self._generate_teaching_instructions(
                concept, diagram_structure, language
            )
            
            return {
                "success": True,
                "concept": concept,
                "diagram_type": diagram_type,
                "visual_output": visual_output,
                "diagram_structure": diagram_structure,
                "teaching_instructions": teaching_instructions,
                "metadata": {
                    "agent": self.name,
                    "processing_time": self.get_processing_time(),
                    "language": language,
                    "grade_level": grade_level,
                    "subject": subject
                }
            }
            
        except Exception as e:
            self.logger.error(f"Visual aid generation failed: {str(e)}")
            return {
                "success": False,
                "error": str(e),
                "agent": self.name
            }

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