# 🧠 Sahaayak AI - Agentic Teaching Assistant Platform

**Empowering Rural Education in India with AI-Powered Teaching Tools**

Sahaayak AI is a comprehensive full-stack platform designed to support teachers in under-resourced, multi-grade classrooms across rural India. The platform combines advanced AI capabilities with an intuitive mobile-first interface to help teachers create content, generate worksheets, assess students, and plan lessons effectively.

## 🌟 Features

### 📚 **Content Generator**
- Generate localized stories and educational content
- Support for multiple Indian languages (Hindi, Marathi, Tamil, Bengali, Gujarati)
- Age-appropriate content creation for different grade levels

### 🖼️ **Worksheet Maker**
- Upload textbook images and convert them into worksheets
- Multi-grade adaptation using Gemini Vision AI
- Customizable difficulty levels and subjects

### 🧠 **Ask Sahaayak**
- Interactive AI teaching assistant
- Context-aware responses for educational queries
- Classroom management and teaching strategy suggestions

### 🎨 **Visual Aids Generator**
- Create blackboard-friendly diagrams and illustrations
- Text-to-visual conversion for complex concepts
- Educational diagram templates

### 🎤 **Reading Assessment**
- Audio-based fluency evaluation using Vertex AI
- Automated transcript generation and scoring
- Progress tracking for individual students

### 📅 **Weekly Planner**
- Automated lesson plan generation
- Subject-wise activity suggestions
- Grade-appropriate learning objectives

## 🏗️ Architecture

### **Frontend (Flutter)**
```
Frontend/
├── lib/
│   ├── core/           # Core services, themes, config
│   ├── features/       # Feature-based modules
│   └── main.dart       # App entry point
├── android/            # Android platform files
├── ios/               # iOS platform files
└── test/              # Widget and integration tests
```

### **Backend (Python FastAPI)**
```
Backend/
├── agents/            # AI agent classes
├── api/              # FastAPI routes
├── firebase/         # Firebase configuration
├── utils/            # Helper utilities
└── main.py           # FastAPI entry point
```

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.16.0 or higher)
- **Python** (3.11 or higher)
- **Firebase Account** with Realtime Database enabled
- **Google Cloud Account** with Generative AI APIs enabled
- **Android Studio** or **Xcode** (for mobile development)

### 🔧 Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd Backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   
   # On Windows
   venv\Scripts\activate
   
   # On macOS/Linux
   source venv/bin/activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**
   ```bash
   cp .env.template .env
   ```
   
   Edit `.env` file with your credentials:
   ```env
   # Google AI API Keys
   GOOGLE_API_KEY=your_google_generative_ai_key
   VERTEX_AI_PROJECT_ID=your_vertex_ai_project_id
   VERTEX_AI_LOCATION=your_region
   
   # Firebase Configuration
   FIREBASE_PROJECT_ID=your_firebase_project_id
   FIREBASE_PRIVATE_KEY=your_firebase_private_key
   FIREBASE_CLIENT_EMAIL=your_firebase_client_email
   
   # API Configuration
   API_HOST=localhost
   API_PORT=8000
   DEBUG=True
   ```

5. **Initialize Firebase**
   - Download your Firebase service account key
   - Place it in `Backend/firebase/serviceAccountKey.json`

6. **Run the backend server**
   ```bash
   python main.py
   ```
   
   The API will be available at `http://localhost:8000`

### 📱 Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd Frontend
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase for Flutter**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   flutterfire configure
   ```

4. **Run the Flutter app**
   ```bash
   # For development (debug mode)
   flutter run
   
   # For Android device/emulator
   flutter run -d android
   
   # For iOS device/simulator (macOS only)
   flutter run -d ios
   
   # For Chrome (web development)
   flutter run -d chrome
   ```

## 🔧 Development Commands

### Backend Commands

```bash
# Run development server with auto-reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Run with specific log level
uvicorn main:app --reload --log-level debug

# Run tests
python -m pytest tests/ -v

# Format code with black
black . --line-length 88

# Lint with flake8
flake8 . --max-line-length 88

# Type checking with mypy
mypy . --ignore-missing-imports
```

### Frontend Commands

```bash
# Run app in debug mode
flutter run --debug

# Run app in release mode
flutter run --release

# Run tests
flutter test

# Run widget tests with coverage
flutter test --coverage

# Analyze code quality
flutter analyze

# Format code
dart format . -l 80

# Build APK for Android
flutter build apk --release

# Build iOS app (requires macOS)
flutter build ios --release

# Build web app
flutter build web

# Clean build cache
flutter clean && flutter pub get
```

## 🐳 Docker Deployment

### Backend Docker

1. **Build Docker image**
   ```bash
   cd Backend
   docker build -t sahaayak-ai-backend .
   ```

2. **Run container**
   ```bash
   docker run -p 8000:8000 \
     -e GOOGLE_API_KEY=your_key \
     -e FIREBASE_PROJECT_ID=your_project \
     sahaayak-ai-backend
   ```

### Docker Compose (Full Stack)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up --build
```

## 📚 API Documentation

### Authentication
All API endpoints require Firebase JWT authentication:
```http
Authorization: Bearer <firebase_jwt_token>
```

### Main Endpoints

#### Content Generation
```http
POST /api/query
Content-Type: application/json

{
  "text": "Create a story about farmers in Hindi",
  "language": "hi",
  "grade_levels": ["grade_3_4"],
  "task_type": "content_generation"
}
```

#### Worksheet Generation
```http
POST /api/generate-worksheet
Content-Type: application/json

{
  "image": "data:image/jpeg;base64,<base64_string>",
  "target_grades": ["grade_3_4", "grade_5_6"],
  "language": "hi",
  "subject": "mathematics"
}
```

#### Audio Assessment
```http
POST /api/assess-audio
Content-Type: multipart/form-data

audio: <audio_file.mp3>
language: hi
grade_level: grade_3_4
```

#### Lesson Planning
```http
GET /api/lesson-plan?subject=mathematics&grade=grade_4&language=hi
```

For complete API documentation, visit `http://localhost:8000/docs` when running the backend.

## 🧪 Testing

### Backend Testing

```bash
# Run all tests
python -m pytest

# Run with coverage
python -m pytest --cov=. --cov-report=html

# Run specific test file
python -m pytest tests/test_agents.py -v

# Run tests with different environments
python -m pytest tests/ --env=staging
```

### Frontend Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Run specific test file
flutter test test/features/auth/auth_test.dart
```

## 🌍 Localization

### Supported Languages
- English (en)
- Hindi (hi) - हिंदी
- Marathi (mr) - मराठी  
- Tamil (ta) - தமிழ்
- Bengali (bn) - বাংলা
- Gujarati (gu) - ગુજરાતી

### Adding New Languages

1. **Backend**: Update language codes in `utils/config.py`
2. **Frontend**: Add translations in `lib/core/localization/`
3. **AI Models**: Configure language-specific prompts in agent classes

## 🔒 Security

### API Security
- Firebase JWT authentication for all endpoints
- Input validation and sanitization
- Rate limiting on AI service calls
- CORS configuration for web clients

### Data Privacy
- No sensitive data logging
- Encrypted data transmission
- Firebase security rules implementation
- User data anonymization options

## 📊 Monitoring & Analytics

### Backend Monitoring
```bash
# View application logs
tail -f logs/app.log

# Monitor API performance
curl http://localhost:8000/health

# Check Firebase connection
curl http://localhost:8000/api/health/firebase
```

### Performance Metrics
- API response times
- AI service call latencies
- User session analytics
- Error rate monitoring

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make changes and commit**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

4. **Run tests**
   ```bash
   # Backend tests
   cd Backend && python -m pytest
   
   # Frontend tests  
   cd Frontend && flutter test
   ```

5. **Push and create pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

### Code Standards

- **Backend**: Follow PEP 8, use black for formatting
- **Frontend**: Follow Dart style guide, use dart format
- **Commits**: Use conventional commit messages
- **Documentation**: Update README for new features

## 📝 Environment Variables

### Backend (.env)
```env
# Required
GOOGLE_API_KEY=your_google_generative_ai_key
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_PRIVATE_KEY=your_firebase_private_key
FIREBASE_CLIENT_EMAIL=your_firebase_client_email

# Optional
VERTEX_AI_PROJECT_ID=your_vertex_ai_project_id
VERTEX_AI_LOCATION=us-central1
API_HOST=localhost
API_PORT=8000
DEBUG=True
LOG_LEVEL=INFO
REDIS_URL=redis://localhost:6379
```

### Frontend (Flutter)
Firebase configuration is handled through `firebase_options.dart` generated by FlutterFire CLI.

## 🚀 Deployment

### Production Deployment

#### Backend (Firebase Cloud Run)
```bash
# Build and deploy
gcloud run deploy sahaayak-ai-backend \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

#### Frontend (Firebase Hosting)
```bash
# Build web version
flutter build web

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

#### Mobile App Stores
```bash
# Android (Google Play Store)
flutter build appbundle --release

# iOS (Apple App Store)
flutter build ios --release
```

## 📞 Support

### Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google AI Documentation](https://ai.google.dev/docs)

### Community
- **Issues**: Report bugs and feature requests
- **Discussions**: Ask questions and share ideas
- **Contributing**: See CONTRIBUTING.md for guidelines

### Contact
- **Email**: support@sahaayak-ai.com
- **Website**: https://sahaayak-ai.com
- **Documentation**: https://docs.sahaayak-ai.com

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Google AI team for Generative AI APIs
- Firebase team for backend infrastructure
- Flutter team for mobile framework
- Open source contributors and rural teachers who inspired this project

---

**Made with ❤️ for rural education in India** 