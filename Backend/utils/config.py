"""
Configuration management for Sahaayak AI Backend

This module handles all application configuration using Pydantic settings
with environment variable support and validation.
"""

from typing import List
from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Application settings with environment variable support.
    
    All settings can be overridden using environment variables.
    For example, APP_NAME can be set via the APP_NAME env var.
    """
    
    # Application Settings
    APP_NAME: str = Field(default="Sahaayak AI Backend", description="Application name")
    APP_VERSION: str = Field(default="1.0.0", description="Application version")
    DEBUG: bool = Field(default=False, description="Debug mode")
    LOG_LEVEL: str = Field(default="INFO", description="Logging level")
    
    # Server Configuration
    HOST: str = Field(default="0.0.0.0", description="Server host")
    PORT: int = Field(default=8000, description="Server port")
    WORKERS: int = Field(default=1, description="Number of worker processes")
    
    # Security
    SECRET_KEY: str = Field(..., description="Secret key for JWT tokens")
    ALGORITHM: str = Field(default="HS256", description="JWT algorithm")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=30, description="Token expiry in minutes")
    
    # Google AI Services
    GOOGLE_API_KEY: str = Field(..., description="Google Gemini API key")
    GOOGLE_APPLICATION_CREDENTIALS: str = Field(..., description="Path to Google service account key")
    
    # Firebase Configuration
    FIREBASE_PROJECT_ID: str = Field(..., description="Firebase project ID")
    FIREBASE_PRIVATE_KEY_ID: str = Field(..., description="Firebase private key ID")
    FIREBASE_PRIVATE_KEY: str = Field(..., description="Firebase private key")
    FIREBASE_CLIENT_EMAIL: str = Field(..., description="Firebase client email")
    FIREBASE_CLIENT_ID: str = Field(..., description="Firebase client ID")
    FIREBASE_AUTH_URI: str = Field(default="https://accounts.google.com/o/oauth2/auth")
    FIREBASE_TOKEN_URI: str = Field(default="https://oauth2.googleapis.com/token")
    FIREBASE_DATABASE_URL: str = Field(..., description="Firebase Realtime Database URL")
    
    # Redis Configuration
    REDIS_URL: str = Field(default="redis://localhost:6379", description="Redis connection URL")
    
    # CORS Settings
    CORS_ORIGINS: List[str] = Field(
        default=["http://localhost:3000", "http://localhost:8080"],
        description="Allowed CORS origins"
    )
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


# Global settings instance
settings = Settings() 