# 🌟 AGARAM (அகரம்) — எழுத்துக்கள் (Eluthukal)

<p align="center">
  <b>A Comprehensive, Modern Full-Stack Ecosystem for Tamil Language Education</b>
  <br />
  <i>Interactive Children's Learning App • On-Device AI Handwriting Recognition • Admin Management Portal • REST API Backend</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Node.js-18+-339933?style=for-the-badge&logo=node.js&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/Express.js-4.x-000000?style=for-the-badge&logo=express&logoColor=white" alt="Express.js" />
  <img src="https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL" />
  <img src="https://img.shields.io/badge/React-18-61DAFB?style=for-the-badge&logo=react&logoColor=black" alt="React" />
  <img src="https://img.shields.io/badge/Vite-5.x-646CFF?style=for-the-badge&logo=vite&logoColor=white" alt="Vite" />
  <img src="https://img.shields.io/badge/PyTorch%20%2F%20TFLite-AI%20Recognition-EE4C2C?style=for-the-badge&logo=pytorch&logoColor=white" alt="PyTorch" />
</p>

---

## 📖 Overview

**AGARAM (எழுத்துக்கள் - Eluthukal)** is an end-to-end educational platform designed to make learning the Tamil language interactive, fun, and accessible for children and beginners. It combines an engaging mobile application, an intelligent real-time handwriting recognition AI model, a robust backend REST API, and an intuitive web administration panel.

---

## ✨ Key Features

- 🔤 **Comprehensive Letter Learning:** உயிர் (Vowels), மெய் (Consonants), உயிர்மெய் (Compound), and ஆய்த எழுத்து with standard phonetics and stroke guides.
- ✍️ **AI Handwriting Recognition:** On-device CNN model that evaluates children's handwriting canvas strokes in real-time with instant pedagogical feedback.
- 📚 **Interactive Stories & Rhymes:** Tamil moral stories (நீதிக்கதைகள்) and rhymes with synchronized audio narration and bilingual support.
- 🎮 **Gamified Quizzes & Badges:** Letter matching, spelling challenges, progress tracking, stars, and unlockable achievement rewards.
- 🖥️ **Centralized Admin Dashboard:** Manage learning content, categories, audio media, student analytics, and system users.
- 🔒 **Secure REST API Backend:** Node.js Express server with JWT role-based authentication, MySQL database persistence, and file management.

---

## 📁 Repository Structure

```text
eluthukal/
├── 📱 frontend/              # Cross-Platform Flutter Application (Android / iOS / Web / Desktop)
│   ├── lib/                  # Dart source code (screens, widgets, controllers, services)
│   ├── assets/               # Media assets (images, audio pronunciations, SVG icons, Lottie)
│   └── pubspec.yaml          # Flutter dependencies & asset configurations
│
├── ⚙️ backend/               # Production-grade Node.js + Express REST API
│   ├── server.js             # API entry point & static asset streaming
│   ├── src/                  # Controllers, routes, middleware, validation, services
│   ├── database/             # MySQL schema, seed files, and migration scripts
│   └── .env                  # Backend environment configuration
│
├── 🖥️ admin-panel/           # React + Vite + TypeScript Web Dashboard
│   ├── src/                  # Admin UI components, management pages, API client
│   ├── package.json          # Frontend admin dependencies
│   └── .env                  # Admin panel environment configuration
│
└── 🧠 ai_model/              # Tamil Handwritten Character Recognition Engine
    ├── dataset/              # Training, validation & test stroke datasets
    ├── models/               # PyTorch checkpoints (.pth) and exported TensorFlow Lite (.tflite)
    ├── scripts/              # Training, preprocessing, benchmarking & evaluation scripts
    └── labels/               # Character index mappings (labels.txt)
```

---

## 🚀 Quick Start Guide

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.16+)
- [Node.js](https://nodejs.org/) (v18+) & `npm`
- [MySQL Server](https://dev.mysql.com/downloads/mysql/) (v8.0+) or XAMPP
- [Python](https://www.python.org/) (v3.9+) *(Optional, for AI model training)*

---

### 1️⃣ Backend Setup (Node.js & MySQL)

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Configure environment variables:
   * Copy `.env.example` to `.env` and configure your database credentials:
   ```env
   PORT=5001
   DB_HOST=localhost
   DB_PORT=3306
   DB_USER=root
   DB_PASSWORD=your_mysql_password
   DB_NAME=eluthukal
   JWT_SECRET=your_jwt_secret_key
   ```

4. Initialize and seed the MySQL database:
   ```bash
   npm run db:init
   ```

5. Start the backend development server:
   ```bash
   npm run dev
   ```
   *API will run at:* `http://localhost:5001`  
   *Health Check:* `http://localhost:5001/api/health`

---

### 2️⃣ Admin Panel Setup (React + Vite)

1. Navigate to the admin panel directory:
   ```bash
   cd admin-panel
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the Vite development server:
   ```bash
   npm run dev
   ```
   *Access dashboard at:* `http://localhost:5173`

> **Default Admin Credentials:**
> - **Username:** `superadmin`
> - **Password:** `Admin@123`

---

### 3️⃣ Mobile Application Setup (Flutter)

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install Flutter packages:
   ```bash
   flutter pub get
   ```

3. Run the app on your connected device, emulator, or Chrome:
   ```bash
   flutter run
   ```

---

### 4️⃣ AI Handwriting Recognition (Optional)

1. Navigate to the AI model directory:
   ```bash
   cd ai_model
   ```

2. Create a virtual environment & install requirements:
   ```bash
   python -m venv .venv
   # Windows:
   .venv\Scripts\activate
   # Linux/Mac:
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. Evaluate the character recognition model:
   ```bash
   python scripts/evaluate_huggingface_model.py
   ```

---

## 🛠️ Tech Stack & Architecture

| Module | Technologies |
| :--- | :--- |
| **Mobile App (Frontend)** | Flutter, Dart, Provider / Riverpod, AudioPlayers, CustomPainter Canvas |
| **Admin Web Dashboard** | React 18, TypeScript, Vite, TailwindCSS / Lucide Icons, Axios |
| **Backend API** | Node.js, Express.js, MySQL2, JWT, Helmet, Morgan, Multer |
| **AI / ML Model** | PyTorch, Torchvision, TensorFlow Lite (TFLite), NumPy, OpenCV |
| **Database** | MySQL (with relational schema, utf8mb4 Tamil Unicode support) |

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!  
Feel free to check the [Issues](https://github.com/selvadav-dav/eluthukal/issues) page.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **ISC License**.

---

<p align="center">
  Made with ❤️ for Tamil Education by <b>Selva & AGARAM Team</b>
</p>