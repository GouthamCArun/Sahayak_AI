"""
Firebase configuration and initialization for Sahaayak AI Backend

This module handles Firebase Admin SDK initialization and provides
utilities for authentication and database operations.
"""

import json
from typing import Dict, Any, Optional

import firebase_admin
from firebase_admin import credentials, auth, db
import structlog

from utils.config import settings

logger = structlog.get_logger(__name__)


class FirebaseManager:
    """
    Firebase service manager for authentication and database operations.
    
    Provides a centralized interface for Firebase operations including
    user authentication, data persistence, and real-time database access.
    """
    
    def __init__(self):
        self._app: Optional[firebase_admin.App] = None
        self._db_ref: Optional[db.Reference] = None
    
    async def initialize(self) -> None:
        """
        Initialize Firebase Admin SDK with service account credentials.
        
        Sets up the Firebase app instance and database reference
        for the application to use.
        """
        try:
            # Create credentials from environment variables
            cred_dict = {
                "type": "service_account",
                "project_id": settings.FIREBASE_PROJECT_ID,
                "private_key_id": settings.FIREBASE_PRIVATE_KEY_ID,
                "private_key": settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n"),
                "client_email": settings.FIREBASE_CLIENT_EMAIL,
                "client_id": settings.FIREBASE_CLIENT_ID,
                "auth_uri": settings.FIREBASE_AUTH_URI,
                "token_uri": settings.FIREBASE_TOKEN_URI,
            }
            
            # Initialize Firebase Admin SDK
            cred = credentials.Certificate(cred_dict)
            self._app = firebase_admin.initialize_app(
                cred,
                {
                    "databaseURL": settings.FIREBASE_DATABASE_URL,
                    "projectId": settings.FIREBASE_PROJECT_ID,
                }
            )
            
            # Initialize database reference
            self._db_ref = db.reference("/", app=self._app)
            
            logger.info("Firebase initialized successfully")
            
        except Exception as e:
            logger.error("Failed to initialize Firebase", error=str(e))
            raise
    
    async def verify_token(self, token: str) -> Dict[str, Any]:
        """
        Verify Firebase ID token and return user information.
        
        Args:
            token: Firebase ID token from client
            
        Returns:
            Dictionary containing user information
            
        Raises:
            Exception: If token verification fails
        """
        try:
            decoded_token = auth.verify_id_token(token, app=self._app)
            logger.debug("Token verified successfully", uid=decoded_token["uid"])
            return decoded_token
        except Exception as e:
            logger.warning("Token verification failed", error=str(e))
            raise
    
    async def get_user_profile(self, uid: str) -> Optional[Dict[str, Any]]:
        """
        Get user profile data from Firebase Realtime Database.
        
        Args:
            uid: User ID from Firebase Auth
            
        Returns:
            User profile data or None if not found
        """
        try:
            profile_ref = self._db_ref.child("users").child(uid)
            profile_data = profile_ref.get()
            
            if profile_data:
                logger.debug("User profile retrieved", uid=uid)
                return profile_data
            else:
                logger.debug("User profile not found", uid=uid)
                return None
                
        except Exception as e:
            logger.error("Failed to get user profile", uid=uid, error=str(e))
            raise
    
    async def update_user_profile(self, uid: str, profile_data: Dict[str, Any]) -> None:
        """
        Update user profile data in Firebase Realtime Database.
        
        Args:
            uid: User ID from Firebase Auth
            profile_data: Profile data to update
        """
        try:
            profile_ref = self._db_ref.child("users").child(uid)
            profile_ref.update(profile_data)
            
            logger.info("User profile updated", uid=uid)
            
        except Exception as e:
            logger.error("Failed to update user profile", uid=uid, error=str(e))
            raise
    
    async def save_interaction(
        self,
        uid: str,
        interaction_type: str,
        request_data: Dict[str, Any],
        response_data: Dict[str, Any]
    ) -> str:
        """
        Save user interaction to Firebase for history tracking.
        
        Args:
            uid: User ID
            interaction_type: Type of interaction (query, assessment, etc.)
            request_data: Original request data
            response_data: AI response data
            
        Returns:
            Interaction ID
        """
        try:
            import time
            
            interaction_data = {
                "type": interaction_type,
                "timestamp": int(time.time()),
                "request": request_data,
                "response": response_data,
            }
            
            # Skip Firebase operations if not initialized (for development)
            if not self._db_ref:
                logger.info(f"Firebase not initialized, skipping interaction save", uid=uid, type=interaction_type)
                return "mock_interaction_id"
                
            # Save to user's interaction history
            interactions_ref = self._db_ref.child("interactions").child(uid)
            new_interaction_ref = interactions_ref.push(interaction_data)
            
            interaction_id = new_interaction_ref.key
            logger.info(
                "Interaction saved",
                uid=uid,
                interaction_id=interaction_id,
                type=interaction_type
            )
            
            return interaction_id
            
        except Exception as e:
            logger.error(
                "Failed to save interaction",
                uid=uid,
                type=interaction_type,
                error=str(e)
            )
            raise
    
    async def get_interaction_history(
        self,
        uid: str,
        limit: int = 50
    ) -> list[Dict[str, Any]]:
        """
        Get user's interaction history from Firebase.
        
        Args:
            uid: User ID
            limit: Maximum number of interactions to return
            
        Returns:
            List of interaction records
        """
        try:
            interactions_ref = self._db_ref.child("interactions").child(uid)
            
            # Get latest interactions ordered by timestamp
            interactions = (
                interactions_ref
                .order_by_child("timestamp")
                .limit_to_last(limit)
                .get()
            )
            
            if interactions:
                # Convert to list and reverse to get newest first
                history = []
                for interaction_id, data in interactions.items():
                    data["id"] = interaction_id
                    history.append(data)
                
                history.reverse()
                
                logger.debug("Interaction history retrieved", uid=uid, count=len(history))
                return history
            else:
                logger.debug("No interaction history found", uid=uid)
                return []
                
        except Exception as e:
            logger.error("Failed to get interaction history", uid=uid, error=str(e))
            raise


# Global Firebase manager instance
firebase_manager = FirebaseManager()


async def initialize_firebase() -> None:
    """Initialize the global Firebase manager."""
    await firebase_manager.initialize()


def get_firebase_manager() -> FirebaseManager:
    """Get the global Firebase manager instance."""
    return firebase_manager 