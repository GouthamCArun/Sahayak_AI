"""
Structured logging configuration for Sahaayak AI Backend

This module sets up structured logging using structlog for better
observability and debugging capabilities.
"""

import logging
import sys
from typing import Any, Dict

import structlog
from structlog.stdlib import LoggerFactory


def setup_logging(log_level: str = "INFO") -> None:
    """
    Configure structured logging for the application.
    
    Sets up structlog with JSON formatting for production
    and human-readable formatting for development.
    
    Args:
        log_level: The logging level (DEBUG, INFO, WARNING, ERROR)
    """
    
    # Configure standard library logging
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=getattr(logging, log_level.upper()),
    )
    
    # Configure structlog
    structlog.configure(
        processors=[
            # Add log level and timestamp
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            # JSON formatting for production
            structlog.processors.JSONRenderer()
            if log_level.upper() != "DEBUG"
            else structlog.dev.ConsoleRenderer(colors=True),
        ],
        context_class=dict,
        logger_factory=LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )


def get_logger(name: str) -> structlog.stdlib.BoundLogger:
    """
    Get a configured logger instance.
    
    Args:
        name: The logger name (typically __name__)
        
    Returns:
        A configured structlog logger instance
    """
    return structlog.get_logger(name)


def log_request(
    method: str,
    url: str,
    status_code: int,
    process_time: float,
    user_id: str = None,
    **kwargs: Any
) -> None:
    """
    Log HTTP request information in a structured format.
    
    Args:
        method: HTTP method
        url: Request URL
        status_code: Response status code
        process_time: Request processing time in seconds
        user_id: Optional user ID for the request
        **kwargs: Additional context to log
    """
    logger = get_logger("api.request")
    
    log_data = {
        "method": method,
        "url": url,
        "status_code": status_code,
        "process_time": f"{process_time:.3f}s",
        **kwargs
    }
    
    if user_id:
        log_data["user_id"] = user_id
    
    if status_code >= 500:
        logger.error("Request failed", **log_data)
    elif status_code >= 400:
        logger.warning("Request error", **log_data)
    else:
        logger.info("Request completed", **log_data)


def log_ai_operation(
    agent_name: str,
    operation: str,
    duration: float,
    success: bool,
    user_id: str = None,
    **kwargs: Any
) -> None:
    """
    Log AI agent operations for monitoring and analysis.
    
    Args:
        agent_name: Name of the AI agent
        operation: Type of operation performed
        duration: Operation duration in seconds
        success: Whether the operation succeeded
        user_id: Optional user ID
        **kwargs: Additional context to log
    """
    logger = get_logger(f"ai.{agent_name.lower()}")
    
    log_data = {
        "agent": agent_name,
        "operation": operation,
        "duration": f"{duration:.3f}s",
        "success": success,
        **kwargs
    }
    
    if user_id:
        log_data["user_id"] = user_id
    
    if success:
        logger.info("AI operation completed", **log_data)
    else:
        logger.error("AI operation failed", **log_data) 