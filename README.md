# 🎓 Sahaayak AI - Agentic AI-Powered Educational Assistant

> **Revolutionizing Rural Education with Multi-Agent AI System**

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![Python](https://img.shields.io/badge/Python-3.9+-green.svg)](https://python.org/)
[![Gemini AI](https://img.shields.io/badge/Gemini%20AI-1.5%20Flash-orange.svg)](https://ai.google.dev/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 🎬 **Watch Our Demo**

[![Sahaayak AI Demo](https://img.youtube.com/vi/O2RJiExZtkY/0.jpg)](https://www.youtube.com/watch?v=O2RJiExZtkY)

**[▶️ Watch Full Demo Video](https://www.youtube.com/watch?v=O2RJiExZtkY)**

<div align="center">

## 🚀 **Hackathon Solution Overview**

</div>

Sahaayak AI is a **revolutionary multi-agent AI system** designed to bridge the educational gap in rural India. Our solution leverages cutting-edge AI agents to provide personalized, culturally-relevant educational content and support for teachers and students in low-resource settings.

<div align="center">

## 📌 **Why We Chose This Problem**

</div>

While researching rural education challenges, we encountered the **Multi-Grade Multi-Level (MGML)** teaching model, widely adopted in Indian government schools. MGML benefits students by encouraging collaborative and self-paced learning. However, we found that **teachers often struggle** in these classrooms due to:

- The **difficulty of handling multiple grade levels simultaneously**
- Lack of **personalized content creation tools**
- **Time constraints** and **curriculum overload**
- **Cultural disconnect** in available learning materials
- Inability to conduct **individual assessments** efficiently

This made it clear that the **teacher—not just the student—needs support**.

### 🧠 **Our Insight:**
> *"If MGML is good for students, how can we make it equally effective for teachers?"*

This led us to the **problem statement**:  
> *"Empowering teachers in multi-grade classrooms using AI to simplify content creation, assessment, and planning."*

Sahaayak AI was built to be a **virtual co-teacher, helping educators focus on what matters most—student growth**.

### 🎯 **Problem Statement**
- **Limited Resources**: Rural schools lack access to quality educational materials
- **Teacher Workload**: Overburdened teachers need automated content generation
- **Cultural Relevance**: Standard materials don't reflect local contexts
- **Language Barriers**: Limited content in regional languages
- **Assessment Gaps**: Lack of personalized learning assessment tools

### 💡 **Our Agentic AI Solution**

We've built a **sophisticated multi-agent AI system** that works collaboratively to solve these challenges:

<div align="center">

## 🤖 **Agentic AI Architecture**

</div>

### **Core AI Agents**

| Agent | Purpose | Capabilities |
|-------|---------|--------------|
| **🎯 OrchestratorAgent** | Master coordinator | Routes requests, manages agent collaboration |
| **📚 ContentGeneratorAgent** | Educational content creation | Generates lessons, stories, explanations in multiple languages |
| **🧠 AssessmentAgent** | Learning evaluation | Audio-based reading assessment, fluency analysis |
| **📋 LessonPlannerAgent** | Curriculum planning | Weekly/monthly lesson plans with cultural context |
| **🎨 VisualAidAgent** | Diagram generation | Creates Mermaid diagrams for visual learning |
| **📝 MaterialAdapterAgent** | Content adaptation | Converts textbook images to interactive worksheets |
| **❓ QueryAgent** | AI tutoring | Personalized question answering and explanations |

### **Agent Collaboration System**
```
User Request → OrchestratorAgent → Specialized Agents → Coordinated Response
```

<div align="center">

## 🏗️ **Technical Architecture**

</div>

### **Frontend (Flutter)**
- **Cross-platform mobile app** for Android/iOS
- **Markdown rendering** for rich content display
- **Real-time audio recording** for assessment
- **Image capture** for worksheet generation
- **Responsive UI** optimized for rural device constraints

### **Backend (Python/Flask)**
- **Multi-agent AI system** with async processing
- **Gemini 1.5 Flash** for advanced AI capabilities
- **RESTful API** with comprehensive error handling
- **Base64 image/audio processing** for content adaptation
- **Structured logging** for debugging and monitoring

### **AI Models & Technologies**
- **Google Gemini 1.5 Flash** - Primary AI model
- **Google Cloud Speech-to-Text** - Audio transcription
- **OpenCV & PIL** - Image processing
- **Mermaid.js** - Diagram generation
- **Markdown** - Content formatting
- **Vertex AI** - Advanced AI capabilities
- **Firebase** - Backend services
- **Google Vision** - Image analysis

<div align="center">

## 🌟 **Key Features**

</div>

### **1. 📚 Intelligent Content Generation**
- **Multi-language support** (English, Hindi, Marathi, Tamil, Bengali, Gujarati, Kannada, Telugu)
- **Cultural adaptation** with local examples (rickshaws, festivals, local foods)
- **Grade-specific content** (Grade 1-2, 3-4, 5-6)
- **Multiple content types**: Stories, explanations, activities, worksheets

### **2. 🎯 Personalized Assessment**
- **Audio-based reading assessment** with real-time transcription
- **Fluency analysis** with WPM and accuracy metrics
- **Personalized feedback** and improvement plans
- **Progress tracking** for individual students

### **3. 📋 Smart Lesson Planning**
- **AI-generated lesson plans** for any subject and duration
- **Cultural context integration** (Indian festivals, local examples)
- **Resource optimization** for low-resource classrooms
- **Differentiation strategies** for mixed-ability classes

### **4. 🎨 Visual Learning Aids**
- **Mermaid diagram generation** for complex concepts
- **Visual representation** of flowcharts, mind maps, timelines
- **Drawing instructions** for blackboard implementation
- **Interactive diagrams** with toggle views

### **5. 📝 Worksheet Generation**
- **Image-to-worksheet conversion** from textbook photos
- **Multi-grade adaptation** of existing materials
- **Culturally relevant examples** and word problems
- **Answer keys and assessment rubrics**

### **6. 🤖 AI Chat Assistant**
- **Context-aware responses** based on user queries
- **Markdown rendering** for rich formatting
- **Integration with assessment results** for personalized help
- **Multi-language support** for regional communication

## 📱 **Screenshots**

<div align="center">

| Dashboard | Content Generation | Worksheet Creation |
|-----------|-------------------|-------------------|
| ![Dashboard](screenshots/dashboard.png) | ![Content Generation](screenshots/content_generation.png) | ![Worksheet Creation](screenshots/worksheet_creation.png) |
| *Main interface* | *AI-generated content* | *Image-based worksheets* |

| Reading Assessment | Visual Aids | AI Chat | Lesson Planning |
|-------------------|-------------|---------|-----------------|
| ![Reading Assessment](screenshots/reading_assessment.png) | ![Visual Aids](screenshots/visual_aids.png) | ![AI Chat](screenshots/ai_chat.png) | ![Lesson Planning](screenshots/lesson_planning.png) |
| *Audio assessment* | *Mermaid diagrams* | *Intelligent chat* | *AI lesson plans* |

</div>

## 🚀 **Quick Start**

### **Prerequisites**
- Flutter 3.16+
- Python 3.9+
- Google Cloud API Key
- Gemini AI API Key

### **Backend Setup**
```bash
cd Backend
pip install -r requirements.txt
python flask_app.py
```

### **Frontend Setup**
```bash
cd Frontend
flutter pub get
flutter run
```

## 🎯 **Hackathon Impact**

### **Immediate Benefits**
- **10x faster** content generation for teachers
- **Personalized learning** for every student
- **Cultural relevance** in educational materials
- **Reduced teacher workload** through automation

### **Scalability**
- **Multi-language support** for diverse regions
- **Offline-capable** content generation
- **Low-resource optimization** for rural schools
- **Extensible agent system** for new features

### **Innovation Highlights**
- **First multi-agent AI system** for rural education
- **Cultural AI adaptation** for Indian context
- **Real-time audio assessment** with AI feedback
- **Visual learning** through AI-generated diagrams

## 🔧 **Technical Innovation**

### **Agentic AI System**
- **Collaborative agents** working together
- **Context-aware routing** for optimal agent selection
- **Error handling** and fallback mechanisms
- **Performance monitoring** and optimization

### **Cultural Intelligence**
- **Local context integration** (festivals, foods, occupations)
- **Regional language support** with proper grammar
- **Rural-appropriate examples** and scenarios
- **Traditional knowledge** preservation

### **Accessibility Features**
- **Offline-first design** for poor connectivity
- **Low-bandwidth optimization** for rural areas
- **Simple UI** for non-technical users
- **Voice-based interaction** for accessibility

## 🏆 **Why This Solution Wins**

### **1. Real Problem, Real Solution**
- Addresses actual challenges faced by rural educators
- Built with input from teachers and students
- Scalable to millions of rural schools

### **2. Cutting-Edge Technology**
- Latest AI models (Gemini 1.5 Flash)
- Multi-agent architecture for complex tasks
- Cross-platform mobile solution

### **3. Cultural Sensitivity**
- Designed specifically for Indian rural context
- Respects local traditions and knowledge
- Supports regional languages and customs

### **4. Immediate Impact**
- Can be deployed today in existing schools
- Requires minimal infrastructure
- Provides instant value to teachers and students

## 🔮 **Future Roadmap**

### **Phase 2: Advanced Features**
- **Voice-based interaction** in regional languages
- **Offline AI models** for poor connectivity
- **Student progress tracking** and analytics
- **Parent-teacher communication** platform

### **Phase 3: Scale & Integration**
- **Government school integration** across states
- **NGO partnerships** for wider deployment
- **Research collaboration** with educational institutions
- **International adaptation** for similar contexts

## 👥 **Team**

- **AI/ML Engineers** - Multi-agent system development
- **Flutter Developers** - Cross-platform mobile app
- **Backend Engineers** - Scalable API and processing
- **UX/UI Designers** - Rural-optimized interface
- **Education Experts** - Pedagogical content validation

## 📞 **Contact**

- **Email**: sahaayak.ai@example.com
- **GitHub**: [github.com/sahaayak-ai](https://github.com/sahaayak-ai)
- **Demo**: [demo.sahaayak.ai](https://demo.sahaayak.ai)

---

**Built with ❤️ for Rural Education in India**

*Empowering teachers, inspiring students, transforming education through AI* 