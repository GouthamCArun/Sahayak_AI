"""
Simple Flask app for content generation - bypasses FastAPI Pydantic issues
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import asyncio
import sys
import os

# Add backend directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from agents.content_generator import ContentGeneratorAgent
from agents.visual_aid import VisualAidAgent
from utils.logging import get_logger

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for frontend

# Initialize logger and agents
logger = get_logger(__name__)
content_generator = ContentGeneratorAgent()
visual_aid = VisualAidAgent()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "Sahaayak AI Flask Backend"})

@app.route('/api/v1/generate', methods=['POST'])
def generate_content():
    """Generate educational content using Gemini API"""
    try:
        # Get JSON data from request - force JSON parsing
        data = request.get_json(force=True)
        
        if not data:
            # Try to parse manually if get_json fails
            try:
                import json
                data = json.loads(request.data.decode('utf-8'))
            except:
                return jsonify({"error": "No valid JSON data provided"}), 400
        
        logger.info(f"Flask received: {data}")
        
        # Extract fields
        content_type = data.get("content_type", "story")
        topic = data.get("topic", "")
        language = data.get("language", "en")
        grade_level = data.get("grade_level", "grade_3_4")
        
        if not topic:
            return jsonify({"error": "Topic is required"}), 400
        
        # Prepare request for content generator
        content_request = {
            "content_type": content_type,
            "topic": topic,
            "language": language,
            "grade_level": grade_level,
            "additional_details": ""
        }
        
        logger.info(f"Generating {content_type} about '{topic}' for {grade_level}")
        
        # Call ContentGenerator (handle async)
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            result = loop.run_until_complete(
                content_generator.execute_with_monitoring(content_request)
            )
        finally:
            loop.close()
        
        logger.info(f"Content generated successfully!")
        logger.info(f"Raw result type: {type(result)}")
        logger.info(f"Raw result keys: {list(result.keys()) if isinstance(result, dict) else 'Not a dict'}")
        
        if isinstance(result, dict) and 'content' in result:
            preview = str(result['content'])[:100] + "..." if len(str(result['content'])) > 100 else str(result['content'])
            logger.info(f"Preview: {preview}")
        
        # Print full response for debugging
        logger.info(f"=== FULL RESPONSE ===")
        logger.info(f"Response: {result}")
        logger.info(f"=== END RESPONSE ===")
        
        # Debug: Log the exact result structure
        logger.info(f"Full result structure: {result}")
        
        # Format response for Flutter frontend compatibility
        # Handle both direct content and nested data.content structure
        content_text = None
        metadata = {}
        suggestions = []
        
        if isinstance(result, dict):
            if 'content' in result:
                # Direct content structure
                content_text = result['content']
                metadata = result.get('metadata', {})
                suggestions = result.get('suggestions', [])
            elif 'data' in result and isinstance(result['data'], dict) and 'content' in result['data']:
                # Nested data.content structure (from ContentGenerator)
                content_text = result['data']['content'] 
                metadata = result['data'].get('metadata', {})
                suggestions = result['data'].get('suggestions', [])
            elif result.get('success') is True and 'data' in result:
                # Handle success response with nested data
                data = result['data']
                content_text = data.get('content', '')
                metadata = data.get('metadata', {})
                suggestions = data.get('suggestions', [])
        
        if content_text:
            frontend_response = {
                "generated_text": content_text,  # Flutter expects this field
                "content": content_text,         # Fallback field
                "title": f"Educational {content_type.title()} about {topic.title()}",
                "topic": topic,
                "content_type": content_type,
                "language": language,
                "grade_level": grade_level,
                **metadata,                      # Include metadata at top level
                "suggestions": suggestions
            }
            logger.info(f"Sending to frontend: {list(frontend_response.keys())}")
            logger.info(f"Frontend response generated_text length: {len(frontend_response.get('generated_text', ''))}")
            return jsonify(frontend_response)
        
        # If content is not found, log the issue and return a debug response
        logger.error(f"Content not found in result! Result: {result}")
        debug_response = {
            "generated_text": "DEBUG: Content generation succeeded but response format is unexpected. Check backend logs.",
            "content": "DEBUG: Content generation succeeded but response format is unexpected. Check backend logs.",
            "debug_info": result,
            "topic": topic,
            "content_type": content_type
        }
        return jsonify(debug_response)
        
    except Exception as e:
        logger.error(f"Content generation failed: {str(e)}")
        return jsonify({"error": f"Generation failed: {str(e)}"}), 500

@app.route('/api/v1/query', methods=['POST'])
def query_endpoint():
    """Handle both content generation and question answering requests"""
    try:
        # Get JSON data from request
        data = request.get_json(force=True)
        
        if not data:
            try:
                import json
                data = json.loads(request.data.decode('utf-8'))
            except:
                return jsonify({"error": "No valid JSON data provided"}), 400
        
        logger.info(f"Flask received query request: {data}")
        
        # Extract request type
        request_type = data.get("type", "question_answering")
        
        if request_type == "content_generation":
            # Handle content generation (existing logic)
            return generate_content()
        elif request_type == "question_answering":
            # Handle question answering
            text = data.get("text", "")
            language = data.get("language", "en")
            context = data.get("context", {})
            
            if not text:
                return jsonify({"error": "Text is required for question answering"}), 400
            
            # Prepare request for content generator as a general explanation
            question_request = {
                "content_type": "explanation",
                "topic": text,  # Use the question as the topic
                "language": language,
                "grade_level": "grade_3_4",  # Default grade level
                "additional_details": f"Context: {context.get('user_role', 'teacher')} in {context.get('context_type', 'classroom')}"
            }
            
            logger.info(f"Generating answer for question: '{text}'")
            
            # Call ContentGenerator (handle async)
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            try:
                result = loop.run_until_complete(
                    content_generator.execute_with_monitoring(question_request)
                )
            finally:
                loop.close()
            
            logger.info(f"Question answered successfully!")
            
            # Format response for chat
            if isinstance(result, dict) and 'content' in result:
                response_text = result['content']
            elif isinstance(result, dict) and 'data' in result and 'content' in result['data']:
                response_text = result['data']['content']
            else:
                response_text = "I apologize, but I couldn't generate a proper response."
            
            frontend_response = {
                "response": response_text,
                "generated_text": response_text,  # Fallback field
                "type": "question_answering",
                "language": language,
                "metadata": {
                    "model_used": "gemini-1.5-flash",
                    "processing_time": result.get('metadata', {}).get('processing_time', 'unknown'),
                    "confidence": 0.8
                }
            }
            
            logger.info(f"Sending answer to frontend: {list(frontend_response.keys())}")
            return jsonify(frontend_response)
        else:
            return jsonify({"error": f"Unsupported request type: {request_type}"}), 400
            
    except Exception as e:
        logger.error(f"Query processing failed: {str(e)}")
        return jsonify({"error": f"Query processing failed: {str(e)}"}), 500

@app.route('/api/v1/generate-quiz', methods=['POST'])
def generate_quiz():
    """Generate educational quiz with 10 questions and answers"""
    try:
        # Get JSON data from request
        data = request.get_json(force=True)
        
        if not data:
            try:
                import json
                data = json.loads(request.data.decode('utf-8'))
            except:
                return jsonify({"error": "No valid JSON data provided"}), 400
        
        logger.info(f"Flask received quiz request: {data}")
        
        # Extract fields
        topic = data.get("topic", "")
        language = data.get("language", "en")
        grade_level = data.get("grade_level", "grade_3_4")
        num_questions = data.get("num_questions", 10)
        
        if not topic:
            return jsonify({"error": "Topic is required"}), 400
        
        # Prepare request for content generator
        quiz_request = {
            "content_type": "quiz",
            "topic": topic,
            "language": language,
            "grade_level": grade_level,
            "num_questions": num_questions
        }
        
        logger.info(f"Generating quiz about '{topic}' for {grade_level}")
        
        # Call ContentGenerator (handle async)
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            result = loop.run_until_complete(
                content_generator.execute_with_monitoring(quiz_request)
            )
        finally:
            loop.close()
        
        logger.info(f"Quiz generated successfully!")
        
        # Print full response for debugging
        logger.info(f"=== QUIZ RESPONSE ===")
        logger.info(f"Quiz Response: {result}")
        logger.info(f"=== END QUIZ RESPONSE ===")
        
        # Parse the quiz content (should be JSON)
        try:
            import json
            import re
            
            content = result.get('content', '{}')
            
            # Try to clean the content first
            if isinstance(content, str):
                # Remove extra whitespace and normalize
                content = re.sub(r'\s+', ' ', content.strip())
                # Remove trailing commas
                content = re.sub(r',\s*}', '}', content)
                content = re.sub(r',\s*]', ']', content)
            
            quiz_data = json.loads(content)
            
            frontend_response = {
                "quiz_data": quiz_data,
                "topic": topic,
                "language": language,
                "grade_level": grade_level,
                "num_questions": num_questions,
                "title": f"Quiz: {topic.title()}",
                "model_used": "gemini-1.5-flash",
                "generation_method": "AI-generated educational quiz"
            }
            
            # Also include the raw data for debugging
            frontend_response["data"] = result
            
            logger.info(f"Sending quiz to frontend: {list(frontend_response.keys())}")
            return jsonify(frontend_response)
            
        except json.JSONDecodeError as e:
            logger.error(f"JSON parsing failed: {str(e)}")
            logger.error(f"Raw content: {result.get('content', '')}")
            
            # If JSON parsing fails, return as text
            frontend_response = {
                "quiz_text": result.get('content', ''),
                "topic": topic,
                "language": language,
                "grade_level": grade_level,
                "num_questions": num_questions,
                "title": f"Quiz: {topic.title()}",
                "model_used": "gemini-1.5-flash",
                "generation_method": "AI-generated educational quiz",
                "parse_error": str(e)
            }
            return jsonify(frontend_response)
        
    except Exception as e:
        logger.error(f"Quiz generation failed: {str(e)}")
        return jsonify({"error": f"Quiz generation failed: {str(e)}"}), 500

@app.route('/api/v1/worksheet-maker', methods=['POST'])
def generate_worksheet():
    """Generate educational worksheet from topic"""
    try:
        # Get JSON data from request
        data = request.get_json(force=True)
        
        if not data:
            try:
                import json
                data = json.loads(request.data.decode('utf-8'))
            except:
                return jsonify({"error": "No valid JSON data provided"}), 400
        
        logger.info(f"Flask received worksheet request: {data}")
        
        # Extract fields
        topic = data.get("topic", "")
        language = data.get("language", "en")
        grade_level = data.get("grade_level", "grade_3_4")
        subject = data.get("subject", "general")
        worksheet_type = data.get("worksheet_type", "mixed")
        
        if not topic:
            return jsonify({"error": "Topic is required"}), 400
        
        # Prepare request for content generator
        worksheet_request = {
            "content_type": "worksheet",
            "topic": topic,
            "language": language,
            "grade_level": grade_level,
            "subject": subject,
            "worksheet_type": worksheet_type
        }
        
        logger.info(f"Generating worksheet about '{topic}' for {grade_level}")
        
        # Call ContentGenerator (handle async)
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            result = loop.run_until_complete(
                content_generator.execute_with_monitoring(worksheet_request)
            )
        finally:
            loop.close()
        
        logger.info(f"Worksheet generated successfully!")
        
        # Print full response for debugging
        logger.info(f"=== WORKSHEET RESPONSE ===")
        logger.info(f"Worksheet Response: {result}")
        logger.info(f"=== END WORKSHEET RESPONSE ===")
        
        # Format response for frontend
        frontend_response = {
            "worksheet_content": result.get('content', ''),
            "topic": topic,
            "language": language,
            "grade_level": grade_level,
            "subject": subject,
            "worksheet_type": worksheet_type,
            "title": f"Worksheet: {topic.title()}",
            "model_used": "gemini-1.5-flash",
            "generation_method": "AI-generated educational worksheet",
            "metadata": result.get('metadata', {}),
            "suggestions": result.get('suggestions', [])
        }
        
        logger.info(f"Sending worksheet to frontend: {list(frontend_response.keys())}")
        return jsonify(frontend_response)
        
    except Exception as e:
        logger.error(f"Worksheet generation failed: {str(e)}")
        return jsonify({"error": f"Worksheet generation failed: {str(e)}"}), 500

@app.route('/api/v1/worksheet-adapter', methods=['POST'])
def adapt_worksheet():
    """Generate worksheet from image using MaterialAdapter"""
    try:
        # Get JSON data from request
        data = request.get_json(force=True)
        
        if not data:
            try:
                data = json.loads(request.data.decode('utf-8'))
            except:
                return jsonify({"error": "No valid JSON data provided"}), 400
        
        logger.info(f"Worksheet adapter request received: {list(data.keys())}")
        
        # Extract fields
        image = data.get("image", "")
        target_grades = data.get("target_grades", ["grade_3_4"])
        language = data.get("language", "en")
        subject = data.get("subject", "general")
        
        if not image:
            return jsonify({"error": "Image data is required"}), 400
        
        # Validate image size (limit to 10MB)
        if len(image) > 10 * 1024 * 1024:  # 10MB limit
            return jsonify({"error": "Image too large. Please use an image smaller than 10MB"}), 400
        
        # Validate image format
        if not image.startswith('data:image/'):
            return jsonify({"error": "Invalid image format. Please provide a valid base64 image"}), 400
        
        # Import MaterialAdapter
        try:
            from agents.material_adapter import MaterialAdapterAgent
            material_adapter = MaterialAdapterAgent()
        except ImportError as e:
            logger.error(f"Failed to import MaterialAdapterAgent: {str(e)}")
            return jsonify({"error": "Material adapter not available"}), 500
        except Exception as e:
            logger.error(f"Failed to initialize MaterialAdapterAgent: {str(e)}")
            return jsonify({"error": "Failed to initialize material adapter"}), 500
        
        # Prepare request for material adapter
        adapter_request = {
            "image": image,
            "target_grades": target_grades,
            "language": language,
            "subject": subject
        }
        
        logger.info(f"Adapting worksheet from image for {target_grades} in {language}")
        
        # Call MaterialAdapter (handle async)
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            result = loop.run_until_complete(
                material_adapter.execute_with_monitoring(adapter_request)
            )
        except Exception as e:
            logger.error(f"MaterialAdapter execution failed: {str(e)}")
            return jsonify({"error": f"Worksheet adaptation failed: {str(e)}"}), 500
        finally:
            loop.close()
        
        logger.info(f"Worksheet adaptation completed successfully!")
        logger.info(f"Raw result type: {type(result)}")
        logger.info(f"Raw result keys: {list(result.keys()) if isinstance(result, dict) else 'Not a dict'}")
        
        # Print full response for debugging
        logger.info(f"=== WORKSHEET ADAPTER RESPONSE ===")
        logger.info(f"Worksheet Adapter Response: {result}")
        logger.info(f"=== END WORKSHEET ADAPTER RESPONSE ===")
        
        # Format response for Flutter frontend compatibility
        content_text = None
        metadata = {}
        
        if isinstance(result, dict):
            if 'content' in result:
                # Direct structure
                content_text = result['content']
                metadata = result.get('metadata', {})
            elif 'data' in result and isinstance(result['data'], dict):
                # Nested data structure
                data_content = result['data']
                content_text = data_content.get('content', '')
                metadata = data_content.get('metadata', {})
            elif result.get('success') is True and 'data' in result:
                # Handle success response with nested data
                data_content = result['data']
                content_text = data_content.get('content', '')
                metadata = data_content.get('metadata', {})
        
        # Extract the actual worksheet data from the result
        worksheet_data = {}
        if isinstance(result, dict) and 'data' in result:
            data_content = result['data']
            if isinstance(data_content, dict):
                # Get the first worksheet content from the worksheets map
                worksheets = data_content.get('worksheets', {})
                first_worksheet_content = ""
                if worksheets and isinstance(worksheets, dict):
                    # Get the first grade level's content
                    first_grade = next(iter(worksheets.values()), {})
                    if isinstance(first_grade, dict):
                        first_worksheet_content = first_grade.get('content', '')
                
                worksheet_data = {
                    "worksheets": data_content.get('worksheets', {}),
                    "extracted_content": data_content.get('extracted_content', {}),
                    "teaching_suggestions": data_content.get('teaching_suggestions', {}),
                    "content": first_worksheet_content or content_text,
                    "target_grades": target_grades,
                    "language": language,
                    "subject": subject,
                    **metadata
                }
        
        if worksheet_data.get('content') or worksheet_data.get('worksheets'):
            
            frontend_response = {
                "worksheet_data": worksheet_data,
                "metadata": {
                    "processing_time": "AI-generated",
                    "model_used": "gemini-1.5-flash",
                    "generation_method": "Image-based worksheet adaptation"
                }
            }
            logger.info(f"Sending worksheet adapter to frontend: {list(frontend_response.keys())}")
            return jsonify(frontend_response)
        
        # If content is not found, log the issue and return a debug response
        logger.error(f"Worksheet adapter content not found in result! Result: {result}")
        debug_response = {
            "worksheet_data": {
                "worksheets": {},
                "extracted_content": {},
                "teaching_suggestions": {},
                "content": "DEBUG: Worksheet adaptation succeeded but response format is unexpected. Check backend logs.",
                "target_grades": target_grades,
                "language": language,
                "subject": subject,
                "debug_info": result
            },
            "metadata": {
                "processing_time": "Error",
                "model_used": "debug",
                "generation_method": "Error handling"
            }
        }
        return jsonify(debug_response)
        
    except Exception as e:
        logger.error(f"Worksheet adaptation failed: {str(e)}")
        return jsonify({"error": f"Worksheet adaptation failed: {str(e)}"}), 500

@app.route('/api/v1/visual-aids', methods=['POST'])
def generate_visual_aid():
    """Generate visual aids/diagrams using Gemini API"""
    try:
        # Get JSON data from request - force JSON parsing
        data = request.get_json(force=True)
        
        if not data:
            # Try to parse manually if get_json fails
            try:
                import json
                data = json.loads(request.data.decode('utf-8'))
            except:
                return jsonify({"error": "No valid JSON data provided"}), 400
        
        logger.info(f"Flask received visual aid request: {data}")
        
        # Extract fields
        concept = data.get("concept", "")
        diagram_type = data.get("diagram_type", "simple")
        language = data.get("language", "en")
        grade_level = data.get("grade_level", "grade_3_4")
        
        if not concept:
            return jsonify({"error": "Concept is required"}), 400
        
        # Prepare request for visual aid agent
        visual_request = {
            "concept": concept,
            "diagram_type": diagram_type,
            "language": language,
            "grade_level": grade_level,
            "style": "blackboard_simple"
        }
        
        logger.info(f"Generating {diagram_type} diagram for '{concept}' in {language}")
        
        # Call VisualAid agent (handle async)
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            result = loop.run_until_complete(
                visual_aid.execute_with_monitoring(visual_request)
            )
        finally:
            loop.close()
        
        logger.info(f"Visual aid generated successfully!")
        logger.info(f"Raw result type: {type(result)}")
        logger.info(f"Raw result keys: {list(result.keys()) if isinstance(result, dict) else 'Not a dict'}")
        
        # Print full response for debugging
        logger.info(f"=== VISUAL AID RESPONSE ===")
        logger.info(f"Visual Aid Response: {result}")
        logger.info(f"=== END VISUAL AID RESPONSE ===")
        
        # Format response for Flutter frontend compatibility
        # Handle both direct content and nested data.content structure
        diagram_description = None
        image_base64 = None
        mermaid_code = None
        metadata = {}
        instructions = []
        teaching_instructions = []
        key_points = []
        
        if isinstance(result, dict):
            if 'diagram_description' in result:
                # Direct structure
                diagram_description = result['diagram_description']
                image_base64 = result.get('image_base64', '')
                mermaid_code = result.get('mermaid_code', '')
                metadata = result.get('metadata', {})
                instructions = result.get('drawing_instructions', [])
                teaching_instructions = result.get('teaching_instructions', [])
                key_points = result.get('key_points', [])
            elif 'data' in result and isinstance(result['data'], dict):
                # Nested data structure
                data_content = result['data']
                diagram_description = data_content.get('diagram_description', '')
                image_base64 = data_content.get('image_base64', '')
                mermaid_code = data_content.get('mermaid_code', '')
                metadata = data_content.get('metadata', {})
                instructions = data_content.get('drawing_instructions', [])
                teaching_instructions = data_content.get('teaching_instructions', [])
                key_points = data_content.get('key_points', [])
            elif result.get('success') is True and 'data' in result:
                # Handle success response with nested data
                data_content = result['data']
                diagram_description = data_content.get('diagram_description', '')
                image_base64 = data_content.get('image_base64', '')
                mermaid_code = data_content.get('mermaid_code', '')
                metadata = data_content.get('metadata', {})
                instructions = data_content.get('drawing_instructions', [])
                teaching_instructions = data_content.get('teaching_instructions', [])
                key_points = data_content.get('key_points', [])
        
        if diagram_description:
            frontend_response = {
                "diagram_description": diagram_description,
                "image_base64": image_base64,
                "mermaid_code": mermaid_code,
                "image_format": result.get('image_format', 'png'),
                "image_width": result.get('image_width', 800),
                "image_height": result.get('image_height', 600),
                "drawing_instructions": instructions,
                "teaching_instructions": teaching_instructions,
                "key_points": key_points,
                "title": f"{concept.title()} Diagram",
                "concept": concept,
                "diagram_type": diagram_type,
                "language": language,
                "grade_level": grade_level,
                **metadata,
                "style": "blackboard_simple"
            }
            logger.info(f"Sending visual aid to frontend: {list(frontend_response.keys())}")
            logger.info(f"Diagram description length: {len(frontend_response.get('diagram_description', ''))}")
            logger.info(f"Image generated: {len(frontend_response.get('image_base64', ''))} characters")
            logger.info(f"Mermaid code length: {len(frontend_response.get('mermaid_code', ''))} characters")
            logger.info(f"Mermaid code: {frontend_response.get('mermaid_code', '')}")
            return jsonify(frontend_response)
        
        # If content is not found, log the issue and return a debug response
        logger.error(f"Diagram content not found in result! Result: {result}")
        debug_response = {
            "diagram_description": "DEBUG: Visual aid generation succeeded but response format is unexpected. Check backend logs.",
            "image_base64": "",
            "image_format": "png",
            "image_width": 800,
            "image_height": 600,
            "debug_info": result,
            "concept": concept,
            "diagram_type": diagram_type
        }
        return jsonify(debug_response)
        
    except Exception as e:
        logger.error(f"Visual aid generation failed: {str(e)}")
        return jsonify({"error": f"Visual aid generation failed: {str(e)}"}), 500

@app.route('/api/v1/lesson-plan', methods=['POST'])
def generate_lesson_plan():
    """Generate lesson plan using ContentGenerator"""
    try:
        # Get JSON data from request
        data = request.get_json(force=True)
        
        if not data:
            try:
                data = json.loads(request.data.decode('utf-8'))
            except:
                return jsonify({"error": "No valid JSON data provided"}), 400
        
        logger.info(f"Lesson plan request received: {data}")
        
        # Extract fields
        subject = data.get("subject", "")
        grade_levels = data.get("grade_levels", ["grade_3_4"])
        duration = data.get("duration", "week")
        topic = data.get("topic", "")
        language = data.get("language", "en")
        resource_level = data.get("resource_level", "basic")
        
        if not subject:
            return jsonify({"error": "Subject is required"}), 400
        
        # Prepare request for content generator
        content_request = {
            "content_type": "lesson_plan",
            "topic": f"{subject} lesson plan for {duration}",
            "language": language,
            "grade_level": grade_levels[0] if grade_levels else "grade_3_4",
            "additional_details": f"Subject: {subject}, Duration: {duration}, Grade Levels: {', '.join(grade_levels)}, Resource Level: {resource_level}, Specific Topic: {topic}" if topic else ""
        }
        
        logger.info(f"Generating lesson plan for '{subject}' for {duration}")
        
        # Call ContentGenerator (handle async)
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            result = loop.run_until_complete(
                content_generator.execute_with_monitoring(content_request)
            )
        finally:
            loop.close()
        
        logger.info(f"Lesson plan generated successfully!")
        logger.info(f"Raw result type: {type(result)}")
        logger.info(f"Raw result keys: {list(result.keys()) if isinstance(result, dict) else 'Not a dict'}")
        
        # Print full response for debugging
        logger.info(f"=== LESSON PLAN RESPONSE ===")
        logger.info(f"Lesson Plan Response: {result}")
        logger.info(f"=== END LESSON PLAN RESPONSE ===")
        
        # Format response for Flutter frontend compatibility
        content_text = None
        metadata = {}
        
        if isinstance(result, dict):
            if 'content' in result:
                # Direct structure
                content_text = result['content']
                metadata = result.get('metadata', {})
            elif 'data' in result and isinstance(result['data'], dict):
                # Nested data structure
                data_content = result['data']
                content_text = data_content.get('content', '')
                metadata = data_content.get('metadata', {})
            elif result.get('success') is True and 'data' in result:
                # Handle success response with nested data
                data_content = result['data']
                content_text = data_content.get('content', '')
                metadata = data_content.get('metadata', {})
        
        if content_text:
            frontend_response = {
                "content": content_text,
                "subject": subject,
                "grade_levels": grade_levels,
                "duration": duration,
                "topic": topic,
                "language": language,
                "resource_level": resource_level,
                **metadata
            }
            logger.info(f"Sending lesson plan to frontend: {list(frontend_response.keys())}")
            return jsonify(frontend_response)
        
        # If content is not found, log the issue and return a debug response
        logger.error(f"Lesson plan content not found in result! Result: {result}")
        debug_response = {
            "content": "DEBUG: Lesson plan generation succeeded but response format is unexpected. Check backend logs.",
            "subject": subject,
            "grade_levels": grade_levels,
            "duration": duration,
            "topic": topic,
            "language": language,
            "resource_level": resource_level,
            "debug_info": result
        }
        return jsonify(debug_response)
        
    except Exception as e:
        logger.error(f"Lesson plan generation failed: {str(e)}")
        return jsonify({"error": f"Lesson plan generation failed: {str(e)}"}), 500

@app.route('/api/v1/assess-reading', methods=['POST'])
def assess_reading():
    """Assess reading from audio using AssessmentAgent"""
    try:
        # Get JSON data from request
        data = request.get_json(force=True)
        
        if not data:
            try:
                data = json.loads(request.data.decode('utf-8'))
            except:
                return jsonify({"error": "No valid JSON data provided"}), 400
        
        logger.info(f"Reading assessment request received: {list(data.keys())}")
        
        # Extract fields
        audio = data.get("audio", "")
        expected_text = data.get("expected_text", "")
        grade_level = data.get("grade_level", "grade_3_4")
        language = data.get("language", "en")
        assessment_type = data.get("assessment_type", "reading_fluency")
        
        if not audio:
            return jsonify({"error": "Audio data is required"}), 400
        
        # Import AssessmentAgent
        from agents.assessment import AssessmentAgent
        assessment_agent = AssessmentAgent()
        
        # Prepare request for assessment agent
        assessment_request = {
            "audio": audio,
            "expected_text": expected_text,
            "grade_level": grade_level,
            "language": language,
            "assessment_type": assessment_type
        }
        
        logger.info(f"Assessing reading for {grade_level} in {language}")
        
        # Call AssessmentAgent (handle async)
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            result = loop.run_until_complete(
                assessment_agent.execute_with_monitoring(assessment_request)
            )
        finally:
            loop.close()
        
        logger.info(f"Reading assessment completed successfully!")
        logger.info(f"Raw result type: {type(result)}")
        logger.info(f"Raw result keys: {list(result.keys()) if isinstance(result, dict) else 'Not a dict'}")
        
        # Print full response for debugging
        logger.info(f"=== READING ASSESSMENT RESPONSE ===")
        logger.info(f"Reading Assessment Response: {result}")
        logger.info(f"=== END READING ASSESSMENT RESPONSE ===")
        
        # Format response for Flutter frontend compatibility
        assessment_data = {}
        transcription = ""
        metrics = {}
        feedback = ""
        
        if isinstance(result, dict):
            if 'assessment_data' in result:
                # Direct structure
                assessment_data = result['assessment_data']
                transcription = result.get('transcription', '')
                metrics = result.get('metrics', {})
                feedback = result.get('feedback', '')
            elif 'data' in result and isinstance(result['data'], dict):
                # Nested data structure
                data_content = result['data']
                assessment_data = data_content.get('assessment_data', {})
                transcription = data_content.get('transcription', '')
                metrics = data_content.get('metrics', {})
                feedback = data_content.get('feedback', '')
            elif result.get('success') is True and 'data' in result:
                # Handle success response with nested data
                data_content = result['data']
                assessment_data = data_content.get('assessment_data', {})
                transcription = data_content.get('transcription', '')
                metrics = data_content.get('metrics', {})
                feedback = data_content.get('feedback', '')
        
        if assessment_data or transcription:
            frontend_response = {
                "assessment_data": assessment_data,
                "transcription": transcription,
                "metrics": metrics,
                "feedback": feedback,
                "grade_level": grade_level,
                "language": language,
                "assessment_type": assessment_type
            }
            logger.info(f"Sending reading assessment to frontend: {list(frontend_response.keys())}")
            return jsonify(frontend_response)
        
        # If content is not found, log the issue and return a debug response
        logger.error(f"Reading assessment content not found in result! Result: {result}")
        debug_response = {
            "assessment_data": {},
            "transcription": "DEBUG: Reading assessment succeeded but response format is unexpected. Check backend logs.",
            "metrics": {},
            "feedback": "Assessment completed but response format needs investigation.",
            "grade_level": grade_level,
            "language": language,
            "assessment_type": assessment_type,
            "debug_info": result
        }
        return jsonify(debug_response)
        
    except Exception as e:
        logger.error(f"Reading assessment failed: {str(e)}")
        return jsonify({"error": f"Reading assessment failed: {str(e)}"}), 500

if __name__ == "__main__":
    print("🚀 Starting Sahaayak AI Flask Backend...")
    print("📍 URL: http://localhost:8001")
    print("🧪 Test: POST http://localhost:8001/api/v1/generate")
    print("📋 Payload: {'topic': 'water cycle', 'content_type': 'story', 'language': 'en', 'grade_level': 'grade_3_4'}")
    
    app.run(host="0.0.0.0", port=8001, debug=True) 