from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import Dict, Any, List, Optional
import json
import base64
from pydantic import BaseModel
from datetime import datetime

from agents.orchestrator import OrchestratorAgent
from agents.content_generator import ContentGeneratorAgent
from agents.material_adapter import MaterialAdapterAgent
from agents.visual_aid import VisualAidAgent
from agents.assessment import AssessmentAgent
from agents.lesson_planner import LessonPlannerAgent
from firebase.firebase_config import FirebaseManager
from utils.logging import get_logger, log_request, log_ai_operation
from utils.config import settings

# Initialize FastAPI app
app = FastAPI(
    title="Sahaayak AI Backend",
    description="AI-powered teaching assistant API for rural Indian schools",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize components
logger = get_logger(__name__)
firebase_manager = FirebaseManager()

# Initialize AI agents
orchestrator = OrchestratorAgent()
content_generator = ContentGeneratorAgent()
material_adapter = MaterialAdapterAgent()
visual_aid = VisualAidAgent()
assessment = AssessmentAgent()
lesson_planner = LessonPlannerAgent()

# Request/Response Models  
class QueryRequest(BaseModel):
    type: str
    text: Optional[str] = None
    content_type: Optional[str] = None
    topic: Optional[str] = None  
    language: Optional[str] = "en"
    grade_level: Optional[str] = None
    context: Optional[Dict[str, Any]] = None
    additional_params: Optional[Dict[str, Any]] = None
    
    class Config:
        extra = "ignore"
        str_strip_whitespace = True

class AudioAssessmentRequest(BaseModel):
    audio: str  # Base64 encoded audio
    expected_text: Optional[str] = None
    grade_level: str = "grade_3_4"
    language: str = "en"
    assessment_type: str = "reading_fluency"

class VisualAidRequest(BaseModel):
    concept: str
    diagram_type: str = "auto"
    language: str = "en"
    grade_level: str = "grade_3_4"
    subject: str = "general"

class LessonPlanRequest(BaseModel):
    subject: str
    grade_levels: List[str]
    duration: str = "week"
    topic: Optional[str] = None
    language: str = "en"
    resource_level: str = "basic"

class WorksheetRequest(BaseModel):
    image: str  # Base64 encoded image
    target_grades: List[str] = ["grade_3_4"]
    language: str = "en"
    subject: str = "general"

# Authentication dependency
async def get_current_user(authorization: str = ""):
    """Verify Firebase ID token and return user info"""
    try:
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Missing or invalid authorization header")
        
        token = authorization.split(" ")[1]
        user_info = firebase_manager.verify_token(token)
        return user_info
    except Exception as e:
        logger.error(f"Authentication failed: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid authentication token")

# Health check
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "Sahaayak AI Backend"}

# Debug endpoint to test request parsing
@app.post("/api/v1/debug")
async def debug_request(request: Request):
    """Debug endpoint to see raw request data"""
    try:
        body = await request.body()
        headers = dict(request.headers)
        
        return {
            "raw_body": body.decode(),
            "content_type": headers.get("content-type"),
            "headers": headers,
            "method": request.method,
            "url": str(request.url)
        }
    except Exception as e:
        return {"error": str(e)}

# Simple test endpoint with same model
@app.post("/api/v1/test")
async def test_query(request: QueryRequest):
    """Simple test endpoint to verify Pydantic parsing works"""
    return {
        "received": {
            "type": request.type,
            "topic": request.topic,
            "content_type": request.content_type,
            "language": request.language,
            "grade_level": request.grade_level
        },
        "status": "success"
    }

# Raw endpoint that bypasses Pydantic validation
@app.post("/api/v1/generate")
async def generate_story_raw(request: Request):
    """Raw endpoint that bypasses Pydantic validation for content generation"""
    try:
        # Parse raw JSON manually
        body = await request.body()
        data = json.loads(body.decode())
        
        logger.info(f"Raw endpoint received: {data}")
        
        # Extract fields manually
        content_type = data.get("content_type", "story")
        topic = data.get("topic", "")
        language = data.get("language", "en")
        grade_level = data.get("grade_level", "grade_3_4")
        
        if not topic:
            return {"error": "Topic is required"}
        
        # Prepare request for content generator
        content_request = {
            "content_type": content_type,
            "topic": topic,
            "language": language,
            "grade_level": grade_level,
            "additional_details": ""
        }
        
        logger.info(f"Calling ContentGenerator with: {content_request}")
        
        # Call ContentGenerator directly
        result = await content_generator.execute_with_monitoring(content_request)
        
        logger.info(f"Generated content keys: {list(result.keys()) if isinstance(result, dict) else 'Not dict'}")
        
        return result
        
    except json.JSONDecodeError as e:
        logger.error(f"JSON parsing failed: {str(e)}")
        return {"error": f"Invalid JSON: {str(e)}"}
    except Exception as e:
        logger.error(f"Story generation failed: {str(e)}")
        return {"error": f"Generation failed: {str(e)}"}

# Main query endpoint (orchestrated AI processing)
@app.post("/api/v1/query")
async def process_query(
    request: QueryRequest
):
    """
    Process user query for content generation using Gemini API
    
    For content_type='story': Generates educational stories using Gemini
    Supports multiple languages and grade levels
    """
    try:
        logger.info(f"Processing {request.type} request: {request.topic}")
        
        # For content generation, route directly to ContentGenerator
        if request.type == "content_generation":
            # Prepare request for content generator
            content_request = {
                "content_type": request.content_type or "story",
                "topic": request.topic,
                "language": request.language,
                "grade_level": request.grade_level,
                "additional_details": request.additional_params.get("additional_details", "") if request.additional_params else ""
            }
            
            logger.info(f"Generating {content_request['content_type']} about '{content_request['topic']}' for {content_request['grade_level']}")
            
            # Call ContentGenerator directly 
            result = await content_generator.execute_with_monitoring(content_request)
            
            # Log what we're returning
            logger.info(f"Content generated successfully. Keys: {list(result.keys()) if isinstance(result, dict) else 'Not a dict'}")
            if isinstance(result, dict) and 'content' in result:
                content_preview = str(result['content'])[:150] + "..." if len(str(result['content'])) > 150 else str(result['content'])
                logger.info(f"Generated content preview: {content_preview}")
            
            # Save interaction
            await _save_interaction("anonymous", "content_generation", content_request, result)
            
            return result
        
        else:
            # For other types, use orchestrator
            orchestrator_request = {
                "type": request.type,
                "text": request.text or request.topic or "",
                "content_type": request.content_type,
                "topic": request.topic,
                "language": request.language,
                "grade_level": request.grade_level,
                "context": request.context or {},
                "user_id": "anonymous",
                **(request.additional_params or {})
            }
            
            result = await orchestrator.execute_with_monitoring(orchestrator_request)
            await _save_interaction("anonymous", "query", orchestrator_request, result)
            
            return result
        
    except Exception as e:
        logger.error(f"Query processing failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Query processing failed: {str(e)}")

# Content generation endpoint
@app.post("/api/v1/generate-content")
async def generate_content(
    request: QueryRequest
):
    """
    Generate educational content using ContentGeneratorAgent
    
    Creates stories, explanations, lessons, and activities
    tailored for the specified grade level and language.
    """
    try:
        logger.info(f"Generating content: {request.content_type}")
        
        # Prepare request for content generator
        content_request = {
            "content_type": request.content_type or "story",
            "topic": request.topic,
            "language": request.language,
            "grade_level": request.grade_level,
            "additional_details": request.additional_params.get("additional_details", "") if request.additional_params else ""
        }
        
        result = await content_generator.execute_with_monitoring(content_request)
        
        # Save to Firebase
        await _save_interaction("anonymous", "content_generation", content_request, result)
        
        return result
        
    except Exception as e:
        logger.error(f"Content generation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Content generation failed: {str(e)}")

# Visual aid generation endpoint
@app.post("/api/v1/generate-diagram")
async def generate_visual_aid(
    request: VisualAidRequest
):
    """
    Generate educational diagrams and visual aids
    
    Creates various types of diagrams including concept maps,
    flowcharts, timelines, and labeled diagrams.
    """
    try:
        logger.info(f"Generating diagram: {request.diagram_type}")
        
        # Prepare request for visual aid agent
        visual_request = {
            "concept": request.concept,
            "diagram_type": request.diagram_type,
            "language": request.language,
            "grade_level": request.grade_level,
            "subject": request.subject
        }
        
        result = await visual_aid.execute_with_monitoring(visual_request)
        
        # Save to Firebase
        await _save_interaction("anonymous", "visual_aid", visual_request, result)
        
        return result
        
    except Exception as e:
        logger.error(f"Visual aid generation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Visual aid generation failed: {str(e)}")

# Audio assessment endpoint
@app.post("/api/v1/assess-audio")
async def assess_audio(
    request: AudioAssessmentRequest
):
    """
    Assess student reading fluency from audio recording
    
    Transcribes audio, calculates reading metrics, and provides
    detailed feedback and improvement suggestions.
    """
    try:
        logger.info(f"Assessing audio: grade {request.grade_level}, language {request.language}")
        
        assessment_request = {
            "audio": request.audio,
            "expected_text": request.expected_text,
            "grade_level": request.grade_level,
            "language": request.language,
            "assessment_type": request.assessment_type
        }
        
        result = await assessment.execute_with_monitoring(assessment_request)
        
        # Save to Firebase
        await _save_interaction("anonymous", "reading_assessment", assessment_request, result)
        
        return result
        
    except Exception as e:
        logger.error(f"Audio assessment failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Audio assessment failed: {str(e)}")

# Lesson plan generation endpoint
@app.post("/api/v1/lesson-plan")
async def generate_lesson_plan(
    request: LessonPlanRequest
):
    """
    Generate comprehensive lesson plans
    
    Creates structured lesson plans with activities, assessments,
    and resources for multi-grade rural classrooms.
    """
    try:
        logger.info(f"Generating lesson plan: {request.subject} for grades {request.grade_levels}")
        
        # Prepare lesson plan request
        lesson_request = {
            "subject": request.subject,
            "grade_levels": request.grade_levels,
            "duration": request.duration,
            "topic": request.topic,
            "language": request.language,
            "resource_level": request.resource_level
        }
        
        result = await lesson_planner.execute_with_monitoring(lesson_request)
        
        # Save to Firebase
        await _save_interaction("anonymous", "lesson_planning", lesson_request, result)
        
        return result
        
    except Exception as e:
        logger.error(f"Lesson plan generation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Lesson plan generation failed: {str(e)}")

# Worksheet generation endpoint
@app.post("/api/v1/worksheet-adapter")
async def adapt_worksheet(
    request: WorksheetRequest
):
    """
    Generate worksheets from textbook images
    
    Uses Gemini Vision to extract content from textbook images
    and adapts them into worksheets for multiple grade levels.
    """
    try:
        logger.info(f"Adapting worksheet: grades {request.target_grades}, language {request.language}")
        
        # Process the worksheet image
        
        worksheet_request = {
            "image": request.image,
            "target_grades": request.target_grades,
            "language": request.language,
            "subject": request.subject
        }
        
        result = await material_adapter.execute_with_monitoring(worksheet_request)
        
        # Save to Firebase
        await _save_interaction("anonymous", "worksheet_generation", worksheet_request, result)
        
        return result
        
    except Exception as e:
        logger.error(f"Worksheet generation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Worksheet generation failed: {str(e)}")

# User interaction history
@app.get("/api/v1/history")
async def get_user_history():
    """
    Get user's interaction history
    
    Returns recent AI interactions for the authenticated user.
    """
    try:
        history = firebase_manager.get_interaction_history("anonymous", 10) # Removed user dependency
        return {"history": history}
        
    except Exception as e:
        logger.error(f"History retrieval failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"History retrieval failed: {str(e)}")

# User profile management
@app.get("/api/v1/profile")
async def get_user_profile():
    """Get user profile information"""
    return {"message": "Profile endpoint - authentication disabled for testing"}

@app.post("/api/v1/profile")
async def update_user_profile():
    """Update user profile information"""
    return {"message": "Profile update - authentication disabled for testing"}

# Agent capabilities
@app.get("/api/v1/capabilities")
async def get_agent_capabilities():
    """Get capabilities of all AI agents"""
    try:
        capabilities = {
            "orchestrator": orchestrator.get_capabilities(),
            "content_generator": content_generator.get_capabilities(),
            "material_adapter": material_adapter.get_capabilities(),
            "visual_aid": visual_aid.get_capabilities(),
            "assessment": assessment.get_capabilities(),
            "lesson_planner": lesson_planner.get_capabilities()
        }
        return {"capabilities": capabilities}
        
    except Exception as e:
        logger.error(f"Capabilities retrieval failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Capabilities retrieval failed: {str(e)}")

# File upload endpoint for images/audio
@app.post("/api/v1/upload")
async def upload_file(
    file: UploadFile = File(...),
    purpose: str = Form(...)
):
    """
    Upload file (image or audio) and return base64 encoded data
    
    Supports common image and audio formats for processing.
    """
    try:
        # Validate file type
        allowed_types = [
            "image/jpeg", "image/png", "image/webp",
            "audio/mpeg", "audio/wav", "audio/mp4", "audio/m4a"
        ]
        
        if file.content_type not in allowed_types:
            raise HTTPException(status_code=400, detail="Unsupported file type")
        
        # Read file content
        content = await file.read()
        
        # Encode to base64
        encoded_content = base64.b64encode(content).decode()
        
        return {
            "success": True,
            "filename": file.filename,
            "content_type": file.content_type,
            "size": len(content),
            "data": f"data:{file.content_type};base64,{encoded_content}"
        }
        
    except Exception as e:
        logger.error(f"File upload failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"File upload failed: {str(e)}")

# Helper function to save interactions
async def _save_interaction(
    user_id: str, 
    interaction_type: str, 
    request_data: Dict[str, Any], 
    result: Dict[str, Any]
):
    """Save user interaction to Firebase"""
    try:
        interaction_data = {
            "type": interaction_type,
            "request": request_data,
            "result": result,
            "timestamp": datetime.now().isoformat(),
            "success": result.get("success", False)
        }
        
        await firebase_manager.save_interaction(user_id, interaction_type, request_data, result)
        
    except Exception as e:
        logger.error(f"Failed to save interaction: {str(e)}")

# Error handlers
@app.exception_handler(404)
async def not_found_handler(request, exc):
    return JSONResponse(
        status_code=404,
        content={"error": "Endpoint not found", "detail": "The requested endpoint does not exist"}
    )

@app.exception_handler(500)
async def internal_error_handler(request, exc):
    logger.error(f"Internal server error: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "detail": "An unexpected error occurred"}
    )

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    logger.info("Starting Sahaayak AI Backend...")
    
    # Initialize Firebase
    firebase_manager.initialize()
    
    logger.info("Sahaayak AI Backend started successfully!")

# Shutdown event  
@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down Sahaayak AI Backend...")
    
    # Cleanup agents
    orchestrator.cleanup()
    content_generator.cleanup()
    material_adapter.cleanup()
    visual_aid.cleanup()
    assessment.cleanup()
    lesson_planner.cleanup()
    
    logger.info("Sahaayak AI Backend shutdown complete!")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 