import base64
import io
import asyncio
import tempfile
import os
from typing import Dict, Any, List, Optional
from pydub import AudioSegment
import speech_recognition as sr
import librosa
import numpy as np

from .base_agent import BaseAgent
from ..utils.logging import get_logger
import google.generativeai as genai
from google.cloud import speech
from ..utils.config import settings

class AssessmentAgent(BaseAgent):
    """
    Assessment Agent for evaluating student reading fluency and comprehension
    
    Uses Vertex AI Speech-to-Text to transcribe audio recordings and
    provides detailed feedback on reading skills and pronunciation.
    """
    
    def __init__(self):
        super().__init__("AssessmentAgent")
        
        # Initialize Google Cloud Speech client
        self.speech_client = speech.SpeechClient()
        self.model = genai.GenerativeModel('gemini-pro')
        
        # Reading assessment criteria
        self.assessment_criteria = {
            "fluency": {
                "excellent": {"wpm": 90, "description": "Reads smoothly with expression"},
                "good": {"wpm": 70, "description": "Reads accurately with some expression"},
                "fair": {"wpm": 50, "description": "Reads with hesitation but accurately"},
                "needs_improvement": {"wpm": 30, "description": "Struggles with word recognition"}
            },
            "accuracy": {
                "calculation": "correct_words / total_words * 100",
                "excellent": 95,
                "good": 90,
                "fair": 85,
                "needs_improvement": 80
            },
            "pronunciation": {
                "factors": ["clarity", "stress_patterns", "intonation", "rhythm"],
                "scoring": "1-5 scale per factor"
            }
        }
        
        # Grade-level expectations (words per minute)
        self.grade_expectations = {
            "grade_1": {"fall": 10, "winter": 30, "spring": 60},
            "grade_2": {"fall": 50, "winter": 70, "spring": 90},
            "grade_3": {"fall": 70, "winter": 90, "spring": 110},
            "grade_4": {"fall": 90, "winter": 110, "spring": 140},
            "grade_5": {"fall": 110, "winter": 140, "spring": 160},
            "grade_6": {"fall": 140, "winter": 160, "spring": 180}
        }

    async def process(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process student audio recording and provide reading assessment
        
        Args:
            request: Contains audio data, expected text, and assessment parameters
            
        Returns:
            Dict containing transcription, fluency scores, and feedback
        """
        try:
            # Extract and validate input
            audio_data = request.get('audio')
            expected_text = request.get('expected_text', '')
            grade_level = request.get('grade_level', 'grade_3')
            language = request.get('language', 'en')
            assessment_type = request.get('assessment_type', 'reading_fluency')
            
            if not audio_data:
                raise ValueError("No audio data provided")
            
            # Process the audio file
            processed_audio = await self._preprocess_audio(audio_data)
            
            # Transcribe audio using Google Cloud Speech-to-Text
            transcription_result = await self._transcribe_audio(
                processed_audio, language
            )
            
            # Calculate reading metrics
            reading_metrics = await self._calculate_reading_metrics(
                transcription_result, expected_text, grade_level
            )
            
            # Generate detailed assessment
            assessment_feedback = await self._generate_assessment_feedback(
                transcription_result, reading_metrics, expected_text, grade_level, language
            )
            
            # Create improvement suggestions
            improvement_plan = await self._create_improvement_plan(
                reading_metrics, grade_level, language
            )
            
            return {
                "success": True,
                "transcription": transcription_result,
                "reading_metrics": reading_metrics,
                "assessment_feedback": assessment_feedback,
                "improvement_plan": improvement_plan,
                "metadata": {
                    "agent": self.name,
                    "processing_time": self.get_processing_time(),
                    "grade_level": grade_level,
                    "language": language,
                    "assessment_type": assessment_type
                }
            }
            
        except Exception as e:
            self.logger.error(f"Assessment processing failed: {str(e)}")
            return {
                "success": False,
                "error": str(e),
                "agent": self.name
            }

    async def _preprocess_audio(self, audio_data: str) -> bytes:
        """
        Preprocess audio for better speech recognition
        
        Args:
            audio_data: Base64 encoded audio data
            
        Returns:
            Preprocessed audio bytes
        """
        try:
            # Decode base64 audio
            if audio_data.startswith('data:audio'):
                # Remove data URL prefix
                audio_data = audio_data.split(',')[1]
            
            audio_bytes = base64.b64decode(audio_data)
            
            # Load audio with pydub for processing
            audio = AudioSegment.from_file(io.BytesIO(audio_bytes))
            
            # Normalize audio
            audio = audio.normalize()
            
            # Convert to mono if stereo
            if audio.channels > 1:
                audio = audio.set_channels(1)
            
            # Set sample rate to 16kHz (optimal for speech recognition)
            audio = audio.set_frame_rate(16000)
            
            # Apply noise reduction (simple high-pass filter)
            audio = audio.high_pass_filter(300)
            
            # Export to WAV format for speech recognition
            output_buffer = io.BytesIO()
            audio.export(output_buffer, format="wav")
            output_buffer.seek(0)
            
            return output_buffer.read()
            
        except Exception as e:
            self.logger.error(f"Audio preprocessing failed: {str(e)}")
            raise

    async def _transcribe_audio(
        self, 
        audio_bytes: bytes, 
        language: str
    ) -> Dict[str, Any]:
        """
        Transcribe audio using Google Cloud Speech-to-Text
        
        Args:
            audio_bytes: Preprocessed audio data
            language: Language code for transcription
            
        Returns:
            Transcription result with timing and confidence data
        """
        try:
            # Map language codes to Google Cloud Speech language codes
            language_mapping = {
                'en': 'en-IN',  # Indian English
                'hi': 'hi-IN',  # Hindi
                'mr': 'mr-IN',  # Marathi
                'ta': 'ta-IN',  # Tamil
                'bn': 'bn-IN',  # Bengali
                'gu': 'gu-IN',  # Gujarati
                'kn': 'kn-IN',  # Kannada
                'te': 'te-IN',  # Telugu
            }
            
            speech_language = language_mapping.get(language, 'en-IN')
            
            # Configure speech recognition
            config = speech.RecognitionConfig(
                encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
                sample_rate_hertz=16000,
                language_code=speech_language,
                enable_word_time_offsets=True,
                enable_word_confidence=True,
                enable_automatic_punctuation=True,
                model='latest_long',
                use_enhanced=True,
            )
            
            audio = speech.RecognitionAudio(content=audio_bytes)
            
            # Perform speech recognition
            response = self.speech_client.recognize(config=config, audio=audio)
            
            if not response.results:
                return {
                    "transcript": "",
                    "words": [],
                    "confidence": 0.0,
                    "duration": 0.0,
                    "error": "No speech detected"
                }
            
            # Extract detailed results
            result = response.results[0]
            alternative = result.alternatives[0]
            
            # Extract word-level timing and confidence
            words_data = []
            for word_info in alternative.words:
                words_data.append({
                    "word": word_info.word,
                    "start_time": word_info.start_time.total_seconds(),
                    "end_time": word_info.end_time.total_seconds(),
                    "confidence": word_info.confidence
                })
            
            # Calculate total duration
            total_duration = 0
            if words_data:
                total_duration = words_data[-1]["end_time"] - words_data[0]["start_time"]
            
            return {
                "transcript": alternative.transcript,
                "words": words_data,
                "confidence": alternative.confidence,
                "duration": total_duration,
                "word_count": len(words_data)
            }
            
        except Exception as e:
            self.logger.error(f"Audio transcription failed: {str(e)}")
            # Fallback to basic speech recognition
            return await self._fallback_transcription(audio_bytes, language)

    async def _fallback_transcription(
        self, 
        audio_bytes: bytes, 
        language: str
    ) -> Dict[str, Any]:
        """
        Fallback transcription using speech_recognition library
        
        Args:
            audio_bytes: Audio data
            language: Language code
            
        Returns:
            Basic transcription result
        """
        try:
            r = sr.Recognizer()
            
            # Save audio to temporary file
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp_file:
                tmp_file.write(audio_bytes)
                tmp_file.flush()
                
                # Load audio file
                with sr.AudioFile(tmp_file.name) as source:
                    audio = r.record(source)
                
                # Clean up temporary file
                os.unlink(tmp_file.name)
            
            # Transcribe using Google Web Speech API
            transcript = r.recognize_google(audio, language=language)
            
            # Estimate duration using librosa
            try:
                y, sr_rate = librosa.load(io.BytesIO(audio_bytes))
                duration = librosa.get_duration(y=y, sr=sr_rate)
            except:
                duration = 10.0  # Default estimate
            
            word_count = len(transcript.split())
            
            return {
                "transcript": transcript,
                "words": [],  # No word-level timing in fallback
                "confidence": 0.8,  # Estimated confidence
                "duration": duration,
                "word_count": word_count,
                "fallback": True
            }
            
        except Exception as e:
            self.logger.error(f"Fallback transcription failed: {str(e)}")
            return {
                "transcript": "",
                "words": [],
                "confidence": 0.0,
                "duration": 0.0,
                "word_count": 0,
                "error": str(e)
            }

    async def _calculate_reading_metrics(
        self, 
        transcription: Dict[str, Any], 
        expected_text: str, 
        grade_level: str
    ) -> Dict[str, Any]:
        """
        Calculate reading fluency metrics
        
        Args:
            transcription: Transcription result with timing
            expected_text: Expected text for accuracy calculation
            grade_level: Student's grade level
            
        Returns:
            Reading metrics including WPM, accuracy, and fluency scores
        """
        try:
            transcript = transcription.get("transcript", "").lower().strip()
            duration = transcription.get("duration", 1.0)
            word_count = transcription.get("word_count", 0)
            confidence = transcription.get("confidence", 0.0)
            
            # Calculate Words Per Minute (WPM)
            wpm = (word_count / duration) * 60 if duration > 0 else 0
            
            # Calculate accuracy if expected text is provided
            accuracy = 0.0
            if expected_text:
                accuracy = self._calculate_text_accuracy(transcript, expected_text.lower())
            
            # Get grade-level expectations
            expectations = self.grade_expectations.get(grade_level, self.grade_expectations["grade_3"])
            expected_wpm = expectations.get("spring", 110)  # Use spring benchmark
            
            # Calculate fluency score (combination of WPM and accuracy)
            wpm_score = min(100, (wpm / expected_wpm) * 100)
            fluency_score = (wpm_score * 0.6 + accuracy * 0.3 + confidence * 100 * 0.1)
            
            # Determine reading level
            reading_level = self._determine_reading_level(wpm, accuracy, grade_level)
            
            # Calculate pronunciation score (based on confidence)
            pronunciation_score = confidence * 100
            
            return {
                "words_per_minute": round(wpm, 1),
                "accuracy_percentage": round(accuracy, 1),
                "fluency_score": round(fluency_score, 1),
                "pronunciation_score": round(pronunciation_score, 1),
                "confidence": round(confidence * 100, 1),
                "reading_level": reading_level,
                "expected_wpm": expected_wpm,
                "duration_seconds": round(duration, 1),
                "word_count": word_count,
                "grade_appropriate": wpm >= expected_wpm * 0.8
            }
            
        except Exception as e:
            self.logger.error(f"Metrics calculation failed: {str(e)}")
            return {
                "words_per_minute": 0,
                "accuracy_percentage": 0,
                "fluency_score": 0,
                "pronunciation_score": 0,
                "confidence": 0,
                "reading_level": "needs_assessment",
                "error": str(e)
            }

    def _calculate_text_accuracy(self, transcript: str, expected: str) -> float:
        """
        Calculate reading accuracy using edit distance
        
        Args:
            transcript: Transcribed text
            expected: Expected text
            
        Returns:
            Accuracy percentage (0-100)
        """
        try:
            import difflib
            
            # Clean and normalize texts
            transcript_words = transcript.split()
            expected_words = expected.split()
            
            if not expected_words:
                return 0.0
            
            # Calculate similarity using difflib
            matcher = difflib.SequenceMatcher(None, transcript_words, expected_words)
            similarity = matcher.ratio()
            
            return similarity * 100
            
        except Exception as e:
            self.logger.error(f"Accuracy calculation failed: {str(e)}")
            return 0.0

    def _determine_reading_level(self, wpm: float, accuracy: float, grade_level: str) -> str:
        """
        Determine reading level based on WPM and accuracy
        
        Args:
            wpm: Words per minute
            accuracy: Reading accuracy percentage
            grade_level: Student's grade level
            
        Returns:
            Reading level description
        """
        expectations = self.grade_expectations.get(grade_level, self.grade_expectations["grade_3"])
        expected_wpm = expectations.get("spring", 110)
        
        if wpm >= expected_wpm and accuracy >= 95:
            return "excellent"
        elif wpm >= expected_wpm * 0.8 and accuracy >= 90:
            return "good"
        elif wpm >= expected_wpm * 0.6 and accuracy >= 85:
            return "fair"
        else:
            return "needs_improvement"

    async def _generate_assessment_feedback(
        self, 
        transcription: Dict[str, Any], 
        metrics: Dict[str, Any], 
        expected_text: str, 
        grade_level: str, 
        language: str
    ) -> Dict[str, Any]:
        """
        Generate detailed assessment feedback using AI
        
        Args:
            transcription: Transcription results
            metrics: Reading metrics
            expected_text: Expected text
            grade_level: Student's grade level
            language: Assessment language
            
        Returns:
            Detailed feedback and recommendations
        """
        try:
            feedback_prompt = f"""
            Analyze this student reading assessment and provide detailed feedback:
            
            Student Details:
            - Grade Level: {grade_level}
            - Language: {language}
            
            Reading Performance:
            - Words Per Minute: {metrics.get('words_per_minute', 0)}
            - Accuracy: {metrics.get('accuracy_percentage', 0)}%
            - Fluency Score: {metrics.get('fluency_score', 0)}
            - Reading Level: {metrics.get('reading_level', 'unknown')}
            
            Expected Text: {expected_text[:200]}...
            Student's Reading: {transcription.get('transcript', '')[:200]}...
            
            Provide feedback in the following format:
            1. Overall Performance Summary
            2. Strengths Identified
            3. Areas for Improvement
            4. Specific Recommendations
            5. Encouraging Comments
            
            Keep feedback positive, constructive, and appropriate for rural Indian classroom context.
            Suggest practical activities that can be done with minimal resources.
            """
            
            response = self.model.generate_content(feedback_prompt)
            
            return {
                "overall_feedback": response.text,
                "performance_level": metrics.get('reading_level', 'unknown'),
                "strengths": self._identify_strengths(metrics),
                "improvement_areas": self._identify_improvement_areas(metrics),
                "encouragement": self._generate_encouragement(metrics, grade_level)
            }
            
        except Exception as e:
            self.logger.error(f"Feedback generation failed: {str(e)}")
            return {
                "overall_feedback": "Assessment completed. Please review the metrics for detailed performance analysis.",
                "error": str(e)
            }

    def _identify_strengths(self, metrics: Dict[str, Any]) -> List[str]:
        """Identify student's reading strengths"""
        strengths = []
        
        if metrics.get('accuracy_percentage', 0) >= 90:
            strengths.append("Accurate word recognition")
        
        if metrics.get('words_per_minute', 0) >= metrics.get('expected_wpm', 100) * 0.8:
            strengths.append("Good reading speed")
        
        if metrics.get('confidence', 0) >= 80:
            strengths.append("Clear pronunciation")
        
        if metrics.get('fluency_score', 0) >= 80:
            strengths.append("Smooth reading flow")
        
        return strengths if strengths else ["Participation in reading assessment"]

    def _identify_improvement_areas(self, metrics: Dict[str, Any]) -> List[str]:
        """Identify areas needing improvement"""
        areas = []
        
        if metrics.get('accuracy_percentage', 0) < 85:
            areas.append("Word recognition accuracy")
        
        if metrics.get('words_per_minute', 0) < metrics.get('expected_wpm', 100) * 0.7:
            areas.append("Reading speed and fluency")
        
        if metrics.get('confidence', 0) < 70:
            areas.append("Pronunciation clarity")
        
        return areas if areas else ["Continue practicing for improvement"]

    def _generate_encouragement(self, metrics: Dict[str, Any], grade_level: str) -> str:
        """Generate encouraging feedback"""
        reading_level = metrics.get('reading_level', 'developing')
        
        encouragements = {
            'excellent': "Outstanding reading! You're reading at an advanced level.",
            'good': "Great job! Your reading skills are developing well.",
            'fair': "Good effort! With practice, you'll become an even better reader.",
            'needs_improvement': "Keep practicing! Every reader improves with time and effort."
        }
        
        return encouragements.get(reading_level, "Keep up the good work in your reading journey!")

    async def _create_improvement_plan(
        self, 
        metrics: Dict[str, Any], 
        grade_level: str, 
        language: str
    ) -> Dict[str, Any]:
        """
        Create personalized improvement plan
        
        Args:
            metrics: Reading assessment metrics
            grade_level: Student's grade level
            language: Assessment language
            
        Returns:
            Structured improvement plan with activities
        """
        try:
            plan_prompt = f"""
            Create a personalized reading improvement plan for a {grade_level} student:
            
            Current Performance:
            - WPM: {metrics.get('words_per_minute', 0)}
            - Accuracy: {metrics.get('accuracy_percentage', 0)}%
            - Reading Level: {metrics.get('reading_level', 'unknown')}
            
            Create a plan with:
            1. Daily practice activities (15-20 minutes)
            2. Weekly goals
            3. Resources needed (minimal, rural-friendly)
            4. Progress tracking methods
            5. Fun reading games
            
            Focus on practical activities for rural Indian classrooms with limited resources.
            Include family involvement suggestions.
            """
            
            response = self.model.generate_content(plan_prompt)
            
            return {
                "improvement_plan": response.text,
                "target_wpm": metrics.get('expected_wpm', 100),
                "current_level": metrics.get('reading_level', 'unknown'),
                "practice_duration": "15-20 minutes daily",
                "review_period": "2 weeks"
            }
            
        except Exception as e:
            self.logger.error(f"Improvement plan generation failed: {str(e)}")
            return {
                "improvement_plan": "Continue regular reading practice. Focus on accuracy and gradually increase speed.",
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
            "description": "Evaluates student reading fluency and provides detailed feedback",
            "input_types": ["audio", "text"],
            "output_types": ["transcription", "assessment", "feedback", "improvement_plan"],
            "supported_formats": ["MP3", "WAV", "M4A"],
            "max_audio_length": "5 minutes",
            "supported_languages": ["en-IN", "hi-IN", "mr-IN", "ta-IN", "bn-IN", "gu-IN"],
            "assessment_types": ["reading_fluency", "pronunciation", "comprehension"],
            "grade_levels": list(self.grade_expectations.keys()),
            "processing_time": "30-60 seconds per audio file"
        } 