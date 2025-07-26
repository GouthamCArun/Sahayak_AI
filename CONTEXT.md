🧠 SAHAAYAK AI — FULL STACK GENERATION PROMPT FOR CURSOR IDE / FIREBASE STUDIO
🔧 BACKEND PROMPT — sahaayak-ai-backend (use this in Cursor or Firebase Studio)
You are an advanced code-generation AI building the backend for Sahaayak AI, an agentic teaching assistant platform that supports teachers in under-resourced, multi-grade classrooms in India. Your job is to generate a complete, modular, production-ready backend system using FastAPI, integrated with Google's Generative AI SDK, Firebase Realtime Database, and Vertex AI APIs.

✅ Core Capabilities
The backend should support the following features:

Generate localized content based on natural language prompts (e.g., "Create a story in Marathi about farmers").

Accept textbook image uploads and adapt them into worksheets for multiple grade levels.

Provide simplified explanations for complex student questions.

Generate simple educational diagrams or visuals.

Evaluate students’ reading fluency from audio input.

Auto-generate weekly lesson plans and learning activities.

🧩 Architecture & Agents
Structure the app with the following modular Python agents, each as its own class with clean interfaces:

OrchestratorAgent: Detects intent from request and routes to appropriate agent.

ContentGeneratorAgent: Creates local-language, age-appropriate stories/lessons.

MaterialAdapterAgent: Uses Gemini Vision to extract content from textbook images and outputs worksheets for multiple grades.

KnowledgeExplainerAgent: Simplifies complex questions into digestible explanations.

VisualAidAgent: Converts text prompts into diagrams or sketches.

AssessmentAgent: Uses Vertex AI Speech-to-Text to transcribe and evaluate student audio.

LessonPlannerAgent: Generates week-long structured lesson plans and game ideas.

ContextMemoryAgent: Maintains teacher metadata and task history in Firebase.

⚙️ Technology Stack
Language: Python 3.11+

Framework: FastAPI

Google APIs: Google Generative AI, Gemini Vision, Vertex AI STT

Auth & DB: Firebase Realtime DB + Firebase Auth

Image/Audio: Pillow or OpenCV, audio decoding

Deployment: Docker + Firebase Cloud Run

🧾 API Endpoints
Expose the following routes with full validation, logging, and Firebase JWT protection:

pgsql
Copy
Edit
POST /api/query            -> Accepts input + task; returns generated result.
GET  /api/history          -> Returns user’s recent interactions.
GET  /api/lesson-plan      -> Returns structured weekly lesson plan.
POST /api/assess-audio     -> Accepts audio; returns transcript + fluency score.
POST /api/generate-diagram -> Generates blackboard-friendly diagram.
Each POST should accept either:

Text

Image (base64 or file)

Audio (MP3/WAV)

Optional: language (ISO code), grade_levels

🔐 Firebase Integration
Use Firebase Admin SDK for:

Auth (JWT validation)

Storing:

Teacher profile (name, grades, language)

Recent queries and generated content

Audio results and links

Provide Firebase security rules (sample read/write access rules).

📦 Project Structure
bash
Copy
Edit
sahaayak_ai/
│
├── agents/                # All agent classes
│   ├── orchestrator.py
│   ├── content_generator.py
│   ├── material_adapter.py
│   ├── ...
│
├── api/                   # FastAPI routes
│   ├── routes.py
│
├── firebase/              # Firebase auth, config
│   ├── firebase_config.py
│
├── utils/                 # Helper functions
│   ├── logging.py
│   ├── validators.py
│
├── main.py                # FastAPI entrypoint
├── requirements.txt
├── Dockerfile
├── .env.template
└── README.md
🔧 Must-Have Features
Input validation

Central error handling

Structured logging

Environment variable usage

Firebase Auth token verification

Caching via Firebase if possible

🧪 Test Plan
Include sample curl/Postman examples for:

Text prompt → Story generation

Image prompt → Worksheet generation

Audio prompt → Fluency assessment

Dummy Firebase user with metadata

Include placeholder assets: textbook.jpg, student_read.mp3

📦 Deployment
Provide Dockerfile for Cloud Run

Use Firebase Hosting for API proxy if needed

Use .env for Gemini/Vertex/Firebase keys

🎨 FRONTEND PROMPT — sahaayak-ai-flutter-ui (mobile-first, for Cursor or Firebase Studio)
You are building a modern, mobile-first Flutter UI for an education app called Sahaayak AI, which assists rural teachers in multi-grade Indian classrooms. The app should be minimal, touch-friendly, multilingual, and optimized for low-resource environments.

🧭 Home Screen
A clean dashboard with 2x3 grid of rounded cards:

Icon	Title
📚	Content Generator
🖼️	Worksheet Maker
🧠	Ask Sahaayak
🎨	Blackboard Diagrams
🎤	Reading Assessment
📅	Weekly Planner

Each card navigates to a simple input screen (text/image/audio) and a result screen.

💬 Interaction Screens
Each task page should have:

A large mic icon (for voice input)

Optional text input

"Submit" button

Loading spinner

Result display with export/share/save options

🖼 Diagram & Worksheet Generator
Accepts text/image input

Shows generated diagram (PNG/SVG or image)

Download/Copy/Save options

🎤 Reading Assessment
Upload/Record student audio

Shows:

Transcript

Accuracy %

Feedback

Store result in Firebase via API

📅 Lesson Planner UI
Dropdowns for Grade + Subject

Calendar/week picker

Shows per-day cards:

📌 Topic

🎯 Objective

🧩 Game/Activity

⚙️ Additional UI Elements
Profile (grades taught, language)

Offline Mode Support (toggle)

Firebase Auth (email/password or OTP)

Local language switcher (e.g., Hindi, Marathi, Tamil)

🪄 UI Styling
Theme: Light + earthy tone palette

Font: Google Sans or Poppins

Layout: Material 3 components

Animations: Subtle page transitions and Lottie loaders

📦 Flutter Structure
css
Copy
Edit
Frontend/
    lib/
    │
    ├── screens/
    │   ├── home_screen.dart
    │   ├── content_input.dart
    │   ├── worksheet_input.dart
    │   ├── assessment_screen.dart
    │
    ├── widgets/
    │   ├── card_grid.dart
    │   ├── result_display.dart
    │   ├── mic_input.dart
    │
    ├── services/
    │   ├── api_service.dart
    │   ├── firebase_service.dart
    │
    ├── models/
    │   ├── response_models.dart
    │
    ├── main.dart
    └── routes.dart
Let me know if you want:

Figma-style visuals

Firebase rules generator

PDF exporter plugin

Flutter Web support

Ready to plug both ends and fly, captain. 💻📱💥