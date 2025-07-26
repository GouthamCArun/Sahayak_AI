from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import json

from .base_agent import BaseAgent
from ..utils.logging import get_logger
import google.generativeai as genai
from ..utils.config import settings

class LessonPlannerAgent(BaseAgent):
    """
    Lesson Planner Agent for generating structured weekly lesson plans
    
    Creates comprehensive lesson plans with activities, assessments,
    and resources tailored for rural Indian multi-grade classrooms.
    """
    
    def __init__(self):
        super().__init__("LessonPlannerAgent")
        self.model = genai.GenerativeModel('gemini-pro')
        
        # Curriculum frameworks for different subjects
        self.curriculum_frameworks = {
            "mathematics": {
                "grade_1_2": ["Numbers 1-100", "Basic Addition/Subtraction", "Shapes", "Patterns", "Measurement"],
                "grade_3_4": ["Numbers 1-1000", "Multiplication/Division", "Fractions", "Time", "Money"],
                "grade_5_6": ["Large Numbers", "Decimals", "Geometry", "Data Handling", "Algebra Basics"]
            },
            "science": {
                "grade_1_2": ["Living/Non-living", "Plants", "Animals", "Our Body", "Weather"],
                "grade_3_4": ["Food", "Water", "Air", "Simple Machines", "Earth & Sky"],
                "grade_5_6": ["Human Body", "Environment", "Light & Sound", "Motion", "Materials"]
            },
            "language": {
                "grade_1_2": ["Letters & Sounds", "Simple Words", "Basic Sentences", "Stories", "Rhymes"],
                "grade_3_4": ["Reading Comprehension", "Grammar Basics", "Creative Writing", "Poetry"],
                "grade_5_6": ["Advanced Reading", "Essay Writing", "Literature", "Debates", "Projects"]
            },
            "social_studies": {
                "grade_1_2": ["Family", "School", "Community", "Festivals", "Helpers"],
                "grade_3_4": ["Local Area", "States of India", "History Basics", "Geography", "Culture"],
                "grade_5_6": ["Indian History", "Geography", "Government", "Economics", "World Studies"]
            }
        }
        
        # Activity types for different learning objectives
        self.activity_types = {
            "introduction": ["storytelling", "demonstration", "question_session", "visual_aids"],
            "practice": ["group_work", "individual_exercises", "games", "hands_on_activities"],
            "assessment": ["oral_questions", "written_test", "project_work", "peer_assessment"],
            "reinforcement": ["revision_games", "practice_sheets", "discussion", "reflection"]
        }
        
        # Resources commonly available in rural schools
        self.available_resources = {
            "basic": ["blackboard", "chalk", "notebooks", "pencils", "locally_available_materials"],
            "enhanced": ["charts", "models", "basic_science_kit", "library_books"],
            "digital": ["smartphone", "tablet", "projector", "internet_access"]
        }
        
        # Indian cultural and contextual elements
        self.cultural_context = {
            "festivals": ["Diwali", "Holi", "Eid", "Christmas", "Dussehra", "Regional_festivals"],
            "local_examples": ["farming", "village_life", "local_markets", "traditional_crafts"],
            "languages": ["Hindi", "English", "Regional_languages"],
            "values": ["respect_for_elders", "community_service", "environmental_care"]
        }

    async def process(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate comprehensive lesson plan based on requirements
        
        Args:
            request: Contains subject, grade levels, duration, and preferences
            
        Returns:
            Dict containing structured lesson plan with activities and resources
        """
        try:
            # Extract and validate input
            subject = request.get('subject', 'mathematics')
            grade_levels = request.get('grade_levels', ['grade_3_4'])
            duration = request.get('duration', 'week')  # week, day, month
            topic = request.get('topic', '')
            language = request.get('language', 'en')
            resource_level = request.get('resource_level', 'basic')
            
            # Generate lesson plan structure
            lesson_structure = await self._create_lesson_structure(
                subject, grade_levels, duration, topic, resource_level
            )
            
            # Generate detailed content for each lesson
            detailed_lessons = await self._generate_detailed_lessons(
                lesson_structure, subject, grade_levels, language
            )
            
            # Create assessment strategy
            assessment_plan = await self._create_assessment_plan(
                subject, grade_levels, detailed_lessons
            )
            
            # Generate resource requirements
            resource_plan = await self._create_resource_plan(
                detailed_lessons, resource_level
            )
            
            # Create differentiation strategies
            differentiation_plan = await self._create_differentiation_strategies(
                subject, grade_levels, detailed_lessons
            )
            
            return {
                "success": True,
                "lesson_plan": {
                    "structure": lesson_structure,
                    "detailed_lessons": detailed_lessons,
                    "assessment_plan": assessment_plan,
                    "resource_plan": resource_plan,
                    "differentiation_plan": differentiation_plan
                },
                "metadata": {
                    "agent": self.name,
                    "processing_time": self.get_processing_time(),
                    "subject": subject,
                    "grade_levels": grade_levels,
                    "duration": duration,
                    "language": language
                }
            }
            
        except Exception as e:
            self.logger.error(f"Lesson planning failed: {str(e)}")
            return {
                "success": False,
                "error": str(e),
                "agent": self.name
            }

    async def _create_lesson_structure(
        self, 
        subject: str, 
        grade_levels: List[str], 
        duration: str, 
        topic: str,
        resource_level: str
    ) -> Dict[str, Any]:
        """
        Create high-level lesson plan structure
        
        Args:
            subject: Subject area
            grade_levels: Target grade levels
            duration: Lesson duration (day/week/month)
            topic: Specific topic if provided
            resource_level: Available resources
            
        Returns:
            Structured lesson plan outline
        """
        try:
            # Get curriculum topics for grade levels
            curriculum_topics = []
            for grade in grade_levels:
                topics = self.curriculum_frameworks.get(subject, {}).get(grade, [])
                curriculum_topics.extend(topics)
            
            # Remove duplicates and select relevant topics
            unique_topics = list(set(curriculum_topics))
            
            structure_prompt = f"""
            Create a {duration}ly lesson plan structure for {subject} covering grade levels {grade_levels}.
            
            Available Topics: {unique_topics}
            Specific Topic Request: {topic}
            Resource Level: {resource_level}
            Cultural Context: Rural Indian classroom, multi-grade teaching
            
            Create a structure with:
            1. Learning objectives aligned with curriculum
            2. Daily lesson breakdown (if weekly plan)
            3. Key concepts and skills to develop
            4. Integration opportunities with other subjects
            5. Cultural connections and local examples
            6. Progression from basic to advanced concepts
            
            Format as structured JSON with clear hierarchy.
            """
            
            response = self.model.generate_content(structure_prompt)
            
            # Try to parse JSON response
            try:
                structure = json.loads(response.text)
            except json.JSONDecodeError:
                # Fallback to text-based structure
                structure = self._create_fallback_structure(subject, grade_levels, duration)
            
            # Add metadata
            structure["created_date"] = datetime.now().isoformat()
            structure["duration"] = duration
            structure["subject"] = subject
            structure["grade_levels"] = grade_levels
            
            return structure
            
        except Exception as e:
            self.logger.error(f"Structure creation failed: {str(e)}")
            return self._create_fallback_structure(subject, grade_levels, duration)

    def _create_fallback_structure(
        self, 
        subject: str, 
        grade_levels: List[str], 
        duration: str
    ) -> Dict[str, Any]:
        """
        Create fallback lesson structure when AI generation fails
        
        Args:
            subject: Subject area
            grade_levels: Target grade levels
            duration: Lesson duration
            
        Returns:
            Basic lesson structure
        """
        return {
            "title": f"{subject.title()} - {duration.title()}ly Plan",
            "learning_objectives": [
                f"Understand key concepts in {subject}",
                f"Apply knowledge through practical activities",
                f"Develop problem-solving skills"
            ],
            "daily_lessons": [
                {
                    "day": 1,
                    "topic": "Introduction and Basic Concepts",
                    "activities": ["introduction", "demonstration", "practice"]
                },
                {
                    "day": 2,
                    "topic": "Guided Practice",
                    "activities": ["review", "guided_practice", "group_work"]
                },
                {
                    "day": 3,
                    "topic": "Independent Practice",
                    "activities": ["independent_work", "peer_learning", "assessment"]
                }
            ],
            "key_concepts": [
                "Foundational understanding",
                "Practical application",
                "Problem solving"
            ]
        }

    async def _generate_detailed_lessons(
        self, 
        structure: Dict[str, Any], 
        subject: str, 
        grade_levels: List[str], 
        language: str
    ) -> List[Dict[str, Any]]:
        """
        Generate detailed lesson plans for each session
        
        Args:
            structure: High-level lesson structure
            subject: Subject area
            grade_levels: Target grade levels
            language: Instruction language
            
        Returns:
            List of detailed lesson plans
        """
        try:
            detailed_lessons = []
            daily_lessons = structure.get("daily_lessons", [])
            
            for lesson_outline in daily_lessons:
                lesson_prompt = f"""
                Create a detailed lesson plan for this session:
                
                Subject: {subject}
                Grade Levels: {grade_levels}
                Language: {language}
                Topic: {lesson_outline.get('topic', 'General')}
                Day: {lesson_outline.get('day', 1)}
                
                Include:
                1. Lesson Objectives (3-4 specific, measurable goals)
                2. Materials Needed (locally available items)
                3. Lesson Structure:
                   - Introduction (5-10 minutes)
                   - Main Activity (20-30 minutes)
                   - Practice/Application (10-15 minutes)
                   - Closure/Assessment (5-10 minutes)
                4. Differentiation for different grade levels
                5. Assessment methods
                6. Homework/Extension activities
                7. Cultural connections and local examples
                
                Focus on practical, engaging activities suitable for rural Indian classrooms.
                """
                
                response = self.model.generate_content(lesson_prompt)
                
                detailed_lesson = {
                    "day": lesson_outline.get("day", len(detailed_lessons) + 1),
                    "topic": lesson_outline.get("topic", "Lesson Topic"),
                    "duration": "45-60 minutes",
                    "content": response.text,
                    "objectives": self._extract_objectives(response.text),
                    "activities": lesson_outline.get("activities", []),
                    "materials": self._extract_materials(response.text),
                    "assessment": self._extract_assessment(response.text)
                }
                
                detailed_lessons.append(detailed_lesson)
            
            return detailed_lessons
            
        except Exception as e:
            self.logger.error(f"Detailed lesson generation failed: {str(e)}")
            return self._create_fallback_lessons(structure, subject)

    def _create_fallback_lessons(
        self, 
        structure: Dict[str, Any], 
        subject: str
    ) -> List[Dict[str, Any]]:
        """Create fallback lessons when AI generation fails"""
        fallback_lessons = []
        daily_lessons = structure.get("daily_lessons", [{"day": 1, "topic": "Introduction"}])
        
        for lesson in daily_lessons:
            fallback_lessons.append({
                "day": lesson.get("day", 1),
                "topic": lesson.get("topic", f"{subject} Lesson"),
                "duration": "45-60 minutes",
                "content": f"Lesson on {lesson.get('topic', subject)}. Include introduction, main activity, practice, and assessment.",
                "objectives": [f"Learn about {lesson.get('topic', subject)}"],
                "activities": ["introduction", "main_activity", "practice", "assessment"],
                "materials": ["blackboard", "chalk", "notebooks"],
                "assessment": "Oral questions and observation"
            })
        
        return fallback_lessons

    def _extract_objectives(self, lesson_content: str) -> List[str]:
        """Extract learning objectives from lesson content"""
        try:
            # Simple extraction based on common patterns
            lines = lesson_content.split('\n')
            objectives = []
            
            in_objectives = False
            for line in lines:
                line = line.strip()
                if 'objective' in line.lower() or 'goal' in line.lower():
                    in_objectives = True
                    continue
                
                if in_objectives and line and (line.startswith('-') or line.startswith('•') or line.startswith('1.')):
                    objective = line.lstrip('-•1234567890. ').strip()
                    if objective:
                        objectives.append(objective)
                
                if in_objectives and line and not line.startswith('-') and not line.startswith('•') and not line[0].isdigit():
                    in_objectives = False
            
            return objectives[:4] if objectives else [f"Complete the lesson successfully"]
            
        except Exception:
            return ["Learn new concepts", "Practice skills", "Apply knowledge"]

    def _extract_materials(self, lesson_content: str) -> List[str]:
        """Extract required materials from lesson content"""
        try:
            # Extract materials mentioned in the content
            common_materials = ["blackboard", "chalk", "notebooks", "pencils", "paper", "charts"]
            mentioned_materials = []
            
            content_lower = lesson_content.lower()
            for material in common_materials:
                if material in content_lower:
                    mentioned_materials.append(material)
            
            return mentioned_materials if mentioned_materials else ["blackboard", "chalk", "notebooks"]
            
        except Exception:
            return ["blackboard", "chalk", "notebooks"]

    def _extract_assessment(self, lesson_content: str) -> str:
        """Extract assessment method from lesson content"""
        try:
            if 'assessment' in lesson_content.lower():
                # Find assessment section
                lines = lesson_content.split('\n')
                for i, line in enumerate(lines):
                    if 'assessment' in line.lower():
                        # Get next few lines
                        assessment_lines = lines[i:i+3]
                        return ' '.join(assessment_lines).strip()
            
            return "Oral questions and observation of student participation"
            
        except Exception:
            return "Teacher observation and informal assessment"

    async def _create_assessment_plan(
        self, 
        subject: str, 
        grade_levels: List[str], 
        lessons: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Create comprehensive assessment strategy
        
        Args:
            subject: Subject area
            grade_levels: Target grade levels
            lessons: Detailed lesson plans
            
        Returns:
            Assessment plan with multiple evaluation methods
        """
        try:
            assessment_prompt = f"""
            Create a comprehensive assessment plan for {subject} across grade levels {grade_levels}.
            
            Lessons covered: {[lesson['topic'] for lesson in lessons]}
            
            Include:
            1. Formative Assessment (daily/ongoing)
            2. Summative Assessment (end of week/unit)
            3. Differentiated assessment for different grades
            4. Practical assessment methods for rural classrooms
            5. Rubrics for evaluation
            6. Student self-assessment opportunities
            7. Portfolio/project-based assessment
            
            Focus on authentic assessment that doesn't require expensive resources.
            """
            
            response = self.model.generate_content(assessment_prompt)
            
            return {
                "formative_assessment": self._extract_formative_methods(response.text),
                "summative_assessment": self._extract_summative_methods(response.text),
                "rubrics": self._create_simple_rubrics(subject),
                "differentiation": self._create_assessment_differentiation(grade_levels),
                "timeline": self._create_assessment_timeline(lessons),
                "detailed_plan": response.text
            }
            
        except Exception as e:
            self.logger.error(f"Assessment plan creation failed: {str(e)}")
            return self._create_fallback_assessment_plan(subject, grade_levels)

    def _extract_formative_methods(self, content: str) -> List[str]:
        """Extract formative assessment methods"""
        methods = [
            "Observation during activities",
            "Oral questioning",
            "Exit tickets",
            "Peer discussion",
            "Quick sketches or diagrams"
        ]
        return methods

    def _extract_summative_methods(self, content: str) -> List[str]:
        """Extract summative assessment methods"""
        methods = [
            "End-of-week quiz",
            "Project presentation",
            "Practical demonstration",
            "Portfolio review",
            "Group presentation"
        ]
        return methods

    def _create_simple_rubrics(self, subject: str) -> Dict[str, Any]:
        """Create simple rubrics for evaluation"""
        return {
            "understanding": {
                "excellent": "Complete understanding, can explain to others",
                "good": "Good understanding, minor gaps",
                "developing": "Basic understanding, needs support",
                "beginning": "Limited understanding, requires help"
            },
            "participation": {
                "excellent": "Active participant, helps others",
                "good": "Regular participation",
                "developing": "Some participation with encouragement",
                "beginning": "Minimal participation"
            },
            "application": {
                "excellent": "Applies knowledge in new situations",
                "good": "Applies knowledge in similar situations",
                "developing": "Applies knowledge with guidance",
                "beginning": "Struggles to apply knowledge"
            }
        }

    def _create_assessment_differentiation(self, grade_levels: List[str]) -> Dict[str, Any]:
        """Create differentiated assessment for different grades"""
        differentiation = {}
        
        for grade in grade_levels:
            if "1" in grade or "2" in grade:
                differentiation[grade] = {
                    "methods": ["oral_assessment", "drawing", "simple_demonstrations"],
                    "complexity": "basic",
                    "support": "high"
                }
            elif "3" in grade or "4" in grade:
                differentiation[grade] = {
                    "methods": ["written_tasks", "projects", "presentations"],
                    "complexity": "intermediate", 
                    "support": "moderate"
                }
            else:
                differentiation[grade] = {
                    "methods": ["essays", "research", "independent_projects"],
                    "complexity": "advanced",
                    "support": "minimal"
                }
        
        return differentiation

    def _create_assessment_timeline(self, lessons: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Create assessment timeline"""
        timeline = []
        
        for i, lesson in enumerate(lessons):
            timeline.append({
                "day": lesson.get("day", i + 1),
                "formative": "Ongoing observation and questioning",
                "summative": "End-of-lesson check" if i == len(lessons) - 1 else "None"
            })
        
        return timeline

    def _create_fallback_assessment_plan(self, subject: str, grade_levels: List[str]) -> Dict[str, Any]:
        """Fallback assessment plan"""
        return {
            "formative_assessment": ["Observation", "Oral questions", "Peer discussion"],
            "summative_assessment": ["Weekly quiz", "Project work"],
            "rubrics": self._create_simple_rubrics(subject),
            "differentiation": self._create_assessment_differentiation(grade_levels),
            "detailed_plan": f"Regular assessment through observation, questioning, and practical activities for {subject}."
        }

    async def _create_resource_plan(
        self, 
        lessons: List[Dict[str, Any]], 
        resource_level: str
    ) -> Dict[str, Any]:
        """
        Create resource requirements and alternatives
        
        Args:
            lessons: Detailed lesson plans
            resource_level: Available resource level
            
        Returns:
            Resource plan with alternatives and procurement suggestions
        """
        try:
            # Collect all materials mentioned in lessons
            all_materials = set()
            for lesson in lessons:
                all_materials.update(lesson.get("materials", []))
            
            available_resources = self.available_resources.get(resource_level, self.available_resources["basic"])
            
            resource_prompt = f"""
            Create a resource plan for these lessons requiring: {list(all_materials)}
            Available resource level: {resource_level}
            Available resources: {available_resources}
            
            Provide:
            1. Essential resources (must-have)
            2. Optional resources (nice-to-have)
            3. Locally available alternatives
            4. DIY/homemade alternatives
            5. Digital alternatives (if applicable)
            6. Cost-effective procurement suggestions
            7. Community resource sharing ideas
            
            Focus on practical, low-cost solutions for rural schools.
            """
            
            response = self.model.generate_content(resource_prompt)
            
            return {
                "essential_resources": list(all_materials)[:5],
                "optional_resources": list(all_materials)[5:],
                "local_alternatives": self._suggest_local_alternatives(all_materials),
                "diy_alternatives": self._suggest_diy_alternatives(all_materials),
                "procurement_plan": response.text,
                "total_estimated_cost": "Minimal - mostly free/locally available"
            }
            
        except Exception as e:
            self.logger.error(f"Resource plan creation failed: {str(e)}")
            return self._create_fallback_resource_plan(lessons)

    def _suggest_local_alternatives(self, materials: set) -> Dict[str, str]:
        """Suggest locally available alternatives"""
        alternatives = {
            "charts": "Large cardboard pieces or cloth",
            "models": "Clay or mud models",
            "measuring_tools": "Locally available containers",
            "manipulatives": "Stones, seeds, or sticks",
            "art_supplies": "Natural colors from flowers/earth"
        }
        
        relevant_alternatives = {}
        for material in materials:
            for key, value in alternatives.items():
                if key in material.lower():
                    relevant_alternatives[material] = value
        
        return relevant_alternatives

    def _suggest_diy_alternatives(self, materials: set) -> Dict[str, str]:
        """Suggest DIY alternatives"""
        diy_options = {
            "flashcards": "Cut cardboard pieces",
            "number_cards": "Paper with handwritten numbers",
            "geometric_shapes": "Cut from cardboard",
            "measuring_tape": "String with marks",
            "balance": "Stick with containers on ends"
        }
        
        relevant_diy = {}
        for material in materials:
            for key, value in diy_options.items():
                if key in material.lower():
                    relevant_diy[material] = value
        
        return relevant_diy

    def _create_fallback_resource_plan(self, lessons: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Fallback resource plan"""
        return {
            "essential_resources": ["blackboard", "chalk", "notebooks", "pencils"],
            "optional_resources": ["charts", "models", "measuring_tools"],
            "local_alternatives": {"charts": "cardboard", "models": "clay"},
            "diy_alternatives": {"flashcards": "cut_paper"},
            "procurement_plan": "Focus on locally available and reusable materials",
            "total_estimated_cost": "Minimal cost - under ₹500"
        }

    async def _create_differentiation_strategies(
        self, 
        subject: str, 
        grade_levels: List[str], 
        lessons: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Create differentiation strategies for multi-grade classroom
        
        Args:
            subject: Subject area
            grade_levels: Target grade levels
            lessons: Detailed lesson plans
            
        Returns:
            Differentiation strategies for various learning needs
        """
        try:
            differentiation_prompt = f"""
            Create differentiation strategies for a multi-grade {subject} classroom with grades {grade_levels}.
            
            Lessons: {[lesson['topic'] for lesson in lessons]}
            
            Provide strategies for:
            1. Different grade levels (content differentiation)
            2. Different learning styles (visual, auditory, kinesthetic)
            3. Different ability levels within same grade
            4. Language barriers (for non-native speakers)
            5. Special needs accommodation
            6. Gifted and advanced learners
            7. Struggling learners
            
            Include practical classroom management tips for handling multiple groups.
            """
            
            response = self.model.generate_content(differentiation_prompt)
            
            return {
                "by_grade_level": self._create_grade_differentiation(grade_levels),
                "by_learning_style": self._create_learning_style_differentiation(),
                "by_ability_level": self._create_ability_differentiation(),
                "classroom_management": self._create_management_strategies(),
                "detailed_strategies": response.text
            }
            
        except Exception as e:
            self.logger.error(f"Differentiation strategy creation failed: {str(e)}")
            return self._create_fallback_differentiation(grade_levels)

    def _create_grade_differentiation(self, grade_levels: List[str]) -> Dict[str, Any]:
        """Create grade-level differentiation"""
        differentiation = {}
        
        for grade in grade_levels:
            if "1" in grade or "2" in grade:
                differentiation[grade] = {
                    "content": "Concrete examples, manipulatives, visual aids",
                    "process": "Guided practice, peer support",
                    "product": "Drawings, oral responses, simple demonstrations"
                }
            elif "3" in grade or "4" in grade:
                differentiation[grade] = {
                    "content": "Semi-concrete examples, some abstract concepts",
                    "process": "Independent work with support",
                    "product": "Written work, simple projects"
                }
            else:
                differentiation[grade] = {
                    "content": "Abstract concepts, complex problems",
                    "process": "Independent research, leadership roles",
                    "product": "Essays, presentations, complex projects"
                }
        
        return differentiation

    def _create_learning_style_differentiation(self) -> Dict[str, List[str]]:
        """Create learning style differentiation"""
        return {
            "visual": ["charts", "diagrams", "color_coding", "mind_maps", "demonstrations"],
            "auditory": ["discussions", "explanations", "songs", "rhymes", "storytelling"],
            "kinesthetic": ["hands_on_activities", "movement", "manipulatives", "role_play", "experiments"]
        }

    def _create_ability_differentiation(self) -> Dict[str, Dict[str, str]]:
        """Create ability level differentiation"""
        return {
            "advanced": {
                "strategy": "Extension activities, leadership roles, mentoring",
                "support": "Independent exploration, research projects"
            },
            "on_level": {
                "strategy": "Standard curriculum with some enrichment",
                "support": "Peer collaboration, choice in activities"
            },
            "struggling": {
                "strategy": "Simplified tasks, extra practice, scaffolding",
                "support": "One-on-one help, visual aids, step-by-step guides"
            }
        }

    def _create_management_strategies(self) -> List[str]:
        """Create classroom management strategies"""
        return [
            "Use station rotation for different grade levels",
            "Pair older students with younger ones",
            "Create independent work packets for each grade",
            "Use visual schedules and clear expectations",
            "Implement peer tutoring systems",
            "Design multilevel activities that scale up/down"
        ]

    def _create_fallback_differentiation(self, grade_levels: List[str]) -> Dict[str, Any]:
        """Fallback differentiation strategies"""
        return {
            "by_grade_level": self._create_grade_differentiation(grade_levels),
            "by_learning_style": self._create_learning_style_differentiation(),
            "by_ability_level": self._create_ability_differentiation(),
            "classroom_management": self._create_management_strategies(),
            "detailed_strategies": "Adapt content, process, and products based on student needs and grade levels."
        }

    def get_capabilities(self) -> Dict[str, Any]:
        """
        Get agent capabilities description
        
        Returns:
            Capabilities dictionary
        """
        return {
            "name": self.name,
            "description": "Generates comprehensive lesson plans for multi-grade rural classrooms",
            "input_types": ["subject", "grade_levels", "topic", "duration"],
            "output_types": ["lesson_plan", "assessment_plan", "resource_plan", "differentiation_strategies"],
            "supported_subjects": list(self.curriculum_frameworks.keys()),
            "supported_grades": ["grade_1", "grade_2", "grade_3", "grade_4", "grade_5", "grade_6"],
            "plan_durations": ["day", "week", "month"],
            "resource_levels": ["basic", "enhanced", "digital"],
            "features": ["multi_grade_support", "cultural_adaptation", "low_resource_optimization"],
            "processing_time": "60-120 seconds per plan"
        } 