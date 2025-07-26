#!/usr/bin/env python3
"""
Sahaayak AI Backend - Main Application Entry Point

This is the main entry point for the Sahaayak AI backend API server.
It initializes the FastAPI application with all routes, middleware,
and AI agents for the rural Indian schools teaching assistant platform.
"""

import os
import sys
import uvicorn
from fastapi import FastAPI

# Add project root to Python path
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, project_root)

from api.routes import app
from utils.config import settings
from utils.logging import setup_logging, get_logger

# Setup logging
setup_logging()
logger = get_logger(__name__)

def main():
    """
    Main function to start the Sahaayak AI backend server
    
    Starts the FastAPI application using uvicorn with production settings
    optimized for rural Indian school environments.
    """
    logger.info("Starting Sahaayak AI Backend Server...")
    logger.info(f"Environment: {'Production' if not settings.debug else 'Development'}")
    logger.info(f"Server: {settings.server_host}:{settings.server_port}")
    
    # Configure uvicorn settings
    uvicorn_config = {
        "app": "main:app",
        "host": settings.server_host,
        "port": settings.server_port,
        "workers": settings.server_workers if not settings.debug else 1,
        "log_level": settings.log_level.lower(),
        "reload": settings.debug,
        "access_log": True,
    }
    
    # Add SSL configuration for production
    if not settings.debug and os.getenv("SSL_KEYFILE") and os.getenv("SSL_CERTFILE"):
        uvicorn_config.update({
            "ssl_keyfile": os.getenv("SSL_KEYFILE"),
            "ssl_certfile": os.getenv("SSL_CERTFILE"),
        })
        logger.info("SSL/TLS encryption enabled")
    
    try:
        uvicorn.run(**uvicorn_config)
    except KeyboardInterrupt:
        logger.info("Server shutdown requested by user")
    except Exception as e:
        logger.error(f"Server startup failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 