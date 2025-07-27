"""
Base Agent class for Sahaayak AI Backend

This module defines the base agent interface that all specialized
AI agents inherit from, providing common functionality and structure.
"""

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional, Union
import time

import structlog

from utils.logging import log_ai_operation

logger = structlog.get_logger(__name__)


class BaseAgent(ABC):
    """
    Abstract base class for all AI agents in the Sahaayak AI system.
    
    This class defines the common interface and functionality that all
    specialized agents must implement, including error handling,
    logging, and performance monitoring.
    """
    
    def __init__(self, name: str):
        """
        Initialize the base agent.
        
        Args:
            name: The name of the agent (e.g., "ContentGenerator", "KnowledgeExplainer")
        """
        self.name = name
        self.logger = structlog.get_logger(f"agent.{name.lower()}")
        
    @abstractmethod
    async def process(
        self,
        request_data: Dict[str, Any],
        user_context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Process a request and return the response.
        
        This is the main method that each agent must implement
        to handle specific types of requests.
        
        Args:
            request_data: The input data for processing
            user_context: Optional user context (profile, preferences, etc.)
            
        Returns:
            Dictionary containing the processed response
            
        Raises:
            Exception: If processing fails
        """
        pass
    
    async def execute_with_monitoring(
        self,
        request_data: Dict[str, Any],
        user_context: Optional[Dict[str, Any]] = None,
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Execute the agent's process method with monitoring and error handling.
        
        This method wraps the process method with timing, logging,
        and error handling capabilities.
        
        Args:
            request_data: The input data for processing
            user_context: Optional user context
            user_id: Optional user ID for logging
            
        Returns:
            Dictionary containing the processed response with metadata
        """
        start_time = time.time()
        operation_type = request_data.get("type", "unknown")
        
        self.logger.info(
            "Starting agent operation",
            operation=operation_type,
            user_id=user_id
        )
        
        try:
            # Execute the main processing logic
            result = await self.process(request_data, user_context)
            
            # Calculate processing time
            duration = time.time() - start_time
            
            # Add metadata to response
            response = {
                "success": True,
                "data": result,
                "metadata": {
                    "agent": self.name,
                    "operation": operation_type,
                    "processing_time": f"{duration:.3f}s",
                    "timestamp": int(time.time())
                }
            }
            
            # Log successful operation
            log_ai_operation(
                agent_name=self.name,
                operation=operation_type,
                duration=duration,
                success=True,
                user_id=user_id,
                input_size=len(str(request_data)),
                output_size=len(str(result))
            )
            
            return response
            
        except Exception as e:
            # Calculate processing time even on error
            duration = time.time() - start_time
            
            # Log failed operation
            log_ai_operation(
                agent_name=self.name,
                operation=operation_type,
                duration=duration,
                success=False,
                user_id=user_id,
                error=str(e)
            )
            
            # Return error response
            return {
                "success": False,
                "error": {
                    "message": str(e),
                    "type": type(e).__name__,
                    "agent": self.name
                },
                "metadata": {
                    "agent": self.name,
                    "operation": operation_type,
                    "processing_time": f"{duration:.3f}s",
                    "timestamp": int(time.time())
                }
            }
    
    def validate_request(self, request_data: Dict[str, Any]) -> bool:
        """
        Validate the request data format and required fields.
        
        Override this method in specific agents to implement
        custom validation logic.
        
        Args:
            request_data: The request data to validate
            
        Returns:
            True if valid, False otherwise
        """
        # Basic validation - check if request_data is not empty
        if not request_data:
            return False
            
        # Check for required 'type' field
        if "type" not in request_data:
            return False
            
        return True
    
    def get_capabilities(self) -> Dict[str, Any]:
        """
        Return the capabilities and supported operations of this agent.
        
        Override this method in specific agents to describe
        what operations they can perform.
        
        Returns:
            Dictionary describing agent capabilities
        """
        return {
            "name": self.name,
            "description": "Base agent with no specific capabilities",
            "supported_operations": [],
            "input_types": ["text"],
            "output_types": ["text"]
        }
    
    async def cleanup(self) -> None:
        """
        Cleanup resources when the agent is destroyed.
        
        Override this method if the agent needs to perform
        cleanup operations (close connections, release resources, etc.).
        """
        self.logger.info("Agent cleanup completed")
        pass
    
    def get_processing_time(self) -> str:
        """
        Get the processing time for the last operation.
        
        This is a placeholder method that should be overridden
        by agents that want to track processing time.
        
        Returns:
            Processing time as a string
        """
        return "AI-generated" 