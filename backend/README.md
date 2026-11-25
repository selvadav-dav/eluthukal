# 🌟 AGARAM Backend API

Production-ready REST API backend for the **AGARAM** Tamil Children's Educational Platform built with **Node.js**, **Express.js**, and **MySQL**.

---

## 📋 Table of Contents

1. [Requirements](#-requirements)
2. [Project Architecture](#-project-architecture)
3. [Installation](#-installation)
4. [MySQL Database Setup](#-mysql-database-setup)
5. [Environment Configuration (`.env`)](#-environment-configuration-env)
6. [Database Migration & Seed Data](#-database-migration--seed-data)
7. [Running the Application](#-running-the-application)
8. [API Documentation & Endpoints](#-api-documentation--endpoints)
9. [Authentication & Authorization](#-authentication--authorization)
10. [File Upload Pipeline](#-file-upload-pipeline)
11. [Flutter Frontend Connection Guide](#-flutter-frontend-connection-guide)
12. [Example API Requests (cURL)](#-example-api-requests-curl)

---

## 📦 Requirements

- **Node.js**: v18.0.0 or higher (v20+ recommended)
- **npm**: v9.0.0 or higher
- **MySQL**: 8.0 or higher

---

## 🏛 Project Architecture

Clean MVC-style structure:

```
backend/
├── src/
│   ├── config/             # Database pool, environment, CORS config
│   │   ├── db.js
│   │   ├── env.js
│   │   └── cors.js
│   ├── controllers/        # Request & response controllers
│   │   ├── adminAuthController.js
│   │   ├── userAuthController.js
│   │   ├── lessonController.js
│   │   ├── letterController.js
│   │   ├── storyController.js
│   │   ├── videoController.js
│   │   ├── quizController.js
│   │   ├── gameController.js
│   │   ├── progressController.js
│   │   └── dashboardController.js
│   ├── middleware/         # Auth guards, Multer, validator, error handler
│   │   ├── authMiddleware.js
│   │   ├── uploadMiddleware.js
│   │   ├── validateMiddleware.js
│   │   └── errorMiddleware.js
│   ├── models/             # Data access layer (MySQL SQL queries)
│   │   ├── adminModel.js
│   │   ├── userModel.js
│   │   ├── lessonModel.js
│   │   ├── letterModel.js
│   │   ├── storyModel.js
│   │   ├── videoModel.js
│   │   ├── quizModel.js
│   │   ├── gameModel.js
│   │   └── progressModel.js
│   ├── routes/             # REST route definitions & validation rules
│   │   ├── index.js
│   │   ├── adminAuthRoutes.js
│   │   ├── userAuthRoutes.js
│   │   ├── lessonRoutes.js
│   │   ├── letterRoutes.js
│   │   ├── storyRoutes.js
│   │   ├── videoRoutes.js
│   │   ├── quizRoutes.js
│   │   ├── gameRoutes.js
│   │   ├── progressRoutes.js
│   │   ├── dashboardRoutes.js
│   │   └── uploadRoutes.js
│   ├── services/           # Business logic (quiz grading, star calculations)
│   │   ├── quizService.js
│   │   └── progressService.js
│   ├── utils/              # Standard JSON response formatters, logger
│   │   ├── apiResponse.js
│   │   └── logger.js
│   └── scripts/            # Automated database bootstrap & seeds
│       └── initDb.js
├── uploads/                # Static asset uploads
│   ├── images/
│   ├── audio/
│   └── videos/
├── database/
│   └── schema.sql          # Relational DDL & initial content seed
├── .env.example
├── .env
├── package.json
├── server.js
└── README.md
```

---

## 🚀 Installation

Open your terminal and navigate to the `backend` folder:

```bash
cd backend
npm install
```

---

## 🗄 MySQL Database Setup

1. Ensure the MySQL service is running on your machine.
   - On Windows (PowerShell): `Get-Service MySQL80`
2. Create the `.env` file from the provided `.env.example`:
   ```bash
   cp .env.example .env
   ```
3. Set your MySQL root password in `.env`:
   ```ini
   DB_HOST=localhost
   DB_PORT=3306
   DB_USER=root
   DB_PASSWORD=your_mysql_password
   DB_NAME=eluthukal
   ```

---

## ⚙ Environment Configuration (`.env`)

| Variable | Default | Description |
| :--- | :--- | :--- |
| `PORT` | `5001` | Server listening port |
| `NODE_ENV` | `development` | Environment mode (`development`, `production`) |
| `API_PREFIX` | `/api/v1` | Base route prefix |
| `DB_HOST` | `localhost` | MySQL hostname or IP |
| `DB_PORT` | `3306` | MySQL port |
| `DB_USER` | `root` | MySQL database user |
| `DB_PASSWORD` | `root` | MySQL database password |
| `DB_NAME` | `eluthukal` | MySQL database name |
| `JWT_SECRET` | `agaram_super_secret...` | Secret key for signing JWT tokens |
| `JWT_EXPIRES_IN`| `7d` | Token validity duration |
| `UPLOAD_PATH` | `uploads` | Folder for storing file uploads |
| `MAX_FILE_SIZE_MB`| `50` | Maximum file upload size limit (MB) |
| `CORS_ORIGIN` | `*` | Allowed CORS origins (comma-separated or `*`) |

---

## 🔨 Database Migration & Seed Data

### Option 1: Automated Node.js Script (Recommended)

Run the built-in database setup script:

```bash
npm run db:init
```

This will:
- Connect to MySQL
- Automatically create the `eluthukal` database
- Create all 15 tables with foreign keys and indexes
- Seed default lessons, Uyir letters, Mei letters, reading stories, videos, quizzes, games, and the super admin account!

### Option 2: MySQL CLI (Manual)

```bash
mysql -u root -p < database/schema.sql
```

> **Default Super Admin Credentials**:
> - **Username**: `superadmin`
> - **Password**: `Admin@123`

---

## 🏁 Running the Application

### Development Mode (with hot-reloading via Nodemon)
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

### Verify Server Health
Visit: [http://localhost:5001/api/health](http://localhost:5001/api/health)
```json
{
  "success": true,
  "message": "AGARAM API is healthy",
  "data": {
    "service": "agaram-backend",
    "version": "1.0.0",
    "uptime": "12s",
    "timestamp": "2026-09-17T12:00:00.000Z"
  }
}
```

---

## 📡 API Documentation & Endpoints

All data API routes are prefixed with `/api/v1/`.

### 1. Public Health Check
- `GET /api/health` - Server health status

### 2. Admin Authentication
- `POST /api/v1/auth/admin/login` - Admin login with JWT generation
- `GET  /api/v1/auth/admin/me` - Authenticated admin profile `[Bearer Token Required]`
- `POST /api/v1/auth/admin/change-password` - Change admin password `[Bearer Token Required]`
- `POST /api/v1/auth/admin/create` - Create new admin account `[super_admin Only]`

### 3. Child User Profile & Session
- `POST /api/v1/users/register` - Register or initialize child learner profile
- `POST /api/v1/users/login` - Login with existing child profile ID
- `GET  /api/v1/users/profile/:id` - Fetch child profile and star stats
- `PUT  /api/v1/users/profile/:id` - Update child profile (name, age, avatar)

### 4. Educational Lessons & Categories
- `GET    /api/v1/lessons` - List all active lesson categories
- `GET    /api/v1/lessons/:id` - Get lesson category detail
- `POST   /api/v1/lessons` - Create lesson category `[Admin Only]`
- `PUT    /api/v1/lessons/:id` - Update lesson category `[Admin Only]`
- `DELETE /api/v1/lessons/:id` - Delete lesson category `[super_admin Only]`

### 5. Tamil Letters (Uyir, Mei, Aytham, Uyirmei)
- `GET    /api/v1/letters` - List letters (filter by `?type=uyir` or `?groupId=...`)
- `GET    /api/v1/letters/:id` - Get letter detail with words, meanings, phonetics, audio, image
- `GET    /api/v1/letters/groups` - List letter classification groups
- `POST   /api/v1/letters` - Create letter `[Admin Only]`
- `PUT    /api/v1/letters/:id` - Update letter `[Admin Only]`
- `DELETE /api/v1/letters/:id` - Delete letter `[super_admin Only]`
- `POST   /api/v1/letters/groups` - Create letter group `[Admin Only]`

### 6. Reading Stories (வாசிப்பு)
- `GET    /api/v1/stories` - List published stories
- `GET    /api/v1/stories/:id` - Get story with all pages and audio narration
- `POST   /api/v1/stories` - Create reading story `[Admin Only]`
- `PUT    /api/v1/stories/:id` - Update reading story `[Admin Only]`
- `DELETE /api/v1/stories/:id` - Delete reading story `[super_admin Only]`
- `POST   /api/v1/stories/:id/pages` - Add page to story `[Admin Only]`
- `PUT    /api/v1/stories/:id/pages/:pageId` - Update page `[Admin Only]`
- `DELETE /api/v1/stories/:id/pages/:pageId` - Delete page `[super_admin Only]`

### 7. Educational Videos
- `GET    /api/v1/videos` - List videos (optional filter: `?category=பாடல்`)
- `GET    /api/v1/videos/:id` - Get video detail
- `POST   /api/v1/videos` - Create video item `[Admin Only]`
- `PUT    /api/v1/videos/:id` - Update video item `[Admin Only]`
- `DELETE /api/v1/videos/:id` - Delete video item `[super_admin Only]`

### 8. Quizzes & Evaluation
- `GET    /api/v1/quizzes` - List quizzes by category (`?category=uyir`)
- `GET    /api/v1/quizzes/:id` - Get quiz questions (answers hidden for child learners)
- `POST   /api/v1/quizzes/:id/submit` - Submit answers, evaluate score, update stars
- `POST   /api/v1/quizzes` - Create quiz `[Admin Only]`
- `PUT    /api/v1/quizzes/:id` - Update quiz `[Admin Only]`
- `DELETE /api/v1/quizzes/:id` - Delete quiz `[super_admin Only]`
- `POST   /api/v1/quizzes/:id/questions` - Add question with multiple options `[Admin Only]`
- `DELETE /api/v1/quizzes/:id/questions/:questionId` - Delete question `[super_admin Only]`

### 9. Interactive Learning Games
- `GET    /api/v1/games` - List games (filter by `?gameType=puzzle` or `balloon`)
- `GET    /api/v1/games/:id` - Get single game question
- `POST   /api/v1/games` - Create game item `[Admin Only]`
- `PUT    /api/v1/games/:id` - Update game item `[Admin Only]`
- `DELETE /api/v1/games/:id` - Delete game item `[super_admin Only]`

### 10. Student Progress & Stars
- `GET  /api/v1/progress/:userId` - Get aggregated progress (compatible with Flutter `UserProgressModel`)
- `POST /api/v1/progress/:userId/update` - Record completion for letter, story, or game
- `GET  /api/v1/progress/:userId/quiz-results` - Get user's quiz attempt history
- `GET  /api/v1/progress/:userId/stars` - Get current total stars, streaks

### 11. Admin Dashboard & Monitoring `[Protected]`
- `GET /api/v1/admin/dashboard/stats` - Total users, lessons, letters, stories, quizzes, total stars
- `GET /api/v1/admin/dashboard/users` - Paginated child learner list
- `GET /api/v1/admin/dashboard/quiz-results` - Audit log of all quiz submissions

### 12. Media Uploads `[Protected]`
- `POST /api/v1/admin/upload/image` - Upload image (`image/jpeg`, `image/png`, `image/webp`, `image/svg+xml`)
- `POST /api/v1/admin/upload/audio` - Upload audio (`audio/mpeg`, `audio/wav`, `audio/aac`, `audio/m4a`)
- `POST /api/v1/admin/upload/video` - Upload video (`video/mp4`, `video/webm`)

---

## 🔒 Authentication & Authorization

- Passwords are encrypted using **bcryptjs** (10 salt rounds).
- Admin sessions use **JSON Web Tokens (JWT)**.
- Include the token in the `Authorization` header for protected endpoints:
  ```
  Authorization: Bearer <your_jwt_token>
  ```
- Role-based access control:
  - `super_admin`: Full access, delete privileges, admin creation.
  - `content_admin`: Content CRUD (letters, stories, videos, quizzes), dashboard viewing.

---

## 📤 File Upload Pipeline

- Powered by **Multer**.
- Uploads are saved inside the `backend/uploads/` directory:
  - `uploads/images/`
  - `uploads/audio/`
  - `uploads/videos/`
- Express serves these statically at: `http://localhost:5001/uploads/...`
- File size limit: **50MB** (configurable in `.env`).

---

## 📱 Flutter Frontend Connection Guide

### 1. Base URL Resolution
- **Android Emulator**: Use `http://10.0.2.2:5001/api/v1`
- **iOS Simulator**: Use `http://localhost:5001/api/v1`
- **Physical Device**: Use your local WiFi IP: `http://192.168.x.x:5001/api/v1`

### 2. Sample Flutter Integration Service
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AgaramApiService {
  static const String baseUrl = 'http://10.0.2.2:5001/api/v1';

  // Fetch Uyir Letters from MySQL Backend
  static async Future<List<dynamic>> fetchUyirLetters() async {
    final response = await http.get(Uri.parse('$baseUrl/letters?type=uyir'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    throw Exception('Failed to load letters: ${response.body}');
  }

  // Submit Quiz Answers
  static async Future<Map<String, dynamic>> submitQuiz(String quizId, String userId, List<Map<String, dynamic>> answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quizzes/$quizId/submit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'answers': answers,
      }),
    );
    return jsonDecode(response.body)['data'];
  }
}
```

---

## 🧪 Example API Requests (cURL)

### 1. Health Check
```bash
curl -X GET http://localhost:5001/api/health
```

### 2. Fetch Uyir Letters
```bash
curl -X GET http://localhost:5001/api/v1/letters?type=uyir
```

### 3. Admin Login
```bash
curl -X POST http://localhost:5001/api/v1/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username": "superadmin", "password": "Admin@123"}'
```

### 4. Fetch Reading Stories
```bash
curl -X GET http://localhost:5001/api/v1/stories
```

### 5. Submit Quiz Answers
```bash
curl -X POST http://localhost:5001/api/v1/quizzes/quiz_uyir/submit \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "default_child",
    "answers": [
      {"questionId": "q_uyir_1", "selectedOptionId": 1},
      {"questionId": "q_uyir_2", "selectedOptionId": 6}
    ]
  }'
```
