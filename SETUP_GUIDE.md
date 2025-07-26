# 🔧 Sahaayak AI: Complete Setup Configuration Guide

This guide covers all the necessary configurations for Google Cloud Console and Firebase to run Sahaayak AI successfully.

## 📋 Prerequisites

- Google Account with billing enabled
- Admin access to create projects
- Basic understanding of Firebase and Google Cloud Platform

---

## 🔥 Firebase Console Configuration

### Step 1: Create Firebase Project

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Click "Create a project" or "Add project"

2. **Project Setup**
   ```
   Project name: sahaayak-ai-production (or your preferred name)
   Enable Google Analytics: Yes (recommended)
   Analytics location: India
   ```

3. **Wait for project creation** (usually takes 1-2 minutes)

### Step 2: Enable Authentication

1. **Navigate to Authentication**
   - In Firebase console, go to "Authentication" → "Get started"

2. **Configure Sign-in Methods**
   ```
   Enable the following providers:
   ✅ Email/Password
   ✅ Phone (for OTP-based login)
   ✅ Google (optional, for teacher convenience)
   ```

3. **Email/Password Setup**
   - Click "Email/Password" → Enable
   - Enable "Email link (passwordless sign-in)" if desired

4. **Phone Authentication Setup**
   - Click "Phone" → Enable
   - Add test phone numbers for development:
   ```
   Test Phone Numbers:
   +91 9999999999 → 123456
   +91 8888888888 → 654321
   ```

5. **Authorized Domains**
   ```
   Add your domains:
   - localhost (for development)
   - your-domain.com (for production)
   - your-app-name.web.app (Firebase Hosting)
   ```

### Step 3: Setup Realtime Database

1. **Create Realtime Database**
   - Go to "Realtime Database" → "Create Database"
   - Choose location: `asia-southeast1` (Singapore - closest to India)
   - Start in **locked mode** (we'll configure rules later)

2. **Database Rules Configuration**
   ```json
   {
     "rules": {
       "users": {
         "$uid": {
           ".read": "$uid === auth.uid",
           ".write": "$uid === auth.uid"
         }
       },
       "teacher_profiles": {
         "$uid": {
           ".read": "$uid === auth.uid",
           ".write": "$uid === auth.uid"
         }
       },
       "content_history": {
         "$uid": {
           ".read": "$uid === auth.uid",
           ".write": "$uid === auth.uid",
           ".indexOn": ["timestamp", "content_type"]
         }
       },
       "lesson_plans": {
         "$uid": {
           ".read": "$uid === auth.uid",
           ".write": "$uid === auth.uid",
           ".indexOn": ["subject", "grade", "created_at"]
         }
       },
       "assessment_results": {
         "$uid": {
           ".read": "$uid === auth.uid",
           ".write": "$uid === auth.uid",
           ".indexOn": ["student_id", "assessment_date"]
         }
       },
       "worksheets": {
         "$uid": {
           ".read": "$uid === auth.uid",
           ".write": "$uid === auth.uid",
           ".indexOn": ["subject", "grade_level", "created_at"]
         }
       }
     }
   }
   ```

### Step 4: Configure Cloud Storage

1. **Setup Cloud Storage**
   - Go to "Storage" → "Get started"
   - Choose "Start in production mode"
   - Location: `asia-south1` (Mumbai, India)

2. **Storage Security Rules**
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       // Allow authenticated users to upload images and audio
       match /uploads/{userId}/{allPaths=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       
       // Generated content (worksheets, diagrams)
       match /generated/{userId}/{allPaths=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       
       // Audio files for assessment
       match /audio/{userId}/{allPaths=**} {
         allow read, write: if request.auth != null && 
                             request.auth.uid == userId &&
                             resource.size < 10 * 1024 * 1024; // 10MB limit
       }
       
       // Public assets (if needed)
       match /public/{allPaths=**} {
         allow read;
       }
     }
   }
   ```

### Step 5: Setup Firebase Hosting (Optional)

1. **Enable Hosting**
   - Go to "Hosting" → "Get started"
   - Install Firebase CLI (we'll cover this later)

2. **Configure Hosting**
   ```json
   {
     "hosting": {
       "public": "build/web",
       "ignore": [
         "firebase.json",
         "**/.*",
         "**/node_modules/**"
       ],
       "rewrites": [
         {
           "source": "**",
           "destination": "/index.html"
         }
       ],
       "headers": [
         {
           "source": "**/*.@(js|css)",
           "headers": [
             {
               "key": "Cache-Control",
               "value": "max-age=31536000"
             }
           ]
         }
       ]
     }
   }
   ```

---

## ☁️ Google Cloud Console Configuration

### Step 1: Access Google Cloud Console

1. **Navigate to Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Select your Firebase project (it's automatically created in GCP)

2. **Enable Billing**
   - Go to "Billing" → Link a billing account
   - This is required for AI APIs

### Step 2: Enable Required APIs

Enable the following APIs in "APIs & Services" → "Library":

```
✅ Firebase Admin SDK API
✅ Firebase Authentication API
✅ Firebase Realtime Database API
✅ Cloud Storage API
✅ Generative AI API
✅ Vertex AI API
✅ Cloud Speech-to-Text API
✅ Cloud Text-to-Speech API
✅ Cloud Translation API
✅ Cloud Vision API
✅ Identity and Access Management (IAM) API
```

### Step 3: Create Service Account

1. **Create Service Account**
   - Go to "IAM & Admin" → "Service Accounts"
   - Click "Create Service Account"

2. **Service Account Details**
   ```
   Service account name: sahaayak-ai-backend
   Description: Backend service for Sahaayak AI platform
   ```

3. **Grant Roles**
   ```
   ✅ Firebase Admin SDK Administrator Service Agent
   ✅ Firebase Realtime Database Admin
   ✅ Storage Admin
   ✅ Vertex AI User
   ✅ Speech Client
   ✅ Translation Client
   ✅ Vision API Client
   ```

4. **Generate Key**
   - Click "Create Key" → JSON format
   - Download and save as `serviceAccountKey.json`
   - **Keep this file secure and never commit to version control**

### Step 4: Configure Vertex AI

1. **Enable Vertex AI**
   - Go to "Vertex AI" → "Enable API"
   - Choose region: `asia-south1` (Mumbai)

2. **Model Access Setup**
   ```
   Enable access to:
   ✅ Gemini Pro
   ✅ Gemini Pro Vision
   ✅ Text-to-Speech API
   ✅ Speech-to-Text API
   ```

3. **Quota Configuration**
   - Go to "Quotas" → Search for "Vertex AI"
   - Increase quotas if needed:
   ```
   Vertex AI API requests: 1000/minute
   Gemini Pro requests: 60/minute
   Text generation characters: 1M/day
   ```

### Step 5: Setup Cloud Speech-to-Text

1. **Enable Speech-to-Text API**
   - API already enabled in step 2

2. **Configure Language Support**
   ```
   Supported Languages:
   ✅ en-IN (English - India)
   ✅ hi-IN (Hindi - India)
   ✅ mr-IN (Marathi - India)
   ✅ ta-IN (Tamil - India)
   ✅ bn-IN (Bengali - India)
   ✅ gu-IN (Gujarati - India)
   ```

3. **Audio Configuration**
   ```
   Supported formats: FLAC, WAV, MP3
   Sample rate: 16000 Hz
   Encoding: LINEAR16, FLAC, MP3
   ```

### Step 6: Configure Google AI Studio

1. **Get Generative AI API Key**
   - Visit: https://makersuite.google.com/app/apikey
   - Create API key for your project
   - **Store securely - this is for Gemini API access**

2. **Configure API Restrictions**
   ```
   API restrictions:
   ✅ Generative Language API
   ✅ Enable for specific IPs (optional)
   ```

---

## 🔐 Security Configuration

### Step 1: IAM Permissions

```json
{
  "bindings": [
    {
      "role": "roles/firebase.admin",
      "members": [
        "serviceAccount:sahaayak-ai-backend@your-project.iam.gserviceaccount.com"
      ]
    },
    {
      "role": "roles/aiplatform.user",
      "members": [
        "serviceAccount:sahaayak-ai-backend@your-project.iam.gserviceaccount.com"
      ]
    }
  ]
}
```

### Step 2: API Key Restrictions

1. **Restrict Generative AI Key**
   ```
   Application restrictions: HTTP referrers
   Website restrictions: 
   - https://your-domain.com/*
   - https://localhost:*/*
   ```

2. **Restrict by IP (Production)**
   ```
   IP addresses:
   - Your server IP
   - Firebase Cloud Run IPs
   ```

### Step 3: Firebase App Configuration

1. **Add Apps to Firebase Project**

2. **Android App**
   ```
   Package name: com.sahaayakai.sahaayak_ai
   SHA-1: (from your debug/release keystore)
   ```

3. **iOS App**
   ```
   Bundle ID: com.sahaayakai.sahaayakAi
   App Store ID: (when available)
   ```

4. **Web App**
   ```
   App nickname: Sahaayak AI Web
   Hosting: Enable Firebase Hosting
   ```

---

## 🌐 Environment Variables Setup

### Backend Environment (.env)

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=sahaayak-ai-backend@your-project.iam.gserviceaccount.com
FIREBASE_DATABASE_URL=https://your-project-default-rtdb.asia-southeast1.firebasedatabase.app/

# Google AI APIs
GOOGLE_API_KEY=your-generative-ai-api-key
VERTEX_AI_PROJECT_ID=your-project-id
VERTEX_AI_LOCATION=asia-south1

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=False
LOG_LEVEL=INFO

# Security
CORS_ORIGINS=["https://your-domain.com", "https://your-project.web.app"]
SECRET_KEY=your-super-secret-key-here
```

### Frontend Firebase Config

The FlutterFire CLI will generate this automatically, but verify it includes:

```dart
// lib/core/config/firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Auto-generated configuration
  }
}
```

---

## 📱 Mobile App Configuration

### Android Configuration

1. **Download google-services.json**
   - From Firebase Console → Project Settings → Your Apps
   - Place in `android/app/google-services.json`

2. **Update android/app/build.gradle**
   ```gradle
   dependencies {
     implementation platform('com.google.firebase:firebase-bom:32.7.0')
     implementation 'com.google.firebase:firebase-auth'
     implementation 'com.google.firebase:firebase-database'
     implementation 'com.google.firebase:firebase-storage'
   }
   ```

### iOS Configuration

1. **Download GoogleService-Info.plist**
   - From Firebase Console → Project Settings → Your Apps
   - Add to Xcode project in `ios/Runner/`

2. **Update ios/Runner/Info.plist**
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLName</key>
       <string>REVERSED_CLIENT_ID</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>your-reversed-client-id</string>
       </array>
     </dict>
   </array>
   ```

---

## 🚀 Deployment Configuration

### Cloud Run Setup

1. **Enable Cloud Run API**
   - Already enabled if following above steps

2. **Deploy Configuration**
   ```yaml
   # cloudbuild.yaml
   steps:
   - name: 'gcr.io/cloud-builders/docker'
     args: ['build', '-t', 'gcr.io/$PROJECT_ID/sahaayak-ai-backend', '.']
   - name: 'gcr.io/cloud-builders/docker'
     args: ['push', 'gcr.io/$PROJECT_ID/sahaayak-ai-backend']
   - name: 'gcr.io/cloud-builders/gcloud'
     args: ['run', 'deploy', 'sahaayak-ai-backend', 
            '--image', 'gcr.io/$PROJECT_ID/sahaayak-ai-backend',
            '--region', 'asia-south1',
            '--allow-unauthenticated']
   ```

### Firebase Hosting

1. **Initialize Hosting**
   ```bash
   firebase login
   firebase init hosting
   ```

2. **Deploy Web App**
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```

---

## ✅ Verification Checklist

### Firebase Verification
- [ ] Authentication enabled with Email/Password and Phone
- [ ] Realtime Database created with proper rules
- [ ] Cloud Storage enabled with security rules
- [ ] Service account created and JSON key downloaded

### Google Cloud Verification
- [ ] All required APIs enabled
- [ ] Billing account linked
- [ ] Vertex AI enabled in correct region
- [ ] Generative AI API key created
- [ ] IAM permissions configured

### Security Verification
- [ ] Database rules restrict access to authenticated users
- [ ] Storage rules prevent unauthorized access
- [ ] API keys restricted to specific domains/IPs
- [ ] Service account has minimal required permissions

### Testing Verification
- [ ] Backend can authenticate with Firebase
- [ ] API calls to Generative AI work
- [ ] Speech-to-Text API responds correctly
- [ ] Database read/write operations succeed
- [ ] File upload to Storage works

---

## 🔧 Troubleshooting

### Common Issues

1. **"Permission denied" errors**
   ```bash
   # Check IAM roles
   gcloud projects get-iam-policy your-project-id
   ```

2. **API quota exceeded**
   ```bash
   # Check quotas
   gcloud compute project-info describe --project=your-project-id
   ```

3. **Firebase connection issues**
   ```bash
   # Test Firebase connection
   firebase projects:list
   ```

4. **Authentication failures**
   - Verify service account JSON is correct
   - Check Firebase Authentication is enabled
   - Validate environment variables

### Support Resources

- **Firebase Support**: https://firebase.google.com/support
- **Google Cloud Support**: https://cloud.google.com/support
- **API Documentation**: https://cloud.google.com/docs

---

This completes the comprehensive setup for both Firebase and Google Cloud Console. Make sure to follow each step carefully and verify configurations before proceeding to development. 